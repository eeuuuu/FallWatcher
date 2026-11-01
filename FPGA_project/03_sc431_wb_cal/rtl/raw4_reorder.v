// Official DDR order is {P4,P3} then {P2,P1}. Restore {P1,P2} then {P3,P4}.
// 2-cycle matched delay on HS/VS/DE/data: every 4-pixel group is emitted
// inside DE, no black pad at line start and no dropped tail pair.
// Pair phase is reset on HS, not on DE holes, so a 1-cycle DE glitch
// cannot flip the rest of the line.
module raw4_reorder (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        i_hs,
	input  wire        i_vs,
	input  wire        i_de,
	input  wire [15:0] i_dat,
	output reg         o_hs,
	output reg         o_vs,
	output reg         o_de,
	output reg  [15:0] o_dat
);

reg [15:0] dat_d;
reg        de_d, de_dd;
reg        hs_d, hs_dd;
reg        vs_d, vs_dd;
reg        pair_d, pair_dd;
reg [15:0] w0;

wire hs_rise = hs_d & ~hs_dd;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		dat_d   <= 16'd0;
		de_d    <= 1'b0;
		de_dd   <= 1'b0;
		hs_d    <= 1'b0;
		hs_dd   <= 1'b0;
		vs_d    <= 1'b0;
		vs_dd   <= 1'b0;
		pair_d  <= 1'b0;
		pair_dd <= 1'b0;
		w0      <= 16'd0;
		o_hs    <= 1'b0;
		o_vs    <= 1'b0;
		o_de    <= 1'b0;
		o_dat   <= 16'd0;
	end else begin
		dat_d <= i_dat;
		de_d  <= i_de;
		de_dd <= de_d;
		hs_d  <= i_hs;
		hs_dd <= hs_d;
		vs_d  <= i_vs;
		vs_dd <= vs_d;

		if (hs_rise)
			pair_d <= 1'b0;
		else if (de_d)
			pair_d <= ~pair_d;
		pair_dd <= pair_d;

		if (de_d && !pair_d)
			w0 <= dat_d;

		o_hs <= hs_dd;
		o_vs <= vs_dd;
		o_de <= de_dd;

		if (!de_dd)
			o_dat <= 16'd0;
		else if (!pair_dd)
			o_dat <= {dat_d[7:0], dat_d[15:8]};
		else
			o_dat <= {w0[7:0], w0[15:8]};
	end
end

endmodule
