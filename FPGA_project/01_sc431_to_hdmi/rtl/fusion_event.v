// Industrial Task2 fusion. Host sim: 04-tool/fal_sim.py (keep in sync).
// TinyML = person gate. Frame-diff box is a motion envelope, not a silhouette.
// Walk (lateral) != fall. Close sit usually has no cy/y1 drop.
// Fall: seen stand, then box on the lower screen (floor), then still ~1.25s.
// Walk (tall body, dx>24): replace immediately — do not drag the old lock.
// Fall stubs (face/hand/upper, not tall walk): union into the stand envelope.
// Confirm FAL: snap the box to a horizontal floor rect. IR idle ~3s vacates.
// Occupancy acquire > vacate: mot_big must not be wiped the same tick.
// person = TinyML hold AND (box or motion). Orphan pd_on without box is not MOT.
// IN = heat AND (person or motion). Cold motion stays MOT; person+heat is IN.
// Standing still with heat: keep last box. IR idle ~3s vacates (clothes
// / leftover pd_on must not veto). Do not vacate on vis_hold expiry.
// FAL heat gone still vacates (heat_lost). Nested / high-IoU box2 is dropped.
// Do not confirm a new FAL while vacating (walk-out ≠ fall).
// HDMI box1 = motion envelope. T-pose / hands: expand X, keep stand height.
// Floor body (pancake or square) replaces downward. Tiny fall stubs still union.
// lock_union only for fall stubs on the same person — not a second body.
// Dual box: box2 = frame-diff CC2, or still-lock + far torso. No 400 px merge.
// Dual-person fall is not handled — FAL only when one person.
// IoU / dual flags are registered. Do not put the multiply on HDMI CE.
module fusion_event (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        i_vs,
	input  wire        mot_valid,
	input  wire [10:0] mot_x0,
	input  wire [10:0] mot_y0,
	input  wire [10:0] mot_x1,
	input  wire [10:0] mot_y1,
	input  wire        mot_valid2,
	input  wire [10:0] mot_x0_2,
	input  wire [10:0] mot_y0_2,
	input  wire [10:0] mot_x1_2,
	input  wire [10:0] mot_y1_2,
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
	output reg  [10:0] box_y1,
	output reg         box_show2,
	output reg  [10:0] box_x0_2,
	output reg  [10:0] box_y0_2,
	output reg  [10:0] box_x1_2,
	output reg  [10:0] box_y1_2
);

reg vs_d;
wire vs_tick = vs_d & ~i_vs;

reg        mot_v_d, mot_v_s, mot_v2_d, mot_v2_s;
reg [10:0] mot_x0_d, mot_y0_d, mot_x1_d, mot_y1_d;
reg [10:0] mot_x0_s, mot_y0_s, mot_x1_s, mot_y1_s;
reg [10:0] mot_x0_2d, mot_y0_2d, mot_x1_2d, mot_y1_2d;
reg [10:0] mot_x0_2s, mot_y0_2s, mot_x1_2s, mot_y1_2s;

wire ir_now = (mlx_to > mlx_ta) && ((mlx_to - mlx_ta) > 8'd3) &&
	(mlx_to <= 8'd45);
wire env = (sht_t >= 8'd10) && (sht_t <= 8'd38);
wire ac  = (sht_t >= 8'd35);

reg [7:0] vis_hold;
reg [6:0] mot_hold;
reg [5:0] ir_hold;
wire vis_on  = pd_on || (vis_hold != 8'd0);
wire ir      = ir_now || (ir_hold != 6'd0);

wire [10:0] mbw = (mot_x1_s > mot_x0_s) ? (mot_x1_s - mot_x0_s) : 11'd0;
wire [10:0] mbh = (mot_y1_s > mot_y0_s) ? (mot_y1_s - mot_y0_s) : 11'd0;
wire [10:0] mcx = (mot_x0_s + mot_x1_s) >> 1;
wire [10:0] mcy = (mot_y0_s + mot_y1_s) >> 1;
wire mot_big  = mot_v_s && (mbw > 11'd80) && (mbh > 11'd40);
wire [10:0] mbw2 = (mot_x1_2s > mot_x0_2s) ? (mot_x1_2s - mot_x0_2s) : 11'd0;
wire [10:0] mbh2 = (mot_y1_2s > mot_y0_2s) ? (mot_y1_2s - mot_y0_2s) : 11'd0;
wire mot_big2 = mot_v2_s && (mbw2 > 11'd80) && (mbh2 > 11'd40);
wire mot_on   = mot_big || mot_big2 || (mot_hold != 7'd0);
wire person   = vis_on && (have_box || mot_on);
/* Stand = feet on the floor and torso height. Arms at 2 m are ~150–250 px. */
wire ar_stand = mot_big && (mbh > mbw) && (mot_y1_s >= 11'd700) &&
	(mbh >= 11'd300) &&
	(!have_box ||
	 (!seen_stand && ((mbh + 11'd80) >= last_h)) ||
	 ((stand_h != 11'd0) && ((mbh + 11'd80) >= stand_h) && (mbh >= 11'd360)));

reg        have_box, have_box2, seen_stand, fal_hold, have_cx, lie_seen;
reg [7:0]  still_cnt;
reg [4:0]  walk_cnt;
reg [8:0]  leave_cnt;
reg [6:0]  box2_hold;
reg [10:0] stand_h, stand_cy, stand_y1, peak_cy, peak_y1, last_cx;
reg [10:0] lx0, ly0, lx1, ly1;
reg [10:0] px0, py0, px1, py1;

wire [10:0] dx = have_cx ?
	((mcx > last_cx) ? (mcx - last_cx) : (last_cx - mcx)) : 11'd0;
wire walking = mot_big && have_cx && (dx > 11'd24);
wire drop_cy = (stand_cy != 11'd0) && (peak_cy > (stand_cy + 11'd70));
wire drop_y1 = (stand_y1 != 11'd0) && (peak_y1 > (stand_y1 + 11'd120));
wire [10:0] last_w = (lx1 > lx0) ? (lx1 - lx0) : 11'd0;
wire [10:0] last_h = (ly1 > ly0) ? (ly1 - ly0) : 11'd0;
wire low_bottom = have_box && (ly1 > 11'd700);
/* Thin band, or stand lock that only grew sideways (arms), is not a lie. */
wire arms_wide = seen_stand && (stand_h != 11'd0) &&
	(last_w > 11'd900) && ((last_h + 11'd100) >= stand_h);
wire tpose_wide = ((last_h < 11'd250) && (last_w > 11'd1000)) || arms_wide;
/* Floor body: pancake, low flat, or a square lump shorter than stand. */
wire now_lie = low_bottom && !tpose_wide &&
	(((last_h + 11'd40) < last_w) || (last_h < 11'd220) ||
	 ((last_h < 11'd400) && (stand_h != 11'd0) &&
	  ((last_h + 11'd80) < stand_h) &&
	  (last_h <= (last_w + 11'd80)) && (last_w <= (last_h + 11'd80))));
wire tpose_mot = (mbh < 11'd250) && (mbw > 11'd1000);
/* Floor fragment: short or wider-than-tall, not a T-pose smear. */
wire frag_lie = mot_big && (mot_y1_s > 11'd700) && !tpose_mot &&
	((mbh + 11'd40) < mbw || mbh < 11'd280);
/* Toward-camera fall: y1 barely moves, cy drops a lot. Squat is ~+160. */
wire deep_drop = seen_stand && low_bottom && !tpose_wide &&
	(peak_cy > (stand_cy + 11'd180)) && (peak_y1 > 11'd680);
wire dropped = (drop_y1 && low_bottom) ||
	(drop_cy && (now_lie || lie_seen)) || deep_drop;
wire ir_valid = (mlx_ta >= 8'd8) && (mlx_ta <= 8'd40);
wire ir_idle = ir_valid && !ir_now;
wire [7:0] sc = (person ? 8'd60 : 8'd0) + (ir ? 8'd25 : 8'd0) + (env ? 8'd15 : 8'd0);
wire [10:0] cx = (lx0 + lx1) >> 1;
wire [10:0] cy = (ly0 + ly1) >> 1;
wire [10:0] ix = cx / 11'd60;
wire [10:0] iy = cy / 11'd45;
wire mot_hand = have_box && mot_big &&
	(mot_y1_s + 11'd80 < ly1) && (mbh + 11'd80 < last_h);
wire short_vs_lock = have_box && seen_stand && (mbh + 11'd80 < last_h);
wire box_huge = (last_w > 11'd1400) || (last_h > 11'd800);
wire smear_mot = (mbw > 11'd1000) || (mbh > 11'd800);
wire mot_ov1 = have_box && mot_big &&
	(mot_x1_s > lx0) && (lx1 > mot_x0_s) && (mot_y1_s > ly0) && (ly1 > mot_y0_s);
wire [10:0] mot_d1 = have_box ?
	((mcx > cx) ? (mcx - cx) : (cx - mcx)) : 11'd2047;
wire [10:0] mot_gap1 = have_box ?
	((lx1 < mot_x0_s) ? (mot_x0_s - lx1) :
	 (mot_x1_s < lx0) ? (lx0 - mot_x1_s) : 11'd0) : 11'd0;
/* Same walker: overlap or a step. Dual-person fall is out of scope. */
wire same_body = !have_box || mot_ov1 || (mot_d1 < 11'd360);
wire walk_follow = walking && (mbh >= 11'd380) && !smear_mot && same_body;
/* Still lock + far torso = person B. Two movers use mot_big2. */
wire second_body = have_box && mot_big && (mbh >= 11'd300) && (mbw > 11'd80) &&
	(mot_d1 >= 11'd360) && (mot_gap1 >= 11'd200) && !mot_ov1 &&
	(mot_y1_s >= 11'd700) && !mot_hand && !smear_mot && !walk_follow;
/* Squat: head drops, feet stay, still a vertical body. Replace — do not
 * union the old stand envelope into a tall strip. Fall stubs keep union. */
wire squat_follow = seen_stand && have_box && mot_big && same_body &&
	(stand_y1 != 11'd0) && (stand_h != 11'd0) &&
	(mot_y1_s >= 11'd680) && (mbh >= 11'd220) &&
	(mbh + 11'd80 < stand_h) && (mbw < 11'd600) &&
	((mbh > mbw) || (mbw >= (mbh + 11'd100))) &&
	(!frag_lie || (mbw >= 11'd280)) &&
	(mot_y0_s > (((stand_y1 > stand_h) ? (stand_y1 - stand_h) : 11'd0) + 11'd80)) &&
	(mot_x0_s > 11'd80) &&
	((mot_y1_s + 11'd80) >= stand_y1) &&
	(mot_y1_s < (stand_y1 + 11'd100)) &&
	!smear_mot && !tpose_mot;
wire two_ppl = mot_big2 || second_body;
/* Upright squat or a clearly wider kneel, peak not a deep crumple. */
wire crouch_ok = seen_stand && have_box && !fal_hold &&
	(stand_h != 11'd0) && (ly1 > 11'd680) &&
	(last_h >= 11'd200) && ((last_h + 11'd80) < stand_h) &&
	((last_h > last_w) || (last_w >= (last_h + 11'd100))) &&
	((stand_cy == 11'd0) || (peak_cy <= (stand_cy + 11'd170)));
/* Substantial body on the floor: follow down. Tiny face/hand stubs union. */
wire fall_follow = seen_stand && have_box && mot_big && same_body &&
	!tpose_mot && !smear_mot && !squat_follow &&
	(mot_y1_s >= 11'd700) &&
	((mbh >= 11'd200) || (mbw >= 11'd300)) &&
	(frag_lie || (mot_y0_s > (ly0 + 11'd80)));
wire leave_block = (mot_big && (mbh >= 11'd200)) || mot_big2 || second_body;
wire leave_ready = ir_idle && !leave_block;
wire fal_pend = seen_stand && dropped && !ac && (walk_cnt == 5'd0) &&
	!leave_ready && !two_ppl && !squat_follow && !crouch_ok;
wire fall_try  = fal_hold || (fal_pend && (still_cnt >= 8'd75));
wire fall      = fall_try && ir;
wire heat_lost = fal_hold && !ir;

/* box2 candidate vs the occupy lock. Use registered dual flags so the
 * multiply does not see the 40-LUT second_body cone. */
wire [10:0] qx0 = second_body_r ? mot_x0_s : (mot_big2_r ? mot_x0_2s : px0);
wire [10:0] qy0 = second_body_r ? mot_y0_s : (mot_big2_r ? mot_y0_2s : py0);
wire [10:0] qx1 = second_body_r ? mot_x1_s : (mot_big2_r ? mot_x1_2s : px1);
wire [10:0] qy1 = second_body_r ? mot_y1_s : (mot_big2_r ? mot_y1_2s : py1);
wire have_q = second_body_r || mot_big2_r || have_box2;
wire [10:0] i0x = (lx0 > qx0) ? lx0 : qx0;
wire [10:0] i0y = (ly0 > qy0) ? ly0 : qy0;
wire [10:0] i1x = (lx1 < qx1) ? lx1 : qx1;
wire [10:0] i1y = (ly1 < qy1) ? ly1 : qy1;
wire ov2 = have_box && have_q && (i1x > i0x) && (i1y > i0y);
wire [10:0] bw = (qx1 > qx0) ? (qx1 - qx0) : 11'd0;
wire [10:0] bh = (qy1 > qy0) ? (qy1 - qy0) : 11'd0;
wire [21:0] iw = ov2 ? {11'd0, i1x - i0x} : 22'd0;
wire [21:0] ih = ov2 ? {11'd0, i1y - i0y} : 22'd0;
wire nest_b = have_box && have_q &&
	(qx0 >= lx0) && (qy0 >= ly0) && (qx1 <= lx1) && (qy1 <= ly1);
wire nest_a = have_box && have_q &&
	(lx0 >= qx0) && (ly0 >= qy0) && (lx1 <= qx1) && (ly1 <= qy1);
wire box2_hand = have_box && have_q && (
	((bh + 11'd160 < last_h) && (qy1 + 11'd200 < ly1)) ||
	((last_h + 11'd160 < bh) && (ly1 + 11'd200 < qy1)));
/* Fall-stub union is single-person only. Dual: do not swallow B. */
wire lock_union = seen_stand && have_box && !box_huge &&
	!walk_follow && !squat_follow && !fall_follow && !smear_mot && !two_ppl;
wire [10:0] lie_span0 = (last_h > last_w) ? last_h : last_w;
wire [10:0] lie_span = (lie_span0 < 11'd480) ? 11'd480 :
	((lie_span0 > 11'd880) ? 11'd880 : lie_span0);
wire [10:0] lie_half = lie_span >> 1;
wire [10:0] lie_x0 = (cx > lie_half) ? (cx - lie_half) : 11'd20;
wire [10:0] lie_x1 = ((cx + lie_half) < 11'd1900) ? (cx + lie_half) : 11'd1900;
wire [10:0] lie_y1 = (ly1 < 11'd820) ? 11'd820 : ly1;
wire [10:0] lie_y0 = (lie_y1 > 11'd220) ? (lie_y1 - 11'd220) : 11'd600;

reg        box2_bad_r, second_body_r, mot_big_r, mot_big2_r;
reg        walk_follow_r, squat_follow_r, fall_follow_r, ar_stand_r, smear_mot_r, lock_union_r;
reg        mot_hand_r, short_vs_r, vis_on_r, mot_on_r, person_r;
reg        now_lie_r, frag_lie_r, fal_pend_r, ir_r, ir_now_r, ac_r;
reg        leave_block_r, leave_ready_r, heat_lost_r, fall_r;
reg        nest_b_r, nest_a_r, ov2_r, box2_hand_r, two_ppl_r;
reg [10:0] mbh_r, mcy_r;
reg [7:0]  sc_r;
reg [10:0] ix_r, iy_r;
reg [10:0] lie_x0_r, lie_x1_r, lie_y0_r, lie_y1_r;
reg [10:0] lw_r, lh_r, bw_r, bh_r;
reg [21:0] iw_r, ih_r, aa_r, ba_r, inter_r;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		mot_v_d <= 1'b0; mot_v_s <= 1'b0;
		mot_v2_d <= 1'b0; mot_v2_s <= 1'b0;
		mot_x0_d <= 11'd0; mot_y0_d <= 11'd0;
		mot_x1_d <= 11'd0; mot_y1_d <= 11'd0;
		mot_x0_s <= 11'd0; mot_y0_s <= 11'd0;
		mot_x1_s <= 11'd0; mot_y1_s <= 11'd0;
		mot_x0_2d <= 11'd0; mot_y0_2d <= 11'd0;
		mot_x1_2d <= 11'd0; mot_y1_2d <= 11'd0;
		mot_x0_2s <= 11'd0; mot_y0_2s <= 11'd0;
		mot_x1_2s <= 11'd0; mot_y1_2s <= 11'd0;
		lw_r <= 11'd0; lh_r <= 11'd0; bw_r <= 11'd0; bh_r <= 11'd0;
		iw_r <= 22'd0; ih_r <= 22'd0;
		aa_r <= 22'd0; ba_r <= 22'd0; inter_r <= 22'd0;
		nest_b_r <= 1'b0; nest_a_r <= 1'b0;
		ov2_r <= 1'b0; box2_hand_r <= 1'b0; two_ppl_r <= 1'b0;
		box2_bad_r <= 1'b0;
		second_body_r <= 1'b0; mot_big_r <= 1'b0; mot_big2_r <= 1'b0;
		walk_follow_r <= 1'b0; squat_follow_r <= 1'b0; fall_follow_r <= 1'b0;
		ar_stand_r <= 1'b0;
		smear_mot_r <= 1'b0; lock_union_r <= 1'b0;
		mot_hand_r <= 1'b0; short_vs_r <= 1'b0;
		vis_on_r <= 1'b0; mot_on_r <= 1'b0; person_r <= 1'b0;
		now_lie_r <= 1'b0; frag_lie_r <= 1'b0;
		fal_pend_r <= 1'b0; ir_r <= 1'b0; ir_now_r <= 1'b0; ac_r <= 1'b0;
		leave_block_r <= 1'b0; leave_ready_r <= 1'b0;
		heat_lost_r <= 1'b0; fall_r <= 1'b0;
		mbh_r <= 11'd0; mcy_r <= 11'd0;
		sc_r <= 8'd0; ix_r <= 11'd0; iy_r <= 11'd0;
		lie_x0_r <= 11'd0; lie_x1_r <= 11'd0;
		lie_y0_r <= 11'd0; lie_y1_r <= 11'd0;
	end else begin
		mot_v_d <= mot_valid; mot_v_s <= mot_v_d;
		mot_v2_d <= mot_valid2; mot_v2_s <= mot_v2_d;
		mot_x0_d <= mot_x0; mot_x0_s <= mot_x0_d;
		mot_y0_d <= mot_y0; mot_y0_s <= mot_y0_d;
		mot_x1_d <= mot_x1; mot_x1_s <= mot_x1_d;
		mot_y1_d <= mot_y1; mot_y1_s <= mot_y1_d;
		mot_x0_2d <= mot_x0_2; mot_x0_2s <= mot_x0_2d;
		mot_y0_2d <= mot_y0_2; mot_y0_2s <= mot_y0_2d;
		mot_x1_2d <= mot_x1_2; mot_x1_2s <= mot_x1_2d;
		mot_y1_2d <= mot_y1_2; mot_y1_2s <= mot_y1_2d;

		lw_r <= last_w;
		lh_r <= last_h;
		bw_r <= bw;
		bh_r <= bh;
		iw_r <= iw;
		ih_r <= ih;
		aa_r <= {11'd0, lw_r} * {11'd0, lh_r};
		ba_r <= {11'd0, bw_r} * {11'd0, bh_r};
		inter_r <= iw_r * ih_r;
		nest_b_r <= nest_b;
		nest_a_r <= nest_a;
		ov2_r <= ov2;
		box2_hand_r <= box2_hand;
		two_ppl_r <= two_ppl;
		/* Products are last cycle. Flags above match that cycle after blanking. */
		box2_bad_r <= box2_hand_r ||
			(!two_ppl_r && (nest_b_r || nest_a_r ||
			 (ov2_r && ((inter_r > (ba_r >> 1)) || (inter_r > (aa_r >> 1))))));

		second_body_r <= second_body;
		mot_big_r <= mot_big;
		mot_big2_r <= mot_big2;
		walk_follow_r <= walk_follow;
		squat_follow_r <= squat_follow;
		fall_follow_r <= fall_follow;
		ar_stand_r <= ar_stand;
		smear_mot_r <= smear_mot;
		lock_union_r <= lock_union;
		mot_hand_r <= mot_hand;
		short_vs_r <= short_vs_lock;
		vis_on_r <= vis_on;
		mot_on_r <= mot_on;
		person_r <= person;
		now_lie_r <= now_lie;
		frag_lie_r <= frag_lie;
		fal_pend_r <= fal_pend;
		ir_r <= ir;
		ir_now_r <= ir_now;
		ac_r <= ac;
		leave_block_r <= leave_block;
		leave_ready_r <= leave_ready;
		heat_lost_r <= heat_lost;
		fall_r <= fall;
		mbh_r <= mbh;
		mcy_r <= mcy;
		sc_r <= sc;
		ix_r <= ix;
		iy_r <= iy;
		lie_x0_r <= lie_x0;
		lie_x1_r <= lie_x1;
		lie_y0_r <= lie_y0;
		lie_y1_r <= lie_y1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		vs_d       <= 1'b0;
		vis_hold   <= 8'd0;
		mot_hold   <= 7'd0;
		ir_hold    <= 6'd0;
		have_box   <= 1'b0;
		have_box2  <= 1'b0;
		box2_hold  <= 7'd0;
		seen_stand <= 1'b0;
		fal_hold   <= 1'b0;
		lie_seen   <= 1'b0;
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
		px0 <= 11'd0;
		py0 <= 11'd0;
		px1 <= 11'd0;
		py1 <= 11'd0;
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
		box_show2 <= 1'b0;
		box_x0_2  <= 11'd0;
		box_y0_2  <= 11'd0;
		box_x1_2  <= 11'd0;
		box_y1_2  <= 11'd0;
	end else begin
		vs_d <= i_vs;
		if (vs_tick) begin
			if (pd_on)
				vis_hold <= 8'd255;
			else if (vis_hold != 8'd0)
				vis_hold <= vis_hold - 8'd1;
			if (ir_now_r)
				ir_hold <= 6'd40;
			else if (ir_hold != 6'd0)
				ir_hold <= ir_hold - 6'd1;
			if (mot_big_r || mot_big2_r)
				mot_hold <= 7'd90;
			else if (mot_hold != 7'd0)
				mot_hold <= mot_hold - 7'd1;

			if (box2_bad_r) begin
				have_box2 <= 1'b0;
				box2_hold <= 7'd0;
			end else if (second_body_r) begin
				px0 <= mot_x0_s;
				py0 <= mot_y0_s;
				px1 <= mot_x1_s;
				py1 <= mot_y1_s;
				have_box2 <= 1'b1;
				box2_hold <= 7'd90;
			end else if (mot_big2_r) begin
				px0 <= mot_x0_2s;
				py0 <= mot_y0_2s;
				px1 <= mot_x1_2s;
				py1 <= mot_y1_2s;
				have_box2 <= 1'b1;
				box2_hold <= 7'd90;
			end else if (vis_on_r && have_box2) begin
				/* occupy: second person standing still keeps last box2 */
			end else if (box2_hold != 7'd0)
				box2_hold <= box2_hold - 7'd1;
			else
				have_box2 <= 1'b0;

			if (mot_big_r && !second_body_r) begin
				if (mot_big2_r || walk_follow_r || squat_follow_r ||
				    fall_follow_r || ar_stand_r) begin
					lx0 <= mot_x0_s;
					ly0 <= mot_y0_s;
					lx1 <= mot_x1_s;
					ly1 <= mot_y1_s;
				end else if (smear_mot_r && seen_stand && have_box) begin
					if (mot_x0_s < lx0) lx0 <= mot_x0_s;
					if (mot_x1_s > lx1) lx1 <= mot_x1_s;
				end else if (lock_union_r) begin
					if (mot_x0_s < lx0) lx0 <= mot_x0_s;
					if (mot_y0_s < ly0) ly0 <= mot_y0_s;
					if (mot_x1_s > lx1) lx1 <= mot_x1_s;
					if (mot_y1_s > ly1) ly1 <= mot_y1_s;
				end else if (mot_hand_r) begin
					if (mot_x0_s < lx0) lx0 <= mot_x0_s;
					if (mot_x1_s > lx1) lx1 <= mot_x1_s;
				end else if (short_vs_r) begin
					/* Tiny stub: keep the body. */
				end else begin
					lx0 <= mot_x0_s;
					ly0 <= mot_y0_s;
					lx1 <= mot_x1_s;
					ly1 <= mot_y1_s;
				end
				have_box  <= 1'b1;
				still_cnt <= 8'd0;
				if (walk_follow_r) begin
					walk_cnt <= 5'd31;
					fal_hold <= 1'b0;
				end else if (walk_cnt != 5'd0)
					walk_cnt <= walk_cnt - 5'd1;
				if (ar_stand_r) begin
					seen_stand <= 1'b1;
					stand_h    <= mbh_r;
					stand_cy   <= mcy_r;
					stand_y1   <= mot_y1_s;
					peak_cy    <= mcy_r;
					peak_y1    <= mot_y1_s;
					fal_hold   <= 1'b0;
					lie_seen   <= 1'b0;
				end else if (squat_follow_r) begin
					peak_cy <= stand_cy;
					peak_y1 <= stand_y1;
				end else if (seen_stand && !walk_follow_r &&
				            (!smear_mot_r || (mot_y1_s > (stand_y1 + 11'd80)))) begin
					if (mcy_r > peak_cy)
						peak_cy <= mcy_r;
					if (mot_y1_s > peak_y1)
						peak_y1 <= mot_y1_s;
				end
				last_cx <= (mot_x0_s + mot_x1_s) >> 1;
				have_cx <= 1'b1;
			end else begin
				if (still_cnt != 8'd255)
					still_cnt <= still_cnt + 8'd1;
				if (walk_cnt != 5'd0)
					walk_cnt <= walk_cnt - 5'd1;
			end

			if (walk_follow_r || squat_follow_r || ar_stand_r) begin
				fal_hold  <= 1'b0;
				lie_seen  <= 1'b0;
				leave_cnt <= 9'd0;
			end else begin
				if (now_lie_r || frag_lie_r)
					lie_seen <= 1'b1;
				if (fal_pend_r && (still_cnt >= 8'd75) && ir_r) begin
					if (!fal_hold && (cx >= 11'd200) && (last_w > 11'd80)) begin
						lx0 <= lie_x0_r;
						lx1 <= lie_x1_r;
						ly0 <= lie_y0_r;
						ly1 <= lie_y1_r;
					end
					fal_hold <= 1'b1;
				end else if (!ir_r)
					fal_hold <= 1'b0;
			end

			if (leave_block_r)
				leave_cnt <= 9'd0;
			else if (leave_ready_r) begin
				if (leave_cnt != 9'd480)
					leave_cnt <= leave_cnt + 9'd1;
			end else
				leave_cnt <= 9'd0;

			if (heat_lost_r ||
			    (leave_ready_r && !fal_hold && !fal_pend_r &&
			     (leave_cnt >= 9'd180))) begin
				seen_stand <= 1'b0;
				fal_hold   <= 1'b0;
				lie_seen   <= 1'b0;
				have_box   <= 1'b0;
				have_box2  <= 1'b0;
				box2_hold  <= 7'd0;
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

			score    <= sc_r;
			ir_x     <= (ix_r > 11'd31) ? 5'd31 : ix_r[4:0];
			ir_y     <= (iy_r > 11'd23) ? 5'd23 : iy_r[4:0];
			box_x0   <= lx0;
			box_y0   <= ly0;
			box_x1   <= lx1;
			box_y1   <= ly1;
			box_show <= mot_on_r || have_box || fal_hold;
			box_x0_2  <= px0;
			box_y0_2  <= py0;
			box_x1_2  <= px1;
			box_y1_2  <= py1;
			box_show2 <= have_box2 && !box2_bad_r &&
				(mot_on_r || vis_on_r || fal_hold);

			if (fall_r) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd4;
			end else if (heat_lost_r) begin
				evt_on   <= 1'b0;
				evt_code <= 3'd0;
			end else if (fal_pend_r && ir_r) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd3;
			end else if (ir_r && (person_r || mot_on_r)) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd3;
			end else if (person_r || mot_on_r) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd1;
			end else if (ir_r) begin
				evt_on   <= 1'b1;
				evt_code <= 3'd2;
			end else if (ac_r) begin
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
