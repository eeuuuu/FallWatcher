// 256 x 8 async FIFO, gray pointers.
module cdc_fifo8 (
	input  wire       wr_clk,
	input  wire       wr_rst_n,
	input  wire       wr_en,
	input  wire [7:0] wr_data,
	output wire       wr_full,
	input  wire       rd_clk,
	input  wire       rd_rst_n,
	input  wire       rd_en,
	output reg  [7:0] rd_data,
	output wire       rd_empty
);

reg  [8:0] wr_bin, rd_bin;
reg  [8:0] wr_gray, rd_gray;
reg  [8:0] wr_gray_rd, wr_gray_rd2;
reg  [8:0] rd_gray_wr, rd_gray_wr2;
reg  [7:0] mem [0:255];

function [8:0] bin2gray;
	input [8:0] b;
	begin
		bin2gray = b ^ {1'b0, b[8:1]};
	end
endfunction

wire [8:0] wr_bin_n = wr_bin + 9'd1;
wire [8:0] rd_bin_n = rd_bin + 9'd1;
assign wr_full  = (bin2gray(wr_bin_n) == {~rd_gray_wr2[8:7], rd_gray_wr2[6:0]});
assign rd_empty = (rd_gray == wr_gray_rd2);

always @(posedge wr_clk or negedge wr_rst_n) begin
	if (!wr_rst_n) begin
		wr_bin  <= 9'd0;
		wr_gray <= 9'd0;
	end else if (wr_en && !wr_full) begin
		mem[wr_bin[7:0]] <= wr_data;
		wr_bin  <= wr_bin_n;
		wr_gray <= bin2gray(wr_bin_n);
	end
end

always @(posedge rd_clk or negedge rd_rst_n) begin
	if (!rd_rst_n) begin
		rd_bin  <= 9'd0;
		rd_gray <= 9'd0;
		rd_data <= 8'd0;
	end else if (rd_en && !rd_empty) begin
		rd_data <= mem[rd_bin[7:0]];
		rd_bin  <= rd_bin_n;
		rd_gray <= bin2gray(rd_bin_n);
	end
end

always @(posedge rd_clk or negedge rd_rst_n) begin
	if (!rd_rst_n) begin
		wr_gray_rd  <= 9'd0;
		wr_gray_rd2 <= 9'd0;
	end else begin
		wr_gray_rd  <= wr_gray;
		wr_gray_rd2 <= wr_gray_rd;
	end
end

always @(posedge wr_clk or negedge wr_rst_n) begin
	if (!wr_rst_n) begin
		rd_gray_wr  <= 9'd0;
		rd_gray_wr2 <= 9'd0;
	end else begin
		rd_gray_wr  <= rd_gray;
		rd_gray_wr2 <= rd_gray_wr;
	end
end

endmodule
