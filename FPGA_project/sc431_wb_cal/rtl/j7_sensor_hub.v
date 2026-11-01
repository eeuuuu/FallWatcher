// MLX90640: official GetTa + ExtractOffset + gain, then residual heat.
module j7_sensor_hub (
	input  wire       clk,
	input  wire       rst_n,
	output reg        sht_ack,
	output reg        mlx_ack,
	output reg  [7:0] temp_c,
	output reg  [7:0] humid,
	output reg  [7:0] dbg,
	input  wire       vs_i,
	output reg [15:0] ts,
	output reg        heat_we,
	output reg  [9:0] heat_addr,
	output reg  [7:0] heat_data,
	output wire       scl_oe,
	output wire       sda_oe,
	input  wire       scl_i,
	input  wire       sda_i,
	input  wire       bus_grant,
	output wire       bus_idle
);

localparam [3:0] S_PWR  = 4'd0;
localparam [3:0] S_INIT = 4'd1;
localparam [3:0] S_POLL = 4'd2;
localparam [3:0] S_CLR  = 4'd3;
localparam [3:0] S_DUMP = 4'd4;
localparam [3:0] S_PTAT = 4'd5;
localparam [3:0] S_WAIT = 4'd6;
localparam [3:0] S_EE   = 4'd7;
localparam [3:0] S_OCC  = 4'd8;
localparam [3:0] S_OFF  = 4'd9;

localparam [7:0] A_W = 8'h66;
localparam [7:0] A_R = 8'h67;
localparam [24:0] WAIT_100MS = 25'd2500000;

reg [3:0]  phase;
reg [3:0]  idx;
reg        issued;
reg [24:0] wait_cnt;
reg [25:0] to_cnt;
reg [9:0]  pix_i;
reg [15:0] ram_addr;
reg [7:0]  msb;
reg [15:0] ptat, cen, stat, word16;
reg [15:0] vmin, vmax, nmin, nmax, ptat0;
reg [3:0]  loop_n;
reg        do_upd;
reg        first_pix;
reg        have_p0;
reg        have_ee;
reg        have_off;
reg [15:0] vptat25;
reg [15:0] ptat_art, ram_gain;
reg [15:0] ee16, ee48, ee50, ee51, ee60;
reg [2:0]  ee_i;
reg [3:0]  occ_i;
reg [5:0]  kt_abs;
reg [3:0]  alpha_ptat;
reg [1:0]  art_i;
reg [15:0] frame_n;
reg        vs_d;
reg [7:0]  to0, to1, to2;
reg [1:0]  to_n;
reg [3:0]  ee_try;
reg [15:0] offset_ref;
reg [3:0]  occ_r_sc, occ_c_sc, occ_p_sc;
reg [15:0] occ_rw [0:5];
reg [15:0] occ_cw [0:7];
(* syn_ramstyle = "block_ram" *)
reg [15:0] nuc_mem [0:767];
reg [15:0] nuc_q;
reg signed [15:0] ir_mean;
reg signed [25:0] ir_acc;
reg [9:0]  ir_cnt;
reg [9:0]  hot_n;
integer    ci;

reg        sta, sto, rd, wr, ack_in;
reg [7:0]  din;
wire       cmd_ack;
wire       ack_out;
wire [7:0] dout;
wire       i2c_al;
wire       scl_o, sda_o, scl_oen, sda_oen;

assign scl_oe = bus_grant & ~scl_oen;
assign sda_oe = bus_grant & ~sda_oen;
assign bus_idle = ((phase == S_PWR) || (phase == S_WAIT)) && !issued;

i2c_master_byte_ctrl u_i2c (
	.clk     (clk),
	.rst     (1'b0),
	.nReset  (rst_n),
	.ena     (bus_grant),
	.clk_cnt (16'd62),
	.start   (sta),
	.stop    (sto),
	.read    (rd),
	.write   (wr),
	.ack_in  (ack_in),
	.din     (din),
	.cmd_ack (cmd_ack),
	.ack_out (ack_out),
	.dout    (dout),
	.i2c_busy(),
	.i2c_al  (i2c_al),
	.scl_i   (scl_i),
	.scl_o   (scl_o),
	.scl_oen (scl_oen),
	.sda_i   (sda_i),
	.sda_o   (sda_o),
	.sda_oen (sda_oen)
);

function [7:0] ta_rel;
	input [15:0] p, p0;
	input [2:0]  sh;
	reg [15:0] d;
	reg [8:0]  t;
	begin
		if (p >= p0) begin
			d = (p - p0) >> sh;
			t = 9'd25 + {1'b0, d[7:0]};
			ta_rel = (t > 9'd99) ? 8'd99 : t[7:0];
		end else begin
			d = (p0 - p) >> sh;
			if (d >= 16'd20)
				ta_rel = 8'd5;
			else
				ta_rel = 8'd25 - d[7:0];
		end
	end
endfunction

function signed [15:0] sx4s;
	input [3:0] n;
	input [3:0] sh;
	reg signed [15:0] v;
	begin
		v = n[3] ? $signed({12'hFFF, n}) : $signed({12'h000, n});
		sx4s = v <<< sh;
	end
endfunction

function signed [15:0] sx6s;
	input [5:0] n;
	input [3:0] sh;
	reg signed [15:0] v;
	begin
		v = n[5] ? $signed({10'h3FF, n}) : $signed({10'h000, n});
		sx6s = v <<< sh;
	end
endfunction

wire [15:0] pix_raw   = {msb, dout};
wire [15:0] pix_u     = pix_raw ^ 16'h8000;
wire [4:0]  dump_row  = pix_i[9:5];
wire [4:0]  dump_col  = pix_i[4:0];
wire        dump_live = (dump_row[0] ^ dump_col[0]) == stat[0];
wire [19:0] den_gt    = ptat * {12'd0, alpha_ptat} + {4'd0, ptat_art};
wire [33:0] num_gt    = {ptat, 18'b0};
wire [15:0] vptatart  = (den_gt == 20'd0) ? 16'd1 : (num_gt / den_gt);
wire [9:0]  kt_raw    = ee50[9:0];
wire [7:0]  kt_ptat   = (kt_raw[8:3] == 6'd0) ? 8'd42 :
	(kt_raw[9] ? ((10'd1024 - kt_raw) >> 3) : (kt_raw >> 3));
wire [16:0] d_ptat    = (vptatart >= vptat25) ?
	{1'b0, (vptatart - vptat25)} : {1'b1, (vptat25 - vptatart)};
wire [16:0] ta_off    = {9'd0, kt_ptat} == 17'd0 ? 17'd0 : (d_ptat[15:0] / {8'd0, kt_ptat});
wire [8:0]  ta_up     = 9'd25 + ta_off[7:0];
wire [8:0]  ta_dn     = (ta_off[7:0] > 8'd20) ? 9'd5 : (9'd25 - ta_off[7:0]);
wire [7:0]  ta_ee     = d_ptat[16] ?
	ta_dn[7:0] : ((ta_up > 9'd99) ? 8'd99 : ta_up[7:0]);

wire [3:0] occ_rn =
	(dump_row[1:0] == 2'd0) ? occ_rw[dump_row[4:2]][3:0] :
	(dump_row[1:0] == 2'd1) ? occ_rw[dump_row[4:2]][7:4] :
	(dump_row[1:0] == 2'd2) ? occ_rw[dump_row[4:2]][11:8] :
	occ_rw[dump_row[4:2]][15:12];
wire [3:0] occ_cn =
	(dump_col[1:0] == 2'd0) ? occ_cw[dump_col[4:2]][3:0] :
	(dump_col[1:0] == 2'd1) ? occ_cw[dump_col[4:2]][7:4] :
	(dump_col[1:0] == 2'd2) ? occ_cw[dump_col[4:2]][11:8] :
	occ_cw[dump_col[4:2]][15:12];

wire signed [15:0] off_calc =
	$signed(offset_ref)
	+ sx4s(occ_rn, occ_r_sc)
	+ sx4s(occ_cn, occ_c_sc)
	+ sx6s(pix_raw[15:10], occ_p_sc);

wire signed [15:0] raw_s  = $signed(pix_raw);
wire signed [15:0] gee_s  = $signed(ee48);
wire signed [15:0] rgn_s  = $signed(ram_gain);
wire signed [31:0] ir_num = raw_s * gee_s;
wire signed [15:0] ir_g   = (rgn_s == 16'sd0) ? raw_s : (ir_num / rgn_s);
wire signed [16:0] ir_c   = $signed({{1{ir_g[15]}}, ir_g})
	- $signed({{1{nuc_q[15]}}, nuc_q});
wire signed [16:0] ir_d   = ir_c - {{1{ir_mean[15]}}, ir_mean};
wire [15:0] ir_pos   = ir_d[16] ? 16'd0 : ir_d[15:0];
wire signed [18:0] heat_x = 19'sd64 + (ir_d <<< 2);
wire [7:0]  heat_out = !have_off ? 8'd64 :
	(heat_x[18] ? 8'd0 : ((heat_x > 19'sd255) ? 8'd255 : heat_x[7:0]));
wire        nuc_we   = (phase == S_OFF) && cmd_ack && (idx == 4'd5);
wire [15:0] nuc_wd   = off_calc;
wire [15:0] to_raw   = nmax[15:2];
wire        plug_fov = (hot_n >= 10'd12) && (nmin > (nmax >> 2));
wire [7:0]  to_add   = ((hot_n < 10'd4) || plug_fov) ? 8'd0 :
	((to_raw > 16'd20) ? 8'd20 : to_raw[7:0]);
wire [8:0]  to_sum   = {1'b0, temp_c} + {1'b0, to_add};
wire [7:0]  to_c     = (to_sum > 9'd99) ? 8'd99 : to_sum[7:0];
wire [7:0]  to_ee    = to_c;

wire [15:0] ee_addr =
	(ee_i == 3'd0) ? 16'h2410 :
	(ee_i == 3'd1) ? 16'h2430 :
	(ee_i == 3'd2) ? 16'h2431 :
	(ee_i == 3'd3) ? 16'h2432 :
	(ee_i == 3'd4) ? 16'h2433 :
	(ee_i == 3'd5) ? 16'h243C :
	16'h243D;
wire [15:0] occ_addr = 16'h2411 + {12'd0, occ_i};
wire [15:0] off_addr = 16'h2440 + {6'd0, pix_i};

wire        i2c_go = (phase == S_INIT) || (phase == S_CLR) || (phase == S_POLL) ||
	(phase == S_DUMP) || (phase == S_PTAT) || (phase == S_EE) ||
	(phase == S_OCC) || (phase == S_OFF);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		phase     <= S_PWR;
		idx       <= 4'd0;
		issued    <= 1'b0;
		wait_cnt  <= 25'd0;
		to_cnt    <= 26'd0;
		pix_i     <= 10'd0;
		ram_addr  <= 16'h0400;
		msb       <= 8'd0;
		ptat      <= 16'd0;
		cen       <= 16'd0;
		stat      <= 16'd0;
		word16    <= 16'd0;
		vmin      <= 16'd0;
		vmax      <= 16'd256;
		nmin      <= 16'hFFFF;
		nmax      <= 16'd0;
		ptat0     <= 16'd0;
		loop_n    <= 4'd0;
		do_upd    <= 1'b0;
		first_pix <= 1'b1;
		have_p0   <= 1'b0;
		have_ee   <= 1'b0;
		have_off  <= 1'b0;
		vptat25   <= 16'd12288;
		ptat_art  <= 16'd0;
		ram_gain  <= 16'd0;
		ee16 <= 16'd0; ee48 <= 16'd0; ee50 <= 16'd0;
		ee51 <= 16'd0; ee60 <= 16'd0;
		ee_i      <= 3'd0;
		occ_i     <= 4'd0;
		kt_abs    <= 6'd8;
		alpha_ptat<= 4'd8;
		art_i     <= 2'd0;
		frame_n   <= 16'd0;
		vs_d      <= 1'b0;
		ts        <= 16'd0;
		to0 <= 8'd0; to1 <= 8'd0; to2 <= 8'd0;
		to_n      <= 2'd0;
		ee_try    <= 4'd0;
		ir_mean   <= 16'sd0;
		ir_acc    <= 26'sd0;
		ir_cnt    <= 10'd0;
		hot_n     <= 10'd0;
		offset_ref<= 16'd0;
		occ_r_sc  <= 4'd0;
		occ_c_sc  <= 4'd0;
		occ_p_sc  <= 4'd0;
		for (ci = 0; ci < 6; ci = ci + 1)
			occ_rw[ci] <= 16'd0;
		for (ci = 0; ci < 8; ci = ci + 1)
			occ_cw[ci] <= 16'd0;
		sht_ack   <= 1'b0;
		mlx_ack   <= 1'b0;
		temp_c    <= 8'd0;
		humid     <= 8'd0;
		dbg       <= 8'd0;
		heat_we   <= 1'b0;
		heat_addr <= 10'd0;
		heat_data <= 8'd0;
		sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
		ack_in <= 1'b0;
		din <= 8'd0;
	end else begin
		sht_ack <= 1'b0;
		heat_we <= 1'b0;
		dbg     <= {have_off, have_ee, loop_n[1:0], 4'h4};
		vs_d    <= vs_i;
		if (vs_i != vs_d)
			frame_n <= frame_n + 16'd1;

		if (i2c_al) begin
			issued   <= 1'b0;
			sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
			idx      <= 4'd0;
			wait_cnt <= 25'd0;
			mlx_ack  <= 1'b0;
			if (!have_off) begin
				phase <= S_OCC;
				occ_i <= 4'd0;
			end else if (!have_ee) begin
				phase <= S_EE;
				ee_i  <= 3'd0;
			end else
				phase <= S_WAIT;
		end else case (phase)
			S_PWR: begin
				wait_cnt <= wait_cnt + 25'd1;
				if (wait_cnt[23]) begin
					phase    <= S_INIT;
					idx      <= 4'd0;
					issued   <= 1'b0;
					wait_cnt <= 25'd0;
				end
			end
			S_WAIT: begin
				if (do_upd) begin
					do_upd  <= 1'b0;
					ts      <= frame_n;
					if (have_ee)
						temp_c <= ta_ee;
					else if (!have_p0 && (ptat != 16'd0)) begin
						have_p0 <= 1'b1;
						ptat0   <= ptat;
						temp_c  <= 8'd25;
					end else if (have_p0)
						temp_c  <= ta_rel(ptat, ptat0, 3'd4);
					to2 <= to1;
					to1 <= to0;
					to0 <= have_ee ? to_ee : to_c;
					if (to_n == 2'd3)
						humid <= ({2'b0, (have_ee ? to_ee : to_c)} + {2'b0, to0} + {2'b0, to1} + {2'b0, to2}) >> 2;
					else begin
						humid <= have_ee ? to_ee : to_c;
						to_n  <= to_n + 2'd1;
					end
					mlx_ack <= 1'b1;
					loop_n  <= (loop_n == 4'd9) ? 4'd0 : (loop_n + 4'd1);
					if ((nmax > nmin) && ((nmax - nmin) > 16'd320))
						vmin <= nmax - 16'd320;
					else
						vmin <= nmin;
					vmax <= (nmax > nmin) ? nmax : (nmin + 16'd32);
					if ((ir_cnt != 10'd0) && (hot_n < 10'd12))
						ir_mean <= ir_acc / $signed({16'd0, ir_cnt});
				end
				wait_cnt <= wait_cnt + 25'd1;
				if ((wait_cnt >= WAIT_100MS) && bus_grant) begin
					idx      <= 4'd0;
					issued   <= 1'b0;
					wait_cnt <= 25'd0;
					to_cnt   <= 26'd0;
					if (!have_off) begin
						phase  <= S_OCC;
						occ_i  <= 4'd0;
					end else if (!have_ee) begin
						phase  <= S_EE;
						ee_i   <= 3'd0;
					end else
						phase <= S_POLL;
				end
			end
			default: begin
				if (phase == S_POLL)
					to_cnt <= to_cnt + 26'd1;
				if ((phase == S_DUMP) && !issued && !dump_live) begin
					if (pix_i == 10'd767) begin
						phase <= S_PTAT;
						idx   <= 4'd0;
					end else begin
						pix_i    <= pix_i + 10'd1;
						ram_addr <= ram_addr + 16'd1;
					end
				end else if (!issued && bus_grant) begin
					issued <= 1'b1;
					sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
					ack_in <= 1'b0;
					if (i2c_go) begin
						if ((phase == S_INIT) && (idx == 4'd3))
							din <= 8'h19;
						else if ((phase == S_INIT) && (idx == 4'd4))
							din <= 8'h01;
						else if ((phase == S_CLR) && (idx == 4'd3))
							din <= 8'h00;
						else if ((phase == S_CLR) && (idx == 4'd4))
							din <= 8'h30;
						case (idx)
							4'd0: begin sta <= 1'b1; wr <= 1'b1; din <= A_W; end
							4'd1: begin wr <= 1'b1;
								if (phase == S_DUMP)
									din <= ram_addr[15:8];
								else if (phase == S_PTAT)
									din <= 8'h07;
								else if (phase == S_EE)
									din <= ee_addr[15:8];
								else if (phase == S_OCC)
									din <= occ_addr[15:8];
								else if (phase == S_OFF)
									din <= off_addr[15:8];
								else
									din <= 8'h80;
							end
							4'd2: begin wr <= 1'b1;
								if (phase == S_DUMP)
									din <= ram_addr[7:0];
								else if (phase == S_PTAT)
									din <= (art_i == 2'd0) ? 8'h00 :
									       (art_i == 2'd1) ? 8'h0A : 8'h20;
								else if (phase == S_EE)
									din <= ee_addr[7:0];
								else if (phase == S_OCC)
									din <= occ_addr[7:0];
								else if (phase == S_OFF)
									din <= off_addr[7:0];
								else if (phase == S_INIT)
									din <= 8'h0D;
								else
									din <= 8'h00;
							end
							4'd3: begin
								if ((phase == S_INIT) || (phase == S_CLR))
									wr <= 1'b1;
								else begin
									sta <= 1'b1;
									wr  <= 1'b1;
									din <= A_R;
								end
							end
							4'd4: begin
								if ((phase == S_INIT) || (phase == S_CLR))
									wr <= 1'b1;
								else begin
									rd     <= 1'b1;
									ack_in <= 1'b0;
								end
							end
							default: begin
								if ((phase == S_INIT) || (phase == S_CLR))
									sto <= 1'b1;
								else begin
									rd     <= 1'b1;
									ack_in <= 1'b1;
									sto    <= 1'b1;
								end
							end
						endcase
					end
				end else if (cmd_ack) begin
					issued <= 1'b0;
					sta <= 1'b0; sto <= 1'b0; rd <= 1'b0; wr <= 1'b0;
					if (phase == S_INIT) begin
						if (idx == 4'd0)
							mlx_ack <= ~ack_out;
						if (idx == 4'd5) begin
							phase    <= S_EE;
							idx      <= 4'd0;
							ee_i     <= 3'd0;
							wait_cnt <= 25'd0;
						end else
							idx <= idx + 4'd1;
					end else if (phase == S_POLL) begin
						if (idx == 4'd0)
							mlx_ack <= ~ack_out;
						if (idx == 4'd4)
							stat[15:8] <= dout;
						if (idx == 4'd5) begin
							stat[7:0] <= dout;
							if ({stat[15:8], dout} & 16'h0008) begin
								phase    <= S_CLR;
								idx      <= 4'd0;
								to_cnt   <= 26'd0;
								nmin     <= 16'hFFFF;
								nmax     <= 16'd0;
								first_pix<= 1'b1;
								ir_acc   <= 26'sd0;
								ir_cnt   <= 10'd0;
								hot_n    <= 10'd0;
							end else if (to_cnt[25]) begin
								phase    <= S_WAIT;
								idx      <= 4'd0;
								wait_cnt <= 25'd0;
							end else
								idx <= 4'd0;
						end else
							idx <= idx + 4'd1;
					end else if (phase == S_CLR) begin
						if (idx == 4'd5) begin
							phase    <= S_DUMP;
							idx      <= 4'd0;
							pix_i    <= 10'd0;
							ram_addr <= 16'h0400;
						end else
							idx <= idx + 4'd1;
					end else if (phase == S_DUMP) begin
						if (idx == 4'd4)
							msb <= dout;
						if (idx == 4'd5) begin
							word16    <= pix_u;
							heat_we   <= 1'b1;
							heat_addr <= pix_i;
							heat_data <= heat_out;
							ir_acc    <= ir_acc + {{9{ir_c[16]}}, ir_c};
							ir_cnt    <= ir_cnt + 10'd1;
							if (ir_pos > 16'd12)
								hot_n <= hot_n + 10'd1;
							if (first_pix) begin
								nmin      <= ir_pos;
								nmax      <= ir_pos;
								first_pix <= 1'b0;
							end else begin
								if (ir_pos < nmin)
									nmin <= ir_pos;
								if (ir_pos > nmax)
									nmax <= ir_pos;
							end
							if (pix_i == 10'd400)
								cen <= pix_u;
							if (pix_i == 10'd767) begin
								phase   <= S_PTAT;
								idx     <= 4'd0;
								art_i   <= 2'd0;
							end else begin
								pix_i    <= pix_i + 10'd1;
								ram_addr <= ram_addr + 16'd1;
								idx      <= 4'd0;
							end
						end else
							idx <= idx + 4'd1;
					end else if (phase == S_EE) begin
						if (idx == 4'd4)
							msb <= dout;
						if (idx == 4'd5) begin
							case (ee_i)
								3'd0: ee16 <= {msb, dout};
								3'd1: ee48 <= {msb, dout};
								3'd2: vptat25 <= {msb, dout};
								3'd3: ee50 <= {msb, dout};
								3'd4: ee51 <= {msb, dout};
								default: ee60 <= {msb, dout};
							endcase
							if (ee_i == 3'd6) begin
								alpha_ptat <= {2'b00, ee16[15:14]} + 4'd8;
								if (ee50[9])
									kt_abs <= ((10'd1024 - ee50[9:0]) >> 3);
								else if (ee50[8:3] == 6'd0)
									kt_abs <= 6'd8;
								else
									kt_abs <= ee50[8:3];
								if ((vptat25 >= 16'd8000) && (vptat25 <= 16'd25000)) begin
									have_ee <= 1'b1;
									have_p0 <= 1'b1;
									ptat0   <= vptat25;
								end
								phase    <= S_OCC;
								occ_i    <= 4'd0;
								idx      <= 4'd0;
								wait_cnt <= 25'd0;
							end else begin
								ee_i <= ee_i + 3'd1;
								idx  <= 4'd0;
							end
						end else
							idx <= idx + 4'd1;
					end else if (phase == S_OCC) begin
						if (idx == 4'd4)
							msb <= dout;
						if (idx == 4'd5) begin
							if (occ_i == 4'd0)
								offset_ref <= {msb, dout};
							else if (occ_i <= 4'd6)
								occ_rw[occ_i - 4'd1] <= {msb, dout};
							else
								occ_cw[occ_i - 4'd7] <= {msb, dout};
							if (occ_i == 4'd14) begin
								occ_p_sc <= ee16[3:0];
								occ_c_sc <= ee16[7:4];
								occ_r_sc <= ee16[11:8];
								phase    <= S_OFF;
								pix_i    <= 10'd0;
								idx      <= 4'd0;
							end else begin
								occ_i <= occ_i + 4'd1;
								idx   <= 4'd0;
							end
						end else
							idx <= idx + 4'd1;
					end else if (phase == S_OFF) begin
						if (idx == 4'd4)
							msb <= dout;
						if (idx == 4'd5) begin
							if (pix_i == 10'd767) begin
								have_off <= 1'b1;
								phase    <= S_WAIT;
								pix_i    <= 10'd0;
								idx      <= 4'd0;
								wait_cnt <= 25'd0;
							end else begin
								pix_i <= pix_i + 10'd1;
								idx   <= 4'd0;
							end
						end else
							idx <= idx + 4'd1;
					end else begin
						if (idx == 4'd4)
							msb <= dout;
						if (idx == 4'd5) begin
							if (art_i == 2'd0) begin
								ptat_art <= {msb, dout};
								art_i    <= 2'd1;
								idx      <= 4'd0;
							end else if (art_i == 2'd1) begin
								ram_gain <= {msb, dout};
								art_i    <= 2'd2;
								idx      <= 4'd0;
							end else begin
								ptat     <= {msb, dout};
								do_upd   <= 1'b1;
								art_i    <= 2'd0;
								phase    <= S_WAIT;
								idx      <= 4'd0;
								wait_cnt <= 25'd0;
							end
						end else
							idx <= idx + 4'd1;
					end
				end
			end
		endcase
	end
end

always @(posedge clk) begin
	nuc_q <= nuc_mem[pix_i];
	if (nuc_we)
		nuc_mem[pix_i] <= nuc_wd;
end

endmodule
