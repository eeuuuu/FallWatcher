// Post-debayer per-channel WB. gain is Q8.8 (256 = 1.00x).
module rgb_wb_q88 (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        i_hs,
	input  wire        i_vs,
	input  wire        i_de,
	input  wire [7:0]  i_r,
	input  wire [7:0]  i_g,
	input  wire [7:0]  i_b,
	input  wire [15:0] r_gain,
	input  wire [15:0] g_gain,
	input  wire [15:0] b_gain,
	output reg         o_hs,
	output reg         o_vs,
	output reg         o_de,
	output reg  [7:0]  o_r,
	output reg  [7:0]  o_g,
	output reg  [7:0]  o_b
);

wire [23:0] pr = i_r * r_gain;
wire [23:0] pg = i_g * g_gain;
wire [23:0] pb = i_b * b_gain;
wire [15:0] sr = pr[23:8];
wire [15:0] sg = pg[23:8];
wire [15:0] sb = pb[23:8];

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		o_hs <= 1'b0;
		o_vs <= 1'b0;
		o_de <= 1'b0;
		o_r  <= 8'd0;
		o_g  <= 8'd0;
		o_b  <= 8'd0;
	end else begin
		o_hs <= i_hs;
		o_vs <= i_vs;
		o_de <= i_de;
		o_r  <= (sr > 16'd255) ? 8'd255 : sr[7:0];
		o_g  <= (sg > 16'd255) ? 8'd255 : sg[7:0];
		o_b  <= (sb > 16'd255) ? 8'd255 : sb[7:0];
	end
end

endmodule
