// CX-SP5F: 9600 8N1, FE ... BE. CLK=25 MHz.
module j7_voice_uart (
	input  wire       clk,
	input  wire       rst_n,
	input  wire       send_go,
	input  wire [7:0] send_byte,
	output wire       tx_busy,
	output reg        uart_tx,
	input  wire       uart_rx,
	output reg        rx_frame,
	output reg [7:0]  rx_cmd
);

localparam [15:0] DIV = 16'd2604;
localparam [15:0] MID = 16'd1302;

reg [1:0]  tx_st;
reg [3:0]  tx_bit;
reg [7:0]  tx_data;
reg [15:0] tx_div;
assign tx_busy = (tx_st != 2'd0);

reg        rx0, rx1, rx2;
reg [2:0]  rx_st;
reg [3:0]  rx_bit;
reg [7:0]  rx_data;
reg [15:0] rx_div;
reg [3:0]  rx_n;
reg        rx_in_fe;
reg [7:0]  rx_cmd_l;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		tx_st   <= 2'd0;
		tx_bit  <= 4'd0;
		tx_data <= 8'd0;
		tx_div  <= 16'd0;
		uart_tx <= 1'b1;
	end else if (tx_st == 2'd0) begin
		uart_tx <= 1'b1;
		tx_div  <= 16'd0;
		if (send_go) begin
			tx_st   <= 2'd1;
			tx_bit  <= 4'd0;
			tx_data <= send_byte;
			uart_tx <= 1'b0;
		end
	end else if (tx_div == (DIV - 16'd1)) begin
		tx_div <= 16'd0;
		if (tx_bit == 4'd0) begin
			uart_tx <= tx_data[0];
			tx_data <= {1'b0, tx_data[7:1]};
			tx_bit  <= 4'd1;
		end else if (tx_bit < 4'd8) begin
			uart_tx <= tx_data[0];
			tx_data <= {1'b0, tx_data[7:1]};
			tx_bit  <= tx_bit + 4'd1;
		end else if (tx_bit == 4'd8) begin
			uart_tx <= 1'b1;
			tx_bit  <= 4'd9;
		end else
			tx_st <= 2'd0;
	end else
		tx_div <= tx_div + 16'd1;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rx0 <= 1'b1; rx1 <= 1'b1; rx2 <= 1'b1;
		rx_st <= 3'd0;
		rx_bit <= 4'd0;
		rx_data <= 8'd0;
		rx_div <= 16'd0;
		rx_n <= 4'd0;
		rx_in_fe <= 1'b0;
		rx_cmd_l <= 8'd0;
		rx_frame <= 1'b0;
		rx_cmd <= 8'd0;
	end else begin
		rx0 <= uart_rx;
		rx1 <= rx0;
		rx2 <= rx1;
		rx_frame <= 1'b0;
		if (rx_st == 3'd0) begin
			rx_div <= 16'd0;
			if (rx2 & ~rx1) begin
				rx_st  <= 3'd1;
				rx_bit <= 4'd0;
				rx_data <= 8'd0;
			end
		end else if (rx_st == 3'd1) begin
			if (rx_div == (MID - 16'd1)) begin
				rx_div <= 16'd0;
				if (rx1 != 1'b0)
					rx_st <= 3'd0;
				else
					rx_st <= 3'd2;
			end else
				rx_div <= rx_div + 16'd1;
		end else if (rx_st == 3'd2) begin
			if (rx_div == (DIV - 16'd1)) begin
				rx_div <= 16'd0;
				rx_data <= {rx1, rx_data[7:1]};
				if (rx_bit == 4'd7)
					rx_st <= 3'd3;
				else
					rx_bit <= rx_bit + 4'd1;
			end else
				rx_div <= rx_div + 16'd1;
		end else begin
			if (rx_div == (DIV - 16'd1)) begin
				rx_div <= 16'd0;
				rx_st  <= 3'd0;
				if (rx1 == 1'b1) begin
					if (rx_data == 8'hFE) begin
						rx_in_fe <= 1'b1;
						rx_n <= 4'd1;
					end else if (rx_in_fe) begin
						rx_n <= rx_n + 4'd1;
						if (rx_n == 4'd4)
							rx_cmd_l <= rx_data;
						if (rx_data == 8'hBE && rx_n >= 4'd6) begin
							rx_in_fe <= 1'b0;
							rx_frame <= 1'b1;
							rx_cmd   <= rx_cmd_l;
						end
						if (rx_n >= 4'd15)
							rx_in_fe <= 1'b0;
					end
				end
			end else
				rx_div <= rx_div + 16'd1;
		end
	end
end

endmodule

// Query 0x01, auto-swap TX/RX if no reply, volume 30, boot 00040→00016.
module j7_voice_ctrl (
	input  wire       clk,
	input  wire       rst_n,
	input  wire       box_show,
	input  wire [2:0] evt_code,
	input  wire       host_play,
	input  wire [15:0] host_track,
	output reg        host_ack,
	input  wire       uart_rx,
	output wire       uart_tx,
	output reg        pin_swap,
	output reg        comm_ok,
	output reg [15:0] last_track
);

localparam [2:0] S_BOOT = 3'd0;
localparam [2:0] S_SEND = 3'd1;
localparam [2:0] S_WAIT = 3'd2;
localparam [2:0] S_NEXT = 3'd3;
localparam [2:0] S_RUN  = 3'd4;

reg [2:0]  st;
reg [3:0]  step;
reg [3:0]  idx;
reg [3:0]  nbyte;
reg [7:0]  pkt0, pkt1, pkt2, pkt3, pkt4, pkt5, pkt6, pkt7, pkt8, pkt9;
reg        send_go;
reg [7:0]  send_byte;
reg [24:0] wait_cnt;
reg [26:0] boot_cnt;
reg        saw_rx;
reg        tried_swap;
reg        in_d, code4_d, code5_d, mot_d, ir_d;
	reg        was_occ;
reg        in_pend, fal_pend_v, q12;
	reg        mot_pend, ir_pend, leave_pend, host_q;
	reg [15:0] host_qtrk;
reg [27:0] cool_cnt;
wire       tx_busy;
wire       rx_frame;
wire [7:0] rx_cmd;

j7_voice_uart u_uart (
	.clk       (clk),
	.rst_n     (rst_n),
	.send_go   (send_go),
	.send_byte (send_byte),
	.tx_busy   (tx_busy),
	.uart_tx   (uart_tx),
	.uart_rx   (uart_rx),
	.rx_frame  (rx_frame),
	.rx_cmd    (rx_cmd)
);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		st <= S_BOOT;
		step <= 4'd0;
		idx <= 4'd0;
		nbyte <= 4'd0;
		send_go <= 1'b0;
		send_byte <= 8'd0;
		wait_cnt <= 25'd0;
		boot_cnt <= 27'd0;
		saw_rx <= 1'b0;
		tried_swap <= 1'b0;
		pin_swap <= 1'b0;
		comm_ok <= 1'b0;
		last_track <= 16'd0;
		in_d <= 1'b0;
		code4_d <= 1'b0;
		code5_d <= 1'b0;
		mot_d <= 1'b0;
		ir_d <= 1'b0;
		was_occ <= 1'b0;
		in_pend <= 1'b0;
		fal_pend_v <= 1'b0;
		q12 <= 1'b0;
		mot_pend <= 1'b0;
		ir_pend <= 1'b0;
		leave_pend <= 1'b0;
		host_q <= 1'b0;
		host_qtrk <= 16'd0;
		host_ack <= 1'b0;
		cool_cnt <= 28'd0;
		pkt0 <= 8'd0; pkt1 <= 8'd0; pkt2 <= 8'd0; pkt3 <= 8'd0;
		pkt4 <= 8'd0; pkt5 <= 8'd0; pkt6 <= 8'd0; pkt7 <= 8'd0;
		pkt8 <= 8'd0; pkt9 <= 8'd0;
	end else begin
		send_go <= 1'b0;
		in_d    <= (evt_code == 3'd3);
		code4_d <= (evt_code == 3'd4);
		code5_d <= (evt_code == 3'd5);
		mot_d   <= (evt_code == 3'd1);
		ir_d    <= (evt_code == 3'd2);
		if ((evt_code == 3'd3) && !in_d)
			in_pend <= 1'b1;
		if ((evt_code == 3'd4) && !code4_d)
			fal_pend_v <= 1'b1;
		if ((evt_code == 3'd1) && !mot_d)
			mot_pend <= 1'b1;
		if ((evt_code == 3'd2) && !ir_d)
			ir_pend <= 1'b1;
		if ((evt_code == 3'd3) || (evt_code == 3'd4))
			was_occ <= 1'b1;
		else if ((evt_code == 3'd0) && was_occ) begin
			leave_pend <= 1'b1;
			was_occ <= 1'b0;
		end
		if (!host_play)
			host_ack <= 1'b0;
		else if (!host_ack && (host_track == 16'd12) &&
		         ((cool_cnt != 28'd0) || in_pend || fal_pend_v ||
		          leave_pend || mot_pend || ir_pend || (st != S_RUN))) begin
			q12 <= 1'b1;
			host_ack <= 1'b1;
		end else if (!host_ack && (host_track != 16'd12) &&
		            ((cool_cnt != 28'd0) || in_pend || fal_pend_v ||
		             leave_pend || (st != S_RUN))) begin
			host_q <= 1'b1;
			host_qtrk <= host_track;
			host_ack <= 1'b1;
		end
		if (rx_frame) begin
			saw_rx  <= 1'b1;
			comm_ok <= 1'b1;
		end
		if (cool_cnt != 28'd0)
			cool_cnt <= cool_cnt - 28'd1;

		case (st)
			S_BOOT: begin
				if (boot_cnt >= 27'd75000000) begin
					step <= 4'd0;
					st   <= S_NEXT;
				end else
					boot_cnt <= boot_cnt + 27'd1;
			end
			S_NEXT: begin
				idx     <= 4'd0;
				saw_rx  <= 1'b0;
				wait_cnt <= 25'd0;
				if (step == 4'd0) begin
					/* query status FE 07 FF FF 01 04 BE */
					nbyte <= 4'd7;
					pkt0 <= 8'hFE; pkt1 <= 8'h07; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
					pkt4 <= 8'h01; pkt5 <= 8'h04; pkt6 <= 8'hBE;
					st <= S_SEND;
				end else if (step == 4'd1) begin
					if (saw_rx || comm_ok)
						step <= 4'd2;
					else if (!tried_swap) begin
						tried_swap <= 1'b1;
						pin_swap   <= ~pin_swap;
						step       <= 4'd0;
					end else
						step <= 4'd2;
					st <= S_NEXT;
				end else if (step == 4'd2) begin
					/* stop: FE 07 FF FF 04 07 BE */
					nbyte <= 4'd7;
					pkt0 <= 8'hFE; pkt1 <= 8'h07; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
					pkt4 <= 8'h04; pkt5 <= 8'h07; pkt6 <= 8'hBE;
					st <= S_SEND;
				end else if (step == 4'd3) begin
					/* single play then stop: FE 0A FF FF 18 06 00 00 24 BE */
					nbyte <= 4'd10;
					pkt0 <= 8'hFE; pkt1 <= 8'h0A; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
					pkt4 <= 8'h18; pkt5 <= 8'h06; pkt6 <= 8'h00; pkt7 <= 8'h00;
					pkt8 <= 8'h24; pkt9 <= 8'hBE;
					st <= S_SEND;
				end else if (step == 4'd4) begin
					/* volume 30: FE 08 FF FF 13 1E 35 BE */
					nbyte <= 4'd8;
					pkt0 <= 8'hFE; pkt1 <= 8'h08; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
					pkt4 <= 8'h13; pkt5 <= 8'h1E; pkt6 <= 8'h35; pkt7 <= 8'hBE;
					st <= S_SEND;
				end else if (step == 4'd5) begin
					/* 00040 欢迎体验智能监护演示 */
					last_track <= 16'd40;
					nbyte <= 4'd9;
					pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
					pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h28; pkt7 <= 8'h34;
					pkt8 <= 8'hBE;
					cool_cnt <= 28'd125000000;
					st <= S_SEND;
				end else if (step == 4'd6) begin
					/* 00016 现在开始功能演示 */
					last_track <= 16'd16;
					nbyte <= 4'd9;
					pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
					pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h10; pkt7 <= 8'h1C;
					pkt8 <= 8'hBE;
					cool_cnt <= 28'd125000000;
					st <= S_SEND;
				end else
					st <= S_RUN;
			end
			S_SEND: begin
				if (!tx_busy && !send_go) begin
					if (idx < nbyte) begin
						send_go <= 1'b1;
						case (idx)
							4'd0: send_byte <= pkt0;
							4'd1: send_byte <= pkt1;
							4'd2: send_byte <= pkt2;
							4'd3: send_byte <= pkt3;
							4'd4: send_byte <= pkt4;
							4'd5: send_byte <= pkt5;
							4'd6: send_byte <= pkt6;
							4'd7: send_byte <= pkt7;
							4'd8: send_byte <= pkt8;
							default: send_byte <= pkt9;
						endcase
						idx <= idx + 4'd1;
					end else begin
						wait_cnt <= 25'd0;
						st <= S_WAIT;
					end
				end
			end
			S_WAIT: begin
				/* Boot plays 40 then 16; wait on cool (~5s). Query 80ms, else 20ms. */
				if ((step == 4'd5) || (step == 4'd6)) begin
					if (cool_cnt == 28'd0) begin
						step <= step + 4'd1;
						st   <= S_NEXT;
					end
				end else begin
					wait_cnt <= wait_cnt + 25'd1;
					if (((step == 4'd0) && (wait_cnt >= 25'd2000000)) ||
					    ((step != 4'd0) && (wait_cnt >= 25'd500000))) begin
						step <= step + 4'd1;
						st   <= S_NEXT;
					end
				end
			end
			default: begin
				if (!tx_busy && !send_go) begin
					if (fal_pend_v) begin
						last_track <= 16'd6;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h06; pkt7 <= 8'h12;
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						fal_pend_v <= 1'b0;
						in_pend <= 1'b0;
						mot_pend <= 1'b0;
						ir_pend <= 1'b0;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if ((evt_code == 3'd5) && !code5_d && (cool_cnt == 28'd0)) begin
						last_track <= 16'd7;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h07; pkt7 <= 8'h13;
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if (in_pend) begin
						last_track <= 16'd5;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h05; pkt7 <= 8'h11;
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						in_pend <= 1'b0;
						mot_pend <= 1'b0;
						ir_pend <= 1'b0;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if (leave_pend) begin
						last_track <= 16'd9;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h09; pkt7 <= 8'h15;
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						leave_pend <= 1'b0;
						mot_pend <= 1'b0;
						ir_pend <= 1'b0;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if (mot_pend) begin
						last_track <= 16'd3;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h03; pkt7 <= 8'h0F;
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						mot_pend <= 1'b0;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if (ir_pend) begin
						last_track <= 16'd4;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h04; pkt7 <= 8'h10;
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						ir_pend <= 1'b0;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if (q12 && (cool_cnt == 28'd0)) begin
						last_track <= 16'd12;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07; pkt5 <= 8'h00; pkt6 <= 8'h0C; pkt7 <= 8'h18;
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						q12 <= 1'b0;
						host_ack <= 1'b1;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if (host_q && (cool_cnt == 28'd0)) begin
						last_track <= host_qtrk;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07;
						pkt5 <= host_qtrk[15:8];
						pkt6 <= host_qtrk[7:0];
						pkt7 <= 8'h0C + host_qtrk[15:8] + host_qtrk[7:0];
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						host_q <= 1'b0;
						host_ack <= 1'b1;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end else if (host_play && !host_ack && (cool_cnt == 28'd0)) begin
						last_track <= host_track;
						nbyte <= 4'd9;
						pkt0 <= 8'hFE; pkt1 <= 8'h09; pkt2 <= 8'hFF; pkt3 <= 8'hFF;
						pkt4 <= 8'h07;
						pkt5 <= host_track[15:8];
						pkt6 <= host_track[7:0];
						pkt7 <= 8'h0C + host_track[15:8] + host_track[7:0];
						pkt8 <= 8'hBE;
						idx <= 4'd0;
						host_ack <= 1'b1;
						if (host_track == 16'd12)
							q12 <= 1'b0;
						cool_cnt <= 28'd75000000;
						st <= S_SEND;
						step <= 4'd8;
					end
				end
			end
		endcase
	end
end

endmodule
