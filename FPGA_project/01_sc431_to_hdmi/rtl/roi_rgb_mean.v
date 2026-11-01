// Center 128x128 mean on 1920x1080. Stats are pre-WB. Magenta ROI box is 1-cycle delayed
// to line up with rgb_wb_q88.
module roi_rgb_mean #(
	parameter [10:0] X0 = 11'd896,
	parameter [10:0] Y0 = 11'd476,
	parameter [10:0] WIN = 11'd128
) (
	input  wire       clk,
	input  wire       rst_n,
	input  wire       i_hs,
	input  wire       i_vs,
	input  wire       i_de,
	input  wire [7:0] i_r,
	input  wire [7:0] i_g,
	input  wire [7:0] i_b,
	output reg  [7:0] o_mean_r,
	output reg  [7:0] o_mean_g,
	output reg  [7:0] o_mean_b,
	output reg [15:0] o_frame,
	output reg        o_border
);

localparam [10:0] X1 = X0 + WIN - 11'd1;
localparam [10:0] Y1 = Y0 + WIN - 11'd1;

reg        vs_d, de_d;
reg [10:0] x, y;
reg [21:0] acc_r, acc_g, acc_b;
reg [14:0] pix_n;

wire in_roi = i_de && (x >= X0) && (x <= X1) && (y >= Y0) && (y <= Y1);
wire near_l = (x <= (X0 + 11'd1));
wire near_r = (x >= (X1 - 11'd1));
wire near_t = (y <= (Y0 + 11'd1));
wire near_b = (y >= (Y1 - 11'd1));
wire on_box = in_roi && (near_l || near_r || near_t || near_b);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d     <= 1'b0;
		de_d     <= 1'b0;
		x        <= 11'd0;
		y        <= 11'd0;
		acc_r    <= 22'd0;
		acc_g    <= 22'd0;
		acc_b    <= 22'd0;
		pix_n    <= 15'd0;
		o_mean_r <= 8'd0;
		o_mean_g <= 8'd0;
		o_mean_b <= 8'd0;
		o_frame  <= 16'd0;
		o_border <= 1'b0;
	end else begin
		vs_d     <= i_vs;
		de_d     <= i_de;
		o_border <= on_box;

		if (vs_d != i_vs) begin
			y <= 11'd0;
			if (pix_n == 15'd16384) begin
				o_mean_r <= acc_r[21:14];
				o_mean_g <= acc_g[21:14];
				o_mean_b <= acc_b[21:14];
				o_frame  <= o_frame + 16'd1;
			end
			acc_r <= 22'd0;
			acc_g <= 22'd0;
			acc_b <= 22'd0;
			pix_n <= 15'd0;
		end else begin
			if (de_d && !i_de && (y != 11'd2047))
				y <= y + 11'd1;
			if (in_roi) begin
				acc_r <= acc_r + {14'd0, i_r};
				acc_g <= acc_g + {14'd0, i_g};
				acc_b <= acc_b + {14'd0, i_b};
				pix_n <= pix_n + 15'd1;
			end
		end

		if (!i_de)
			x <= 11'd0;
		else
			x <= x + 11'd1;
	end
end

endmodule
