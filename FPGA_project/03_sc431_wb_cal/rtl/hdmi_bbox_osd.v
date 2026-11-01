// Draw a 3-pixel red border from a frame-stable bbox. Counts on DE.
module hdmi_bbox_osd #(
	parameter [10:0] BORDER = 11'd3
) (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        i_hs,
	input  wire        i_vs,
	input  wire        i_de,
	input  wire [7:0]  i_r,
	input  wire [7:0]  i_g,
	input  wire [7:0]  i_b,
	input  wire        i_box_valid,
	input  wire [10:0] i_x0,
	input  wire [10:0] i_y0,
	input  wire [10:0] i_x1,
	input  wire [10:0] i_y1,
	output reg         o_hs,
	output reg         o_vs,
	output reg         o_de,
	output reg  [7:0]  o_r,
	output reg  [7:0]  o_g,
	output reg  [7:0]  o_b
);

reg        vs_d, de_d;
reg [10:0] x, y;
reg        box_v;
reg [10:0] x0, y0, x1, y1;

wire [10:0] x0e = x0;
wire [10:0] y0e = y0;
wire [10:0] x1e = (x1 < 11'd1919) ? x1 : 11'd1919;
wire [10:0] y1e = (y1 < 11'd1079) ? y1 : 11'd1079;

wire in_x = (x >= x0e) && (x <= x1e);
wire in_y = (y >= y0e) && (y <= y1e);
wire near_l = (x >= x0e) && (x <= (x0e + BORDER));
wire near_r = (x1e >= BORDER) && (x >= (x1e - BORDER)) && (x <= x1e);
wire near_t = (y >= y0e) && (y <= (y0e + BORDER));
wire near_b = (y1e >= BORDER) && (y >= (y1e - BORDER)) && (y <= y1e);
wire on_box = box_v && in_x && in_y && (near_l || near_r || near_t || near_b);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d  <= 1'b0;
		de_d  <= 1'b0;
		x     <= 11'd0;
		y     <= 11'd0;
		box_v <= 1'b0;
		x0    <= 11'd0;
		y0    <= 11'd0;
		x1    <= 11'd0;
		y1    <= 11'd0;
		o_hs  <= 1'b0;
		o_vs  <= 1'b0;
		o_de  <= 1'b0;
		o_r   <= 8'd0;
		o_g   <= 8'd0;
		o_b   <= 8'd0;
	end else begin
		vs_d <= i_vs;
		de_d <= i_de;

		if (vs_d != i_vs) begin
			y     <= 11'd0;
			box_v <= i_box_valid;
			x0    <= i_x0;
			y0    <= i_y0;
			x1    <= i_x1;
			y1    <= i_y1;
		end else if (de_d && !i_de && (y != 11'd2047))
			y <= y + 11'd1;

		if (!i_de)
			x <= 11'd0;
		else
			x <= x + 11'd1;

		o_hs <= i_hs;
		o_vs <= i_vs;
		o_de <= i_de;
		if (i_de && on_box) begin
			o_r <= 8'hFF;
			o_g <= 8'h18;
			o_b <= 8'h18;
		end else begin
			o_r <= i_r;
			o_g <= i_g;
			o_b <= i_b;
		end
	end
end

endmodule
