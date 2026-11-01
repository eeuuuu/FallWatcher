// 32x24 MLX heat map, 8x pixels, top-right side window. Dual-clock BRAM.
module j7_thermal_osd #(
	parameter [10:0] ORIGIN_X = 11'd1648,
	parameter [10:0] ORIGIN_Y = 11'd16,
	parameter [10:0] SCALE    = 11'd8,
	parameter [10:0] BORDER   = 11'd2
) (
	input  wire       wr_clk,
	input  wire       wr_en,
	input  wire [9:0] wr_addr,
	input  wire [7:0] wr_data,
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
	output reg  [7:0] o_b
);

localparam [10:0] WIN_W = 11'd256;
localparam [10:0] WIN_H = 11'd192;

(* syn_ramstyle = "block_ram" *)
reg [7:0] mem [0:767];
reg [7:0] rd_q;

reg        vs_d, de_d;
reg [10:0] x, y;

always @(posedge wr_clk) begin
	if (wr_en)
		mem[wr_addr] <= wr_data;
end

wire [10:0] px = x - ORIGIN_X;
wire [10:0] py = y - ORIGIN_Y;
wire        in_win = i_de &&
	(x >= ORIGIN_X) && (x < (ORIGIN_X + WIN_W)) &&
	(y >= ORIGIN_Y) && (y < (ORIGIN_Y + WIN_H));
wire        on_border = i_de &&
	(x >= (ORIGIN_X - BORDER)) && (x < (ORIGIN_X + WIN_W + BORDER)) &&
	(y >= (ORIGIN_Y - BORDER)) && (y < (ORIGIN_Y + WIN_H + BORDER)) &&
	!in_win;
wire [4:0] sx = px[7:3];
wire [4:0] sy = py[7:3];
wire [9:0] rd_addr = {sy, 5'd0} + {5'd0, sx};

always @(posedge clk) begin
	rd_q <= mem[rd_addr];
end

wire [7:0] v = rd_q;
wire [7:0] cr = (v < 8'd64)  ? 8'd0 :
	(v < 8'd128) ? {v[5:0], 2'b00} :
	8'd255;
wire [7:0] cg = (v < 8'd64)  ? {v[5:0], 2'b00} :
	(v < 8'd128) ? 8'd255 :
	(v < 8'd192) ? (8'd255 - {v[5:0], 2'b00}) :
	8'd0;
wire [7:0] cb = (v < 8'd64)  ? 8'd255 :
	(v < 8'd128) ? (8'd255 - {v[5:0], 2'b00}) :
	8'd0;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d <= 1'b0;
		de_d <= 1'b0;
		x <= 11'd0;
		y <= 11'd0;
		o_hs <= 1'b0;
		o_vs <= 1'b0;
		o_de <= 1'b0;
		o_r <= 8'd0;
		o_g <= 8'd0;
		o_b <= 8'd0;
	end else begin
		vs_d <= i_vs;
		de_d <= i_de;
		if (vs_d != i_vs)
			y <= 11'd0;
		else if (de_d && !i_de && (y != 11'd2047))
			y <= y + 11'd1;
		if (!i_de)
			x <= 11'd0;
		else
			x <= x + 11'd1;
		o_hs <= i_hs;
		o_vs <= i_vs;
		o_de <= i_de;
		if (on_border) begin
			o_r <= 8'h40;
			o_g <= 8'hFF;
			o_b <= 8'hC0;
		end else if (in_win) begin
			o_r <= cr;
			o_g <= cg;
			o_b <= cb;
		end else begin
			o_r <= i_r;
			o_g <= i_g;
			o_b <= i_b;
		end
	end
end

endmodule
