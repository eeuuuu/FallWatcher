// 8x subsampled frame-diff on 2-pixel/clk RGB. No NN.
// Y≈(R+2G+B)/4, |Y-Yprev| > THRESH accumulates a bbox for the next HDMI frame.
module motion_frame_diff #(
	parameter [7:0]  THRESH   = 8'd28,
	parameter [15:0] MIN_AREA = 16'd16,
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
	output reg  [10:0] o_y1
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

wire hit = sample_d && (abs_d > THRESH);

reg [7:0]  xmin, xmax, ymin, ymax;
reg [15:0] area;
reg        have;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d    <= 1'b0;
		de_d    <= 1'b0;
		hcnt    <= 10'd0;
		vcnt    <= 11'd0;
		xmin    <= 8'd0;
		xmax    <= 8'd0;
		ymin    <= 8'd0;
		ymax    <= 8'd0;
		area    <= 16'd0;
		have    <= 1'b0;
		o_valid <= 1'b0;
		o_x0    <= 11'd0;
		o_y0    <= 11'd0;
		o_x1    <= 11'd0;
		o_y1    <= 11'd0;
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
			if (have && (area >= MIN_AREA)) begin
				o_valid <= 1'b1;
				o_x0    <= {xmin, 3'b000};
				o_y0    <= {ymin, 3'b000};
				o_x1    <= {xmax, 3'b111};
				o_y1    <= {ymax, 3'b111};
			end else begin
				o_valid <= 1'b0;
			end
			xmin <= 8'hFF;
			xmax <= 8'd0;
			ymin <= 8'hFF;
			ymax <= 8'd0;
			area <= 16'd0;
			have <= 1'b0;
		end else if (hit && (h_idx_d < H_SUB[7:0]) && (v_idx_d < V_SUB[7:0])) begin
			have <= 1'b1;
			if (area != 16'hFFFF)
				area <= area + 16'd1;
			if (h_idx_d < xmin) xmin <= h_idx_d;
			if (h_idx_d > xmax) xmax <= h_idx_d;
			if (v_idx_d < ymin) ymin <= v_idx_d;
			if (v_idx_d > ymax) ymax <= v_idx_d;
		end
	end
end

endmodule
