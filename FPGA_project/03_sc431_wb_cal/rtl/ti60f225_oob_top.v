
/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2021 Efinix Inc. All rights reserved.
//
// Description:
// Example top file for ti60f225 dev kit OOB design
//
// Language:  Verilog 2001
//
// ------------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////////
//`define SOFT_TAP 1
`include "ddr3_controller/ddr3_parameter.vh"
// `include "define.v"

module ti60f225_oob_top #(

	parameter                       RANK_RATIO         = 1,       // # of unique CS outputs per rank
	parameter                       ASYN_AXI_CLK       = `ASYN_AXI_CLK, 
	parameter                       RANKS              = `RANKS,
	parameter                       CK_WIDTH           = `CK_WIDTH,       // # of CK/CK# outputs to memory   
	parameter                       CKE_WIDTH          = `CKE_WIDTH,       // # of cke outputs
	parameter                       CS_WIDTH           = `CS_WIDTH,       // # of unique CS outputs
	parameter                       BANK_WIDTH         = `BANK_WIDTH,       // # of bank bits
	parameter                       ROW_WIDTH          = `ROW_WIDTH,       // DRAM address bus width
	parameter                       COL_WIDTH          = `COL_WIDTH,      // column address width
	parameter                       DM_WIDTH           = `DM_WIDTH,       // # of DM (data mask)
	parameter                       DQS_WIDTH          = `DQS_WIDTH,       // # of DQS (strobe)
	parameter                       DQ_WIDTH           = `DQ_WIDTH,      // # of DQ (data)
	parameter                       ODT_WIDTH          = `ODT_WIDTH,
	parameter                       DQ_CNT_WIDTH       = `DQ_CNT_WIDTH,       // = ceil(log2(DQ_WIDTH))
	parameter                       DQS_CNT_WIDTH      = `DQS_CNT_WIDTH,       // = ceil(log2(DQS_WIDTH))  
	parameter                       DRAM_WIDTH         = `DRAM_WIDTH,       // # of DQ per DQS   
	parameter                       DATA_WIDTH         = `DATA_WIDTH,
	parameter                       ADDR_WIDTH         = `ADDR_WIDTH,    
	parameter                       AXI_ID_WIDTH       = `AXI_ID_WIDTH,
	parameter                       AXI_ADDR_WIDTH     = `AXI_ADDR_WIDTH,
	parameter                       AXI_DATA_WIDTH     = `AXI_DATA_WIDTH
)
(
   //Clocks 
	input	wire	i_arstn,
    input  wire system_uart_0_io_rxd,
    output wire system_uart_0_io_txd,
    input  wire jtag_inst1_CAPTURE,
    input  wire jtag_inst1_DRCK,
    input  wire jtag_inst1_RESET,
    input  wire jtag_inst1_RUNTEST,
    input  wire jtag_inst1_SEL,
    input  wire jtag_inst1_SHIFT,
    input  wire jtag_inst1_TCK,
    input  wire jtag_inst1_TDI,
    input  wire jtag_inst1_TMS,
    input  wire jtag_inst1_UPDATE,
    output wire jtag_inst1_TDO,
    input	wire	i_mipi_rx_pclk,
    input wire  vid_clk_dvi2,
    input wire hdmi_tx_slow_clk,
    // input   wire    i_soc_clk,
    input wire CLK_5M,
    input  wire CLK_25M,
	output  wire    pll_inst1_RSTN,
	input	wire	i_pll_locked,
	input 	wire  	pll_locked,
	output  wire    pll_inst4_RSTN,
	input   wire    pll_inst4_LOCKED,
	output  wire  	USER_PLL_RSTN,
    output 	wire 	DDR3_PLL_RSTN,
	input 	wire  	user_pll_locked,
    //CSI Interface
    input	 wire		io_cam_sda_IN,
    output wire   io_cam_sda_OUT,
    output wire		io_cam_sda_OE,

    output io_cam_scl_OUT,
    input io_cam_scl_IN,
    output io_cam_scl_OE,

    input  wire io_j7_sda_IN,
    output wire io_j7_sda_OUT,
    output wire io_j7_sda_OE,
    output wire io_j7_scl_OUT,
    input  wire io_j7_scl_IN,
    output wire io_j7_scl_OE,
    input  wire io_j7_sht_sda_IN,
    output wire io_j7_sht_sda_OUT,
    output wire io_j7_sht_sda_OE,
    output wire io_j7_sht_scl_OUT,
    input  wire io_j7_sht_scl_IN,
    output wire io_j7_sht_scl_OE,
    output wire o_j7_buzzer,
    input  wire       rxc,
    input  wire       rx_dv_HI,
    input  wire       rx_dv_LO,
    input  wire [3:0] rxd_hi_i,
    input  wire [3:0] rxd_lo_i,
    output wire       tx_en_o_HI,
    output wire       tx_en_o_LO,
    output wire       txc_hi_o,
    output wire       txc_lo_o,
    output wire [3:0] txd_hi_o,
    output wire [3:0] txd_lo_o,
    output wire       phy_rst_n,

    output	wire		o_cam_rst_p,
    
    input	wire		i_cam_ck_LP_P_IN,
    input	wire		i_cam_ck_LP_N_IN,
    output	wire		o_cam_ck_HS_TERM,
    output	wire		o_cam_ck_HS_ENA,
    input	wire		i_cam_ck_CLKOUT,
    
    input	wire	[7:0]			cam_d0_HS_IN,
    input	  wire		      cam_d0_LP_P_IN,
    input	  wire		      cam_d0_LP_N_IN,
    output	wire		      cam_d0_HS_TERM,
    output	wire		      cam_d0_HS_ENA,
    output	wire		      cam_d0_RST,
    output	wire		      cam_d0_FIFO_RD,
    input	  wire		      cam_d0_FIFO_EMPTY,
    
    input 	wire	[7:0]			cam_d1_HS_IN,
    input	  wire		        cam_d1_LP_P_IN,
    input	  wire		        cam_d1_LP_N_IN,
    output	wire		        cam_d1_HS_TERM,
    output	wire		        cam_d1_HS_ENA,
    output	wire		        cam_d1_RST,
    output	wire		        cam_d1_FIFO_RD,
    input	  wire		        cam_d1_FIFO_EMPTY,
    
    input 	wire	[7:0]			cam_d2_HS_IN,
    input	  wire		        cam_d2_LP_P_IN,
    input	  wire		        cam_d2_LP_N_IN,
    output	wire		        cam_d2_HS_TERM,
    output	wire		        cam_d2_HS_ENA,
    output	wire		        cam_d2_RST,
    output	wire		        cam_d2_FIFO_RD,
    input	  wire		        cam_d2_FIFO_EMPTY,  
   
    input 	wire	[7:0]			cam_d3_HS_IN,
    input	  wire		        cam_d3_LP_P_IN,
    input	  wire		        cam_d3_LP_N_IN,
    output	wire		        cam_d3_HS_TERM,
    output	wire		        cam_d3_HS_ENA,
    output	wire		        cam_d3_RST,
    output	wire		        cam_d3_FIFO_RD,
    input	  wire		        cam_d3_FIFO_EMPTY,

	
	input 					tx_cal_clk_90edge,
  	input 					rx_cal_clk,
  	input 					tx_cal_clk,
	input                              core_clk,     // CORE CLK @ 100MHz
	input                              sdram_clk,    // SDRAM CK @ 400MHz
	// PLL status flags  
	output [2:0]                       pll_shift,  
	output [4:0]                       pll_shift_sel,
	output                             pll_shift_ena,  
	// memory interface ports
	output                             ddr_ck_hi,
	output                             ddr_ck_lo,
	output                             ddr_reset_n,
	output [CKE_WIDTH-1:0]             ddr_cke,     
	output [ROW_WIDTH-1:0]             ddr_addr,
	output [BANK_WIDTH-1:0]            ddr_ba,
	output                             ddr_cas_n,
 
	output [CS_WIDTH*RANK_RATIO-1:0]   ddr_cs_n,
	output                             ddr_ras_n,
	output                             ddr_we_n,
	
	input  [DQS_WIDTH-1:0]             ddr_dqs_in_hi,
	input  [DQS_WIDTH-1:0]             ddr_dqs_in_lo,
	input  [DQ_WIDTH-1:0]              ddr_dq_in_hi,
	input  [DQ_WIDTH-1:0]              ddr_dq_in_lo,
	
	output [DQS_WIDTH-1:0]             ddr_dqs_oe,
	output [DQS_WIDTH-1:0]             ddr_dqs_oe_n,
	output [DQ_WIDTH-1:0]              ddr_dq_oe,  
	output [DQS_WIDTH-1:0]             ddr_dqs_out_hi,
	output [DQS_WIDTH-1:0]             ddr_dqs_out_lo,
	output [DQ_WIDTH-1:0]              ddr_dq_out_hi,
	output [DQ_WIDTH-1:0]              ddr_dq_out_lo,
	output [DM_WIDTH-1:0]              ddr_dm_hi,
	output [DM_WIDTH-1:0]              ddr_dm_lo,
	output [ODT_WIDTH-1:0]             ddr_odt,

       //LED: D0=GPIOR_27 event; D7 off (real buzzer is J7-34)
       output [7:0] led,
       output       led_d25,

       // MIPI DSI
       input	wire	                     i_mipi_tx_pclk		,
       output	wire	                     mipi_dp_clk_LP_P_OUT		,
       output	wire	                     mipi_dp_clk_LP_N_OUT		,
       output	wire	[7:0] 	              mipi_dp_clk_HS_OUT		,
       output	wire	                     mipi_dp_clk_HS_OE		,
       output	wire	                     mipi_dp_data3_LP_P_OUT	,
       output	wire	                     mipi_dp_data2_LP_P_OUT	,
       output	wire	                     mipi_dp_data1_LP_P_OUT	,
       output	wire	                     mipi_dp_data0_LP_P_OUT	,
       output	wire	                     mipi_dp_data3_LP_N_OUT	,
       output	wire	                     mipi_dp_data2_LP_N_OUT	,
       output	wire	                     mipi_dp_data1_LP_N_OUT	,
       output	wire	                     mipi_dp_data0_LP_N_OUT	,
       output	wire	[7:0] 	              mipi_dp_data0_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data1_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data2_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data3_HS_OUT	       ,
       output	wire	                     mipi_dp_data3_HS_OE		,
       output	wire	                     mipi_dp_data2_HS_OE		,
       output	wire	                     mipi_dp_data1_HS_OE		,
       output	wire	                     mipi_dp_data0_HS_OE		,

       output	wire	                     mipi_dp_clk_RST		,
       output	wire	                     mipi_dp_data0_RST		,
       output	wire	                     mipi_dp_data1_RST		,
       output	wire	                     mipi_dp_data2_RST		,
       output	wire	                     mipi_dp_data3_RST		,
       output	wire	                     mipi_dp_clk_LP_P_OE		,
       output	wire	                     mipi_dp_clk_LP_N_OE		,
       output	wire	                     mipi_dp_data3_LP_P_OE	,
       output	wire	                     mipi_dp_data3_LP_N_OE	,
       output	wire	                     mipi_dp_data2_LP_P_OE	,
       output	wire	                     mipi_dp_data2_LP_N_OE	,
       output	wire	                     mipi_dp_data1_LP_P_OE	,
       output	wire	                     mipi_dp_data1_LP_N_OE	,
       output	wire	                     mipi_dp_data0_LP_P_OE	,
       output	wire	                     mipi_dp_data0_LP_N_OE	,

       input  wire	                     mipi_dp_data0_LP_P_IN	,
       input  wire	                     mipi_dp_data0_LP_N_IN	,
       output	wire	                     LCD_RST_P			,
       output wire                        LCD_POWER			,

       // hdmi interface

    output tmds_tx_clk_TX_OE,
    output [9:0] tmds_tx_clk_TX_DATA,
    output tmds_tx_clk_TX_RST,
    output tmds_tx_data0_TX_OE,
    output [9:0] tmds_tx_data0_TX_DATA,
    output tmds_tx_data0_TX_RST,
    output tmds_tx_data1_TX_OE,
    output [9:0] tmds_tx_data1_TX_DATA,
    output tmds_tx_data1_TX_RST,
    output tmds_tx_data2_TX_OE,
    output [9:0] tmds_tx_data2_TX_DATA,
    output tmds_tx_data2_TX_RST


);



//===============================================================================
//localparam
//===============================================================================
localparam WR_FIFO_DEPTH  = 1024;
localparam RD_FIFO_DEPTH  = 1024;

// HDMI 1080p60: USER_PLL 148.75 MHz 1-pix, vid_clk_dvi2 74.375 MHz 2-pix, genlock to FB
localparam	MAX_HRES		= 12'd1920;
localparam	MAX_VRES		= 12'd1080;
localparam	HSP			= 8'd44;
localparam	HBP			= 8'd148;
localparam	HFP			= 8'd88;
localparam	VSP			= 8'd5;
localparam	VBP			= 8'd36;
localparam	VFP			= 8'd4;
//===============================================================================
//signal
//===============================================================================
   
wire                              app_sr_active;
wire                              app_ref_ack;
wire                              app_zq_ack;
wire                              cal_done;

// Slave Interface Write Address Ports
wire [AXI_ID_WIDTH-1:0]           fb_axi_awid;
wire [AXI_ADDR_WIDTH-1:0]         fb_axi_awaddr;
wire [7:0]                        fb_axi_awlen;
wire [2:0]                        fb_axi_awsize;
wire [1:0]                        fb_axi_awburst;
wire [0:0]                        fb_axi_awlock;
wire [3:0]                        fb_axi_awcache;
wire [2:0]                        fb_axi_awprot;
wire                              fb_axi_awvalid;
wire                              fb_axi_awready;
wire [AXI_DATA_WIDTH-1:0]         fb_axi_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0]     fb_axi_wstrb;
wire                              fb_axi_wlast;
wire                              fb_axi_wvalid;
wire                              fb_axi_wready;
wire                              fb_axi_bready;
wire [AXI_ID_WIDTH-1:0]           fb_axi_bid;
wire [1:0]                        fb_axi_bresp;
wire                              fb_axi_bvalid;
wire [AXI_ID_WIDTH-1:0]           fb_axi_arid;
wire [AXI_ADDR_WIDTH-1:0]         fb_axi_araddr;
wire [7:0]                        fb_axi_arlen;
wire [2:0]                        fb_axi_arsize;
wire [1:0]                        fb_axi_arburst;
wire [0:0]                        fb_axi_arlock;
wire [3:0]                        fb_axi_arcache;
wire [2:0]                        fb_axi_arprot;
wire                              fb_axi_arvalid;
wire                              fb_axi_arready;
wire                              fb_axi_rready;
wire [AXI_ID_WIDTH-1:0]           fb_axi_rid;
wire [AXI_DATA_WIDTH-1:0]         fb_axi_rdata;
wire [1:0]                        fb_axi_rresp;
wire                              fb_axi_rlast;
wire                              fb_axi_rvalid;

wire [7:0]                        cpu_awid;
wire [AXI_ADDR_WIDTH-1:0]         cpu_awaddr;
wire [7:0]                        cpu_awlen;
wire [2:0]                        cpu_awsize;
wire [1:0]                        cpu_awburst;
wire                              cpu_awlock;
wire [3:0]                        cpu_awcache;
wire [2:0]                        cpu_awprot;
wire                              cpu_awvalid;
wire                              cpu_awready;
wire [AXI_DATA_WIDTH-1:0]         cpu_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0]     cpu_wstrb;
wire                              cpu_wlast;
wire                              cpu_wvalid;
wire                              cpu_wready;
wire                              cpu_bready;
wire [7:0]                        cpu_bid;
wire [1:0]                        cpu_bresp;
wire                              cpu_bvalid;
wire [7:0]                        cpu_arid;
wire [AXI_ADDR_WIDTH-1:0]         cpu_araddr;
wire [7:0]                        cpu_arlen;
wire [2:0]                        cpu_arsize;
wire [1:0]                        cpu_arburst;
wire                              cpu_arlock;
wire [3:0]                        cpu_arcache;
wire [2:0]                        cpu_arprot;
wire                              cpu_arvalid;
wire                              cpu_arready;
wire                              cpu_rready;
wire [7:0]                        cpu_rid;
wire [AXI_DATA_WIDTH-1:0]         cpu_rdata;
wire [1:0]                        cpu_rresp;
wire                              cpu_rlast;
wire                              cpu_rvalid;

wire [AXI_ID_WIDTH-1:0]           s_axi_awid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_awaddr;
wire [7:0]                        s_axi_awlen;
wire [2:0]                        s_axi_awsize;
wire [1:0]                        s_axi_awburst;
wire [0:0]                        s_axi_awlock;
wire [3:0]                        s_axi_awcache;
wire [2:0]                        s_axi_awprot;
wire                              s_axi_awvalid;
wire                              s_axi_awready;
// Slave Interface Write Data Ports
wire [AXI_DATA_WIDTH-1:0]         s_axi_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0]     s_axi_wstrb;
wire                              s_axi_wlast;
wire                              s_axi_wvalid;
wire                              s_axi_wready;
// Slave Interface Write Response Ports
wire                              s_axi_bready;
wire [AXI_ID_WIDTH-1:0]           s_axi_bid;
wire [1:0]                        s_axi_bresp;
wire                              s_axi_bvalid;
// Slave Interface Read Address Ports
wire [AXI_ID_WIDTH-1:0]           s_axi_arid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_araddr;
wire [7:0]                        s_axi_arlen;
wire [2:0]                        s_axi_arsize;
wire [1:0]                        s_axi_arburst;
wire [0:0]                        s_axi_arlock;
wire [3:0]                        s_axi_arcache;
wire [2:0]                        s_axi_arprot;
wire                              s_axi_arvalid;
wire                              s_axi_arready;
// Slave Interface Read Data Ports
wire                              s_axi_rready;
wire [AXI_ID_WIDTH-1:0]           s_axi_rid;
wire [AXI_DATA_WIDTH-1:0]         s_axi_rdata;
wire [1:0]                        s_axi_rresp;
wire                              s_axi_rlast;
wire                              s_axi_rvalid;




////////////////////////////////////////////////////////////////
// System & Debugger
wire    w_arstn;
wire	w_sysclk_mcu_arstn;
wire	w_sysclk_mcu_arst;
wire	w_mipi_rx_pclk_arstn;
wire	w_mipi_rx_pclk_arst;

wire		       w_mipi_rx_vs;
wire		       w_mipi_rx_hs;
wire	       w_mipi_rx_de;
wire	[63:0]			w_mipi_rx_data	;

wire					io_systemReset;
wire [15:0]				apb0_paddr;
wire					apb0_psel;
wire					apb0_penable;
wire					apb0_pwrite;
wire [31:0]				apb0_pwdata;
wire					apb0_pready;
wire [31:0]				apb0_prdata;
wire					apb0_pslverr;
wire					print_wr_clk;
wire					print_wr_rst_n;
wire					print_wr_en;
wire [7:0]				print_wr_data;
wire					print_wr_full;
wire					print_bin_wr_en;
wire [7:0]				print_bin_wr_data;
wire					print_bin_wr_full;
wire [13:0]				gray96_cpu_addr;
wire [7:0]				gray96_cpu_data;
wire [15:0]				gray96_cpu_frame;
wire [7:0]				pd_score_cpu;
wire					pd_on_cpu;
reg  [7:0]				sht_c0, sht_c1, to_c0, to_c1, ta_c0, ta_c1, sc_c0, sc_c1;
reg						vok_c0, vok_c1, vsw_c0, vsw_c1;
reg  [15:0]				vtk_c0, vtk_c1;
wire					lp_hw;
wire [1:0]				lp_st_hw;
wire [3:0]				lp_sec_hw;
reg						lp_c0, lp_c1;
reg  [1:0]				lpst_c0, lpst_c1;
reg  [3:0]				lpsc_c0, lpsc_c1;
wire					host_play_req;
wire [15:0]				host_play_trk;
wire					host_play_ack_25;
reg						host_play_ack_c0, host_play_ack_c;
reg						play_r0, play_r1;
reg  [15:0]				play_t0, play_t1;
reg  [2:0]				code_c0, code_c1;
reg						evt_c0, evt_c1, mot_c0, mot_c1;
reg  [4:0]				irx_c0, irx_c1, iry_c0, iry_c1;
reg  [10:0]				mx0_c0, mx0_c1, my0_c0, my0_c1, mx1_c0, mx1_c1, my1_c0, my1_c1;



//===================================================================================================
//reset module
//===================================================================================================

assign w_arstn  		       = i_pll_locked & pll_locked & user_pll_locked;
assign pll_inst1_RSTN  		= i_arstn;
assign USER_PLL_RSTN      		= i_arstn;
assign mipi_dsi_tx_pll_RSTN 	= i_arstn;
assign DDR3_PLL_RSTN 		= i_arstn;
reset_ctrl
#(
	.NUM_RST		(2),
	.CYCLE			(1),
	.IN_RST_ACTIVE	(4'b00),
	.OUT_RST_ACTIVE	(4'b10)
)
inst_reset_ctrl
(
	.i_arst		({2{w_arstn}}),//({{4{i_pll_locked}},                  {2{i_arstn}}}),
	.i_clk			({2{i_mipi_rx_pclk}}),
	.o_srst		({w_mipi_rx_pclk_arst, w_mipi_rx_pclk_arstn})
);


reset_ctrl
#(
	.NUM_RST		(2),
	.CYCLE			(10),
	.IN_RST_ACTIVE	(2'b00),
	.OUT_RST_ACTIVE	(2'b10)
)
inst_reset_mcu_ctrl
(
	.i_arst		({2{w_arstn}}),
	.i_clk			({2{i_soc_clk}}),
	.o_srst		({w_sysclk_mcu_arst,w_sysclk_mcu_arstn})
);



reg [25:0] cnt = 'd0;
always @( posedge core_clk)
begin 
       cnt <= cnt + 1'b1;
end
wire        fus_evt;
reg         fus_evt_c1, fus_evt_c2;
always @(posedge core_clk) begin
	fus_evt_c1 <= fus_evt;
	fus_evt_c2 <= fus_evt_c1;
end
assign led[0]   = fus_evt_c2 ? cnt[22] : 1'b0;
assign led[6:1] = 6'b0;
assign led[7]   = 1'b0;
assign led_d25  = 1'b0;

//========================================================================================================
//MIPI RX
//========================================================================================================
wire i_mipi_clk ;
assign i_mipi_clk = core_clk;
assign i_soc_clk  = core_clk;

		assign	cam_d0_RST		= 1'b0;
		assign	cam_d1_RST		= 1'b0;
		assign  cam_d2_RST = 1'b0;
    assign  cam_d3_RST = 1'b0;
	
	
		

		csi_rx_controller inst_efx_csi2_rx
		(
              .reset_n			(i_arstn),
              .clk				(i_mipi_clk),
              .reset_byte_HS_n	(i_arstn),
              .clk_byte_HS		  (i_cam_ck_CLKOUT),
              .reset_pixel_n		(w_mipi_rx_pclk_arstn),
              .clk_pixel			  (i_mipi_rx_pclk),
              
              .Rx_LP_CLK_P		  (i_cam_ck_LP_P_IN),
              .Rx_LP_CLK_N		  (i_cam_ck_LP_N_IN),
              .Rx_HS_enable_C		(o_cam_ck_HS_ENA),
              .LVDS_termen_C		(o_cam_ck_HS_TERM),
              
              .Rx_LP_D_P			({cam_d3_LP_P_IN, cam_d2_LP_P_IN, cam_d1_LP_P_IN, cam_d0_LP_P_IN}),//(r_mipi_rx_data_LP_P_IN_2P),
              .Rx_LP_D_N			({cam_d3_LP_N_IN, cam_d2_LP_N_IN, cam_d1_LP_N_IN, cam_d0_LP_N_IN}),//(r_mipi_rx_data_LP_N_IN_2P),
              .Rx_HS_D_0			(cam_d0_HS_IN),//(r_mipi_rx_data_HS_IN_2P[0*8+:8]),
              .Rx_HS_D_1			(cam_d1_HS_IN),//(r_mipi_rx_data_HS_IN_2P[1*8+:8]),
              .Rx_HS_D_2			(cam_d2_HS_IN),
              .Rx_HS_D_3			(cam_d3_HS_IN),
              .Rx_HS_D_4			(),
              .Rx_HS_D_5			(),
              .Rx_HS_D_6			(),
              .Rx_HS_D_7			(),
              .Rx_HS_enable_D		({cam_d3_HS_ENA    ,cam_d2_HS_ENA    ,cam_d1_HS_ENA    ,cam_d0_HS_ENA    }),//( w_cam_d_HS_ENA),
              .LVDS_termen_D		({cam_d3_HS_TERM   ,cam_d2_HS_TERM   ,cam_d1_HS_TERM   ,cam_d0_HS_TERM   }),
              .fifo_rd_enable		({cam_d3_FIFO_RD   ,cam_d2_FIFO_RD   ,cam_d1_FIFO_RD   ,cam_d0_FIFO_RD   }),
              .fifo_rd_empty		({cam_d3_FIFO_EMPTY,cam_d2_FIFO_EMPTY,cam_d1_FIFO_EMPTY,cam_d0_FIFO_EMPTY}),
              .DLY_enable_D		       (),
              .DLY_inc_D			(),
              .u_dly_enable_D		(),
              .u_dly_inc_D		       (),
              
              .axi_clk			(1'b0),
              .axi_reset_n		       (1'b0),
              .axi_awaddr			(6'b0),
              .axi_awvalid		       (1'b0),
              .axi_awready		       (),
              .axi_wdata			(32'b0),
              .axi_wvalid			(1'b0),
              .axi_wready			(),
              
              .axi_bvalid			(),
              .axi_bready			(1'b0),
              .axi_araddr			(6'b0),
              .axi_arvalid		       (1'b0),
              .axi_arready		       (),
              .axi_rdata			(),
              .axi_rvalid			(),
              .axi_rready			(1'b1),
              
              .hsync_vc0			(w_mipi_rx_hs),
              .hsync_vc1			(),
              .hsync_vc2			(),
              .hsync_vc3			(),
              .vsync_vc0			(w_mipi_rx_vs),
              .vsync_vc1			(),
              .vsync_vc2			(),
              .vsync_vc3			(),
              .vc				(),
              .word_count			(),
              .shortpkt_data_field        (),
              .datatype			(),
              .pixel_per_clk		(),
              .pixel_data			(w_mipi_rx_data),
              .pixel_data_valid	       (w_mipi_rx_de),
              .irq				()
		);

//========================================================================================================
//
//========================================================================================================
		

//*************** imx219 config********************/
// mipi_config_imx219_top u_config_imx219(
// 										.i_sys_clk(CLK_5M)    	,    /////48M 
// 										.sys_rstn(vid_rst_n )    ,
// 										.o_sen_rst_n(o_cam_rstn)  	,
										
										// .o_iic_sda_OE(io_cam_sda_OE) ,
										// .i_iic_sda(io_cam_sda_IN)   	,
										// .o_iic_sda(io_cam_sda_OUT)   	,
										// .o_iic_scl(io_cam_scl)    	
										// ); 	

wire scl_padoen_o;
wire sda_padoen_o;


reg [12:0] i2c_rst_cnt = '0;

always @( posedge CLK_5M or negedge w_arstn )
begin
    if( !w_arstn )
       i2c_rst_cnt <= 'd0;
    else 
       i2c_rst_cnt <= i2c_rst_cnt[12] ? i2c_rst_cnt : i2c_rst_cnt + 1'b1;
end
wire i2c_rst_n = i2c_rst_cnt[12];

wire        cam_extra_req, cam_extra_ack;
wire [15:0] cam_extra_addr;
wire [7:0]  cam_extra_data;
i2c_master_ctrl_top u2_i2c_master_ctrl_top(
  /*i*/.clk			(CLK_5M		),
  /*i*/.rst_n			(i2c_rst_n		),
  /*i*/.scl_pad_i     (io_cam_scl_IN),//(1'b1),
  /*o*/.scl_pad_o     (io_cam_scl_OUT),
  /*o*/.scl_padoen_o  (scl_padoen_o),
  /*i*/.sda_pad_i     (io_cam_sda_IN),
  /*o*/.sda_pad_o     (io_cam_sda_OUT),
  /*o*/.sda_padoen_o  (sda_padoen_o),
  .extra_req  (cam_extra_req),
  .extra_addr (cam_extra_addr),
  .extra_data (cam_extra_data),
  .extra_ack  (cam_extra_ack)
  );
assign o_cam_rst_p = ~w_arstn;
assign io_cam_scl_OE = ~scl_padoen_o;
assign io_cam_sda_OE = ~sda_padoen_o;

//=====================================================================================
//frame buffer
//=====================================================================================
wire [7:0] 	ch0_r;
wire [7:0]    ch0_g;
wire [7:0]    ch0_b;
wire ch0_vs;
wire ch0_hs;
wire ch0_de;
// IMX219
  frame_buffer #(
.I_VID_WIDTH         (32),
.O_VID_WIDTH         (16),
.START_ADDR          (32'h00100000     ),
.AXI_DATA_WIDTH      ( AXI_DATA_WIDTH	),
.AXI_ADDR_WIDTH      ( AXI_ADDR_WIDTH	),
.WR_FIFO_DEPTH	      ( 1024		),    
.RD_FIFO_DEPTH 	      ( 1024 	),
.BURST_LEN  	       (127),
.FB_NUM	            (3),
.MAX_VID_WIDTH	    (960) ,
.MAX_VID_HIGHT	    (1080) 


)checker0(
       .axi_clk		(core_clk 	        ),
       .rst_n			(vid_rst_n   ),

/*i*/.i_clk			(i_mipi_rx_pclk      ),
/*i*/.i_vs			(w_mipi_rx_vs	),
/*i*/.i_de			(w_mipi_rx_de & w_mipi_rx_hs	),
/*i*/.vin 			({w_mipi_rx_data[39:32],w_mipi_rx_data[29:22],w_mipi_rx_data[19:12],w_mipi_rx_data[9:2]}	),
                     
/*i*/.o_clk			(vid_clk_dvi2),//(i_mipi_rx_pclk	),
/*i*/.o_hs    		(ch0_hs		),			
/*i*/.o_vs    		(ch0_vs		),			
/*i*/.o_de    		(ch0_de		),			
/*i*/.vout    		({ch0_g,ch0_b}	),//ch0_r,

/*i*/.H_FRONT_PORCH (HFP/2  		),//
/*i*/.H_SYNC 	 	    (HSP/2	 	),
/*i*/.H_VALID 	 	  (MAX_HRES/2     ),//		
/*i*/.H_BACK_PORCH	(HBP/2		),//		
/*i*/.V_FRONT_PORCH (VFP  		),//		
/*i*/.V_SYNC 	 	    (VSP 	 	),//		
/*i*/.V_VALID 	 	  (MAX_VRES     ),//		
/*i*/.V_BACK_PORCH	(VBP		),//		

       .awid			(fb_axi_awid	),      
       .awaddr		(fb_axi_awaddr	),
       .awlen			(fb_axi_awlen	),
       .awsize		(fb_axi_awsize	),
       .awburst		(fb_axi_awburst),
       .awprot    (fb_axi_awprot ),
       .awcache   (fb_axi_awcache),
       .awlock		(fb_axi_awlock	),
       .awvalid		(fb_axi_awvalid),
       .awready		(fb_axi_awready),

       .arid			(fb_axi_arid	  ),
       .araddr		(fb_axi_araddr	),
       .arlen			(fb_axi_arlen	),
       .arsize		(fb_axi_arsize	),
       .arburst 	(fb_axi_arburst),

       .arprot    (fb_axi_arprot ),
       .arcache   (fb_axi_arcache),
       .arlock 		(fb_axi_arlock	),
       .arvalid		(fb_axi_arvalid),
       .arready		(fb_axi_arready),

       .wdata			(fb_axi_wdata	),
       .wstrb			(fb_axi_wstrb	),
       .wlast			(fb_axi_wlast	),
       .wvalid		(fb_axi_wvalid	),
       .wready		(fb_axi_wready	),


       .rid			  (fb_axi_rid	),
       .rdata			(fb_axi_rdata	),
       .rlast			(fb_axi_rlast	),
       .rvalid 		(fb_axi_rvalid	),
       .rready		(fb_axi_rready	),
       .rresp			(fb_axi_rresp	),

       .bid			  (fb_axi_bid	),
       .bvalid		(fb_axi_bvalid	),
       .bready	  (fb_axi_bready	)
);


localparam CPU_OWN_DDR = 0;
generate
if (CPU_OWN_DDR) begin : g_cpu_ddr
	assign s_axi_awid    = cpu_awid[AXI_ID_WIDTH-1:0];
	assign s_axi_awaddr  = cpu_awaddr;
	assign s_axi_awlen   = cpu_awlen;
	assign s_axi_awsize  = cpu_awsize;
	assign s_axi_awburst = cpu_awburst;
	assign s_axi_awlock  = cpu_awlock;
	assign s_axi_awcache = cpu_awcache;
	assign s_axi_awprot  = cpu_awprot;
	assign s_axi_awvalid = cpu_awvalid;
	assign cpu_awready   = s_axi_awready;
	assign s_axi_wdata   = cpu_wdata;
	assign s_axi_wstrb   = cpu_wstrb;
	assign s_axi_wlast   = cpu_wlast;
	assign s_axi_wvalid  = cpu_wvalid;
	assign cpu_wready    = s_axi_wready;
	assign cpu_bid[AXI_ID_WIDTH-1:0] = s_axi_bid;
	assign cpu_bresp     = s_axi_bresp;
	assign cpu_bvalid    = s_axi_bvalid;
	assign s_axi_bready  = cpu_bready;
	assign s_axi_arid    = cpu_arid[AXI_ID_WIDTH-1:0];
	assign s_axi_araddr  = cpu_araddr;
	assign s_axi_arlen   = cpu_arlen;
	assign s_axi_arsize  = cpu_arsize;
	assign s_axi_arburst = cpu_arburst;
	assign s_axi_arlock  = cpu_arlock;
	assign s_axi_arcache = cpu_arcache;
	assign s_axi_arprot  = cpu_arprot;
	assign s_axi_arvalid = cpu_arvalid;
	assign cpu_arready   = s_axi_arready;
	assign cpu_rid[AXI_ID_WIDTH-1:0] = s_axi_rid;
	assign cpu_rdata     = s_axi_rdata;
	assign cpu_rresp     = s_axi_rresp;
	assign cpu_rlast     = s_axi_rlast;
	assign cpu_rvalid    = s_axi_rvalid;
	assign s_axi_rready  = cpu_rready;
	assign fb_axi_awready = 1'b1;
	assign fb_axi_wready  = 1'b1;
	assign fb_axi_bid     = {AXI_ID_WIDTH{1'b0}};
	assign fb_axi_bresp   = 2'b0;
	assign fb_axi_bvalid  = 1'b0;
	assign fb_axi_arready = 1'b1;
	assign fb_axi_rid     = {AXI_ID_WIDTH{1'b0}};
	assign fb_axi_rdata   = {AXI_DATA_WIDTH{1'b0}};
	assign fb_axi_rresp   = 2'b0;
	assign fb_axi_rlast   = 1'b0;
	assign fb_axi_rvalid  = 1'b0;
end else begin : g_axi_mux
	axi4_2m_pri #(
		.ADDR_WIDTH (AXI_ADDR_WIDTH),
		.DATA_WIDTH (AXI_DATA_WIDTH),
		.ID_WIDTH   (AXI_ID_WIDTH)
	) u_axi_mux (
		.clk     (core_clk),
		.rst_n   (w_arstn),
		.s0_awid    (fb_axi_awid),
		.s0_awaddr  (fb_axi_awaddr),
		.s0_awlen   (fb_axi_awlen),
		.s0_awsize  (fb_axi_awsize),
		.s0_awburst (fb_axi_awburst),
		.s0_awlock  (fb_axi_awlock),
		.s0_awcache (fb_axi_awcache),
		.s0_awprot  (fb_axi_awprot),
		.s0_awvalid (fb_axi_awvalid),
		.s0_awready (fb_axi_awready),
		.s0_wdata   (fb_axi_wdata),
		.s0_wstrb   (fb_axi_wstrb),
		.s0_wlast   (fb_axi_wlast),
		.s0_wvalid  (fb_axi_wvalid),
		.s0_wready  (fb_axi_wready),
		.s0_bid     (fb_axi_bid),
		.s0_bresp   (fb_axi_bresp),
		.s0_bvalid  (fb_axi_bvalid),
		.s0_bready  (fb_axi_bready),
		.s0_arid    (fb_axi_arid),
		.s0_araddr  (fb_axi_araddr),
		.s0_arlen   (fb_axi_arlen),
		.s0_arsize  (fb_axi_arsize),
		.s0_arburst (fb_axi_arburst),
		.s0_arlock  (fb_axi_arlock),
		.s0_arcache (fb_axi_arcache),
		.s0_arprot  (fb_axi_arprot),
		.s0_arvalid (fb_axi_arvalid),
		.s0_arready (fb_axi_arready),
		.s0_rid     (fb_axi_rid),
		.s0_rdata   (fb_axi_rdata),
		.s0_rresp   (fb_axi_rresp),
		.s0_rlast   (fb_axi_rlast),
		.s0_rvalid  (fb_axi_rvalid),
		.s0_rready  (fb_axi_rready),
		.s1_awid    (cpu_awid[AXI_ID_WIDTH-1:0]),
		.s1_awaddr  (cpu_awaddr),
		.s1_awlen   (cpu_awlen),
		.s1_awsize  (cpu_awsize),
		.s1_awburst (cpu_awburst),
		.s1_awlock  (cpu_awlock),
		.s1_awcache (cpu_awcache),
		.s1_awprot  (cpu_awprot),
		.s1_awvalid (cpu_awvalid),
		.s1_awready (cpu_awready),
		.s1_wdata   (cpu_wdata),
		.s1_wstrb   (cpu_wstrb),
		.s1_wlast   (cpu_wlast),
		.s1_wvalid  (cpu_wvalid),
		.s1_wready  (cpu_wready),
		.s1_bid     (cpu_bid[AXI_ID_WIDTH-1:0]),
		.s1_bresp   (cpu_bresp),
		.s1_bvalid  (cpu_bvalid),
		.s1_bready  (cpu_bready),
		.s1_arid    (cpu_arid[AXI_ID_WIDTH-1:0]),
		.s1_araddr  (cpu_araddr),
		.s1_arlen   (cpu_arlen),
		.s1_arsize  (cpu_arsize),
		.s1_arburst (cpu_arburst),
		.s1_arlock  (cpu_arlock),
		.s1_arcache (cpu_arcache),
		.s1_arprot  (cpu_arprot),
		.s1_arvalid (cpu_arvalid),
		.s1_arready (cpu_arready),
		.s1_rid     (cpu_rid[AXI_ID_WIDTH-1:0]),
		.s1_rdata   (cpu_rdata),
		.s1_rresp   (cpu_rresp),
		.s1_rlast   (cpu_rlast),
		.s1_rvalid  (cpu_rvalid),
		.s1_rready  (cpu_rready),
		.m_awid    (s_axi_awid),
		.m_awaddr  (s_axi_awaddr),
		.m_awlen   (s_axi_awlen),
		.m_awsize  (s_axi_awsize),
		.m_awburst (s_axi_awburst),
		.m_awlock  (s_axi_awlock),
		.m_awcache (s_axi_awcache),
		.m_awprot  (s_axi_awprot),
		.m_awvalid (s_axi_awvalid),
		.m_awready (s_axi_awready),
		.m_wdata   (s_axi_wdata),
		.m_wstrb   (s_axi_wstrb),
		.m_wlast   (s_axi_wlast),
		.m_wvalid  (s_axi_wvalid),
		.m_wready  (s_axi_wready),
		.m_bid     (s_axi_bid),
		.m_bresp   (s_axi_bresp),
		.m_bvalid  (s_axi_bvalid),
		.m_bready  (s_axi_bready),
		.m_arid    (s_axi_arid),
		.m_araddr  (s_axi_araddr),
		.m_arlen   (s_axi_arlen),
		.m_arsize  (s_axi_arsize),
		.m_arburst (s_axi_arburst),
		.m_arlock  (s_axi_arlock),
		.m_arcache (s_axi_arcache),
		.m_arprot  (s_axi_arprot),
		.m_arvalid (s_axi_arvalid),
		.m_arready (s_axi_arready),
		.m_rid     (s_axi_rid),
		.m_rdata   (s_axi_rdata),
		.m_rresp   (s_axi_rresp),
		.m_rlast   (s_axi_rlast),
		.m_rvalid  (s_axi_rvalid),
		.m_rready  (s_axi_rready)
	);
end
endgenerate
assign cpu_bid[7:AXI_ID_WIDTH] = {(8-AXI_ID_WIDTH){1'b0}};
assign cpu_rid[7:AXI_ID_WIDTH] = {(8-AXI_ID_WIDTH){1'b0}};

wire soc_async_reset = ~w_arstn | ~cal_done;

soc u_sapphire_soc (
	.io_asyncReset                      (soc_async_reset),
	.io_systemClk                       (core_clk),
	.io_memoryClk                       (core_clk),
	.io_memoryReset                     (),
	.io_systemReset                     (io_systemReset),
	.system_uart_0_io_txd               (system_uart_0_io_txd),
	.system_uart_0_io_rxd               (system_uart_0_io_rxd),
	.io_ddrA_aw_payload_prot            (cpu_awprot),
	.io_ddrA_aw_payload_qos             (),
	.io_ddrA_aw_payload_cache           (cpu_awcache),
	.io_ddrA_aw_payload_lock            (cpu_awlock),
	.io_ddrA_aw_payload_burst           (cpu_awburst),
	.io_ddrA_aw_payload_size            (cpu_awsize),
	.io_ddrA_aw_payload_len             (cpu_awlen),
	.io_ddrA_aw_payload_region          (),
	.io_ddrA_aw_payload_id              (cpu_awid),
	.io_ddrA_aw_payload_addr            (cpu_awaddr),
	.io_ddrA_aw_ready                   (cpu_awready),
	.io_ddrA_aw_valid                   (cpu_awvalid),
	.io_ddrA_w_payload_last             (cpu_wlast),
	.io_ddrA_w_ready                    (cpu_wready),
	.io_ddrA_w_valid                    (cpu_wvalid),
	.io_ddrA_w_payload_strb             (cpu_wstrb),
	.io_ddrA_w_payload_data             (cpu_wdata),
	.io_ddrA_b_payload_resp             (cpu_bresp),
	.io_ddrA_b_payload_id               (cpu_bid),
	.io_ddrA_b_ready                    (cpu_bready),
	.io_ddrA_b_valid                    (cpu_bvalid),
	.io_ddrA_ar_payload_prot            (cpu_arprot),
	.io_ddrA_ar_payload_qos             (),
	.io_ddrA_ar_payload_cache           (cpu_arcache),
	.io_ddrA_ar_payload_region          (),
	.io_ddrA_ar_payload_lock            (cpu_arlock),
	.io_ddrA_ar_payload_burst           (cpu_arburst),
	.io_ddrA_ar_payload_size            (cpu_arsize),
	.io_ddrA_ar_payload_len             (cpu_arlen),
	.io_ddrA_ar_payload_id              (cpu_arid),
	.io_ddrA_ar_payload_addr            (cpu_araddr),
	.io_ddrA_ar_ready                   (cpu_arready),
	.io_ddrA_ar_valid                   (cpu_arvalid),
	.io_ddrA_r_payload_last             (cpu_rlast),
	.io_ddrA_r_payload_resp             (cpu_rresp),
	.io_ddrA_r_payload_id               (cpu_rid),
	.io_ddrA_r_payload_data             (cpu_rdata),
	.io_ddrA_r_ready                    (cpu_rready),
	.io_ddrA_r_valid                    (cpu_rvalid),
	.system_spi_0_io_sclk_write         (),
	.system_spi_0_io_data_0_writeEnable (),
	.system_spi_0_io_data_0_read        (1'b0),
	.system_spi_0_io_data_0_write       (),
	.system_spi_0_io_data_1_writeEnable (),
	.system_spi_0_io_data_1_read        (1'b0),
	.system_spi_0_io_data_1_write       (),
	.system_spi_0_io_data_2_writeEnable (),
	.system_spi_0_io_data_2_read        (1'b0),
	.system_spi_0_io_data_2_write       (),
	.system_spi_0_io_data_3_writeEnable (),
	.system_spi_0_io_data_3_read        (1'b0),
	.system_spi_0_io_data_3_write       (),
	.system_spi_0_io_ss                 (),
	.io_apbSlave_0_PADDR                (apb0_paddr),
	.io_apbSlave_0_PSEL                 (apb0_psel),
	.io_apbSlave_0_PENABLE              (apb0_penable),
	.io_apbSlave_0_PREADY               (apb0_pready),
	.io_apbSlave_0_PWRITE               (apb0_pwrite),
	.io_apbSlave_0_PWDATA               (apb0_pwdata),
	.io_apbSlave_0_PRDATA               (apb0_prdata),
	.io_apbSlave_0_PSLVERROR            (apb0_pslverr),
	.system_gpio_0_io_write             (),
	.system_gpio_0_io_read              (4'b0),
	.system_gpio_0_io_writeEnable       (),
	.system_i2c_0_io_sda_write          (),
	.system_i2c_0_io_sda_read           (1'b1),
	.system_i2c_0_io_scl_write          (),
	.system_i2c_0_io_scl_read           (1'b1),
	.userInterruptA                     (1'b0),
	.axiAInterrupt                      (1'b0),
	.axiA_awready                       (1'b1),
	.axiA_wready                        (1'b1),
	.axiA_bvalid                        (1'b0),
	.axiA_bid                           (8'b0),
	.axiA_bresp                         (2'b0),
	.axiA_arready                       (1'b1),
	.axiA_rvalid                        (1'b0),
	.axiA_rlast                         (1'b1),
	.axiA_rdata                         (32'b0),
	.axiA_rid                           (8'b0),
	.axiA_rresp                         (2'b0),
	.io_ddrMasters_0_clk                (core_clk),
	.io_ddrMasters_0_aw_valid           (1'b0),
	.io_ddrMasters_0_aw_payload_addr    (32'b0),
	.io_ddrMasters_0_aw_payload_id      (4'b0),
	.io_ddrMasters_0_aw_payload_region  (4'b0),
	.io_ddrMasters_0_aw_payload_len     (8'b0),
	.io_ddrMasters_0_aw_payload_size    (3'b0),
	.io_ddrMasters_0_aw_payload_burst   (2'b0),
	.io_ddrMasters_0_aw_payload_lock    (1'b0),
	.io_ddrMasters_0_aw_payload_cache   (4'b0),
	.io_ddrMasters_0_aw_payload_qos     (4'b0),
	.io_ddrMasters_0_aw_payload_prot    (3'b0),
	.io_ddrMasters_0_w_valid            (1'b0),
	.io_ddrMasters_0_w_payload_data     (32'b0),
	.io_ddrMasters_0_w_payload_strb     (4'b0),
	.io_ddrMasters_0_w_payload_last     (1'b0),
	.io_ddrMasters_0_b_ready            (1'b1),
	.io_ddrMasters_0_ar_valid           (1'b0),
	.io_ddrMasters_0_ar_payload_addr    (32'b0),
	.io_ddrMasters_0_ar_payload_id      (4'b0),
	.io_ddrMasters_0_ar_payload_region  (4'b0),
	.io_ddrMasters_0_ar_payload_len     (8'b0),
	.io_ddrMasters_0_ar_payload_size    (3'b0),
	.io_ddrMasters_0_ar_payload_burst   (2'b0),
	.io_ddrMasters_0_ar_payload_lock    (1'b0),
	.io_ddrMasters_0_ar_payload_cache   (4'b0),
	.io_ddrMasters_0_ar_payload_qos     (4'b0),
	.io_ddrMasters_0_ar_payload_prot    (3'b0),
	.io_ddrMasters_0_r_ready            (1'b1),
	.jtagCtrl_tck                       (jtag_inst1_TCK),
	.jtagCtrl_tdi                       (jtag_inst1_TDI),
	.jtagCtrl_tdo                       (jtag_inst1_TDO),
	.jtagCtrl_enable                    (jtag_inst1_SEL),
	.jtagCtrl_capture                   (jtag_inst1_CAPTURE),
	.jtagCtrl_shift                     (jtag_inst1_SHIFT),
	.jtagCtrl_update                    (jtag_inst1_UPDATE),
	.jtagCtrl_reset                     (jtag_inst1_RESET)
);

ddr3_top                 u_ddr3_top
(

.axi_clk                (core_clk            ),
.core_clk               (core_clk            ),
.sdram_clk              (sdram_clk           ),  
.rx_cal_clk             (rx_cal_clk          ),
.tx_cal_clk             (tx_cal_clk          ),
.tx_cal_clk_90edge      (tx_cal_clk_90edge   ),
.rstn                   (w_arstn             ),      
.pll_shift              (pll_shift           ),
.pll_shift_sel          (pll_shift_sel       ),
.pll_shift_ena          (pll_shift_ena       ),       
///////////////DDR BUS
.ddr_ck_hi              (ddr_ck_hi           ),
.ddr_ck_lo              (ddr_ck_lo           ),
.ddr_cke                (ddr_cke             ),    
.ddr_reset_n            (ddr_reset_n         ),
.ddr_cs_n               (ddr_cs_n            ),
.ddr_ras_n              (ddr_ras_n           ),
.ddr_cas_n              (ddr_cas_n           ),
.ddr_we_n               (ddr_we_n            ),     
.ddr_addr               (ddr_addr            ),
.ddr_ba                 (ddr_ba              ),

.ddr_dqs_oe             (ddr_dqs_oe          ),
.ddr_dqs_oe_n           (ddr_dqs_oe_n        ),
.ddr_dq_oe              (ddr_dq_oe           ),
.ddr_dqs_in_hi          (ddr_dqs_in_hi       ),
.ddr_dqs_in_lo          (ddr_dqs_in_lo       ),
.ddr_dq_in_hi           (ddr_dq_in_hi        ),
.ddr_dq_in_lo           (ddr_dq_in_lo        ),

.ddr_dqs_out_hi         (ddr_dqs_out_hi      ),
.ddr_dqs_out_lo         (ddr_dqs_out_lo      ),
.ddr_dq_out_hi          (ddr_dq_out_hi       ),
.ddr_dq_out_lo          (ddr_dq_out_lo       ),

.ddr_dm_hi              (ddr_dm_hi           ),
.ddr_dm_lo              (ddr_dm_lo           ),
.ddr_odt                (ddr_odt             ),

// Application interface ports
.app_sr_req                     (1'b0),
.app_ref_req                    (1'b0),
.app_zq_req                     (1'b0),
.app_sr_active                  (app_sr_active),
.app_ref_ack                    (app_ref_ack),
.app_zq_ack                     (app_zq_ack),

// Slave Interface Write Address Ports
.s_axi_awid                     (s_axi_awid        ),
.s_axi_awaddr                   (s_axi_awaddr      ),
.s_axi_awlen                    (s_axi_awlen       ),
.s_axi_awsize                   (s_axi_awsize      ),
.s_axi_awburst                  (s_axi_awburst     ),
.s_axi_awlock                   (s_axi_awlock      ),
.s_axi_awcache                  (s_axi_awcache     ),
.s_axi_awprot                   (s_axi_awprot      ),
.s_axi_awqos                    (4'h0              ),
.s_axi_awvalid                  (s_axi_awvalid     ),
.s_axi_awready                  (s_axi_awready     ),
// Slave Interface Write Data Ports
.s_axi_wdata                    (s_axi_wdata       ),
.s_axi_wstrb                    (s_axi_wstrb       ),
.s_axi_wlast                    (s_axi_wlast       ),
.s_axi_wvalid                   (s_axi_wvalid      ),
.s_axi_wready                   (s_axi_wready      ),
// Slave Interface Write Response Ports
.s_axi_bid                      (s_axi_bid         ),
.s_axi_bresp                    (s_axi_bresp       ),
.s_axi_bvalid                   (s_axi_bvalid      ),
.s_axi_bready                   (s_axi_bready      ),
// Slave Interface Read Address Ports
.s_axi_arid                     (s_axi_arid        ),
.s_axi_araddr                   (s_axi_araddr      ),
.s_axi_arlen                    (s_axi_arlen       ),
.s_axi_arsize                   (s_axi_arsize      ),
.s_axi_arburst                  (s_axi_arburst     ),
.s_axi_arlock                   (s_axi_arlock      ),
.s_axi_arcache                  (s_axi_arcache     ),
.s_axi_arprot                   (s_axi_arprot      ),
.s_axi_arqos                    (4'h0              ),
.s_axi_arvalid                  (s_axi_arvalid     ),
.s_axi_arready                  (s_axi_arready     ),
// Slave Interface Read Data Ports
.s_axi_rid                      (s_axi_rid         ),
.s_axi_rdata                    (s_axi_rdata       ),
.s_axi_rresp                    (s_axi_rresp       ),
.s_axi_rlast                    (s_axi_rlast       ),
.s_axi_rvalid                   (s_axi_rvalid      ),
.s_axi_rready                   (s_axi_rready      ),
//DEBUG       
.wrlvl_dq_check                 (wrlvl_dq_check    ) ,
.rd_level_dqs_check             (rd_level_dqs_check) ,
.init_cur_state                 (init_cur_state    ) ,
.idelay_ld                      (idelay_ld         ) ,
.mpr_rdlvl_dly                  (mpr_rdlvl_dly     ) ,
.cal_done                       (cal_done          ) 
);

//***************************************************************************
// debayer
//***************************************************************************


wire        rgb_vs;
wire        rgb_hs;
wire        rgb_de;
wire        rgb_valid;
wire [47:0] rgb_datax2;
wire        raw_hs, raw_vs, raw_de;
wire [15:0] raw_dat;

raw4_reorder u_raw4_reorder (
	.clk   (vid_clk_dvi2),
	.rst_n (vid_rst_n),
	.i_hs  (ch0_hs),
	.i_vs  (ch0_vs),
	.i_de  (ch0_de),
	.i_dat ({ch0_g, ch0_b}),
	.o_hs  (raw_hs),
	.o_vs  (raw_vs),
	.o_de  (raw_de),
	.o_dat (raw_dat)
);

wire [15:0] rgb_gain_r, rgb_gain_g, rgb_gain_b;
wire [15:0] rgb_gain_r_rx, rgb_gain_g_rx, rgb_gain_b_rx;
wire [7:0]  stat_r_rx, stat_g_rx, stat_b_rx;
wire [15:0] stat_frame_rx;
wire [7:0] analog_gain_rx;
wire       analog_we_rx, cam_we_rx;
wire [15:0] cam_addr_rx;
wire [7:0]  cam_data_rx;
wire        eth_dbg_hb, eth_dbg_rx, eth_dbg_tx, eth_dbg_arp;
wire [11:0] tcp_rx_raddr, tcp_rx_len, tcp_tx_waddr, tcp_tx_len;
wire [7:0]  tcp_rx_rdata, tcp_tx_wdata;
wire        tcp_rx_valid, tcp_rx_ack, tcp_tx_we, tcp_tx_kick, tcp_tx_busy;

eth_host u_eth_host (
	.rst_n      (w_arstn),
	.rxc        (rxc),
	.rx_dv_HI   (rx_dv_HI),
	.rx_dv_LO   (rx_dv_LO),
	.rxd_hi_i   (rxd_hi_i),
	.rxd_lo_i   (rxd_lo_i),
	.tx_en_o_HI (tx_en_o_HI),
	.tx_en_o_LO (tx_en_o_LO),
	.txc_hi_o   (txc_hi_o),
	.txc_lo_o   (txc_lo_o),
	.txd_hi_o   (txd_hi_o),
	.txd_lo_o   (txd_lo_o),
	.phy_rst_n  (phy_rst_n),
	.rgb_r      (rgb_gain_r_rx),
	.rgb_g      (rgb_gain_g_rx),
	.rgb_b      (rgb_gain_b_rx),
	.stat_r     (stat_r_rx),
	.stat_g     (stat_g_rx),
	.stat_b     (stat_b_rx),
	.stat_frame (stat_frame_rx),
	.analog_gain(analog_gain_rx),
	.analog_we  (analog_we_rx),
	.cam_addr   (cam_addr_rx),
	.cam_data   (cam_data_rx),
	.cam_we     (cam_we_rx),
	.dbg_rxc_hb (eth_dbg_hb),
	.dbg_rx_seen(eth_dbg_rx),
	.dbg_tx_seen(eth_dbg_tx),
	.dbg_arp_seen(eth_dbg_arp),
	.print_wr_clk   (print_wr_clk),
	.print_wr_rst_n (print_wr_rst_n),
	.print_wr_en    (print_wr_en),
	.print_wr_data  (print_wr_data),
	.print_wr_full  (print_wr_full),
	.print_bin_wr_en   (print_bin_wr_en),
	.print_bin_wr_data (print_bin_wr_data),
	.print_bin_wr_full (print_bin_wr_full),
	.tcp_pclk      (core_clk),
	.tcp_presetn   (w_arstn),
	.tcp_rx_raddr  (tcp_rx_raddr),
	.tcp_rx_rdata  (tcp_rx_rdata),
	.tcp_rx_len    (tcp_rx_len),
	.tcp_rx_valid  (tcp_rx_valid),
	.tcp_rx_ack    (tcp_rx_ack),
	.tcp_tx_we     (tcp_tx_we),
	.tcp_tx_waddr  (tcp_tx_waddr),
	.tcp_tx_wdata  (tcp_tx_wdata),
	.tcp_tx_len    (tcp_tx_len),
	.tcp_tx_kick   (tcp_tx_kick),
	.tcp_tx_busy   (tcp_tx_busy)
);

apb_print u_apb_print (
	.pclk     (core_clk),
	.presetn  (w_arstn),
	.paddr    (apb0_paddr),
	.psel     (apb0_psel),
	.penable  (apb0_penable),
	.pwrite   (apb0_pwrite),
	.pwdata   (apb0_pwdata),
	.pready   (apb0_pready),
	.prdata   (apb0_prdata),
	.pslverr  (apb0_pslverr),
	.wr_clk   (print_wr_clk),
	.wr_rst_n (print_wr_rst_n),
	.wr_en    (print_wr_en),
	.wr_data  (print_wr_data),
	.wr_full  (print_wr_full),
	.wr_bin_en   (print_bin_wr_en),
	.wr_bin_data (print_bin_wr_data),
	.wr_bin_full (print_bin_wr_full),
	.gray_addr  (gray96_cpu_addr),
	.gray_data  (gray96_cpu_data),
	.gray_frame (gray96_cpu_frame),
	.sht        (sht_c1),
	.mlx_to     (to_c1),
	.mlx_ta     (ta_c1),
	.score      (sc_c1),
	.evt_on     (evt_c1),
	.evt_code   (code_c1),
	.mot_valid  (mot_c1),
	.ir_x       (irx_c1),
	.ir_y       (iry_c1),
	.mot_x0     (mx0_c1),
	.mot_y0     (my0_c1),
	.mot_x1     (mx1_c1),
	.mot_y1     (my1_c1),
	.pd_score   (pd_score_cpu),
	.pd_on      (pd_on_cpu),
	.tcp_rx_raddr (tcp_rx_raddr),
	.tcp_rx_rdata (tcp_rx_rdata),
	.tcp_rx_len   (tcp_rx_len),
	.tcp_rx_valid (tcp_rx_valid),
	.tcp_rx_ack   (tcp_rx_ack),
	.tcp_tx_we    (tcp_tx_we),
	.tcp_tx_waddr (tcp_tx_waddr),
	.tcp_tx_wdata (tcp_tx_wdata),
	.tcp_tx_len   (tcp_tx_len),
	.tcp_tx_kick  (tcp_tx_kick),
	.tcp_tx_busy  (tcp_tx_busy),
	.voice_ok     (vok_c1),
	.voice_swap   (vsw_c1),
	.voice_track  (vtk_c1),
	.lp           (lp_c1),
	.lp_st        (lpst_c1),
	.lp_sec       (lpsc_c1),
	.host_play_req (host_play_req),
	.host_play_trk (host_play_trk),
	.host_play_ack (host_play_ack_c)
);

reg [15:0] rgb_r_d1, rgb_r_d2, rgb_g_d1, rgb_g_d2, rgb_b_d1, rgb_b_d2;
always @(posedge hdmi_tx_slow_clk or negedge vid_rst_n) begin
	if (!vid_rst_n) begin
		{rgb_r_d1, rgb_r_d2} <= {16'd256, 16'd256};
		{rgb_g_d1, rgb_g_d2} <= {16'd256, 16'd256};
		{rgb_b_d1, rgb_b_d2} <= {16'd256, 16'd256};
	end else begin
		rgb_r_d1 <= rgb_gain_r_rx; rgb_r_d2 <= rgb_r_d1;
		rgb_g_d1 <= rgb_gain_g_rx; rgb_g_d2 <= rgb_g_d1;
		rgb_b_d1 <= rgb_gain_b_rx; rgb_b_d2 <= rgb_b_d1;
	end
end
assign rgb_gain_r = rgb_r_d2;
assign rgb_gain_g = rgb_g_d2;
assign rgb_gain_b = rgb_b_d2;

reg analog_tog, analog_d1, analog_d2, analog_d3;
reg cam_tog, cam_d1, cam_d2, cam_d3;
reg [7:0]  analog_gain_hold;
reg [15:0] cam_addr_hold;
reg [7:0]  cam_data_hold;

always @(posedge rxc or negedge w_arstn) begin
	if (!w_arstn) begin
		analog_tog <= 1'b0;
		cam_tog    <= 1'b0;
		analog_gain_hold <= 8'd40;
		cam_addr_hold    <= 16'd0;
		cam_data_hold    <= 8'd0;
	end else begin
		if (analog_we_rx) begin
			analog_tog       <= ~analog_tog;
			analog_gain_hold <= analog_gain_rx;
		end
		if (cam_we_rx) begin
			cam_tog       <= ~cam_tog;
			cam_addr_hold <= cam_addr_rx;
			cam_data_hold <= cam_data_rx;
		end
	end
end

always @(posedge CLK_5M or negedge i2c_rst_n) begin
	if (!i2c_rst_n) begin
		{analog_d1, analog_d2, analog_d3} <= 3'b000;
		{cam_d1, cam_d2, cam_d3}          <= 3'b000;
	end else begin
		analog_d1 <= analog_tog; analog_d2 <= analog_d1; analog_d3 <= analog_d2;
		cam_d1    <= cam_tog;    cam_d2    <= cam_d1;    cam_d3    <= cam_d2;
	end
end

cam_gain_i2c u_cam_gain_i2c (
	.clk         (CLK_5M),
	.rst_n       (i2c_rst_n),
	.analog_we   (analog_d2 ^ analog_d3),
	.analog_gain (analog_gain_hold),
	.cam_we      (cam_d2 ^ cam_d3),
	.cam_addr    (cam_addr_hold),
	.cam_data    (cam_data_hold),
	.extra_req   (cam_extra_req),
	.extra_addr  (cam_extra_addr),
	.extra_data  (cam_extra_data),
	.extra_ack   (cam_extra_ack)
);

debayer_top_2to1 debayer_top
(
	.in_pclk		  (vid_clk_dvi2),//(i_mipi_rx_pclk ),
	.in_rstn		  (vid_rst_n	),
	
	.raw_vs_i		  (raw_vs		      ),
	.raw_hs_i		  (raw_hs		      ),
	.raw_de_i		  (raw_de		      ),
	.raw_valid_i	(raw_de	        ),
	.raw_datax4_i	(raw_dat	), // raw4_reorder already emits {P1,P2} then {P3,P4}
	
	.rgb_vs_o		  (rgb_vs         ),
	.rgb_hs_o		  (rgb_hs         ),
	.rgb_de_o		  (rgb_de         ),
	.rgb_valid_o	(rgb_valid      ),
	.rgb_datax2_o (rgb_datax2     ),// {R1,G1,B1,R0,G0,B0}
	.r_gain_i     (3'd4),
	.g_gain_i     (3'd4),
	.b_gain_i     (3'd4)
);
wire        cam_hs_1p, cam_vs_1p, cam_de_1p;
wire [7:0]  cam_r, cam_g, cam_b;
hdmi_2pix_to_1pix #(
	.INV_SYNC (1'b1)
) u_hdmi_2pix_to_1pix (
	.vid_clk  (vid_clk_dvi2),
	.hdmi_clk (hdmi_tx_slow_clk),
	.rst_n    (vid_rst_n),
	.i_hs     (rgb_hs),
	.i_vs     (rgb_vs),
	.i_de     (rgb_de),
	.i_datax2 (rgb_datax2),
	.o_hs     (cam_hs_1p),
	.o_vs     (cam_vs_1p),
	.o_de     (cam_de_1p),
	.o_r      (cam_r),
	.o_g      (cam_g),
	.o_b      (cam_b)
);

wire        wb_hs, wb_vs, wb_de, roi_border;
wire [7:0]  wb_r, wb_g, wb_b;
wire [7:0]  stat_r_vid, stat_g_vid, stat_b_vid;
wire [15:0] stat_frame_vid;

roi_rgb_mean u_roi_rgb_mean (
	.clk      (hdmi_tx_slow_clk),
	.rst_n    (vid_rst_n),
	.i_hs     (cam_hs_1p),
	.i_vs     (cam_vs_1p),
	.i_de     (cam_de_1p),
	.i_r      (cam_r),
	.i_g      (cam_g),
	.i_b      (cam_b),
	.o_mean_r (stat_r_vid),
	.o_mean_g (stat_g_vid),
	.o_mean_b (stat_b_vid),
	.o_frame  (stat_frame_vid),
	.o_border (roi_border)
);

rgb_wb_q88 u_rgb_wb_q88 (
	.clk    (hdmi_tx_slow_clk),
	.rst_n  (vid_rst_n),
	.i_hs   (cam_hs_1p),
	.i_vs   (cam_vs_1p),
	.i_de   (cam_de_1p),
	.i_r    (cam_r),
	.i_g    (cam_g),
	.i_b    (cam_b),
	.r_gain (rgb_gain_r),
	.g_gain (rgb_gain_g),
	.b_gain (rgb_gain_b),
	.o_hs   (wb_hs),
	.o_vs   (wb_vs),
	.o_de   (wb_de),
	.o_r    (wb_r),
	.o_g    (wb_g),
	.o_b    (wb_b)
);

wire [7:0] prev_in_r = roi_border ? 8'hFF : wb_r;
wire [7:0] prev_in_g = roi_border ? 8'h00 : wb_g;
wire [7:0] prev_in_b = roi_border ? 8'h00 : wb_b;

reg [7:0]  stat_r_d1, stat_r_d2, stat_g_d1, stat_g_d2, stat_b_d1, stat_b_d2;
reg [15:0] stat_f_d1, stat_f_d2;
always @(posedge rxc or negedge w_arstn) begin
	if (!w_arstn) begin
		{stat_r_d1, stat_r_d2} <= 16'd0;
		{stat_g_d1, stat_g_d2} <= 16'd0;
		{stat_b_d1, stat_b_d2} <= 16'd0;
		{stat_f_d1, stat_f_d2} <= 32'd0;
	end else begin
		stat_r_d1 <= stat_r_vid; stat_r_d2 <= stat_r_d1;
		stat_g_d1 <= stat_g_vid; stat_g_d2 <= stat_g_d1;
		stat_b_d1 <= stat_b_vid; stat_b_d2 <= stat_b_d1;
		stat_f_d1 <= stat_frame_vid; stat_f_d2 <= stat_f_d1;
	end
end
assign stat_r_rx     = stat_r_d2;
assign stat_g_rx     = stat_g_d2;
assign stat_b_rx     = stat_b_d2;
assign stat_frame_rx = stat_f_d2;

wire        mot_valid;
wire [10:0] mot_x0, mot_y0, mot_x1, mot_y1;
motion_frame_diff u_motion_frame_diff (
	.clk      (vid_clk_dvi2),
	.rst_n    (vid_rst_n),
	.i_vs     (rgb_vs),
	.i_hs     (rgb_hs),
	.i_de     (rgb_de),
	.i_datax2 (rgb_datax2),
	.o_valid  (mot_valid),
	.o_x0     (mot_x0),
	.o_y0     (mot_y0),
	.o_x1     (mot_x1),
	.o_y1     (mot_y1)
);

wire        prev_hs, prev_vs, prev_de;
wire [7:0]  prev_r, prev_g, prev_b;
gray96_preview u_gray96_preview (
	.clk   (hdmi_tx_slow_clk),
	.rst_n (vid_rst_n),
	.i_hs  (wb_hs),
	.i_vs  (wb_vs),
	.i_de  (wb_de),
	.i_r   (prev_in_r),
	.i_g   (prev_in_g),
	.i_b   (prev_in_b),
	.o_hs  (prev_hs),
	.o_vs  (prev_vs),
	.o_de  (prev_de),
	.o_r   (prev_r),
	.o_g   (prev_g),
	.o_b   (prev_b),
	.cpu_clk   (core_clk),
	.cpu_rst_n (w_arstn),
	.cpu_addr  (gray96_cpu_addr),
	.cpu_data  (gray96_cpu_data),
	.cpu_frame (gray96_cpu_frame)
);
wire        fus_box;
wire [10:0] fus_x0, fus_y0, fus_x1, fus_y1;
wire        osd_hs, osd_vs, osd_de;
wire [7:0]  osd_r, osd_g, osd_b;
hdmi_bbox_osd u_hdmi_bbox_osd (
	.clk         (hdmi_tx_slow_clk),
	.rst_n       (vid_rst_n),
	.i_hs        (prev_hs),
	.i_vs        (prev_vs),
	.i_de        (prev_de),
	.i_r         (prev_r),
	.i_g         (prev_g),
	.i_b         (prev_b),
	.i_box_valid (fus_box),
	.i_x0        (fus_x0),
	.i_y0        (fus_y0),
	.i_x1        (fus_x1),
	.i_y1        (fus_y1),
	.o_hs        (osd_hs),
	.o_vs        (osd_vs),
	.o_de        (osd_de),
	.o_r         (osd_r),
	.o_g         (osd_g),
	.o_b         (osd_b)
);
wire        sht_ack, mlx_ack;
wire [7:0]  sht_temp, sht_humi, mlx_ta, mlx_to, sht_dbg;
wire        heat_we;
wire [9:0]  heat_addr;
wire [7:0]  heat_data;
wire        j7_scl_oe, j7_sda_oe;
wire        sht_scl_oe, sht_sda_oe;
wire        sht_want, sht_busy, mlx_idle;
reg         grant_sht;
reg [11:0]  i2c_gap;
wire        voice_tx, voice_rx;
wire        voice_ok, voice_swap;
wire [15:0] voice_track;
reg vs25_0, vs25_1;
reg [15:0] vid_frame;
wire [15:0] sht_ts, mlx_ts;
always @(posedge CLK_25M) begin
	vs25_0 <= hdmi_tx_vs;
	vs25_1 <= vs25_0;
	if (vs25_1 != vs25_0)
		vid_frame <= vid_frame + 16'd1;
end
j7_sht_hub u_j7_sht_hub (
	.clk       (CLK_25M),
	.rst_n     (w_arstn),
	.sht_ack   (sht_ack),
	.temp_c    (sht_temp),
	.humid     (sht_humi),
	.vs_i      (vs25_1),
	.ts        (sht_ts),
	.scl_oe    (sht_scl_oe),
	.sda_oe    (sht_sda_oe),
	.scl_i     (grant_sht ? io_j7_scl_IN : 1'b1),
	.sda_i     (grant_sht ? io_j7_sda_IN : 1'b1),
	.bus_grant (grant_sht),
	.bus_want  (sht_want),
	.bus_busy  (sht_busy)
);
j7_sensor_hub u_j7_sensor_hub (
	.clk       (CLK_25M),
	.rst_n     (w_arstn),
	.sht_ack   (),
	.mlx_ack   (mlx_ack),
	.temp_c    (mlx_ta),
	.humid     (mlx_to),
	.dbg       (sht_dbg),
	.vs_i      (vs25_1),
	.ts        (mlx_ts),
	.heat_we   (heat_we),
	.heat_addr (heat_addr),
	.heat_data (heat_data),
	.scl_oe    (j7_scl_oe),
	.sda_oe    (j7_sda_oe),
	.scl_i     (grant_sht ? 1'b1 : io_j7_scl_IN),
	.sda_i     (grant_sht ? 1'b1 : io_j7_sda_IN),
	.bus_grant (~grant_sht),
	.bus_idle  (mlx_idle)
);
always @(posedge CLK_25M or negedge w_arstn) begin
	if (!w_arstn) begin
		grant_sht <= 1'b0;
		i2c_gap   <= 12'd0;
	end else if (grant_sht) begin
		if (!sht_want && !sht_busy) begin
			if (i2c_gap >= 12'd2000) begin
				grant_sht <= 1'b0;
				i2c_gap   <= 12'd0;
			end else
				i2c_gap <= i2c_gap + 12'd1;
		end else
			i2c_gap <= 12'd0;
	end else if (sht_want && mlx_idle)
		grant_sht <= 1'b1;
end
// Shared I2C: J7-39 SDA=GPIOL_06, J7-40 SCL=GPIOR_13
assign io_j7_scl_OUT     = 1'b0;
assign io_j7_sda_OUT     = 1'b0;
assign io_j7_scl_OE      = grant_sht ? sht_scl_oe : j7_scl_oe;
assign io_j7_sda_OE      = grant_sht ? sht_sda_oe : j7_sda_oe;
// Voice UART. Default: J7-38=FPGA TX, J7-37=FPGA RX. pin_swap flips them.
assign io_j7_sht_scl_OUT = voice_swap ? 1'b1 : voice_tx;
assign io_j7_sht_scl_OE  = voice_swap ? 1'b0 : 1'b1;
assign io_j7_sht_sda_OUT = voice_swap ? voice_tx : 1'b1;
assign io_j7_sht_sda_OE  = voice_swap ? 1'b1 : 1'b0;
assign voice_rx          = voice_swap ? io_j7_sht_scl_IN : io_j7_sht_sda_IN;
reg sht_s0, sht_s1, mlx_s0, mlx_s1;
reg vok_s0, vok_s1, vsw_s0, vsw_s1;
reg [7:0] st_s0, st_s1, sh_s0, sh_s1;
reg [7:0] ta_s0, ta_s1, to_s0, to_s1, d_s0, d_s1;
reg [15:0] vf_s0, vf_s1, sts_s0, sts_s1, mts_s0, mts_s1;
always @(posedge hdmi_tx_slow_clk) begin
	sht_s0 <= sht_ack; sht_s1 <= sht_s0;
	mlx_s0 <= mlx_ack; mlx_s1 <= mlx_s0;
	vok_s0 <= voice_ok; vok_s1 <= vok_s0;
	vsw_s0 <= voice_swap; vsw_s1 <= vsw_s0;
	st_s0 <= sht_temp; st_s1 <= st_s0;
	sh_s0 <= sht_humi; sh_s1 <= sh_s0;
	ta_s0 <= mlx_ta;   ta_s1 <= ta_s0;
	to_s0 <= mlx_to;   to_s1 <= to_s0;
	d_s0  <= sht_dbg;  d_s1  <= d_s0;
	vf_s0 <= vid_frame; vf_s1 <= vf_s0;
	sts_s0 <= sht_ts; sts_s1 <= sts_s0;
	mts_s0 <= mlx_ts; mts_s1 <= mts_s0;
end
wire        sns_hs, sns_vs, sns_de;
wire [7:0]  sns_r, sns_g, sns_b;
j7_sensor_osd u_j7_sensor_osd (
	.clk     (hdmi_tx_slow_clk),
	.rst_n   (vid_rst_n),
	.i_hs    (osd_hs),
	.i_vs    (osd_vs),
	.i_de    (osd_de),
	.i_r     (osd_r),
	.i_g     (osd_g),
	.i_b     (osd_b),
	.sht_ack (sht_s1),
	.mlx_ack (mlx_s1),
	.sht_t   (st_s1),
	.sht_h   (sh_s1),
	.mlx_ta  (ta_s1),
	.mlx_to  (to_s1),
	.dbg     (d_s1),
	.vid_f   (vf_s1),
	.sht_ts  (sts_s1),
	.mlx_ts  (mts_s1),
	.voice_ok (vok_s1),
	.voice_swap (vsw_s1),
	.o_hs    (sns_hs),
	.o_vs    (sns_vs),
	.o_de    (sns_de),
	.o_r     (sns_r),
	.o_g     (sns_g),
	.o_b     (sns_b)
);
wire        thm_hs, thm_vs, thm_de;
wire [7:0]  thm_r, thm_g, thm_b;
j7_thermal_osd u_j7_thermal_osd (
	.wr_clk  (CLK_25M),
	.wr_en   (heat_we),
	.wr_addr (heat_addr),
	.wr_data (heat_data),
	.clk     (hdmi_tx_slow_clk),
	.rst_n   (vid_rst_n),
	.i_hs    (sns_hs),
	.i_vs    (sns_vs),
	.i_de    (sns_de),
	.i_r     (sns_r),
	.i_g     (sns_g),
	.i_b     (sns_b),
	.o_hs    (thm_hs),
	.o_vs    (thm_vs),
	.o_de    (thm_de),
	.o_r     (thm_r),
	.o_g     (thm_g),
	.o_b     (thm_b)
);
wire [2:0]  fus_code;
wire [7:0]  fus_score;
wire [4:0]  fus_ir_x, fus_ir_y;
fusion_event u_fusion_event (
	.clk       (hdmi_tx_slow_clk),
	.rst_n     (vid_rst_n),
	.i_vs      (thm_vs),
	.mot_valid (mot_valid),
	.mot_x0    (mot_x0),
	.mot_y0    (mot_y0),
	.mot_x1    (mot_x1),
	.mot_y1    (mot_y1),
	.mlx_to    (to_s1),
	.mlx_ta    (ta_s1),
	.sht_t     (st_s1),
	.pd_on     (pd_on_v1),
	.evt_on    (fus_evt),
	.evt_code  (fus_code),
	.score     (fus_score),
	.ir_x      (fus_ir_x),
	.ir_y      (fus_ir_y),
	.box_show  (fus_box),
	.box_x0    (fus_x0),
	.box_y0    (fus_y0),
	.box_x1    (fus_x1),
	.box_y1    (fus_y1)
);
idle_lp u_idle_lp (
	.clk      (hdmi_tx_slow_clk),
	.rst_n    (vid_rst_n),
	.i_vs     (thm_vs),
	.evt_code (fus_code),
	.box_show (fus_box),
	.lp       (lp_hw),
	.lp_st    (lp_st_hw),
	.sec      (lp_sec_hw)
);
reg        box25_0, box25_1;
reg [2:0]  code25_0, code25_1;
always @(posedge CLK_25M) begin
	box25_0  <= fus_box;
	box25_1  <= box25_0;
	code25_0 <= fus_code;
	code25_1 <= code25_0;
end
/* J7-34 GPIOL_03, active-high. FAL ~6 Hz, AC ~1.5 Hz. IN/MOT/IR silent. */
reg [23:0] bz_cnt;
always @(posedge CLK_25M)
	bz_cnt <= bz_cnt + 24'd1;
assign o_j7_buzzer = (code25_1 == 3'd4) ? bz_cnt[21] :
	((code25_1 == 3'd5) ? bz_cnt[23] : 1'b0);
always @(posedge CLK_25M or negedge w_arstn) begin
	if (!w_arstn) begin
		play_r0 <= 1'b0;
		play_r1 <= 1'b0;
		play_t0 <= 16'd0;
		play_t1 <= 16'd0;
	end else begin
		play_r0 <= host_play_req;
		play_r1 <= play_r0;
		play_t0 <= host_play_trk;
		play_t1 <= play_t0;
	end
end
always @(posedge core_clk or negedge w_arstn) begin
	if (!w_arstn) begin
		host_play_ack_c0 <= 1'b0;
		host_play_ack_c  <= 1'b0;
	end else begin
		host_play_ack_c0 <= host_play_ack_25;
		host_play_ack_c  <= host_play_ack_c0;
	end
end
j7_voice_ctrl u_j7_voice_ctrl (
	.clk        (CLK_25M),
	.rst_n      (w_arstn),
	.box_show   (box25_1),
	.evt_code   (code25_1),
	.host_play  (play_r1),
	.host_track (play_t1),
	.host_ack   (host_play_ack_25),
	.uart_rx    (voice_rx),
	.uart_tx    (voice_tx),
	.pin_swap   (voice_swap),
	.comm_ok    (voice_ok),
	.last_track (voice_track)
);
wire        fus_hs, fus_vs, fus_de;
wire [7:0]  fus_r, fus_g, fus_b;
fusion_osd u_fusion_osd (
	.clk      (hdmi_tx_slow_clk),
	.rst_n    (vid_rst_n),
	.i_hs     (thm_hs),
	.i_vs     (thm_vs),
	.i_de     (thm_de),
	.i_r      (thm_r),
	.i_g      (thm_g),
	.i_b      (thm_b),
	.evt_on   (fus_evt),
	.evt_code (fus_code),
	.score    (fus_score),
	.ir_x     (fus_ir_x),
	.ir_y     (fus_ir_y),
	.pd_score (pd_sc_v1),
	.lp_st    (lp_st_hw),
	.lp_sec   (lp_sec_hw),
	.o_hs     (fus_hs),
	.o_vs     (fus_vs),
	.o_de     (fus_de),
	.o_r      (fus_r),
	.o_g      (fus_g),
	.o_b      (fus_b)
);
reg pd_on_v0, pd_on_v1;
reg [7:0] pd_sc_v0, pd_sc_v1;
always @(posedge hdmi_tx_slow_clk) begin
	pd_on_v0 <= pd_on_cpu;
	pd_on_v1 <= pd_on_v0;
	pd_sc_v0 <= pd_score_cpu;
	pd_sc_v1 <= pd_sc_v0;
end
always @(posedge core_clk) begin
	sht_c0 <= st_s1;   sht_c1 <= sht_c0;
	to_c0  <= to_s1;   to_c1  <= to_c0;
	ta_c0  <= ta_s1;   ta_c1  <= ta_c0;
	sc_c0  <= fus_score; sc_c1 <= sc_c0;
	code_c0 <= fus_code; code_c1 <= code_c0;
	evt_c0 <= fus_evt; evt_c1 <= evt_c0;
	mot_c0 <= mot_valid; mot_c1 <= mot_c0;
	irx_c0 <= fus_ir_x; irx_c1 <= irx_c0;
	iry_c0 <= fus_ir_y; iry_c1 <= iry_c0;
	mx0_c0 <= mot_x0; mx0_c1 <= mx0_c0;
	my0_c0 <= mot_y0; my0_c1 <= my0_c0;
	mx1_c0 <= mot_x1; mx1_c1 <= mx1_c0;
	my1_c0 <= mot_y1; my1_c1 <= my1_c0;
	vok_c0 <= voice_ok; vok_c1 <= vok_c0;
	vsw_c0 <= voice_swap; vsw_c1 <= vsw_c0;
	vtk_c0 <= voice_track; vtk_c1 <= vtk_c0;
	lp_c0 <= lp_hw; lp_c1 <= lp_c0;
	lpst_c0 <= lp_st_hw; lpst_c1 <= lpst_c0;
	lpsc_c0 <= lp_sec_hw; lpsc_c1 <= lpsc_c0;
end
reg [7:0] hdmi_tx_rdata ;
reg [7:0] hdmi_tx_gdata ;
reg [7:0] hdmi_tx_bdata ;
reg hdmi_tx_vs;
reg hdmi_tx_hs;
reg hdmi_tx_de;
//==============================================================================
// MIPI DSI
//==============================================================================
// signal 

reg		[25:0]	r_rst_cnt;

wire	[31:0]	w_axi_rdata;
wire			w_axi_awready;
wire			w_axi_wready;
wire			w_axi_arready;
wire			w_axi_rvalid;
wire			w_axi_bvalid;

wire	[6:0]	w_axi_awaddr;
wire			w_axi_awvalid;
wire	[31:0]	w_axi_wdata;
wire			w_axi_wvalid;
wire			w_axi_bready;
wire	[6:0]	w_axi_araddr;
wire			w_axi_arvalid;
wire			w_axi_rready;

wire			w_confdone;


assign  LCD_POWER 			= i_arstn;
assign	LCD_RST_P	      = ~w_arstn;//~r_rst_cnt[23]; LCD复位先释放，然后再释放MIPI 的复位
assign	mipi_dp_clk_RST		= ~i_arstn;
assign	mipi_dp_data0_RST	= ~i_arstn;
assign	mipi_dp_data1_RST	= ~i_arstn;
assign	mipi_dp_data2_RST	= ~i_arstn;
assign	mipi_dp_data3_RST	= ~i_arstn;
////////////////////////////////////////////////////////////////
always@(posedge i_mipi_clk or  negedge w_arstn )
begin
  if ( !w_arstn ) begin
    r_rst_cnt	<= 'd0;
  end else 		
    r_rst_cnt	<= r_rst_cnt[25] ? r_rst_cnt :r_rst_cnt + 1'b1;
end

wire axi_rst_n = r_rst_cnt[25];

reg [26:0] dly_cnt = 'd0;

always @( posedge vid_clk_dvi2 or negedge w_arstn )
begin
  if( !w_arstn )
    dly_cnt <= 'd0;
  else if( w_confdone )
    dly_cnt <= dly_cnt[26] ? dly_cnt :(dly_cnt + 1'b1);
  else 
    dly_cnt <= 'd0;
end 

assign vid_rst_n = dly_cnt[26];



assign w_confdone = 1'b1;

assign mipi_dp_clk_LP_P_OUT = 1'b0;
assign mipi_dp_clk_LP_N_OUT = 1'b0;
assign mipi_dp_clk_HS_OUT   = 8'b0;
assign mipi_dp_clk_HS_OE    = 1'b0;
assign mipi_dp_clk_LP_P_OE  = 1'b0;
assign mipi_dp_clk_LP_N_OE  = 1'b0;
assign mipi_dp_data0_LP_P_OUT = 1'b0;
assign mipi_dp_data1_LP_P_OUT = 1'b0;
assign mipi_dp_data2_LP_P_OUT = 1'b0;
assign mipi_dp_data3_LP_P_OUT = 1'b0;
assign mipi_dp_data0_LP_N_OUT = 1'b0;
assign mipi_dp_data1_LP_N_OUT = 1'b0;
assign mipi_dp_data2_LP_N_OUT = 1'b0;
assign mipi_dp_data3_LP_N_OUT = 1'b0;
assign mipi_dp_data0_LP_P_OE = 1'b0;
assign mipi_dp_data1_LP_P_OE = 1'b0;
assign mipi_dp_data2_LP_P_OE = 1'b0;
assign mipi_dp_data3_LP_P_OE = 1'b0;
assign mipi_dp_data0_LP_N_OE = 1'b0;
assign mipi_dp_data1_LP_N_OE = 1'b0;
assign mipi_dp_data2_LP_N_OE = 1'b0;
assign mipi_dp_data3_LP_N_OE = 1'b0;
assign mipi_dp_data0_HS_OUT = 8'b0;
assign mipi_dp_data1_HS_OUT = 8'b0;
assign mipi_dp_data2_HS_OUT = 8'b0;
assign mipi_dp_data3_HS_OUT = 8'b0;
assign mipi_dp_data0_HS_OE = 1'b0;
assign mipi_dp_data1_HS_OE = 1'b0;
assign mipi_dp_data2_HS_OE = 1'b0;
assign mipi_dp_data3_HS_OE = 1'b0;

assign w_axi_awready = 1'b1;
assign w_axi_wready  = 1'b1;
assign w_axi_arready = 1'b1;
assign w_axi_bvalid  = 1'b0;
assign w_axi_rvalid  = 1'b0;
assign w_axi_rdata   = 32'b0;

wire hs;
wire vs;
wire de;
wire [7:0] rgb_r;
wire [7:0] rgb_g;
wire [7:0] rgb_b;
  
  color_bar_rgb #(
	.HS_POLORY 		(1'b0		),
	.VS_POLORY 		(1'b0		),
	.H_FRONT_PORCH 	(HFP		),
	.H_SYNC 		(HSP		),
	.H_VALID 		(MAX_HRES	),
	.H_BACK_PORCH 	(HBP		),
	.V_FRONT_PORCH 	(VFP		),
	.V_SYNC 		(VSP		),
	.V_VALID 		(MAX_VRES	),
	.V_BACK_PORCH 	(VBP		),
	.TEST_MODE 		(2'd2)
  ) u_hdmi_tg (
	.clk	(hdmi_tx_slow_clk),
	.rst_n	(vid_rst_n),
	.i_rdata(8'd0),
	.i_gdata(8'd0),
	.i_bdata(8'd0),
	.hs	(hs),
	.vs	(vs),
	.de	(de),
	.rgb_r	(rgb_r),
	.rgb_g	(rgb_g),
	.rgb_b	(rgb_b)
  );

reg cal_hdmi_d = 1'b0;
reg cal_hdmi   = 1'b0;
reg src_cam    = 1'b0;
always @(posedge hdmi_tx_slow_clk) begin
	cal_hdmi_d <= cal_done;
	cal_hdmi   <= cal_hdmi_d;
	if (cal_hdmi)
		src_cam <= 1'b1;
end

always @( posedge hdmi_tx_slow_clk )
begin
  if (src_cam) begin
    hdmi_tx_hs    <= wb_hs;
    hdmi_tx_vs    <= wb_vs;
    hdmi_tx_de    <= wb_de;
    hdmi_tx_rdata <= wb_de ? prev_in_r : 8'd0;
    hdmi_tx_gdata <= wb_de ? prev_in_g : 8'd0;
    hdmi_tx_bdata <= wb_de ? prev_in_b : 8'd0;
  end else begin
    hdmi_tx_hs    <= hs;
    hdmi_tx_vs    <= vs;
    hdmi_tx_de    <= de;
    hdmi_tx_rdata <= rgb_r;
    hdmi_tx_gdata <= rgb_g;
    hdmi_tx_bdata <= rgb_b;
  end
end

// MIPI DSI 已拆：省 BRAM 给 Sapphire。画面走 HDMI。

// ch0_vs		    
// ch0_hs		    
// ch0_de		    
// ch0_de	      
// {ch0_g,ch0_b}

//=================================================================================
//hdmi tx ctrl 
//=================================================================================
wire                            video_hs;
wire                            video_vs;
wire                            video_de;
wire[7:0]                       video_r;
wire[7:0]                       video_g;
wire[7:0]                       video_b;

assign tmds_tx_data0_TX_OE = 1'b1;
assign tmds_tx_data1_TX_OE = 1'b1;
assign tmds_tx_data2_TX_OE = 1'b1;
assign tmds_tx_clk_TX_OE   = 1'b1;

assign tmds_tx_data0_TX_RST = 1'b0;
assign tmds_tx_data1_TX_RST = 1'b0;
assign tmds_tx_data2_TX_RST = 1'b0;
assign tmds_tx_clk_TX_RST   = 1'b0;

// 	  color_bar color_bar_m0(
// 	.clk(hdmi_tx_slow_clk),
// 	.rst(~vid_rst_n),
// 	.hs(video_hs),
// 	.vs(video_vs),
// 	.de(video_de),
// 	.rgb_r(video_r),
// 	.rgb_g(video_g),
// 	.rgb_b(video_b)
// );

wire [9:0] tmds_data0;
wire [9:0] tmds_data1;
wire [9:0] tmds_data2;
wire [9:0] tmds_clk ;


dvi_encoder dvi_encoder_m0
(
	.pixelclk      		(hdmi_tx_slow_clk          ),// system clock
	.rst_p         		(~vid_rst_n      ),// reset
	.i_bdata      		(hdmi_tx_bdata ),
	.i_gdata     		  (hdmi_tx_gdata ),
	.i_rdata       		(hdmi_tx_rdata ),
	.i_hs         		(hdmi_tx_hs    ),
	.i_vs         		(hdmi_tx_vs    ),
	.i_de            	(hdmi_tx_de    ),
  .video_format     (2'b00),
  .video_VIC        (0),
	.audio_L			    (24'd0),
  .audio_R			    (24'd0),
  .audio_valid		  (1'b0),
  .audio_N                (6144),     //(20'h01880),//     
  .audio_CTS              (148500),      //(20'h28488),//      
  .audio_sample_frequency (4'd0),
  .audio_word_length      (4'd0),

	.tmds_data0    		(tmds_data0),
  .tmds_data1    		(tmds_data1),
  .tmds_data2    		(tmds_data2),
  .tmds_clk      	  (tmds_clk  )
);
assign tmds_tx_clk_TX_DATA   = ~tmds_clk;
assign tmds_tx_data0_TX_DATA = ~tmds_data0;
assign tmds_tx_data1_TX_DATA = ~tmds_data1;
assign tmds_tx_data2_TX_DATA = ~tmds_data2;



endmodule
