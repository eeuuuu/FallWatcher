// CPU mailbox at 0xF8100000. Official APB3 timing (PREADY low in IDLE).
// 0x00 W print char / R print_full
// 0x04 R gray_frame
// 0x08 R {sht,to,ta,score}
// 0x0C R {ir_y,ir_x,mot,code,evt}
// 0x10 W/R pd_score[7:0] | pd_on[8]
// 0x14 R {mot_y0,mot_x0}
// 0x18 R {mot_y1,mot_x1}
// 0x30 R {mot_y0_2,mot_x0_2}
// 0x34 R {mot_y1_2,mot_x1_2}
// 0x1C R bin_full
// 0x20 W binary UDP byte (port 5002)
// 0x1000+(i<<2) R gray96 pixel i
module apb_print (
	input  wire        pclk,
	input  wire        presetn,
	input  wire [15:0] paddr,
	input  wire        psel,
	input  wire        penable,
	input  wire        pwrite,
	input  wire [31:0] pwdata,
	output wire        pready,
	output wire [31:0] prdata,
	output wire        pslverr,
	output wire        wr_clk,
	output wire        wr_rst_n,
	output wire        wr_en,
	output wire [7:0]  wr_data,
	input  wire        wr_full,
	output wire        wr_bin_en,
	output wire [7:0]  wr_bin_data,
	input  wire        wr_bin_full,
	output wire [13:0] gray_addr,
	input  wire [7:0]  gray_data,
	input  wire [15:0] gray_frame,
	input  wire [7:0]  sht,
	input  wire [7:0]  mlx_to,
	input  wire [7:0]  mlx_ta,
	input  wire [7:0]  score,
	input  wire        evt_on,
	input  wire [2:0]  evt_code,
	input  wire        mot_valid,
	input  wire        box2_show,
	input  wire [4:0]  ir_x,
	input  wire [4:0]  ir_y,
	input  wire [10:0] mot_x0,
	input  wire [10:0] mot_y0,
	input  wire [10:0] mot_x1,
	input  wire [10:0] mot_y1,
	input  wire [10:0] mot_x0_2,
	input  wire [10:0] mot_y0_2,
	input  wire [10:0] mot_x1_2,
	input  wire [10:0] mot_y1_2,
	output reg  [7:0]  pd_score,
	output reg         pd_on,
	output reg  [11:0] tcp_rx_raddr,
	input  wire [7:0]  tcp_rx_rdata,
	input  wire [11:0] tcp_rx_len,
	input  wire        tcp_rx_valid,
	output reg         tcp_rx_ack,
	output reg         tcp_tx_we,
	output reg  [11:0] tcp_tx_waddr,
	output reg  [7:0]  tcp_tx_wdata,
	output reg  [11:0] tcp_tx_len,
	output reg         tcp_tx_kick,
	input  wire        tcp_tx_busy,
	input  wire        voice_ok,
	input  wire        voice_swap,
	input  wire [15:0] voice_track,
	input  wire        lp,
	input  wire [1:0]  lp_st,
	input  wire [3:0]  lp_sec,
	output reg         host_play_req,
	output reg  [15:0] host_play_trk,
	input  wire        host_play_ack,
	output reg         alarm_arm
);

localparam [1:0] IDLE = 2'd0, SETUP = 2'd1, ACCESS = 2'd2;

reg  [1:0]  bus_st;
reg         slave_ready;
wire        act_write = pwrite  & (bus_st == ACCESS);
wire        act_read  = ~pwrite & (bus_st == ACCESS);

wire        sel_gray = (paddr >= 16'h1000) && (paddr < 16'hA000);
wire [13:0] word     = paddr[15:2];
wire        wr_pulse = act_write & ~slave_ready;

assign wr_clk   = pclk;
assign wr_rst_n = presetn;
assign pslverr  = 1'b0 & (|paddr);
assign gray_addr = sel_gray ? (word - 14'h0400) : 14'd0;
assign pready   = slave_ready & (bus_st != IDLE);
assign wr_en       = wr_pulse & (word == 14'd0);
assign wr_data     = pwdata[7:0];
assign wr_bin_en   = wr_pulse & (word == 14'd8);
assign wr_bin_data = pwdata[7:0];

reg [31:0] rdata;
always @(*) begin
	if (sel_gray)
		rdata = {24'd0, gray_data};
	else begin
		case (word)
			14'd0: rdata = {31'd0, wr_full};
			14'd1: rdata = {16'd0, gray_frame};
			14'd2: rdata = {sht, mlx_to, mlx_ta, score};
			14'd3: rdata = {11'd0, ir_y, ir_x, 1'b0, box2_show, mot_valid, evt_code, evt_on};
			14'd4: rdata = {23'd0, pd_on, pd_score};
			14'd5: rdata = {5'd0, mot_y0, 5'd0, mot_x0};
			14'd6: rdata = {5'd0, mot_y1, 5'd0, mot_x1};
			14'd7: rdata = {31'd0, wr_bin_full};
			14'd12: rdata = {5'd0, mot_y0_2, 5'd0, mot_x0_2};
			14'd13: rdata = {5'd0, mot_y1_2, 5'd0, mot_x1_2};
			14'd9: rdata = {14'd0, voice_swap, voice_ok, voice_track};
			14'd11: rdata = {22'd0, lp_st, lp_sec, 3'd0, lp};
			14'd14: rdata = {31'd0, alarm_arm};
			14'd16: rdata = {14'd0, tcp_tx_busy, tcp_rx_valid, tcp_rx_len};
			14'd17: rdata = {24'd0, tcp_rx_rdata};
			14'd19: rdata = {31'd0, tcp_tx_busy};
			default: rdata = 32'd0;
		endcase
	end
end
assign prdata = rdata;

always @(posedge pclk or negedge presetn) begin
	if (!presetn)
		bus_st <= IDLE;
	else begin
		case (bus_st)
			IDLE:   bus_st <= (psel && !penable) ? SETUP : IDLE;
			SETUP:  bus_st <= (psel &&  penable) ? ACCESS : IDLE;
			ACCESS: bus_st <= pready ? IDLE : ACCESS;
			default: bus_st <= IDLE;
		endcase
	end
end

always @(posedge pclk or negedge presetn) begin
	if (!presetn)
		slave_ready <= 1'b0;
	else
		slave_ready <= act_write | act_read;
end

wire rd_done = act_read & slave_ready;

always @(posedge pclk or negedge presetn) begin
	if (!presetn) begin
		pd_score <= 8'd0;
		pd_on    <= 1'b0;
		host_play_req <= 1'b0;
		host_play_trk <= 16'd0;
		alarm_arm     <= 1'b0;
		tcp_rx_raddr <= 12'd0;
		tcp_rx_ack   <= 1'b0;
		tcp_tx_we    <= 1'b0;
		tcp_tx_waddr <= 12'd0;
		tcp_tx_wdata <= 8'd0;
		tcp_tx_len   <= 12'd0;
		tcp_tx_kick  <= 1'b0;
	end else begin
		tcp_rx_ack  <= 1'b0;
		tcp_tx_we   <= 1'b0;
		tcp_tx_kick <= 1'b0;
		if (wr_pulse && (word == 14'd4)) begin
			pd_score <= pwdata[7:0];
			pd_on    <= pwdata[8];
		end
		if (wr_pulse && (word == 14'd10)) begin
			host_play_trk <= pwdata[15:0];
			host_play_req <= 1'b1;
		end else if (host_play_ack)
			host_play_req <= 1'b0;
		if (wr_pulse && (word == 14'd16)) begin
			tcp_rx_ack   <= 1'b1;
			tcp_rx_raddr <= 12'd0;
		end
		if (rd_done && (word == 14'd17))
			tcp_rx_raddr <= tcp_rx_raddr + 12'd1;
		tcp_tx_we <= wr_pulse && (word == 14'd18);
		if (wr_pulse && (word == 14'd18))
			tcp_tx_wdata <= pwdata[7:0];
		if (tcp_tx_we)
			tcp_tx_waddr <= tcp_tx_waddr + 12'd1;
		if (wr_pulse && (word == 14'd20))
			tcp_tx_waddr <= 12'd0;
		if (wr_pulse && (word == 14'd14))
			alarm_arm <= pwdata[0];
		if (wr_pulse && (word == 14'd19)) begin
			tcp_tx_len   <= pwdata[11:0];
			tcp_tx_kick  <= 1'b1;
			tcp_tx_waddr <= 12'd0;
		end
	end
end

endmodule
