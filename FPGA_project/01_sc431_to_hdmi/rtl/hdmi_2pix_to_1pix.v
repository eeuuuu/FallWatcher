// Convert 2-pixel/clk video (vid_clk = hdmi_clk/2, same USER_PLL) to 1-pixel/clk HDMI.
// 74.375 MHz / 148.75 MHz (colorbar PLL). Capture on HDMI negedge (mid vid period).
// rgb_datax2 = {pix1[15:8], pix0[7:0]}. raw_to_rgb LSB=even/left, MSB=odd/right.
// Emit [23:0] (even) then [47:24] (odd). High-half-first swaps columns → vertical comb.
// Phase is forced to 0 during blanking so each line starts on the first half.
// HS/VS from the camera pipeline are active-high; set INV_SYNC=1 for CEA-861.
module hdmi_2pix_to_1pix #(
	parameter INV_SYNC = 1'b1
) (
	input  wire        vid_clk,
	input  wire        hdmi_clk,
	input  wire        rst_n,
	input  wire        i_hs,
	input  wire        i_vs,
	input  wire        i_de,
	input  wire [47:0] i_datax2,
	output reg         o_hs,
	output reg         o_vs,
	output reg         o_de,
	output reg  [7:0]  o_r,
	output reg  [7:0]  o_g,
	output reg  [7:0]  o_b
);

reg        hs_v, vs_v, de_v;
reg [47:0] pix_v;

always @(posedge vid_clk or negedge rst_n) begin
	if (!rst_n) begin
		hs_v  <= 1'b0;
		vs_v  <= 1'b0;
		de_v  <= 1'b0;
		pix_v <= 48'd0;
	end else begin
		hs_v  <= i_hs;
		vs_v  <= i_vs;
		de_v  <= i_de;
		pix_v <= i_datax2;
	end
end

reg        hs_n, vs_n, de_n;
reg [47:0] pix_n;

always @(negedge hdmi_clk or negedge rst_n) begin
	if (!rst_n) begin
		hs_n  <= 1'b0;
		vs_n  <= 1'b0;
		de_n  <= 1'b0;
		pix_n <= 48'd0;
	end else begin
		hs_n  <= hs_v;
		vs_n  <= vs_v;
		de_n  <= de_v;
		pix_n <= pix_v;
	end
end

reg        hs_d, vs_d, de_d;
reg        sel;
reg [47:0] hold;

always @(posedge hdmi_clk or negedge rst_n) begin
	if (!rst_n) begin
		hs_d  <= 1'b0;
		vs_d  <= 1'b0;
		de_d  <= 1'b0;
		sel   <= 1'b0;
		hold  <= 48'd0;
		o_hs  <= 1'b0;
		o_vs  <= 1'b0;
		o_de  <= 1'b0;
		o_r   <= 8'd0;
		o_g   <= 8'd0;
		o_b   <= 8'd0;
	end else begin
		hs_d <= hs_n;
		vs_d <= vs_n;
		de_d <= de_n;

		if (!de_d) begin
			sel  <= 1'b0;
			hold <= pix_n;
			{o_r, o_g, o_b} <= pix_n[47:24];
			o_de <= 1'b0;
		end else if (!sel) begin
			sel  <= 1'b1;
			hold <= pix_n;
			{o_r, o_g, o_b} <= pix_n[47:24];
			o_de <= 1'b1;
		end else begin
			sel  <= 1'b0;
			{o_r, o_g, o_b} <= hold[23:0];
			o_de <= 1'b1;
		end

		o_hs <= INV_SYNC ? ~hs_d : hs_d;
		o_vs <= INV_SYNC ? ~vs_d : vs_d;
	end
end

endmodule
