// Bottom env bar: SHT / MLX / timestamps. 16x16, origin-aligned, above last lines.
module j7_sensor_osd #(
	parameter [10:0] ORIGIN_X = 11'd224,
	parameter [10:0] ORIGIN_Y = 11'd872
) (
	input  wire       clk,
	input  wire       rst_n,
	input  wire       i_hs,
	input  wire       i_vs,
	input  wire       i_de,
	input  wire [7:0] i_r,
	input  wire [7:0] i_g,
	input  wire [7:0] i_b,
	input  wire       sht_ack,
	input  wire       mlx_ack,
	input  wire [7:0] sht_t,
	input  wire [7:0] sht_h,
	input  wire [7:0] mlx_ta,
	input  wire [7:0] mlx_to,
	input  wire [7:0] dbg,
	input  wire [15:0] vid_f,
	input  wire [15:0] sht_ts,
	input  wire [15:0] mlx_ts,
	input  wire       voice_ok,
	input  wire       voice_swap,
	output reg        o_hs,
	output reg        o_vs,
	output reg        o_de,
	output reg  [7:0] o_r,
	output reg  [7:0] o_g,
	output reg  [7:0] o_b
);

reg        vs_d, de_d;
reg [10:0] x, y;
reg        sht_d, mlx_d, vok_d, vsw_d;
reg [7:0]  st_d, sh_d, ta_d, to_d, dbg_d;
reg [15:0] vf_d, sts_d, mts_d;

function [7:0] font_row;
	input [7:0] ch;
	input [2:0] row;
	reg [63:0] bmp;
	begin
		case (ch)
			8'h20: bmp = 64'h0000000000000000;
			8'h25: bmp = 64'h00C6CC183066C600;
			8'h2D: bmp = 64'h000000007E000000;
			8'h30: bmp = 64'h003C666E76663C00;
			8'h31: bmp = 64'h0018181818187E00;
			8'h32: bmp = 64'h003C660C18307E00;
			8'h33: bmp = 64'h003C660C0C663C00;
			8'h34: bmp = 64'h000C1C3C6C7E0C00;
			8'h35: bmp = 64'h007E607C06663C00;
			8'h36: bmp = 64'h003C607C66663C00;
			8'h37: bmp = 64'h007E060C18303000;
			8'h38: bmp = 64'h003C663C66663C00;
			8'h39: bmp = 64'h003C66663E063C00;
			8'h3A: bmp = 64'h0000180000180000;
			8'h41: bmp = 64'h00183C66667E6600;
			8'h42: bmp = 64'h007C66667C66667C00;
			8'h43: bmp = 64'h003C666060663C00;
			8'h44: bmp = 64'h00786C6666666C7800;
			8'h45: bmp = 64'h007E60607C60607E00;
			8'h46: bmp = 64'h007E60607C60606000;
			8'h47: bmp = 64'h003C66606E663C00;
			8'h48: bmp = 64'h0066667E66666600;
			8'h4B: bmp = 64'h00666C78786C6600;
			8'h4C: bmp = 64'h0060606060607E00;
			8'h4D: bmp = 64'h0066777F6B636300;
			8'h4E: bmp = 64'h0066767E7E6E6600;
			8'h4F: bmp = 64'h003C666666663C00;
			8'h52: bmp = 64'h007C66667C6C6600;
			8'h53: bmp = 64'h003C60603C067C00;
			8'h54: bmp = 64'h007E181818181800;
			8'h58: bmp = 64'h0066663C3C666600;
			8'h61: bmp = 64'h00003C067E667E00;
			8'h65: bmp = 64'h00003C667E603C00;
			8'h6D: bmp = 64'h0000667F6B636300;
			8'h72: bmp = 64'h00006C7660606000;
			default: bmp = 64'h0000000000000000;
		endcase
		font_row = bmp[8*(3'd7 - row) +: 8];
	end
endfunction

function [7:0] dec2;
	input [7:0] v;
	input       tens;
	reg [7:0] t, o;
	begin
		if (v >= 8'd90) t = 8'd9;
		else if (v >= 8'd80) t = 8'd8;
		else if (v >= 8'd70) t = 8'd7;
		else if (v >= 8'd60) t = 8'd6;
		else if (v >= 8'd50) t = 8'd5;
		else if (v >= 8'd40) t = 8'd4;
		else if (v >= 8'd30) t = 8'd3;
		else if (v >= 8'd20) t = 8'd2;
		else if (v >= 8'd10) t = 8'd1;
		else t = 8'd0;
		o = v - (t * 8'd10);
		dec2 = tens ? (8'h30 + t) : (8'h30 + o);
	end
endfunction

function [7:0] hex1;
	input [3:0] n;
	begin
		hex1 = (n < 4'd10) ? (8'h30 + {4'd0, n}) : (8'h37 + {4'd0, n});
	end
endfunction

wire [10:0] xrel = x - ORIGIN_X;
wire [10:0] yrel = y - ORIGIN_Y;
wire [4:0]  col  = xrel[10:4];
wire [3:0]  row  = yrel[10:4];
wire [3:0]  px16 = xrel[3:0];
wire [3:0]  py16 = yrel[3:0];
wire [2:0]  px   = xrel[3:1];
wire [2:0]  py   = yrel[3:1];

reg        use_cjk;
reg [5:0]  cjk_idx;
reg [7:0]  ch;
wire [15:0] cjk_bits;

osd_font16 u_cjk (
	.idx  (cjk_idx),
	.row  (py16),
	.bits (cjk_bits)
);

always @(*) begin
	ch = 8'h20;
	use_cjk = 1'b0;
	cjk_idx = 6'd0;
	if (row == 4'd0) begin
		case (col)
			5'd0: begin use_cjk = 1'b1; cjk_idx = 6'd26; end
			5'd1: begin use_cjk = 1'b1; cjk_idx = 6'd27; end
			5'd2: begin use_cjk = 1'b1; cjk_idx = 6'd28; end
			5'd3: begin use_cjk = 1'b1; cjk_idx = 6'd29; end
			5'd4: begin use_cjk = 1'b1; cjk_idx = 6'd30; end
			5'd5: begin use_cjk = 1'b1; cjk_idx = 6'd31; end
			5'd7: begin use_cjk = 1'b1; cjk_idx = sht_d ? 6'd32 : 6'd35; end
			5'd8: begin use_cjk = 1'b1; cjk_idx = 6'd33; end
			5'd9: begin use_cjk = 1'b1; cjk_idx = 6'd34; end
			5'd11: begin use_cjk = 1'b1; cjk_idx = 6'd26; end
			5'd12: begin use_cjk = 1'b1; cjk_idx = 6'd28; end
			5'd13: ch = 8'h3A;
			5'd14: ch = dec2(st_d, 1'b1);
			5'd15: ch = dec2(st_d, 1'b0);
			5'd16: ch = 8'h43;
			5'd18: begin use_cjk = 1'b1; cjk_idx = 6'd27; end
			5'd19: begin use_cjk = 1'b1; cjk_idx = 6'd28; end
			5'd20: ch = 8'h3A;
			5'd21: ch = dec2(sh_d, 1'b1);
			5'd22: ch = dec2(sh_d, 1'b0);
			5'd23: ch = 8'h25;
			default: ch = 8'h20;
		endcase
	end else if (row == 4'd1) begin
		case (col)
			5'd0: begin use_cjk = 1'b1; cjk_idx = 6'd13; end
			5'd1: begin use_cjk = 1'b1; cjk_idx = 6'd14; end
			5'd2: begin use_cjk = 1'b1; cjk_idx = 6'd29; end
			5'd3: begin use_cjk = 1'b1; cjk_idx = 6'd30; end
			5'd4: begin use_cjk = 1'b1; cjk_idx = 6'd31; end
			5'd6: begin use_cjk = 1'b1; cjk_idx = mlx_d ? 6'd32 : 6'd35; end
			5'd7: begin use_cjk = 1'b1; cjk_idx = 6'd33; end
			5'd8: begin use_cjk = 1'b1; cjk_idx = 6'd34; end
			5'd10: begin use_cjk = 1'b1; cjk_idx = 6'd36; end
			5'd11: begin use_cjk = 1'b1; cjk_idx = 6'd37; end
			5'd12: ch = 8'h3A;
			5'd13: ch = dec2(ta_d, 1'b1);
			5'd14: ch = dec2(ta_d, 1'b0);
			5'd16: begin use_cjk = 1'b1; cjk_idx = 6'd38; end
			5'd17: begin use_cjk = 1'b1; cjk_idx = 6'd39; end
			5'd18: ch = 8'h3A;
			5'd19: ch = dec2(to_d, 1'b1);
			5'd20: ch = dec2(to_d, 1'b0);
			default: ch = 8'h20;
		endcase
	end else if (row == 4'd2) begin
		case (col)
			5'd0: ch = 8'h46;
			5'd1: ch = 8'h72;
			5'd2: ch = 8'h61;
			5'd3: ch = 8'h6D;
			5'd4: ch = 8'h65;
			5'd5: ch = 8'h3A;
			5'd6: ch = hex1(vf_d[15:12]);
			5'd7: ch = hex1(vf_d[11:8]);
			5'd8: ch = hex1(vf_d[7:4]);
			5'd9: ch = hex1(vf_d[3:0]);
			5'd11: ch = 8'h53;
			5'd12: ch = 8'h48;
			5'd13: ch = 8'h54;
			5'd14: ch = 8'h3A;
			5'd15: ch = hex1(sts_d[15:12]);
			5'd16: ch = hex1(sts_d[11:8]);
			5'd17: ch = hex1(sts_d[7:4]);
			5'd18: ch = hex1(sts_d[3:0]);
			5'd20: ch = 8'h4D;
			5'd21: ch = 8'h4C;
			5'd22: ch = 8'h58;
			5'd23: ch = 8'h3A;
			5'd24: ch = hex1(mts_d[15:12]);
			5'd25: ch = hex1(mts_d[11:8]);
			5'd26: ch = hex1(mts_d[7:4]);
			5'd27: ch = hex1(mts_d[3:0]);
			default: ch = 8'h20;
		endcase
	end
end

wire in_win = i_de &&
	(x >= ORIGIN_X) && (x < (ORIGIN_X + 11'd464)) &&
	(y >= ORIGIN_Y) && (y < (ORIGIN_Y + 11'd48));
wire [7:0] bits = font_row(ch, py);
wire on_pix = in_win && (use_cjk ? cjk_bits[4'd15 - px16] : bits[3'd7 - px]);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d <= 1'b0;
		de_d <= 1'b0;
		x <= 11'd0;
		y <= 11'd0;
		sht_d <= 1'b0;
		mlx_d <= 1'b0;
		vok_d <= 1'b0;
		vsw_d <= 1'b0;
		st_d <= 8'd0;
		sh_d <= 8'd0;
		ta_d <= 8'd0;
		to_d <= 8'd0;
		dbg_d <= 8'd0;
		vf_d <= 16'd0;
		sts_d <= 16'd0;
		mts_d <= 16'd0;
		o_hs <= 1'b0;
		o_vs <= 1'b0;
		o_de <= 1'b0;
		o_r <= 8'd0;
		o_g <= 8'd0;
		o_b <= 8'd0;
	end else begin
		vs_d <= i_vs;
		de_d <= i_de;
		if (vs_d != i_vs) begin
			y     <= 11'd0;
			sht_d <= sht_ack;
			mlx_d <= mlx_ack;
			vok_d <= voice_ok;
			vsw_d <= voice_swap;
			st_d  <= sht_t;
			sh_d  <= sht_h;
			ta_d  <= mlx_ta;
			to_d  <= mlx_to;
			dbg_d <= dbg;
			vf_d  <= vid_f;
			sts_d <= sht_ts;
			mts_d <= mlx_ts;
		end else if (de_d && !i_de && (y != 11'd2047))
			y <= y + 11'd1;
		if (!i_de)
			x <= 11'd0;
		else
			x <= x + 11'd1;
		o_hs <= i_hs;
		o_vs <= i_vs;
		o_de <= i_de;
		if (on_pix) begin
			o_r <= 8'hFF;
			o_g <= 8'hE8;
			o_b <= 8'h48;
		end else begin
			o_r <= i_r;
			o_g <= i_g;
			o_b <= i_b;
		end
	end
end

endmodule
