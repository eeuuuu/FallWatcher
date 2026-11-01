// 2-master AXI4 mux. Grant is registered and held until the burst ends.
// S1 (CPU) wins when both request; S0 (video) otherwise.
module axi4_2m_pri #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 128,
	parameter ID_WIDTH   = 4,
	parameter STRB_WIDTH = DATA_WIDTH/8
)(
	input  wire                     clk,
	input  wire                     rst_n,

	input  wire [ID_WIDTH-1:0]      s0_awid,
	input  wire [ADDR_WIDTH-1:0]    s0_awaddr,
	input  wire [7:0]               s0_awlen,
	input  wire [2:0]               s0_awsize,
	input  wire [1:0]               s0_awburst,
	input  wire                     s0_awlock,
	input  wire [3:0]               s0_awcache,
	input  wire [2:0]               s0_awprot,
	input  wire                     s0_awvalid,
	output wire                     s0_awready,
	input  wire [DATA_WIDTH-1:0]    s0_wdata,
	input  wire [STRB_WIDTH-1:0]    s0_wstrb,
	input  wire                     s0_wlast,
	input  wire                     s0_wvalid,
	output wire                     s0_wready,
	output wire [ID_WIDTH-1:0]      s0_bid,
	output wire [1:0]               s0_bresp,
	output wire                     s0_bvalid,
	input  wire                     s0_bready,
	input  wire [ID_WIDTH-1:0]      s0_arid,
	input  wire [ADDR_WIDTH-1:0]    s0_araddr,
	input  wire [7:0]               s0_arlen,
	input  wire [2:0]               s0_arsize,
	input  wire [1:0]               s0_arburst,
	input  wire                     s0_arlock,
	input  wire [3:0]               s0_arcache,
	input  wire [2:0]               s0_arprot,
	input  wire                     s0_arvalid,
	output wire                     s0_arready,
	output wire [ID_WIDTH-1:0]      s0_rid,
	output wire [DATA_WIDTH-1:0]    s0_rdata,
	output wire [1:0]               s0_rresp,
	output wire                     s0_rlast,
	output wire                     s0_rvalid,
	input  wire                     s0_rready,

	input  wire [ID_WIDTH-1:0]      s1_awid,
	input  wire [ADDR_WIDTH-1:0]    s1_awaddr,
	input  wire [7:0]               s1_awlen,
	input  wire [2:0]               s1_awsize,
	input  wire [1:0]               s1_awburst,
	input  wire                     s1_awlock,
	input  wire [3:0]               s1_awcache,
	input  wire [2:0]               s1_awprot,
	input  wire                     s1_awvalid,
	output wire                     s1_awready,
	input  wire [DATA_WIDTH-1:0]    s1_wdata,
	input  wire [STRB_WIDTH-1:0]    s1_wstrb,
	input  wire                     s1_wlast,
	input  wire                     s1_wvalid,
	output wire                     s1_wready,
	output wire [ID_WIDTH-1:0]      s1_bid,
	output wire [1:0]               s1_bresp,
	output wire                     s1_bvalid,
	input  wire                     s1_bready,
	input  wire [ID_WIDTH-1:0]      s1_arid,
	input  wire [ADDR_WIDTH-1:0]    s1_araddr,
	input  wire [7:0]               s1_arlen,
	input  wire [2:0]               s1_arsize,
	input  wire [1:0]               s1_arburst,
	input  wire                     s1_arlock,
	input  wire [3:0]               s1_arcache,
	input  wire [2:0]               s1_arprot,
	input  wire                     s1_arvalid,
	output wire                     s1_arready,
	output wire [ID_WIDTH-1:0]      s1_rid,
	output wire [DATA_WIDTH-1:0]    s1_rdata,
	output wire [1:0]               s1_rresp,
	output wire                     s1_rlast,
	output wire                     s1_rvalid,
	input  wire                     s1_rready,

	output wire [ID_WIDTH-1:0]      m_awid,
	output wire [ADDR_WIDTH-1:0]    m_awaddr,
	output wire [7:0]               m_awlen,
	output wire [2:0]               m_awsize,
	output wire [1:0]               m_awburst,
	output wire                     m_awlock,
	output wire [3:0]               m_awcache,
	output wire [2:0]               m_awprot,
	output wire                     m_awvalid,
	input  wire                     m_awready,
	output wire [DATA_WIDTH-1:0]    m_wdata,
	output wire [STRB_WIDTH-1:0]    m_wstrb,
	output wire                     m_wlast,
	output wire                     m_wvalid,
	input  wire                     m_wready,
	input  wire [ID_WIDTH-1:0]      m_bid,
	input  wire [1:0]               m_bresp,
	input  wire                     m_bvalid,
	output wire                     m_bready,
	output wire [ID_WIDTH-1:0]      m_arid,
	output wire [ADDR_WIDTH-1:0]    m_araddr,
	output wire [7:0]               m_arlen,
	output wire [2:0]               m_arsize,
	output wire [1:0]               m_arburst,
	output wire                     m_arlock,
	output wire [3:0]               m_arcache,
	output wire [2:0]               m_arprot,
	output wire                     m_arvalid,
	input  wire                     m_arready,
	input  wire [ID_WIDTH-1:0]      m_rid,
	input  wire [DATA_WIDTH-1:0]    m_rdata,
	input  wire [1:0]               m_rresp,
	input  wire                     m_rlast,
	input  wire                     m_rvalid,
	output wire                     m_rready
);

localparam [1:0] W_IDLE = 2'd0, W_ADDR = 2'd1, W_DATA = 2'd2, W_RESP = 2'd3;
localparam [1:0] R_IDLE = 2'd0, R_ADDR = 2'd1, R_DATA = 2'd2;

reg [1:0] wr_st, rd_st;
reg       wr_sel, rd_sel;
reg       wr_aw_done, wr_w_done;

wire wr_use1 = (wr_st != W_IDLE) & wr_sel;
wire wr_use0 = (wr_st != W_IDLE) & ~wr_sel;
wire rd_use1 = (rd_st != R_IDLE) & rd_sel;
wire rd_use0 = (rd_st != R_IDLE) & ~rd_sel;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		wr_st      <= W_IDLE;
		wr_sel     <= 1'b0;
		wr_aw_done <= 1'b0;
		wr_w_done  <= 1'b0;
	end else begin
		case (wr_st)
			W_IDLE: begin
				wr_aw_done <= 1'b0;
				wr_w_done  <= 1'b0;
				if (s1_awvalid) begin
					wr_sel <= 1'b1;
					wr_st  <= W_ADDR;
				end else if (s0_awvalid) begin
					wr_sel <= 1'b0;
					wr_st  <= W_ADDR;
				end
			end
			W_ADDR: begin
				if (m_awvalid & m_awready)
					wr_aw_done <= 1'b1;
				if (m_wvalid & m_wready & m_wlast)
					wr_w_done <= 1'b1;
				if ((wr_aw_done | (m_awvalid & m_awready)) &
				    (wr_w_done  | (m_wvalid & m_wready & m_wlast)))
					wr_st <= W_RESP;
			end
			W_RESP: begin
				if (m_bvalid & m_bready) begin
					wr_st      <= W_IDLE;
					wr_aw_done <= 1'b0;
					wr_w_done  <= 1'b0;
				end
			end
			default: wr_st <= W_IDLE;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rd_st  <= R_IDLE;
		rd_sel <= 1'b0;
	end else begin
		case (rd_st)
			R_IDLE: begin
				if (s1_arvalid) begin
					rd_sel <= 1'b1;
					rd_st  <= R_ADDR;
				end else if (s0_arvalid) begin
					rd_sel <= 1'b0;
					rd_st  <= R_ADDR;
				end
			end
			R_ADDR: begin
				if (m_arvalid & m_arready)
					rd_st <= R_DATA;
			end
			R_DATA: begin
				if (m_rvalid & m_rready & m_rlast)
					rd_st <= R_IDLE;
			end
			default: rd_st <= R_IDLE;
		endcase
	end
end

assign m_awid    = wr_use1 ? s1_awid    : s0_awid;
assign m_awaddr  = wr_use1 ? s1_awaddr  : s0_awaddr;
assign m_awlen   = wr_use1 ? s1_awlen   : s0_awlen;
assign m_awsize  = wr_use1 ? s1_awsize  : s0_awsize;
assign m_awburst = wr_use1 ? s1_awburst : s0_awburst;
assign m_awlock  = wr_use1 ? s1_awlock  : s0_awlock;
assign m_awcache = wr_use1 ? s1_awcache : s0_awcache;
assign m_awprot  = wr_use1 ? s1_awprot  : s0_awprot;
assign m_awvalid = (wr_st == W_ADDR) & ~wr_aw_done & (wr_sel ? s1_awvalid : s0_awvalid);
assign s0_awready = (wr_st == W_ADDR) & ~wr_sel & ~wr_aw_done & m_awready;
assign s1_awready = (wr_st == W_ADDR) &  wr_sel & ~wr_aw_done & m_awready;

assign m_wdata  = wr_use1 ? s1_wdata : s0_wdata;
assign m_wstrb  = wr_use1 ? s1_wstrb : s0_wstrb;
assign m_wlast  = wr_use1 ? s1_wlast : s0_wlast;
assign m_wvalid = (wr_st == W_ADDR) & ~wr_w_done & (wr_sel ? s1_wvalid : s0_wvalid);
assign s0_wready = (wr_st == W_ADDR) & ~wr_sel & ~wr_w_done & m_wready;
assign s1_wready = (wr_st == W_ADDR) &  wr_sel & ~wr_w_done & m_wready;

assign s0_bid    = m_bid;
assign s1_bid    = m_bid;
assign s0_bresp  = m_bresp;
assign s1_bresp  = m_bresp;
assign s0_bvalid = (wr_st == W_RESP) & ~wr_sel & m_bvalid;
assign s1_bvalid = (wr_st == W_RESP) &  wr_sel & m_bvalid;
assign m_bready  = (wr_st == W_RESP) & (wr_sel ? s1_bready : s0_bready);

assign m_arid    = rd_use1 ? s1_arid    : s0_arid;
assign m_araddr  = rd_use1 ? s1_araddr  : s0_araddr;
assign m_arlen   = rd_use1 ? s1_arlen   : s0_arlen;
assign m_arsize  = rd_use1 ? s1_arsize  : s0_arsize;
assign m_arburst = rd_use1 ? s1_arburst : s0_arburst;
assign m_arlock  = rd_use1 ? s1_arlock  : s0_arlock;
assign m_arcache = rd_use1 ? s1_arcache : s0_arcache;
assign m_arprot  = rd_use1 ? s1_arprot  : s0_arprot;
assign m_arvalid = (rd_st == R_ADDR) & (rd_sel ? s1_arvalid : s0_arvalid);
assign s0_arready = (rd_st == R_ADDR) & ~rd_sel & m_arready;
assign s1_arready = (rd_st == R_ADDR) &  rd_sel & m_arready;

assign s0_rid    = m_rid;
assign s1_rid    = m_rid;
assign s0_rdata  = m_rdata;
assign s1_rdata  = m_rdata;
assign s0_rresp  = m_rresp;
assign s1_rresp  = m_rresp;
assign s0_rlast  = m_rlast;
assign s1_rlast  = m_rlast;
assign s0_rvalid = (rd_st == R_DATA) & ~rd_sel & m_rvalid;
assign s1_rvalid = (rd_st == R_DATA) &  rd_sel & m_rvalid;
assign m_rready  = (rd_st == R_DATA) & (rd_sel ? s1_rready : s0_rready);

endmodule
