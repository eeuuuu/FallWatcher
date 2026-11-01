// 96x96 grayscale capture (Y=(R+2G+B)/4, step 20x11) + 2x preview at bottom-left.
// Single BRAM page (Ti60 MEMORY already near full). Does not change frame-diff.
module gray96_preview #(
	parameter [10:0] ORIGIN_X = 11'd16,
	parameter [10:0] ORIGIN_Y = 11'd872,
	parameter [10:0] BORDER   = 11'd2
) (
	input  wire       clk,
	input  wire       rst_n,
	input  wire       i_hs,
	input  wire       i_vs,
	input  wire       i_de,
	input  wire [7:0] i_r,
	input  wire [7:0] i_g,
	input  wire [7:0] i_b,
	output reg        o_hs,
	output reg        o_vs,
	output reg        o_de,
	output reg  [7:0] o_r,
	output reg  [7:0] o_g,
	output reg  [7:0] o_b,
	input  wire       cpu_clk,
	input  wire       cpu_rst_n,
	input  wire [13:0] cpu_addr,
	output reg  [7:0] cpu_data,
	output wire [15:0] cpu_frame
);

localparam [10:0] WIN = 11'd192;

reg        vs_d, de_d;
reg [10:0] x, y;
reg [4:0]  x_mod;
reg [3:0]  y_mod;
reg [6:0]  x_idx, y_idx;
wire [9:0] y_sum = {2'b0, i_r} + {1'b0, i_g, 1'b0} + {2'b0, i_b};
wire [7:0] y8    = y_sum[9:2];

wire sample = i_de && (x_mod == 5'd0) && (y_mod == 4'd0) &&
		(x_idx < 7'd96) && (y_idx < 7'd96);
wire [13:0] wr_addr = {y_idx, 6'd0} + {1'b0, y_idx, 5'd0} + {7'd0, x_idx};

(* syn_ramstyle = "block_ram" *)
reg [7:0] mem [0:9215];
reg [7:0] rd_q;

wire [10:0] px = x - ORIGIN_X;
wire [10:0] py = y - ORIGIN_Y;
wire        in_win = i_de && (x >= ORIGIN_X) && (x < (ORIGIN_X + WIN)) &&
		(y >= ORIGIN_Y) && (y < (ORIGIN_Y + WIN));
wire        on_border = i_de &&
		(x >= (ORIGIN_X - BORDER)) && (x < (ORIGIN_X + WIN + BORDER)) &&
		(y >= (ORIGIN_Y - BORDER)) && (y < (ORIGIN_Y + WIN + BORDER)) &&
		!in_win;
wire [6:0]  sx = px[7:1];
wire [6:0]  sy = py[7:1];
wire [13:0] rd_addr = {sy, 6'd0} + {1'b0, sy, 5'd0} + {7'd0, sx};

always @(posedge clk) begin
	if (sample)
		mem[wr_addr] <= y8;
	rd_q <= mem[rd_addr];
end

always @(posedge cpu_clk)
	cpu_data <= mem[cpu_addr];

reg [15:0] frame_vid;
reg [15:0] frame_s0, frame_s1;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		frame_vid <= 16'd0;
	else if (!vs_d && i_vs)
		frame_vid <= frame_vid + 16'd1;
end
always @(posedge cpu_clk or negedge cpu_rst_n) begin
	if (!cpu_rst_n) begin
		frame_s0 <= 16'd0;
		frame_s1 <= 16'd0;
	end else begin
		frame_s0 <= frame_vid;
		frame_s1 <= frame_s0;
	end
end
assign cpu_frame = frame_s1;

reg       in_win_d, on_border_d;
reg [7:0] r_d, g_d, b_d;
reg       hs_d, vs_d2, de_d2;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d        <= 1'b0;
		de_d        <= 1'b0;
		x           <= 11'd0;
		y           <= 11'd0;
		x_mod       <= 5'd0;
		y_mod       <= 4'd0;
		x_idx       <= 7'd0;
		y_idx       <= 7'd0;
		in_win_d    <= 1'b0;
		on_border_d <= 1'b0;
		r_d         <= 8'd0;
		g_d         <= 8'd0;
		b_d         <= 8'd0;
		hs_d        <= 1'b0;
		vs_d2       <= 1'b0;
		de_d2       <= 1'b0;
		o_hs        <= 1'b0;
		o_vs        <= 1'b0;
		o_de        <= 1'b0;
		o_r         <= 8'd0;
		o_g         <= 8'd0;
		o_b         <= 8'd0;
	end else begin
		vs_d <= i_vs;
		de_d <= i_de;

		if (vs_d != i_vs) begin
			y         <= 11'd0;
			y_mod     <= 4'd0;
			y_idx     <= 7'd0;
		end else if (de_d && !i_de && (y != 11'd2047)) begin
			y <= y + 11'd1;
			if (y_mod == 4'd10) begin
				y_mod <= 4'd0;
				if (y_idx != 7'd127)
					y_idx <= y_idx + 7'd1;
			end else
				y_mod <= y_mod + 4'd1;
		end

		if (!i_de) begin
			x     <= 11'd0;
			x_mod <= 5'd0;
			x_idx <= 7'd0;
		end else begin
			x <= x + 11'd1;
			if (x_mod == 5'd19) begin
				x_mod <= 5'd0;
				if (x_idx != 7'd127)
					x_idx <= x_idx + 7'd1;
			end else
				x_mod <= x_mod + 5'd1;
		end

		in_win_d    <= in_win;
		on_border_d <= on_border;
		r_d         <= i_r;
		g_d         <= i_g;
		b_d         <= i_b;
		hs_d        <= i_hs;
		vs_d2       <= i_vs;
		de_d2       <= i_de;

		o_hs <= hs_d;
		o_vs <= vs_d2;
		o_de <= de_d2;
		if (de_d2 && on_border_d) begin
			o_r <= 8'h20;
			o_g <= 8'hE0;
			o_b <= 8'hE0;
		end else if (de_d2 && in_win_d) begin
			o_r <= rd_q;
			o_g <= rd_q;
			o_b <= rd_q;
		end else begin
			o_r <= r_d;
			o_g <= g_d;
			o_b <= b_d;
		end
	end
end

endmodule
