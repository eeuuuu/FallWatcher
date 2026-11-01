// Empty-scene 10s countdown then low-power. Host sim: 04-tool/fal_sim.py IdleLp.
// Empty = no box and not MOT/IN/FAL (IDL / IR / AC all count).
// Any MOT/IN/FAL or box clears the timer and leaves LP.
module idle_lp (
	input  wire       clk,
	input  wire       rst_n,
	input  wire       i_vs,
	input  wire [2:0] evt_code,
	input  wire       box_show,
	output reg        lp,
	output reg  [1:0] lp_st,
	output reg  [3:0] sec
);

reg vs_d;
wire vs_tick = vs_d & ~i_vs;
wire busy = box_show || (evt_code == 3'd1) || (evt_code == 3'd3) ||
	(evt_code == 3'd4);
reg [9:0] cnt;

function [3:0] sec_left;
	input [9:0] n;
	begin
		if (n < 10'd60) sec_left = 4'd10;
		else if (n < 10'd120) sec_left = 4'd9;
		else if (n < 10'd180) sec_left = 4'd8;
		else if (n < 10'd240) sec_left = 4'd7;
		else if (n < 10'd300) sec_left = 4'd6;
		else if (n < 10'd360) sec_left = 4'd5;
		else if (n < 10'd420) sec_left = 4'd4;
		else if (n < 10'd480) sec_left = 4'd3;
		else if (n < 10'd540) sec_left = 4'd2;
		else sec_left = 4'd1;
	end
endfunction

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d  <= 1'b0;
		cnt   <= 10'd0;
		lp    <= 1'b0;
		lp_st <= 2'd0;
		sec   <= 4'd0;
	end else begin
		vs_d <= i_vs;
		if (vs_tick) begin
			if (busy) begin
				cnt   <= 10'd0;
				lp    <= 1'b0;
				lp_st <= 2'd0;
				sec   <= 4'd0;
			end else if (lp) begin
				lp_st <= 2'd2;
				sec   <= 4'd0;
			end else if (cnt >= 10'd599) begin
				lp    <= 1'b1;
				lp_st <= 2'd2;
				sec   <= 4'd0;
			end else begin
				cnt   <= cnt + 10'd1;
				lp_st <= 2'd1;
				sec   <= sec_left(cnt);
			end
		end
	end
end

endmodule
