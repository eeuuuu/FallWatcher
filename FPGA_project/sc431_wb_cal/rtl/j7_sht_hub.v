// SHT30 on shared J7-39/40 I2C. Cmd 0x2400, CRC-8, 1 Hz.
// Only drives the bus when bus_grant=1 (MLX idle window).
module j7_sht_hub (
	input  wire       clk,
	input  wire       rst_n,
	output reg        sht_ack,
	output reg  [7:0] temp_c,
	output reg  [7:0] humid,
	input  wire       vs_i,
	output reg [15:0] ts,
	output wire       scl_oe,
	output wire       sda_oe,
	input  wire       scl_i,
	input  wire       sda_i,
	input  wire       bus_grant,
	output wire       bus_want,
	output wire       bus_busy
);

localparam [2:0] P_PWR  = 3'd0;
localparam [2:0] P_CMD  = 3'd1;
localparam [2:0] P_CONV = 3'd2;
localparam [2:0] P_RD   = 3'd3;
localparam [2:0] P_IDLE = 3'd4;

localparam [7:0] A_W = 8'h88;
localparam [7:0] A_R = 8'h89;
localparam [24:0] WAIT_PWR  = 25'd8000000;
localparam [24:0] WAIT_CONV = 25'd2500000;
localparam [24:0] WAIT_1S   = 25'd25000000;

reg [2:0]  phase;
reg [3:0]  idx;
reg        issued;
reg [24:0] wait_cnt;
reg [7:0]  b0, b1, b2, b3, b4, b5;
reg        do_upd;
reg        saw_ack;
reg        have_s;
reg [7:0]  t0, t1, t2, h0, h1, h2;
reg [15:0] frame_n;
reg        vs_d;

reg        sta, sto, rd, wr, ack_in;
reg [7:0]  din;
wire       cmd_ack;
wire       ack_out;
wire [7:0] dout;
wire       i2c_al;
wire       scl_o, sda_o, scl_oen, sda_oen;

assign scl_oe = bus_grant & ~scl_oen;
assign sda_oe = bus_grant & ~sda_oen;
assign bus_want = (phase == P_CMD) || (phase == P_RD);
assign bus_busy = issued;

i2c_master_byte_ctrl u_i2c (
	.clk     (clk),
	.rst     (1'b0),
	.nReset  (rst_n),
	.ena     (bus_grant),
	.clk_cnt (16'd62),
	.start   (sta),
	.stop    (sto),
	.read    (rd),
	.write   (wr),
	.ack_in  (ack_in),
	.din     (din),
	.cmd_ack (cmd_ack),
	.ack_out (ack_out),
	.dout    (dout),
	.i2c_busy(),
	.i2c_al  (i2c_al),
	.scl_i   (scl_i),
	.scl_o   (scl_o),
	.scl_oen (scl_oen),
	.sda_i   (sda_i),
	.sda_o   (sda_o),
	.sda_oen (sda_oen)
);

function [7:0] crc8_sht;
	input [15:0] data;
	integer i;
	reg [7:0] crc;
	begin
		crc = 8'hFF;
		crc = crc ^ data[15:8];
		for (i = 0; i < 8; i = i + 1)
			crc = crc[7] ? ({crc[6:0], 1'b0} ^ 8'h31) : {crc[6:0], 1'b0};
		crc = crc ^ data[7:0];
		for (i = 0; i < 8; i = i + 1)
			crc = crc[7] ? ({crc[6:0], 1'b0} ^ 8'h31) : {crc[6:0], 1'b0};
		crc8_sht = crc;
	end
endfunction

wire crc_t_ok = (crc8_sht({b0, b1}) == b2);
wire crc_h_ok = (crc8_sht({b3, b4}) == b5);
wire not_ff   = ({b0, b1} != 16'hFFFF) && ({b3, b4} != 16'hFFFF);
wire [23:0] tmul = {b0, b1} * 8'd175;
wire [23:0] hmul = {b3, b4} * 8'd100;
wire [8:0]  ttmp = {1'b0, tmul[23:16]};
wire [8:0]  tcal = (ttmp > 9'd45) ? (ttmp - 9'd45) : 9'd0;
wire [7:0]  t_c  = (tcal > 9'd99) ? 8'd99 : tcal[7:0];
wire [7:0]  h_c  = (hmul[23:16] > 8'd99) ? 8'd99 : hmul[23:16];

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		phase    <= P_PWR;
		idx      <= 4'd0;
		issued   <= 1'b0;
		wait_cnt <= 25'd0;
		b0 <= 8'd0; b1 <= 8'd0; b2 <= 8'd0;
		b3 <= 8'd0; b4 <= 8'd0; b5 <= 8'd0;
		do_upd   <= 1'b0;
		saw_ack  <= 1'b0;
		have_s   <= 1'b0;
		t0 <= 8'd0; t1 <= 8'd0; t2 <= 8'd0;
		h0 <= 8'd0; h1 <= 8'd0; h2 <= 8'd0;
		frame_n  <= 16'd0;
		vs_d     <= 1'b0;
		ts       <= 16'd0;
		sht_ack  <= 1'b0;
		temp_c   <= 8'd0;
		humid    <= 8'd0;
		sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
		ack_in <= 1'b0;
		din <= 8'd0;
	end else begin
		vs_d <= vs_i;
		if (vs_i != vs_d)
			frame_n <= frame_n + 16'd1;
		if (i2c_al) begin
			issued   <= 1'b0;
			sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
			phase    <= P_IDLE;
			idx      <= 4'd0;
			wait_cnt <= 25'd0;
			sht_ack  <= 1'b0;
		end else case (phase)
			P_PWR: begin
				wait_cnt <= wait_cnt + 25'd1;
				if (wait_cnt >= WAIT_PWR) begin
					phase    <= P_CMD;
					idx      <= 4'd0;
					issued   <= 1'b0;
					wait_cnt <= 25'd0;
					saw_ack  <= 1'b0;
				end
			end
			P_CONV: begin
				wait_cnt <= wait_cnt + 25'd1;
				if (wait_cnt >= WAIT_CONV) begin
					phase    <= P_RD;
					idx      <= 4'd0;
					issued   <= 1'b0;
					wait_cnt <= 25'd0;
				end
			end
			P_IDLE: begin
				if (do_upd) begin
					do_upd <= 1'b0;
					if (crc_t_ok && crc_h_ok && not_ff) begin
						if (!have_s) begin
							t0 <= t_c; t1 <= t_c; t2 <= t_c;
							h0 <= h_c; h1 <= h_c; h2 <= h_c;
							temp_c  <= t_c;
							humid   <= h_c;
							have_s  <= 1'b1;
							sht_ack <= 1'b1;
							ts      <= frame_n;
						end else if (((t_c > t0) ? (t_c - t0) : (t0 - t_c)) < 8'd20) begin
							t2 <= t1; t1 <= t0; t0 <= t_c;
							h2 <= h1; h1 <= h0; h0 <= h_c;
							temp_c  <= ({2'b0, t_c} + {2'b0, t0} + {2'b0, t1} + {2'b0, t2}) >> 2;
							humid   <= ({2'b0, h_c} + {2'b0, h0} + {2'b0, h1} + {2'b0, h2}) >> 2;
							sht_ack <= 1'b1;
							ts      <= frame_n;
						end
					end else
						sht_ack <= saw_ack;
				end
				wait_cnt <= wait_cnt + 25'd1;
				if (wait_cnt >= WAIT_1S) begin
					phase    <= P_CMD;
					idx      <= 4'd0;
					issued   <= 1'b0;
					wait_cnt <= 25'd0;
					saw_ack  <= 1'b0;
				end
			end
			default: begin
				if (!issued) begin
					if (!bus_grant) begin
						sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
					end else begin
					issued <= 1'b1;
					sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
					ack_in <= 1'b0;
					if (phase == P_CMD) begin
						case (idx)
							4'd0: begin sta <= 1'b1; wr <= 1'b1; din <= A_W; end
							4'd1: begin wr <= 1'b1; din <= 8'h24; end
							default: begin wr <= 1'b1; sto <= 1'b1; din <= 8'h00; end
						endcase
					end else begin
						case (idx)
							4'd0: begin sta <= 1'b1; wr <= 1'b1; din <= A_R; end
							4'd6: begin rd <= 1'b1; ack_in <= 1'b1; sto <= 1'b1; end
							default: begin rd <= 1'b1; ack_in <= 1'b0; end
						endcase
					end
					end
				end else if (cmd_ack) begin
					issued <= 1'b0;
					sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
					if (phase == P_CMD) begin
						if (idx == 4'd0)
							saw_ack <= ~ack_out;
						if (idx == 4'd2) begin
							sht_ack  <= saw_ack | ~ack_out;
							phase    <= P_CONV;
							idx      <= 4'd0;
							wait_cnt <= 25'd0;
						end else
							idx <= idx + 4'd1;
					end else begin
						if (idx == 4'd0)
							saw_ack <= saw_ack & ~ack_out;
						if (idx == 4'd1) b0 <= dout;
						if (idx == 4'd2) b1 <= dout;
						if (idx == 4'd3) b2 <= dout;
						if (idx == 4'd4) b3 <= dout;
						if (idx == 4'd5) b4 <= dout;
						if (idx == 4'd6) begin
							b5       <= dout;
							do_upd   <= 1'b1;
							phase    <= P_IDLE;
							idx      <= 4'd0;
							wait_cnt <= 25'd0;
						end else
							idx <= idx + 4'd1;
					end
				end
			end
		endcase
	end
end

endmodule
