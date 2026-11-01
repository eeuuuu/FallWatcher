// Official GE MAC (ARP/ICMP/UDP TX+RX) on board RGMII.
// TX clock = PHY rxc (no extra PLL). Protocol reused by Task 3.
// Payload 16B: 8TUN | cmd | seq | reg | len | data[31:0] | rsvd[31:0]
// cmd: W=0x57 write, R=0x52 read, A=0x41 ack. E/V reserved.
module eth_host (
	input  wire        rst_n,
	input  wire        rxc,
	input  wire        rx_dv_HI,
	input  wire        rx_dv_LO,
	input  wire [3:0]  rxd_hi_i,
	input  wire [3:0]  rxd_lo_i,
	output wire        tx_en_o_HI,
	output wire        tx_en_o_LO,
	output wire        txc_hi_o,
	output wire        txc_lo_o,
	output wire [3:0]  txd_hi_o,
	output wire [3:0]  txd_lo_o,
	output wire        phy_rst_n,
	output reg  [15:0] rgb_r,
	output reg  [15:0] rgb_g,
	output reg  [15:0] rgb_b,
	input  wire [7:0]  stat_r,
	input  wire [7:0]  stat_g,
	input  wire [7:0]  stat_b,
	input  wire [15:0] stat_frame,
	output reg  [7:0]  analog_gain,
	output reg         analog_we,
	output reg  [15:0] cam_addr,
	output reg  [7:0]  cam_data,
	output reg         cam_we,
	output wire        dbg_rxc_hb,
	output wire        dbg_rx_seen,
	output wire        dbg_tx_seen,
	output wire        dbg_arp_seen,
	input  wire        print_wr_clk,
	input  wire        print_wr_rst_n,
	input  wire        print_wr_en,
	input  wire [7:0]  print_wr_data,
	output wire        print_wr_full,
	input  wire        print_bin_wr_en,
	input  wire [7:0]  print_bin_wr_data,
	output wire        print_bin_wr_full,
	input  wire        tcp_pclk,
	input  wire        tcp_presetn,
	input  wire [11:0] tcp_rx_raddr,
	output wire [7:0]  tcp_rx_rdata,
	output wire [11:0] tcp_rx_len,
	output wire        tcp_rx_valid,
	input  wire        tcp_rx_ack,
	input  wire        tcp_tx_we,
	input  wire [11:0] tcp_tx_waddr,
	input  wire [7:0]  tcp_tx_wdata,
	input  wire [11:0] tcp_tx_len,
	input  wire        tcp_tx_kick,
	output wire        tcp_tx_busy
);

localparam [47:0] LOCAL_MAC = 48'h00_0A_35_01_FE_C0;
localparam [31:0] LOCAL_IP  = 32'hC0_A8_0A_0A; // 192.168.10.10
localparam [15:0] UDP_PORT    = 16'd5000;
localparam [15:0] PRINT_PORT  = 16'd5001;
localparam [15:0] BIN_PORT    = 16'd5002;
localparam [31:0] MAGIC       = 32'h3854554E;    // "8TUN"

assign phy_rst_n = 1'b1;
assign txc_hi_o  = 1'b1;
assign txc_lo_o  = 1'b0;

reg  [3:0] align_rxd_hi;
reg        align_rx_dv_hi;
wire [3:0] align_rxd_lo = rxd_lo_i;
wire       align_rx_dv_lo = rx_dv_LO;

always @(posedge rxc) begin
	align_rxd_hi   <= rxd_hi_i;
	align_rx_dv_hi <= rx_dv_HI;
end

wire        gmii_tx_clk, gmii_rx_clk;
wire [7:0]  gmii_rxd;
wire        gmii_rx_dv;
reg  [7:0]  gmii_txd;
reg         gmii_tx_en;
wire        gmii_tx_en_mac;
wire [7:0]  gmii_txd_mac;

util_gmii_to_rgmii u_rgmii (
	.rst_n            (rst_n),
	.rgmii_rxc        (rxc),
	.rgmii_rx_hi      (align_rxd_lo),
	.rgmii_rx_lo      (align_rxd_hi),
	.rgmii_rx_dv      (align_rx_dv_hi),
	.rgmii_rx_er      (align_rx_dv_lo),
	.rgmii_tx_ctrl_hi (tx_en_o_HI),
	.rgmii_tx_ctrl_lo (tx_en_o_LO),
	.rgmii_txd_lo     (txd_lo_o),
	.rgmii_txd_hi     (txd_hi_o),
	.gmii_txd         (gmii_txd),
	.gmii_tx_en       (gmii_tx_en),
	.gmii_tx_er       (1'b0),
	.gmii_tx_clk      (gmii_tx_clk),
	.gmii_crs         (),
	.gmii_col         (),
	.gmii_rxd         (gmii_rxd),
	.gmii_rx_dv       (gmii_rx_dv),
	.gmii_rx_er       (),
	.gmii_rx_clk      (gmii_rx_clk),
	.duplex_mode      (1'b1)
);

reg        gmii_rx_dv_d0;
reg  [7:0] gmii_rxd_d0;
always @(posedge gmii_rx_clk or negedge rst_n) begin
	if (!rst_n) begin
		gmii_rx_dv_d0 <= 1'b0;
		gmii_rxd_d0   <= 8'd0;
	end else begin
		gmii_rx_dv_d0 <= gmii_rx_dv;
		gmii_rxd_d0   <= gmii_rxd;
	end
end

wire        tcp_tx_en;
wire [7:0]  tcp_txd;
wire        tcp_busy;

eth_tcp_mac #(
	.LOCAL_MAC (LOCAL_MAC),
	.LOCAL_IP  (LOCAL_IP),
	.TCP_PORT  (16'd80)
) u_tcp (
	.rxc           (gmii_rx_clk),
	.rst_n         (rst_n),
	.gmii_rxd      (gmii_rxd_d0),
	.gmii_rx_dv    (gmii_rx_dv_d0),
	.mac_tx_active (gmii_tx_en_mac),
	.tcp_tx_en     (tcp_tx_en),
	.tcp_txd       (tcp_txd),
	.tcp_busy      (tcp_busy),
	.pclk          (tcp_pclk),
	.presetn       (tcp_presetn),
	.tcp_rx_raddr  (tcp_rx_raddr),
	.tcp_rx_rdata  (tcp_rx_rdata),
	.tcp_rx_len    (tcp_rx_len),
	.tcp_rx_valid  (tcp_rx_valid),
	.tcp_rx_ack    (tcp_rx_ack),
	.tcp_tx_we     (tcp_tx_we),
	.tcp_tx_waddr  (tcp_tx_waddr),
	.tcp_tx_wdata  (tcp_tx_wdata),
	.tcp_tx_len_i  (tcp_tx_len),
	.tcp_tx_kick   (tcp_tx_kick),
	.tcp_tx_busy   (tcp_tx_busy)
);

always @(posedge gmii_tx_clk or negedge rst_n) begin
	if (!rst_n) begin
		gmii_tx_en <= 1'b0;
		gmii_txd   <= 8'd0;
	end else if (tcp_busy || tcp_tx_en) begin
		gmii_tx_en <= tcp_tx_en;
		gmii_txd   <= tcp_txd;
	end else begin
		gmii_tx_en <= gmii_tx_en_mac;
		gmii_txd   <= gmii_txd_mac;
	end
end

wire        udp_ram_data_req;
wire        mac_send_end;
wire [7:0]  udp_rec_ram_rdata;
wire [15:0] udp_rec_data_length;
wire        udp_rec_data_valid;
wire [31:0] ip_rec_source_ip_addr;
wire        mac_not_exist;

reg  [7:0]  ram_wr_data;
reg         ram_wr_en;
reg         udp_tx_req;
reg         arp_request_req;
reg  [10:0] udp_rec_ram_read_addr;
reg  [31:0] dest_ip;
reg  [15:0] dest_port;
reg  [15:0] udp_send_len;
wire        arp_found;

mac_top u_mac (
	.gmii_tx_clk               (gmii_tx_clk),
	.gmii_rx_clk               (gmii_rx_clk),
	.rst_n                     (rst_n),
	.source_mac_addr           (LOCAL_MAC),
	.TTL                       (8'h80),
	.source_ip_addr            (LOCAL_IP),
	.destination_ip_addr       (dest_ip),
	.udp_send_source_port      (dest_port),
	.udp_send_destination_port (dest_port),
	.ram_wr_data               (ram_wr_data),
	.ram_wr_en                 (ram_wr_en),
	.udp_ram_data_req          (udp_ram_data_req),
	.udp_send_data_length      (udp_send_len),
	.udp_tx_req                (udp_tx_req),
	.arp_request_req           (arp_request_req),
	.mac_data_valid            (gmii_tx_en_mac),
	.mac_send_end              (mac_send_end),
	.mac_tx_data               (gmii_txd_mac),
	.rx_dv                     (gmii_rx_dv_d0),
	.mac_rx_datain             (gmii_rxd_d0),
	.udp_rec_ram_rdata         (udp_rec_ram_rdata),
	.udp_rec_ram_read_addr     (udp_rec_ram_read_addr),
	.udp_rec_data_length       (udp_rec_data_length),
	.udp_rec_data_valid        (udp_rec_data_valid),
	.arp_found                 (arp_found),
	.mac_not_exist             (mac_not_exist),
	.ip_rec_source_ip_addr     (ip_rec_source_ip_addr)
);

(* mark_debug = "true" *) wire dbg_rx_dv = gmii_rx_dv;
(* mark_debug = "true" *) wire dbg_tx_en = gmii_tx_en;

reg [26:0] hb_cnt;
reg        rx_seen, tx_seen, arp_seen_r, rxc_hb;
always @(posedge gmii_tx_clk or negedge rst_n) begin
	if (!rst_n) begin
		hb_cnt    <= 27'd0;
		rx_seen   <= 1'b0;
		tx_seen   <= 1'b0;
		arp_seen_r<= 1'b0;
		rxc_hb    <= 1'b0;
	end else begin
		hb_cnt <= hb_cnt + 27'd1;
		rxc_hb <= hb_cnt[24];
		if (gmii_rx_dv) rx_seen <= 1'b1;
		if (gmii_tx_en) tx_seen <= 1'b1;
		if (arp_found)  arp_seen_r <= 1'b1;
	end
end
assign dbg_rxc_hb   = rxc_hb;
assign dbg_rx_seen  = rx_seen;
assign dbg_tx_seen  = tx_seen;
assign dbg_arp_seen = arp_seen_r;
wire hb_tick = (hb_cnt[25:0] == 26'd0);

reg  [3:0]  st;
reg  [8:0]  cnt;
reg  [7:0]  pkt [0:15];
reg  [7:0]  ack [0:15];
reg  [7:0]  print_buf [0:255];
reg  [8:0]  print_len;
reg  [16:0] print_to;
reg         print_tx;
reg         rec_valid_d;
reg         udp_pend;
reg  [7:0]  udp_hit;

wire        print_empty;
wire [7:0]  print_rdata;
reg         print_rd_en;
cdc_fifo8 u_print_fifo (
	.wr_clk   (print_wr_clk),
	.wr_rst_n (print_wr_rst_n),
	.wr_en    (print_wr_en),
	.wr_data  (print_wr_data),
	.wr_full  (print_wr_full),
	.rd_clk   (gmii_tx_clk),
	.rd_rst_n (rst_n),
	.rd_en    (print_rd_en),
	.rd_data  (print_rdata),
	.rd_empty (print_empty)
);

wire        bin_empty;
wire [7:0]  bin_rdata;
reg         bin_rd_en;
cdc_fifo8 u_bin_fifo (
	.wr_clk   (print_wr_clk),
	.wr_rst_n (print_wr_rst_n),
	.wr_en    (print_bin_wr_en),
	.wr_data  (print_bin_wr_data),
	.wr_full  (print_bin_wr_full),
	.rd_clk   (gmii_tx_clk),
	.rd_rst_n (rst_n),
	.rd_en    (bin_rd_en),
	.rd_data  (bin_rdata),
	.rd_empty (bin_empty)
);

localparam S_IDLE=4'd0, S_RD=4'd1, S_WAITQ=4'd2, S_LATCH=4'd3, S_APPLY=4'd4,
           S_TXREQ=4'd5, S_WR=4'd6, S_WAITEND=4'd7,
           S_PGET=4'd8, S_PWAIT=4'd9, S_PCAP=4'd10,
           S_BGET=4'd11, S_BWAIT=4'd12, S_BCAP=4'd13;

wire [31:0] pkt_magic = {pkt[0], pkt[1], pkt[2], pkt[3]};
wire [7:0]  pkt_cmd   = pkt[4];
wire [7:0]  pkt_seq   = pkt[5];
wire [7:0]  pkt_reg   = pkt[6];
wire [31:0] pkt_data  = {pkt[11], pkt[10], pkt[9], pkt[8]};

function [15:0] q88_from_wr;
	input [31:0] d;
	reg   [15:0] g;
	begin
		if (d[31:3] == 29'd0) begin
			case (d[2:0])
				3'd0: g = 16'd64;
				3'd1: g = 16'd64;
				3'd2: g = 16'd128;
				3'd3: g = 16'd192;
				3'd4: g = 16'd256;
				3'd5: g = 16'd320;
				3'd6: g = 16'd384;
				default: g = 16'd448;
			endcase
		end else begin
			g = d[15:0];
			if (g < 16'd64)
				g = 16'd64;
			else if (g > 16'd1024)
				g = 16'd1024;
		end
		q88_from_wr = g;
	end
endfunction

function [31:0] rd_reg;
	input [7:0] r;
	begin
		case (r)
			8'h00: rd_reg = {16'd0, rgb_r};
			8'h01: rd_reg = {16'd0, rgb_g};
			8'h02: rd_reg = {16'd0, rgb_b};
			8'h10: rd_reg = {24'd0, analog_gain};
			8'h20: rd_reg = {cam_addr, 8'd0, cam_data};
			8'h30: rd_reg = {24'd0, stat_r};
			8'h31: rd_reg = {24'd0, stat_g};
			8'h32: rd_reg = {24'd0, stat_b};
			8'h33: rd_reg = {16'd0, stat_frame};
			8'h34: rd_reg = {8'd0, stat_r, stat_g, stat_b};
			default: rd_reg = 32'd0;
		endcase
	end
endfunction

integer i;
always @(posedge gmii_tx_clk or negedge rst_n) begin
	if (!rst_n) begin
		st          <= S_IDLE;
		cnt         <= 9'd0;
		rgb_r       <= 16'd256;
		rgb_g       <= 16'd256;
		rgb_b       <= 16'd256;
		analog_gain <= 8'd40;
		analog_we   <= 1'b0;
		cam_addr    <= 16'd0;
		cam_data    <= 8'd0;
		cam_we      <= 1'b0;
		ram_wr_data <= 8'd0;
		ram_wr_en   <= 1'b0;
		udp_tx_req  <= 1'b0;
		arp_request_req <= 1'b0;
		udp_rec_ram_read_addr <= 11'd0;
		dest_ip     <= 32'hC0_A8_0A_0C; // 192.168.10.12
		dest_port   <= UDP_PORT;
		udp_send_len <= 16'd16;
		print_len   <= 9'd0;
		print_to    <= 17'd0;
		print_tx    <= 1'b0;
		print_rd_en <= 1'b0;
		bin_rd_en   <= 1'b0;
		rec_valid_d <= 1'b0;
		udp_pend    <= 1'b0;
		udp_hit     <= 8'd0;
		for (i = 0; i < 16; i = i + 1) begin
			pkt[i] <= 8'd0;
			ack[i] <= 8'd0;
		end
	end else begin
		analog_we <= 1'b0;
		cam_we    <= 1'b0;
		udp_tx_req <= 1'b0;
		arp_request_req <= 1'b0;
		print_rd_en <= 1'b0;
		bin_rd_en   <= 1'b0;
		rec_valid_d <= udp_rec_data_valid;
		if (udp_rec_data_valid && !rec_valid_d)
			udp_hit <= udp_hit + 8'd1;
		if (udp_rec_data_valid && !rec_valid_d)
			udp_pend <= 1'b1;
		case (st)
			S_IDLE: begin
				ram_wr_en <= 1'b0;
				cnt <= 9'd0;
				udp_rec_ram_read_addr <= 11'd0;
				if (tcp_busy) begin
					/* let RISC-V HTTP have the wire */
				end
				else if (udp_pend) begin
					udp_pend <= 1'b0;
					dest_port <= UDP_PORT;
					print_tx  <= 1'b0;
					st <= S_RD;
				end
				else if (!bin_empty) begin
					dest_port <= BIN_PORT;
					print_tx  <= 1'b1;
					print_len <= 9'd0;
					print_to  <= 17'd0;
					st <= S_BGET;
				end
				else if (!print_empty) begin
					dest_port <= PRINT_PORT;
					print_tx  <= 1'b1;
					print_len <= 9'd0;
					print_to  <= 17'd0;
					st <= S_PGET;
				end
				else if (hb_tick) begin
					ack[0] <= 8'h38; ack[1] <= 8'h54; ack[2] <= 8'h55; ack[3] <= 8'h4E;
					ack[4] <= 8'h48; ack[5] <= 8'h00; ack[6] <= 8'hFF; ack[7] <= 8'd4;
					ack[8] <= stat_r; ack[9] <= stat_g; ack[10] <= stat_b; ack[11] <= analog_gain;
					ack[12] <= udp_hit; ack[13] <= 8'd0; ack[14] <= 8'd0; ack[15] <= 8'd0;
					udp_send_len <= 16'd16;
					dest_port <= UDP_PORT;
					print_tx  <= 1'b0;
					cnt <= 9'd0;
					st <= S_TXREQ;
				end
			end
			S_PGET: begin
				if (!print_empty) begin
					print_rd_en <= 1'b1;
					print_to    <= 17'd0;
					st <= S_PWAIT;
				end else if (print_len != 9'd0) begin
					print_to <= print_to + 17'd1;
					if (print_to[16]) begin
						udp_send_len <= {7'd0, print_len};
						st <= S_TXREQ;
					end
				end else
					st <= S_IDLE;
			end
			S_PWAIT: begin
				st <= S_PCAP;
			end
			S_PCAP: begin
				print_buf[print_len[7:0]] <= print_rdata;
				if (print_rdata == 8'h0A || print_len == 9'd63) begin
					udp_send_len <= {7'd0, print_len} + 16'd1;
					print_len <= 9'd0;
					st <= S_TXREQ;
				end else begin
					print_len <= print_len + 9'd1;
					st <= S_PGET;
				end
			end
			S_BGET: begin
				if (!bin_empty) begin
					bin_rd_en <= 1'b1;
					print_to  <= 17'd0;
					st <= S_BWAIT;
				end else if (print_len != 9'd0) begin
					print_to <= print_to + 17'd1;
					if (print_to[16]) begin
						udp_send_len <= {7'd0, print_len};
						st <= S_TXREQ;
					end
				end else
					st <= S_IDLE;
			end
			S_BWAIT: begin
				st <= S_BCAP;
			end
			S_BCAP: begin
				print_buf[print_len[7:0]] <= bin_rdata;
				if (print_len == 9'd255) begin
					udp_send_len <= 16'd256;
					print_len <= 9'd0;
					st <= S_TXREQ;
				end else begin
					print_len <= print_len + 9'd1;
					st <= S_BGET;
				end
			end
			S_RD: begin
				udp_rec_ram_read_addr <= {4'd0, cnt[6:0]};
				st <= S_WAITQ;
			end
			S_WAITQ: begin
				st <= S_LATCH;
			end
			S_LATCH: begin
				pkt[cnt[3:0]] <= udp_rec_ram_rdata;
				if (cnt == 7'd15)
					st <= S_APPLY;
				else begin
					cnt <= cnt + 7'd1;
					st  <= S_RD;
				end
			end
			S_APPLY: begin
				if (ip_rec_source_ip_addr != 32'd0)
					dest_ip <= ip_rec_source_ip_addr;
				if (pkt_magic == MAGIC && pkt_cmd == 8'h57) begin
					case (pkt_reg)
						8'h00: rgb_r <= q88_from_wr(pkt_data);
						8'h01: rgb_g <= q88_from_wr(pkt_data);
						8'h02: rgb_b <= q88_from_wr(pkt_data);
						8'h10: begin
							analog_gain <= (pkt_data[7:0] > 8'd177) ? 8'd177 : pkt_data[7:0];
							analog_we   <= 1'b1;
						end
						8'h20: begin
							cam_addr <= pkt_data[31:16];
							cam_data <= pkt_data[7:0];
							cam_we   <= 1'b1;
						end
						default: ;
					endcase
				end
				ack[0]  <= 8'h38; ack[1] <= 8'h54; ack[2] <= 8'h55; ack[3] <= 8'h4E;
				ack[4]  <= (pkt_magic == MAGIC) ? 8'h41 : 8'h4E;
				ack[5]  <= pkt_seq;
				ack[6]  <= pkt_reg;
				ack[7]  <= 8'd4;
				{ack[11], ack[10], ack[9], ack[8]} <= (pkt_cmd == 8'h52) ? rd_reg(pkt_reg) : pkt_data;
				ack[12] <= udp_hit; ack[13] <= pkt[0]; ack[14] <= pkt[1]; ack[15] <= pkt[2];
				udp_send_len <= 16'd16;
				dest_port <= UDP_PORT;
				print_tx  <= 1'b0;
				cnt <= 9'd0;
				st  <= S_TXREQ;
			end
			S_TXREQ: begin
				udp_tx_req <= 1'b1;
				if (udp_ram_data_req) begin
					udp_tx_req <= 1'b0;
					st <= S_WR;
					cnt <= 9'd0;
				end
			end
			S_WR: begin
				ram_wr_en   <= 1'b1;
				ram_wr_data <= print_tx ? print_buf[cnt[7:0]] : ack[cnt[3:0]];
				if (({7'd0, cnt} + 16'd1) >= udp_send_len) begin
					cnt <= 9'd0;
					st  <= S_WAITEND;
				end else
					cnt <= cnt + 9'd1;
			end
			S_WAITEND: begin
				ram_wr_en <= 1'b0;
				if (mac_send_end)
					st <= S_IDLE;
			end
			default: st <= S_IDLE;
		endcase
	end
end

endmodule
