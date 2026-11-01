// Task2 overlay: Chinese event text + center LP banner + IR-window marker.
module fusion_osd #(
	parameter [10:0] TEXT_X   = 11'd16,
	parameter [10:0] TEXT_Y   = 11'd48,
	parameter [10:0] BANNER_Y = 11'd8,
	parameter [10:0] HEAT_X   = 11'd1648,
	parameter [10:0] HEAT_Y   = 11'd16,
	parameter [10:0] SCALE    = 11'd8,
	parameter [10:0] HINT_X   = 11'd1680,
	parameter [10:0] HINT_Y   = 11'd1056
) (
	input  wire       clk,
	input  wire       rst_n,
	input  wire       i_hs,
	input  wire       i_vs,
	input  wire       i_de,
	input  wire [7:0] i_r,
	input  wire [7:0] i_g,
	input  wire [7:0] i_b,
	input  wire       evt_on,
	input  wire [2:0] evt_code,
	input  wire [7:0] score,
	input  wire [4:0] ir_x,
	input  wire [4:0] ir_y,
	input  wire [7:0] pd_score,
	input  wire [1:0] lp_st,
	input  wire [3:0] lp_sec,
	output reg        o_hs,
	output reg        o_vs,
	output reg        o_de,
	output reg  [7:0] o_r,
	output reg  [7:0] o_g,
	output reg  [7:0] o_b
);

reg        vs_d, de_d;
reg [10:0] x, y;
reg        on_d;
reg [2:0]  code_d;
reg [7:0]  sc_d, pd_d;
reg [4:0]  ix_d, iy_d;
reg [1:0]  st_d;
reg [3:0]  sec_d;

function [7:0] font_row;
	input [7:0] ch;
	input [2:0] row;
	reg [63:0] bmp;
	begin
		case (ch)
			8'h20: bmp = 64'h0000000000000000;
			8'h2C: bmp = 64'h0000000000181830;
			8'h3A: bmp = 64'h0000180000180000;
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

wire [10:0] xrel = x - TEXT_X;
wire [10:0] yrel = y - TEXT_Y;
wire [4:0]  col  = xrel[10:4];
wire [3:0]  px16 = xrel[3:0];
wire [3:0]  py16 = yrel[3:0];
wire [2:0]  px8  = xrel[3:1];
wire [2:0]  py8  = yrel[3:1];
wire in_text = i_de &&
	(x >= TEXT_X) && (x < (TEXT_X + 11'd448)) &&
	(y >= TEXT_Y) && (y < (TEXT_Y + 11'd16));
wire [10:0] hxrel = x - HINT_X;
wire [10:0] hyrel = y - HINT_Y;
wire [3:0]  hcol  = hxrel[7:4];
wire [3:0]  hpx   = hxrel[3:0];
wire [3:0]  hpy   = hyrel[3:0];
wire in_hint = i_de &&
	(x >= HINT_X) && (x < (HINT_X + 11'd224)) &&
	(y >= HINT_Y) && (y < (HINT_Y + 11'd16));

wire [10:0] ban_w = (st_d == 2'd2) ? 11'd128 :
	((st_d == 2'd1) ? 11'd96 : 11'd96);
wire [10:0] ban_x = 11'd960 - (ban_w >> 1);
wire [10:0] bxrel = x - ban_x;
wire [10:0] byrel = y - BANNER_Y;
wire [2:0]  bcol  = bxrel[10:5];
wire [3:0]  bpx   = bxrel[4:1];
wire [3:0]  bpy   = byrel[4:1];
wire in_ban = i_de &&
	(x >= ban_x) && (x < (ban_x + ban_w)) &&
	(y >= BANNER_Y) && (y < (BANNER_Y + 11'd32));

reg        use_cjk;
reg [5:0]  cjk_idx;
reg [3:0]  cjk_row;
reg [7:0]  asc_ch;
reg [3:0]  bit_sel;
wire [15:0] cjk_bits;

osd_font16 u_cjk (
	.idx  (cjk_idx),
	.row  (cjk_row),
	.bits (cjk_bits)
);

always @(*) begin
	use_cjk = 1'b0;
	cjk_idx = 6'd0;
	cjk_row = 4'd0;
	asc_ch  = 8'h20;
	bit_sel = 4'd0;
	if (in_ban) begin
		cjk_row = bpy;
		bit_sel = bpx;
		if (st_d == 2'd2) begin
			use_cjk = 1'b1;
			case (bcol)
				3'd0: cjk_idx = 6'd3;
				3'd1: cjk_idx = 6'd4;
				3'd2: cjk_idx = 6'd5;
				3'd3: cjk_idx = 6'd6;
				default: use_cjk = 1'b0;
			endcase
		end else if (st_d == 2'd1) begin
			if (bcol == 3'd2) begin
				use_cjk = 1'b1;
				cjk_idx = 6'd40;
			end else begin
				asc_ch = (bcol == 3'd0) ?
					(8'h30 + ((sec_d >= 4'd10) ? 8'd1 : 8'd0)) :
					(8'h30 + ((sec_d >= 4'd10) ? 8'd0 : {4'd0, sec_d}));
			end
		end else begin
			use_cjk = 1'b1;
			case (bcol)
				3'd0: cjk_idx = 6'd0;
				3'd1: cjk_idx = 6'd1;
				3'd2: cjk_idx = 6'd2;
				default: use_cjk = 1'b0;
			endcase
		end
	end else if (in_text) begin
		cjk_row = py16;
		bit_sel = px16;
		case (col)
			5'd0: begin use_cjk = 1'b1; cjk_idx = 6'd7; end
			5'd1: begin use_cjk = 1'b1; cjk_idx = 6'd8; end
			5'd2: begin asc_ch = 8'h3A; end
			5'd3: begin
				use_cjk = 1'b1;
				case (code_d)
					3'd1: cjk_idx = 6'd11;
					3'd2: cjk_idx = 6'd13;
					3'd3: cjk_idx = 6'd15;
					3'd4: cjk_idx = 6'd17;
					3'd5: cjk_idx = 6'd19;
					default: cjk_idx = 6'd9;
				endcase
			end
			5'd4: begin
				use_cjk = 1'b1;
				case (code_d)
					3'd1: cjk_idx = 6'd12;
					3'd2: cjk_idx = 6'd14;
					3'd3: cjk_idx = 6'd16;
					3'd4: cjk_idx = 6'd18;
					3'd5: cjk_idx = 6'd20;
					default: cjk_idx = 6'd10;
				endcase
			end
			5'd6: begin use_cjk = 1'b1; cjk_idx = 6'd41; end
			5'd7: begin use_cjk = 1'b1; cjk_idx = 6'd42; end
			5'd8: begin use_cjk = 1'b1; cjk_idx = 6'd28; end
			5'd9: begin asc_ch = 8'h3A; end
			5'd10: begin
				asc_ch = (sc_d >= 8'd100) ? 8'h31 : 8'h20;
			end
			5'd11: asc_ch = dec2((sc_d >= 8'd100) ? (sc_d - 8'd100) : sc_d, 1'b1);
			5'd12: asc_ch = dec2((sc_d >= 8'd100) ? (sc_d - 8'd100) : sc_d, 1'b0);
			5'd14: begin use_cjk = 1'b1; cjk_idx = 6'd20; end
			5'd15: begin use_cjk = 1'b1; cjk_idx = 6'd23; end
			5'd16: begin asc_ch = 8'h3A; end
			5'd17: asc_ch = dec2({3'd0, ix_d}, 1'b1);
			5'd18: asc_ch = dec2({3'd0, ix_d}, 1'b0);
			5'd19: asc_ch = 8'h2C;
			5'd20: asc_ch = dec2({3'd0, iy_d}, 1'b1);
			5'd21: asc_ch = dec2({3'd0, iy_d}, 1'b0);
			5'd23: begin use_cjk = 1'b1; cjk_idx = 6'd24; end
			5'd24: begin use_cjk = 1'b1; cjk_idx = 6'd39; end
			5'd25: begin asc_ch = 8'h3A; end
			5'd26: asc_ch = dec2(pd_d, 1'b1);
			5'd27: asc_ch = dec2(pd_d, 1'b0);
			default: asc_ch = 8'h20;
		endcase
	end else if (in_hint) begin
		/* 人员演示须距摄像头2米以上 */
		cjk_row = hpy;
		bit_sel = hpx;
		case (hcol)
			4'd0:  begin use_cjk = 1'b1; cjk_idx = 6'd24; end
			4'd1:  begin use_cjk = 1'b1; cjk_idx = 6'd43; end
			4'd2:  begin use_cjk = 1'b1; cjk_idx = 6'd44; end
			4'd3:  begin use_cjk = 1'b1; cjk_idx = 6'd45; end
			4'd4:  begin use_cjk = 1'b1; cjk_idx = 6'd46; end
			4'd5:  begin use_cjk = 1'b1; cjk_idx = 6'd47; end
			4'd6:  begin use_cjk = 1'b1; cjk_idx = 6'd48; end
			4'd7:  begin use_cjk = 1'b1; cjk_idx = 6'd49; end
			4'd8:  begin use_cjk = 1'b1; cjk_idx = 6'd50; end
			4'd9:  begin use_cjk = 1'b1; cjk_idx = 6'd51; end
			4'd10: begin asc_ch = 8'h32; end
			4'd11: begin use_cjk = 1'b1; cjk_idx = 6'd52; end
			4'd12: begin use_cjk = 1'b1; cjk_idx = 6'd53; end
			4'd13: begin use_cjk = 1'b1; cjk_idx = 6'd54; end
			default: asc_ch = 8'h20;
		endcase
	end
end

wire [2:0] asc_row = in_ban ? byrel[4:2] : (in_hint ? hyrel[3:1] : py8);
wire [2:0] asc_col = in_ban ? bxrel[4:2] : (in_hint ? hxrel[3:1] : px8);
wire [7:0] asc_bits = font_row(asc_ch, asc_row);
wire on_cjk = use_cjk && cjk_bits[4'd15 - bit_sel];
wire on_asc = (!use_cjk) && (in_text || in_ban || in_hint) &&
	asc_bits[3'd7 - asc_col];
wire on_pix = on_cjk || on_asc;

wire [10:0] mx0 = HEAT_X + {3'd0, ix_d, 3'd0};
wire [10:0] my0 = HEAT_Y + {3'd0, iy_d, 3'd0};
wire [10:0] mx1 = mx0 + SCALE - 11'd1;
wire [10:0] my1 = my0 + SCALE - 11'd1;
wire in_cell = i_de && on_d &&
	(x >= mx0) && (x <= mx1) &&
	(y >= my0) && (y <= my1);
wire vis_map = (code_d == 3'd1) || (code_d == 3'd3) || (code_d == 3'd4);
wire on_mark = vis_map && in_cell && (
	(x == mx0) || (x == mx1) || (y == my0) || (y == my1)
);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d <= 1'b0;
		de_d <= 1'b0;
		x <= 11'd0;
		y <= 11'd0;
		on_d <= 1'b0;
		code_d <= 3'd0;
		sc_d <= 8'd0;
		pd_d <= 8'd0;
		ix_d <= 5'd0;
		iy_d <= 5'd0;
		st_d <= 2'd0;
		sec_d <= 4'd0;
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
			y      <= 11'd0;
			on_d   <= evt_on;
			code_d <= evt_code;
			sc_d   <= score;
			pd_d   <= pd_score;
			ix_d   <= ir_x;
			iy_d   <= ir_y;
			st_d   <= lp_st;
			sec_d  <= lp_sec;
		end else if (de_d && !i_de && (y != 11'd2047))
			y <= y + 11'd1;
		if (!i_de)
			x <= 11'd0;
		else
			x <= x + 11'd1;
		o_hs <= i_hs;
		o_vs <= i_vs;
		o_de <= i_de;
		if (in_ban && on_pix) begin
			if (st_d == 2'd2) begin
				o_r <= 8'h20;
				o_g <= 8'hE8;
				o_b <= 8'h50;
			end else if (st_d == 2'd1) begin
				o_r <= 8'hFF;
				o_g <= 8'hF0;
				o_b <= 8'h30;
			end else begin
				o_r <= 8'h30;
				o_g <= 8'h90;
				o_b <= 8'hFF;
			end
		end else if (in_text && on_pix) begin
			o_r <= 8'hFF;
			o_g <= 8'hE0;
			o_b <= 8'h20;
		end else if (in_text) begin
			o_r <= 8'h10;
			o_g <= 8'h10;
			o_b <= 8'h10;
		end else if (in_hint && on_pix) begin
			o_r <= 8'hFB;
			o_g <= 8'hBF;
			o_b <= 8'h24;
		end else if (in_hint) begin
			o_r <= 8'h10;
			o_g <= 8'h10;
			o_b <= 8'h10;
		end else if (on_mark) begin
			o_r <= 8'hFF;
			o_g <= 8'hFF;
			o_b <= 8'hFF;
		end else begin
			o_r <= i_r;
			o_g <= i_g;
			o_b <= i_b;
		end
	end
end

endmodule
