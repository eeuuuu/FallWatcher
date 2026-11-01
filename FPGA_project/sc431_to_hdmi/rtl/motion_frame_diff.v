// 8x subsampled frame-diff. Motion pixels, not a silhouette.
// MERGE_X only closes noise holes. Hands are high (small y1); people stand
// on the floor. Second box: two person CCs, gap>=28*8=224 px,
// centers>=36*8=288 px, both feet low. Closer blobs UNION. Two hands → one.
// A fragment is dropped, never drawn as box2.
module motion_frame_diff #(
	parameter [7:0]  THRESH   = 8'd28,
	parameter [15:0] MIN_AREA = 16'd16,
	parameter [7:0]  MERGE_X  = 8'd8,
	parameter [7:0]  MIN_H    = 8'd18,
	parameter [7:0]  MIN_W    = 8'd8,
	parameter [7:0]  SEP_X    = 8'd28,
	parameter [8:0]  SEP_C    = 9'd36,
	parameter [7:0]  MIN_Y1   = 8'd70,
	parameter [7:0]  Y1_SLACK = 8'd48,
	parameter        H_SUB    = 240,
	parameter        V_SUB    = 135
) (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        i_vs,
	input  wire        i_hs,
	input  wire        i_de,
	input  wire [47:0] i_datax2,
	output reg         o_valid,
	output reg  [10:0] o_x0,
	output reg  [10:0] o_y0,
	output reg  [10:0] o_x1,
	output reg  [10:0] o_y1,
	output reg         o_valid2,
	output reg  [10:0] o_x0_2,
	output reg  [10:0] o_y0_2,
	output reg  [10:0] o_x1_2,
	output reg  [10:0] o_y1_2
);

reg        vs_d, de_d;
reg [9:0]  hcnt;
reg [10:0] vcnt;

wire [7:0] r0 = i_datax2[23:16];
wire [7:0] g0 = i_datax2[15:8];
wire [7:0] b0 = i_datax2[7:0];
wire [9:0] y_sum = {2'b0, r0} + {1'b0, g0, 1'b0} + {2'b0, b0};
wire [7:0] y_cur = y_sum[9:2];

wire sample = i_de && (hcnt[1:0] == 2'b00) && (vcnt[2:0] == 3'b000);
wire [7:0]  h_idx = hcnt[9:2];
wire [7:0]  v_idx = vcnt[10:3];
wire [14:0] addr  = (v_idx << 8) - (v_idx << 4) + {7'b0, h_idx};

reg [7:0]  prev_mem [0:32767];
reg [7:0]  y_prev;
reg [7:0]  y_hold;
reg        sample_d;
reg [7:0]  h_idx_d, v_idx_d;

always @(posedge clk) begin
	if (sample) begin
		y_prev         <= prev_mem[addr];
		prev_mem[addr] <= y_cur;
		y_hold         <= y_cur;
	end
	sample_d <= sample;
	h_idx_d  <= h_idx;
	v_idx_d  <= v_idx;
end

wire [7:0] abs_d = (y_hold > y_prev) ? (y_hold - y_prev) : (y_prev - y_hold);
wire hit = sample_d && (abs_d > THRESH) &&
	(h_idx_d < H_SUB[7:0]) && (v_idx_d < V_SUB[7:0]);

reg        have0, have1;
reg [7:0]  x00, x01, y00, y01;
reg [7:0]  x10, x11, y10, y11;
reg [15:0] area0, area1;

wire [8:0] hx = {1'b0, h_idx_d};
wire [8:0] x00m = (x00 > MERGE_X) ? ({1'b0, x00} - {1'b0, MERGE_X}) : 9'd0;
wire [8:0] x01p = {1'b0, x01} + {1'b0, MERGE_X};
wire [8:0] x10m = (x10 > MERGE_X) ? ({1'b0, x10} - {1'b0, MERGE_X}) : 9'd0;
wire [8:0] x11p = {1'b0, x11} + {1'b0, MERGE_X};
wire near0 = have0 && (hx >= x00m) && (hx <= x01p);
wire near1 = have1 && (hx >= x10m) && (hx <= x11p);
wire [8:0] c0 = ({1'b0, x00} + {1'b0, x01}) >> 1;
wire [8:0] c1 = ({1'b0, x10} + {1'b0, x11}) >> 1;
wire [8:0] d0 = (hx > c0) ? (hx - c0) : (c0 - hx);
wire [8:0] d1 = (hx > c1) ? (hx - c1) : (c1 - hx);
wire pick0 = near0 && (!near1 || (d0 <= d1));
wire pick1 = near1 && (!near0 || (d1 < d0));

wire ok0 = have0 && (area0 >= MIN_AREA);
wire ok1 = have1 && (area1 >= MIN_AREA);
wire [7:0] h0 = (y01 > y00) ? (y01 - y00) : 8'd0;
wire [7:0] w0 = (x01 > x00) ? (x01 - x00) : 8'd0;
wire [7:0] h1 = (y11 > y10) ? (y11 - y10) : 8'd0;
wire [7:0] w1 = (x11 > x10) ? (x11 - x10) : 8'd0;
wire person0 = ok0 && (h0 >= MIN_H) && (w0 >= MIN_W);
wire person1 = ok1 && (h1 >= MIN_H) && (w1 >= MIN_W);
wire [8:0] gapx = (x01 < x10) ? ({1'b0, x10} - {1'b0, x01}) :
	(x11 < x00) ? ({1'b0, x00} - {1'b0, x11}) : 9'd0;
wire nested = (x00 <= x10 && x01 >= x11 && y00 <= y10 && y01 >= y11) ||
	(x10 <= x00 && x11 >= x01 && y10 <= y00 && y11 >= y01);
wire [7:0] ix0 = (x00 > x10) ? x00 : x10;
wire [7:0] iy0 = (y00 > y10) ? y00 : y10;
wire [7:0] ix1 = (x01 < x11) ? x01 : x11;
wire [7:0] iy1 = (y01 < y11) ? y01 : y11;
wire ov = (ix1 > ix0) && (iy1 > iy0);
wire [15:0] inter = ov ? ({8'd0, ix1 - ix0} * {8'd0, iy1 - iy0}) : 16'd0;
wire [15:0] a0 = {8'd0, w0} * {8'd0, h0};
wire [15:0] a1 = {8'd0, w1} * {8'd0, h1};
wire heavy = ov && ((inter > (a0 >> 1)) || (inter > (a1 >> 1)));
wire comparable = (h0 >= (h1 >> 1)) && (h1 >= (h0 >> 1));
wire separated = (gapx >= {1'b0, SEP_X});
wire [8:0] dc = (c0 > c1) ? (c0 - c1) : (c1 - c0);
wire far = (dc >= SEP_C);
wire ground0 = y01 >= MIN_Y1;
wire ground1 = y11 >= MIN_Y1;
wire same_floor = (y01 > y11) ? ((y01 - y11) <= Y1_SLACK) :
	((y11 - y01) <= Y1_SLACK);
/* Two people, not two arms / one-body split. 32 sub = 256 px. */
wire tall0 = h0 >= 8'd32;
wire tall1 = h1 >= 8'd32;
wire two_p = person0 && person1 && comparable && !nested && !heavy &&
	separated && far && ground0 && ground1 && same_floor && tall0 && tall1;

task expand0;
	begin
		have0 <= 1'b1;
		if (area0 != 16'hFFFF)
			area0 <= area0 + 16'd1;
		if (h_idx_d < x00) x00 <= h_idx_d;
		if (h_idx_d > x01) x01 <= h_idx_d;
		if (v_idx_d < y00) y00 <= v_idx_d;
		if (v_idx_d > y01) y01 <= v_idx_d;
	end
endtask

task expand1;
	begin
		have1 <= 1'b1;
		if (area1 != 16'hFFFF)
			area1 <= area1 + 16'd1;
		if (h_idx_d < x10) x10 <= h_idx_d;
		if (h_idx_d > x11) x11 <= h_idx_d;
		if (v_idx_d < y10) y10 <= v_idx_d;
		if (v_idx_d > y11) y11 <= v_idx_d;
	end
endtask

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d     <= 1'b0;
		de_d     <= 1'b0;
		hcnt     <= 10'd0;
		vcnt     <= 11'd0;
		have0    <= 1'b0;
		have1    <= 1'b0;
		x00 <= 8'd0; x01 <= 8'd0; y00 <= 8'd0; y01 <= 8'd0;
		x10 <= 8'd0; x11 <= 8'd0; y10 <= 8'd0; y11 <= 8'd0;
		area0    <= 16'd0;
		area1    <= 16'd0;
		o_valid  <= 1'b0;
		o_valid2 <= 1'b0;
		o_x0 <= 11'd0; o_y0 <= 11'd0; o_x1 <= 11'd0; o_y1 <= 11'd0;
		o_x0_2 <= 11'd0; o_y0_2 <= 11'd0; o_x1_2 <= 11'd0; o_y1_2 <= 11'd0;
	end else begin
		vs_d <= i_vs;
		de_d <= i_de;

		if (!i_de)
			hcnt <= 10'd0;
		else
			hcnt <= hcnt + 10'd1;

		if (vs_d && !i_vs)
			vcnt <= 11'd0;
		else if (de_d && !i_de && (vcnt != 11'd2047))
			vcnt <= vcnt + 11'd1;

		if (vs_d && !i_vs) begin
			if (two_p) begin
				if (x00 <= x10) begin
					o_valid  <= 1'b1;
					o_x0 <= {x00, 3'b000}; o_y0 <= {y00, 3'b000};
					o_x1 <= {x01, 3'b111}; o_y1 <= {y01, 3'b111};
					o_valid2 <= 1'b1;
					o_x0_2 <= {x10, 3'b000}; o_y0_2 <= {y10, 3'b000};
					o_x1_2 <= {x11, 3'b111}; o_y1_2 <= {y11, 3'b111};
				end else begin
					o_valid  <= 1'b1;
					o_x0 <= {x10, 3'b000}; o_y0 <= {y10, 3'b000};
					o_x1 <= {x11, 3'b111}; o_y1 <= {y11, 3'b111};
					o_valid2 <= 1'b1;
					o_x0_2 <= {x00, 3'b000}; o_y0_2 <= {y00, 3'b000};
					o_x1_2 <= {x01, 3'b111}; o_y1_2 <= {y01, 3'b111};
				end
			end else if (person0 && person1 && ground0 && ground1) begin
				o_valid  <= 1'b1;
				o_x0 <= {(x00 < x10) ? x00 : x10, 3'b000};
				o_y0 <= {(y00 < y10) ? y00 : y10, 3'b000};
				o_x1 <= {(x01 > x11) ? x01 : x11, 3'b111};
				o_y1 <= {(y01 > y11) ? y01 : y11, 3'b111};
				o_valid2 <= 1'b0;
			end else if (person1 && ground1 && !(person0 && ground0)) begin
				o_valid  <= 1'b1;
				o_x0 <= {x10, 3'b000}; o_y0 <= {y10, 3'b000};
				o_x1 <= {x11, 3'b111}; o_y1 <= {y11, 3'b111};
				o_valid2 <= 1'b0;
			end else if (person0 && ground0) begin
				o_valid  <= 1'b1;
				o_x0 <= {x00, 3'b000}; o_y0 <= {y00, 3'b000};
				o_x1 <= {x01, 3'b111}; o_y1 <= {y01, 3'b111};
				o_valid2 <= 1'b0;
			end else if (person0 && (!person1 || (h0 >= h1))) begin
				o_valid  <= 1'b1;
				o_x0 <= {x00, 3'b000}; o_y0 <= {y00, 3'b000};
				o_x1 <= {x01, 3'b111}; o_y1 <= {y01, 3'b111};
				o_valid2 <= 1'b0;
			end else if (person1) begin
				o_valid  <= 1'b1;
				o_x0 <= {x10, 3'b000}; o_y0 <= {y10, 3'b000};
				o_x1 <= {x11, 3'b111}; o_y1 <= {y11, 3'b111};
				o_valid2 <= 1'b0;
			end else if (ok0) begin
				o_valid  <= 1'b1;
				o_x0 <= {x00, 3'b000}; o_y0 <= {y00, 3'b000};
				o_x1 <= {x01, 3'b111}; o_y1 <= {y01, 3'b111};
				o_valid2 <= 1'b0;
			end else if (ok1) begin
				o_valid  <= 1'b1;
				o_x0 <= {x10, 3'b000}; o_y0 <= {y10, 3'b000};
				o_x1 <= {x11, 3'b111}; o_y1 <= {y11, 3'b111};
				o_valid2 <= 1'b0;
			end else begin
				o_valid  <= 1'b0;
				o_valid2 <= 1'b0;
			end
			have0 <= 1'b0;
			have1 <= 1'b0;
			area0 <= 16'd0;
			area1 <= 16'd0;
			x00 <= 8'hFF; x01 <= 8'd0; y00 <= 8'hFF; y01 <= 8'd0;
			x10 <= 8'hFF; x11 <= 8'd0; y10 <= 8'hFF; y11 <= 8'd0;
		end else if (hit) begin
			if (pick0)
				expand0;
			else if (pick1)
				expand1;
			else if (!have0)
				expand0;
			else if (!have1)
				expand1;
			/* else: two people, hit in the gap — do not grow them together */
		end
	end
end

endmodule
