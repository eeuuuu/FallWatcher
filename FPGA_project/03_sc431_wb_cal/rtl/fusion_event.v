// Industrial Task2 fusion. Host sim: 04-tool/fal_sim.py (keep in sync).
// TinyML = person gate. Frame-diff box is a motion envelope, not a silhouette.
// Walk (lateral) != fall. Close sit usually has no cy/y1 drop.
// Fall: seen stand, then box on the lower screen (floor), then still ~1.25s.
// Wide T-pose (thin full-width band) is not a fall, even if y1>700.
// Occupancy acquire > vacate: mot_big must not be wiped the same tick.
// person = TinyML hold AND (box or motion). Orphan pd_on without box is not MOT.
// IN = heat AND (person or motion). Cold motion stays MOT; person+heat is IN.
// Do not vacate during mot_hold or the TinyML blind window (~2.5s after last motion).
// FAL stays only while heat (ir) is present; heat gone → drop FAL to IDL.
// Do not confirm a new FAL while vacating (walk-out ≠ fall).
module fusion_event (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        i_vs,
	input  wire        mot_valid,
	input  wire [10:0] mot_x0,
	input  wire [10:0] mot_y0,
	input  wire [10:0] mot_x1,
	input  wire [10:0] mot_y1,
	input  wire [7:0]  mlx_to,
	input  wire [7:0]  mlx_ta,
	input  wire [7:0]  sht_t,
	input  wire        pd_on,
	output reg         evt_on,
	output reg  [2:0]  evt_code,
	output reg  [7:0]  score,
	output reg  [4:0]  ir_x,
	output reg  [4:0]  ir_y,
	output reg         box_show,
	output reg  [10:0] box_x0,
	output reg  [10:0] box_y0,
	output reg  [10:0] box_x1,
	output reg  [10:0] box_y1
);

reg vs_d;
wire vs_tick = vs_d & ~i_vs;

wire ir_now = (mlx_to > mlx_ta) && ((mlx_to - mlx_ta) > 8'd3) &&
	(mlx_to <= 8'd45);
wire env = (sht_t >= 8'd10) && (sht_t <= 8'd38);
wire ac  = (sht_t >= 8'd35);

reg [7:0] vis_hold;
reg [6:0] mot_hold;
reg [5:0] ir_hold;
wire vis_on  = pd_on || (vis_hold != 8'd0);
wire ir      = ir_now || (ir_hold != 6'd0);

wire [10:0] mbw = (mot_x1 > mot_x0) ? (mot_x1 - mot_x0) : 11'd0;
wire [10:0] mbh = (mot_y1 > mot_y0) ? (mot_y1 - mot_y0) : 11'd0;
wire [10:0] mcx = (mot_x0 + mot_x1) >> 1;
wire [10:0] mcy = (mot_y0 + mot_y1) >> 1;
wire mot_big  = mot_valid && (mbw > 11'd80) && (mbh > 11'd40);
wire mot_on   = mot_big || (mot_hold != 7'd0);
wire person   = vis_on && (have_box || mot_on);
wire ar_stand = mot_big && (mbh >= 11'd160) && (mbh > mbw);

reg        have_box, seen_stand, fal_hold, have_cx;
reg [7:0]  still_cnt;
reg [4:0]  walk_cnt;
reg [8:0]  leave_cnt;
reg [10:0] stand_h, stand_cy, stand_y1, peak_cy, peak_y1, last_cx;
reg [10:0] lx0, ly0, lx1, ly1;

wire [10:0] dx = have_cx ?
	((mcx > last_cx) ? (mcx - last_cx) : (last_cx - mcx)) : 11'd0;
wire walking = mot_big && have_cx && (dx > 11'd24);
wire drop_cy = (stand_cy != 11'd0) && (peak_cy > (stand_cy + 11'd70));
wire drop_y1 = (stand_y1 != 11'd0) && (peak_y1 > (stand_y1 + 11'd120));
wire [10:0] last_w = (lx1 > lx0) ? (lx1 - lx0) : 11'd0;
wire [10:0] last_h = (ly1 > ly0) ? (ly1 - ly0) : 11'd0;
wire low_bottom = have_box && (ly1 > 11'd700);
/* Thin full-width band is T-pose / arms, not a body on the floor. */
wire tpose_wide = (last_h < 11'd250) && (last_w > 11'd1000);
wire now_lie = low_bottom && !tpose_wide &&
	((last_h + 11'd40) < last_w || last_h < 11'd220);
wire dropped = (drop_y1 && low_bottom) || (drop_cy && now_lie);
wire ir_valid = (mlx_ta >= 8'd8) && (mlx_ta <= 8'd40);
wire ir_idle = ir_valid && !ir_now;
wire leave_ready = !pd_on && !mot_on && ir_idle;
wire fal_pend = seen_stand && dropped && !ac && (walk_cnt == 5'd0) && !leave_ready;
wire fall_try  = fal_hold || (fal_pend && (still_cnt >= 8'd75));
wire fall      = fall_try && ir;
wire heat_lost = fal_hold && !ir;
wire [7:0] sc = (person ? 8'd60 : 8'd0) + (ir ? 8'd25 : 8'd0) + (env ? 8'd15 : 8'd0);
wire [10:0] cx = (lx0 + lx1) >> 1;
wire [10:0] cy = (ly0 + ly1) >> 1;
wire [10:0] ix = cx / 11'd60;
wire [10:0] iy = cy / 11'd45;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d       <= 1'b0;
		vis_hold   <= 8'd0;
		mot_hold   <= 7'd0;
		ir_hold    <= 6'd0;
		have_box   <= 1'b0;
		seen_stand <= 1'b0;
		fal_hold   <= 1'b0;
		have_cx    <= 1'b0;
		still_cnt  <= 8'd0;
		walk_cnt   <= 5'd0;
		leave_cnt  <= 9'd0;
		stand_h    <= 11'd0;
		stand_cy   <= 11'd0;
		stand_y1   <= 11'd0;
		peak_cy    <= 11'd0;
		peak_y1    <= 11'd0;
		last_cx    <= 11'd0;
		lx0 <= 11'd0;
		ly0 <= 11'd0;
		lx1 <= 11'd0;
		ly1 <= 11'd0;
		evt_on   <= 1'b0;
		evt_code <= 3'd0;
		score    <= 8'd0;
		ir_x     <= 5'd0;
		ir_y     <= 5'd0;
		box_show <= 1'b0;
		box_x0   <= 11'd0;
		box_y0   <= 11'd0;
		box_x1   <= 11'd0;
		box_y1   <= 11'd0;
	end else begin
		vs_d <= i_vs;
		if (vs_tick) begin
			if (pd_on)
				vis_hold <= 8'd255;
			else if (vis_hold != 8'd0)
				vis_hold <= vis_hold - 8'd1;
			if (ir_now)
				ir_hold <= 6'd40;
			else if (ir_hold != 6'd0)
				ir_hold <= ir_hold - 6'd1;
			if (mot_big)
				mot_hold <= 7'd90;
			else if (mot_hold != 7'd0)
				mot_hold <= mot_hold - 7'd1;

			if (mot_big) begin
				lx0 <= mot_x0;
				ly0 <= mot_y0;
				lx1 <= mot_x1;
				ly1 <= mot_y1;
				have_box  <= 1'b1;
				still_cnt <= 8'd0;
				if (walking) begin
					walk_cnt <= 5'd31;
					fal_hold <= 1'b0;
				end else if (walk_cnt != 5'd0)
					walk_cnt <= walk_cnt - 5'd1;
				if (ar_stand) begin
					seen_stand <= 1'b1;
					stand_h    <= mbh;
					stand_cy   <= mcy;
					stand_y1   <= mot_y1;
					peak_cy    <= mcy;
					peak_y1    <= mot_y1;
					fal_hold   <= 1'b0;
				end else if (seen_stand && !walking) begin
					if (mcy > peak_cy)
						peak_cy <= mcy;
					if (mot_y1 > peak_y1)
						peak_y1 <= mot_y1;
				end
				last_cx <= mcx;
				have_cx <= 1'b1;
			end else begin
				if (still_cnt != 8'd255)
					still_cnt <= still_cnt + 8'd1;
				if (walk_cnt != 5'd0)
					walk_cnt <= walk_cnt - 5'd1;
			end

			if (walking || ar_stand) begin
				fal_hold  <= 1'b0;
				leave_cnt <= 9'd0;
			end else if (fal_pend && (still_cnt >= 8'd75) && ir)
				fal_hold <= 1'b1;
			else if (!ir)
				fal_hold <= 1'b0;

			if (mot_big)
				leave_cnt <= 9'd0;
			else if (leave_ready) begin
				if (leave_cnt != 9'd480)
					leave_cnt <= leave_cnt + 9'd1;
			end else
				leave_cnt <= 9'd0;

			if (!mot_on &&
			    (heat_lost ||
			     (!ir && !fal_hold && !fal_pend && (still_cnt >= 8'd120)) ||
			     (!pd_on && !fal_hold && !fal_pend &&
			      ((leave_cnt >= 9'd60) || (still_cnt >= 8'd150) ||
			       (vis_hold == 8'd0))))) begin
				seen_stand <= 1'b0;
				fal_hold   <= 1'b0;
				have_box   <= 1'b0;
				walk_cnt   <= 5'd0;
				have_cx    <= 1'b0;
				leave_cnt  <= 9'd0;
				peak_cy    <= 11'd0;
				peak_y1    <= 11'd0;
				stand_cy   <= 11'd0;
				stand_y1   <= 11'd0;
				vis_hold   <= 8'd0;
				mot_hold   <= 7'd0;
			end

			score    <= sc;
			ir_x     <= (ix > 11'd31) ? 5'd31 : ix[4:0];
			ir_y     <= (iy > 11'd23) ? 5'd23 : iy[4:0];
			box_x0   <= lx0;
			box_y0   <= ly0;
			box_x1   <= lx1;
			box_y1   <= ly1;
			box_show <= mot_on || (have_box && (vis_on || fal_hold));

			if (fall) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd4;
			end else if (heat_lost) begin
				evt_on   <= 1'b0;
				evt_code <= 3'd0;
			end else if (fal_pend && ir) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd3;
			end else if (ir && (person || mot_on)) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd3;
			end else if (person || mot_on) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd1;
			end else if (ir) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd2;
			end else if (ac) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd5;
			end else begin
				evt_on   <= 1'b0;
				evt_code <= 3'd0;
			end
		end
	end
end

endmodule
