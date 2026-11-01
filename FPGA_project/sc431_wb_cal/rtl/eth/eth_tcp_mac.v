// TCP:80 single-packet mailbox. UDP MAC stays as-is; RISC-V runs HTTP.
module eth_tcp_mac #(
	parameter [47:0] LOCAL_MAC = 48'h00_0A_35_01_FE_C0,
	parameter [31:0] LOCAL_IP  = 32'hC0_A8_0A_0A, // 192.168.10.10
	parameter [15:0] TCP_PORT  = 16'd80
)(
	input  wire        rxc,
	input  wire        rst_n,
	input  wire [7:0]  gmii_rxd,
	input  wire        gmii_rx_dv,
	input  wire        mac_tx_active,
	output reg         tcp_tx_en,
	output reg  [7:0]  tcp_txd,
	output wire        tcp_busy,
	input  wire        pclk,
	input  wire        presetn,
	input  wire [11:0] tcp_rx_raddr,
	output reg  [7:0]  tcp_rx_rdata,
	output wire [11:0] tcp_rx_len,
	output wire        tcp_rx_valid,
	input  wire        tcp_rx_ack,
	input  wire        tcp_tx_we,
	input  wire [11:0] tcp_tx_waddr,
	input  wire [7:0]  tcp_tx_wdata,
	input  wire [11:0] tcp_tx_len_i,
	input  wire        tcp_tx_kick,
	output wire        tcp_tx_busy
);

localparam RX_MAX = 2048;
localparam TX_MAX = 4096;
localparam [2:0] R_IDLE=3'd0, R_PRE=3'd1, R_DATA=3'd2, R_DONE=3'd3;
localparam [2:0] T_IDLE=3'd0, T_WAIT=3'd1, T_PRE=3'd2, T_DATA=3'd3, T_IFG=3'd4;

(* syn_ramstyle = "block_ram" *) reg [7:0] rx_mem [0:RX_MAX-1];
(* syn_ramstyle = "block_ram" *) reg [7:0] tx_mem [0:TX_MAX-1];
reg [11:0] tx_raddr;
reg [7:0]  tx_rd;
wire       rx_we = (rst == R_DATA) && gmii_rx_dv && (wr_addr < RX_MAX[11:0]);

reg [2:0]  rst;
reg [11:0] wr_addr, rx_len_r;
reg        rx_full, rx_done_tog;
reg        mac_ok, bcast, type_ok, ip_ok, proto_ok, dip_ok, port_ok;
reg [3:0]  ihl;
reg [7:0]  type_hi, dip_b0, dip_b1, dip_b2, dport_hi;
reg [11:0] tcp_off;
reg [3:0]  dv_gap;

always @(posedge rxc or negedge rst_n) begin
	if (!rst_n) begin
		rst         <= R_IDLE;
		wr_addr     <= 12'd0;
		rx_len_r    <= 12'd0;
		rx_done_tog <= 1'b0;
		mac_ok <= 1'b0; bcast <= 1'b0; type_ok <= 1'b0;
		ip_ok <= 1'b0; proto_ok <= 1'b0; dip_ok <= 1'b0; port_ok <= 1'b0;
		ihl <= 4'd5; type_hi <= 8'd0; tcp_off <= 12'd34;
		dip_b0 <= 8'd0; dip_b1 <= 8'd0; dip_b2 <= 8'd0; dport_hi <= 8'd0;
		dv_gap <= 4'd0;
	end else begin
		case (rst)
			R_IDLE: begin
				wr_addr <= 12'd0;
				mac_ok <= 1'b0; bcast <= 1'b0; type_ok <= 1'b0;
				ip_ok <= 1'b0; proto_ok <= 1'b0; dip_ok <= 1'b0; port_ok <= 1'b0;
				ihl <= 4'd5; tcp_off <= 12'd34;
				dv_gap <= 4'd0;
				if (gmii_rx_dv && (gmii_rxd == 8'h55))
					rst <= R_PRE;
			end
			R_PRE: begin
				if (!gmii_rx_dv)
					rst <= R_IDLE;
				else if (gmii_rxd == 8'hD5)
					rst <= R_DATA;
				else if (gmii_rxd != 8'h55)
					rst <= R_IDLE;
			end
			R_DATA: begin
				if (!gmii_rx_dv) begin
					if (dv_gap >= 4'd8)
						rst <= R_DONE;
					else
						dv_gap <= dv_gap + 4'd1;
				end else if (wr_addr < RX_MAX[11:0]) begin
					dv_gap <= 4'd0;
					if (wr_addr == 12'd0) begin mac_ok <= (gmii_rxd == LOCAL_MAC[47:40]); bcast <= (gmii_rxd == 8'hFF); end
					if (wr_addr == 12'd1) begin mac_ok <= mac_ok & (gmii_rxd == LOCAL_MAC[39:32]); bcast <= bcast & (gmii_rxd == 8'hFF); end
					if (wr_addr == 12'd2) begin mac_ok <= mac_ok & (gmii_rxd == LOCAL_MAC[31:24]); bcast <= bcast & (gmii_rxd == 8'hFF); end
					if (wr_addr == 12'd3) begin mac_ok <= mac_ok & (gmii_rxd == LOCAL_MAC[23:16]); bcast <= bcast & (gmii_rxd == 8'hFF); end
					if (wr_addr == 12'd4) begin mac_ok <= mac_ok & (gmii_rxd == LOCAL_MAC[15:8]);  bcast <= bcast & (gmii_rxd == 8'hFF); end
					if (wr_addr == 12'd5) begin mac_ok <= mac_ok & (gmii_rxd == LOCAL_MAC[7:0]);   bcast <= bcast & (gmii_rxd == 8'hFF); end
					if (wr_addr == 12'd12) type_hi <= gmii_rxd;
					if (wr_addr == 12'd13) type_ok <= (type_hi == 8'h08) && (gmii_rxd == 8'h00);
					if (wr_addr == 12'd14) begin
						ip_ok   <= (gmii_rxd[7:4] == 4'h4) && (gmii_rxd[3:0] >= 4'd5);
						ihl     <= gmii_rxd[3:0];
						tcp_off <= 12'd14 + {6'd0, gmii_rxd[3:0], 2'b00};
					end
					if (wr_addr == 12'd23) proto_ok <= (gmii_rxd == 8'h06);
					if (wr_addr == 12'd30) dip_b0 <= gmii_rxd;
					if (wr_addr == 12'd31) dip_b1 <= gmii_rxd;
					if (wr_addr == 12'd32) dip_b2 <= gmii_rxd;
					if (wr_addr == 12'd33) dip_ok <= (dip_b0 == LOCAL_IP[31:24]) && (dip_b1 == LOCAL_IP[23:16])
					                                 && (dip_b2 == LOCAL_IP[15:8]) && (gmii_rxd == LOCAL_IP[7:0]);
					if (wr_addr == (tcp_off + 12'd2)) dport_hi <= gmii_rxd;
					if (wr_addr == (tcp_off + 12'd3))
						port_ok <= (dport_hi == TCP_PORT[15:8]) && (gmii_rxd == TCP_PORT[7:0]);
					wr_addr <= wr_addr + 12'd1;
				end
			end
			R_DONE: begin
				if (!rx_full && (mac_ok || bcast) && type_ok && ip_ok && proto_ok && dip_ok && port_ok
					&& (wr_addr >= 12'd58)) begin
					rx_len_r    <= wr_addr - 12'd4;
					rx_done_tog <= ~rx_done_tog;
				end
				rst <= R_IDLE;
			end
			default: rst <= R_IDLE;
		endcase
	end
end

reg rx_done_s0, rx_done_s1, rx_done_s2;
reg rx_ack_tog, rx_ack_s0, rx_ack_s1, rx_ack_s2;
reg rx_valid_p;
reg [11:0] rx_len_p;

always @(posedge pclk or negedge presetn) begin
	if (!presetn) begin
		rx_done_s0 <= 1'b0; rx_done_s1 <= 1'b0; rx_done_s2 <= 1'b0;
		rx_valid_p <= 1'b0; rx_len_p <= 12'd0; rx_ack_tog <= 1'b0;
	end else begin
		rx_done_s0 <= rx_done_tog;
		rx_done_s1 <= rx_done_s0;
		rx_done_s2 <= rx_done_s1;
		if (rx_done_s1 != rx_done_s2) begin
			rx_valid_p <= 1'b1;
			rx_len_p   <= rx_len_r;
		end
		if (tcp_rx_ack && rx_valid_p) begin
			rx_valid_p <= 1'b0;
			rx_ack_tog <= ~rx_ack_tog;
		end
	end
end

always @(posedge rxc) begin
	if (rx_we)
		rx_mem[wr_addr] <= gmii_rxd;
end

always @(posedge pclk) begin
	tcp_rx_rdata <= rx_mem[tcp_rx_raddr];
end

always @(posedge rxc or negedge rst_n) begin
	if (!rst_n) begin
		rx_ack_s0 <= 1'b0; rx_ack_s1 <= 1'b0; rx_ack_s2 <= 1'b0;
		rx_full <= 1'b0;
	end else begin
		rx_ack_s0 <= rx_ack_tog;
		rx_ack_s1 <= rx_ack_s0;
		rx_ack_s2 <= rx_ack_s1;
		if ((rst == R_DONE) && !rx_full && (mac_ok || bcast) && type_ok && ip_ok && proto_ok && dip_ok && port_ok
			&& (wr_addr >= 12'd58))
			rx_full <= 1'b1;
		if (rx_ack_s1 != rx_ack_s2)
			rx_full <= 1'b0;
	end
end

assign tcp_rx_len   = rx_len_p;
assign tcp_rx_valid = rx_valid_p;

always @(posedge pclk) begin
	if (tcp_tx_we)
		tx_mem[tcp_tx_waddr] <= tcp_tx_wdata;
end

always @(posedge rxc) begin
	tx_rd <= tx_mem[tx_raddr];
end

reg tx_kick_tog, tx_kick_s0, tx_kick_s1, tx_kick_s2;
reg tx_done_tog, tx_done_s0, tx_done_s1, tx_done_s2;
reg tx_busy_p;
reg [11:0] tx_len_hold, tx_len_r;
reg [2:0]  tst;
reg [12:0] tcnt;
reg [3:0]  ifg;

always @(posedge pclk or negedge presetn) begin
	if (!presetn) begin
		tx_kick_tog <= 1'b0; tx_busy_p <= 1'b0; tx_len_hold <= 12'd0;
		tx_done_s0 <= 1'b0; tx_done_s1 <= 1'b0; tx_done_s2 <= 1'b0;
	end else begin
		tx_done_s0 <= tx_done_tog;
		tx_done_s1 <= tx_done_s0;
		tx_done_s2 <= tx_done_s1;
		if (tcp_tx_kick && !tx_busy_p) begin
			tx_kick_tog <= ~tx_kick_tog;
			tx_busy_p   <= 1'b1;
			tx_len_hold <= (tcp_tx_len_i < 12'd60) ? 12'd60 : tcp_tx_len_i;
		end
		if (tx_done_s1 != tx_done_s2)
			tx_busy_p <= 1'b0;
	end
end
assign tcp_tx_busy = tx_busy_p;
assign tcp_busy    = (tst != T_IDLE) && (tst != T_WAIT);

always @(posedge rxc or negedge rst_n) begin
	if (!rst_n) begin
		tx_kick_s0 <= 1'b0; tx_kick_s1 <= 1'b0; tx_kick_s2 <= 1'b0;
		tx_done_tog <= 1'b0;
		tst <= T_IDLE; tcnt <= 13'd0; ifg <= 4'd0;
		tcp_tx_en <= 1'b0; tcp_txd <= 8'd0;
		tx_len_r <= 12'd0; tx_raddr <= 12'd0;
	end else begin
		tx_kick_s0 <= tx_kick_tog;
		tx_kick_s1 <= tx_kick_s0;
		tx_kick_s2 <= tx_kick_s1;
		case (tst)
			T_IDLE: begin
				tcp_tx_en <= 1'b0;
				ifg <= 4'd0;
				tcnt <= 13'd0;
				if (tx_kick_s1 != tx_kick_s2) begin
					tx_len_r <= tx_len_hold;
					tst <= T_WAIT;
				end
			end
			T_WAIT: begin
				if (mac_tx_active)
					ifg <= 4'd0;
				else if (ifg < 4'd12)
					ifg <= ifg + 4'd1;
				else begin
					tcnt <= 13'd0;
					tst <= T_PRE;
				end
			end
			T_PRE: begin
				tcp_tx_en <= 1'b1;
				tcp_txd <= (tcnt < 13'd7) ? 8'h55 : 8'hD5;
				if (tcnt == 13'd6)
					tx_raddr <= 12'd0;
				if (tcnt == 13'd7) begin
					tcnt <= 13'd0;
					tx_raddr <= 12'd1;
					tst <= T_DATA;
				end else
					tcnt <= tcnt + 13'd1;
			end
			T_DATA: begin
				tcp_tx_en <= 1'b1;
				tcp_txd <= tx_rd;
				if (tcnt + 13'd1 >= {1'b0, tx_len_r}) begin
					tcnt <= 13'd0;
					tst <= T_IFG;
				end else begin
					tx_raddr <= tcnt[11:0] + 12'd2;
					tcnt <= tcnt + 13'd1;
				end
			end
			T_IFG: begin
				tcp_tx_en <= 1'b0;
				if (tcnt == 13'd12) begin
					tx_done_tog <= ~tx_done_tog;
					tst <= T_IDLE;
				end else
					tcnt <= tcnt + 13'd1;
			end
			default: tst <= T_IDLE;
		endcase
	end
end

endmodule
