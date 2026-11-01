#include "task3.h"

#define DW 48
#define DH 48
#define DIFF_TH 28
#define MIN_AREA 40
#define MISS_MAX 2
#define IOU_NUM 3
#define IOU_DEN 10

static t3_trk_t s_trk[T3_MAX_TRK];
static uint16_t s_next_tid;
static uint8_t  s_fg[DW * DH];
static uint8_t  s_vis[DW * DH];
static int16_t  s_stk[DW * DH];

void t3_track_init(void)
{
    int i;
    for (i = 0; i < T3_MAX_TRK; i++)
        s_trk[i].used = 0;
    s_next_tid = 1;
}

void t3_track_clear(void)
{
    int i;
    for (i = 0; i < T3_MAX_TRK; i++)
        s_trk[i].used = 0;
}

static uint32_t box_iou(uint16_t ax0, uint16_t ay0, uint16_t ax1, uint16_t ay1,
                        uint16_t bx0, uint16_t by0, uint16_t bx1, uint16_t by1)
{
    uint16_t ix0 = ax0 > bx0 ? ax0 : bx0;
    uint16_t iy0 = ay0 > by0 ? ay0 : by0;
    uint16_t ix1 = ax1 < bx1 ? ax1 : bx1;
    uint16_t iy1 = ay1 < by1 ? ay1 : by1;
    uint32_t iw = (ix1 > ix0) ? (uint32_t)(ix1 - ix0) : 0;
    uint32_t ih = (iy1 > iy0) ? (uint32_t)(iy1 - iy0) : 0;
    uint32_t inter = iw * ih;
    uint32_t a = (uint32_t)(ax1 - ax0) * (uint32_t)(ay1 - ay0);
    uint32_t b = (uint32_t)(bx1 - bx0) * (uint32_t)(by1 - by0);
    uint32_t uni = a + b - inter;
    if (uni == 0)
        return 0;
    return (inter * 100) / uni;
}

static int flood(int sx, int sy, int *x0, int *y0, int *x1, int *y1, int *area)
{
    int sp = 0;
    int i = sy * DW + sx;
    if (!s_fg[i] || s_vis[i])
        return 0;
    s_stk[sp++] = (int16_t)i;
    s_vis[i] = 1;
    *x0 = *x1 = sx;
    *y0 = *y1 = sy;
    *area = 0;
    while (sp) {
        int p = s_stk[--sp];
        int x = p % DW;
        int y = p / DW;
        (*area)++;
        if (x < *x0) *x0 = x;
        if (x > *x1) *x1 = x;
        if (y < *y0) *y0 = y;
        if (y > *y1) *y1 = y;
        if (x > 0 && s_fg[p - 1] && !s_vis[p - 1]) {
            s_vis[p - 1] = 1;
            s_stk[sp++] = (int16_t)(p - 1);
        }
        if (x + 1 < DW && s_fg[p + 1] && !s_vis[p + 1]) {
            s_vis[p + 1] = 1;
            s_stk[sp++] = (int16_t)(p + 1);
        }
        if (y > 0 && s_fg[p - DW] && !s_vis[p - DW]) {
            s_vis[p - DW] = 1;
            s_stk[sp++] = (int16_t)(p - DW);
        }
        if (y + 1 < DH && s_fg[p + DW] && !s_vis[p + DW]) {
            s_vis[p + DW] = 1;
            s_stk[sp++] = (int16_t)(p + DW);
        }
    }
    return 1;
}

int t3_blobs(const uint8_t *g96, const uint8_t *prev96, t3_det_t *out, int maxn)
{
    int x, y, n = 0, i;
    for (y = 0; y < DH; y++) {
        for (x = 0; x < DW; x++) {
            int g = (int)g96[(y * 2) * 96 + (x * 2)];
            int p = (int)prev96[(y * 2) * 96 + (x * 2)];
            int d = g - p;
            if (d < 0) d = -d;
            i = y * DW + x;
            s_fg[i] = (d >= DIFF_TH) ? 1 : 0;
            s_vis[i] = 0;
        }
    }
    for (y = 0; y < DH; y++) {
        for (x = 0; x < DW; x++) {
            int x0, y0, x1, y1, area;
            if (!flood(x, y, &x0, &y0, &x1, &y1, &area))
                continue;
            if (area < MIN_AREA)
                continue;
            if (n < maxn) {
                out[n].x0 = (uint16_t)(x0 * 40);
                out[n].y0 = (uint16_t)(y0 * 22);
                out[n].x1 = (uint16_t)((x1 + 1) * 40);
                out[n].y1 = (uint16_t)((y1 + 1) * 22);
                out[n].area = (uint16_t)area;
                n++;
            } else {
                int w = 0;
                for (i = 1; i < maxn; i++)
                    if (out[i].area < out[w].area) w = i;
                if (area > (int)out[w].area) {
                    out[w].x0 = (uint16_t)(x0 * 40);
                    out[w].y0 = (uint16_t)(y0 * 22);
                    out[w].x1 = (uint16_t)((x1 + 1) * 40);
                    out[w].y1 = (uint16_t)((y1 + 1) * 22);
                    out[w].area = (uint16_t)area;
                }
            }
        }
    }
    return n;
}

static void add_box(t3_det_t *out, int *nd, int maxn,
                   int x0, int y0, int x1, int y1, int force)
{
    int i;
    uint32_t best = 0;
    if (x1 <= x0 || y1 <= y0)
        return;
    if (!force) {
        for (i = 0; i < *nd; i++) {
            uint32_t iou = box_iou((uint16_t)x0, (uint16_t)y0, (uint16_t)x1, (uint16_t)y1,
                                   out[i].x0, out[i].y0, out[i].x1, out[i].y1);
            if (iou > best) best = iou;
        }
        if (best >= 25)
            return;
    }
    if (*nd >= maxn)
        return;
    i = *nd;
    out[i].x0 = (uint16_t)x0;
    out[i].y0 = (uint16_t)y0;
    out[i].x1 = (uint16_t)x1;
    out[i].y1 = (uint16_t)y1;
    out[i].area = (uint16_t)(((x1 - x0) * (y1 - y0)) / 256);
    (*nd)++;
}

void t3_add_box(t3_det_t *out, int *nd, int maxn, int x0, int y0, int x1, int y1)
{
    add_box(out, nd, maxn, x0, y0, x1, y1, 0);
}

void t3_add_box_force(t3_det_t *out, int *nd, int maxn, int x0, int y0, int x1, int y1)
{
    add_box(out, nd, maxn, x0, y0, x1, y1, 1);
}

int t3_is_extra(const t3_det_t *pri, const t3_det_t *b)
{
    uint32_t iou, inter, ba;
    uint16_t bw, bh, ix0, iy0, ix1, iy1;
    if (!pri || !b)
        return 0;
    bw = (b->x1 > b->x0) ? (uint16_t)(b->x1 - b->x0) : 0;
    bh = (b->y1 > b->y0) ? (uint16_t)(b->y1 - b->y0) : 0;
    if (b->area < MIN_AREA || bw < 80 || bh < 40)
        return 0;
    ix0 = pri->x0 > b->x0 ? pri->x0 : b->x0;
    iy0 = pri->y0 > b->y0 ? pri->y0 : b->y0;
    ix1 = pri->x1 < b->x1 ? pri->x1 : b->x1;
    iy1 = pri->y1 < b->y1 ? pri->y1 : b->y1;
    inter = 0;
    if (ix1 > ix0 && iy1 > iy0)
        inter = (uint32_t)(ix1 - ix0) * (uint32_t)(iy1 - iy0);
    ba = (uint32_t)bw * (uint32_t)bh;
    if (ba && (inter * 100 / ba) >= 40)
        return 0;
    iou = box_iou(pri->x0, pri->y0, pri->x1, pri->y1, b->x0, b->y0, b->x1, b->y1);
    return (iou < 25) ? 1 : 0;
}

static int alloc_slot(void)
{
    int i;
    for (i = 0; i < T3_MAX_TRK; i++)
        if (!s_trk[i].used)
            return i;
    return -1;
}

int t3_update(const t3_det_t *dets, int nd, t3_trk_t *dst)
{
    uint8_t used_t[T3_MAX_TRK];
    uint8_t used_d[T3_MAX_TRK];
    int i, j, nout = 0;
    for (i = 0; i < T3_MAX_TRK; i++) {
        used_t[i] = 0;
        used_d[i] = 0;
    }
    for (i = 0; i < nd && i < T3_MAX_TRK; i++) {
        int best = -1;
        uint32_t best_iou = 0;
        for (j = 0; j < T3_MAX_TRK; j++) {
            uint32_t iou;
            if (!s_trk[j].used || used_t[j])
                continue;
            iou = box_iou(dets[i].x0, dets[i].y0, dets[i].x1, dets[i].y1,
                          s_trk[j].x0, s_trk[j].y0, s_trk[j].x1, s_trk[j].y1);
            if (iou > best_iou) {
                best_iou = iou;
                best = j;
            }
        }
        if (best >= 0 && best_iou >= 12) {
            t3_trk_t *t = &s_trk[best];
            int16_t cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
            int16_t cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
            t->vx = (int16_t)(cx - t->cx);
            t->vy = (int16_t)(cy - t->cy);
            t->cx = cx;
            t->cy = cy;
            t->px = (int16_t)(cx + t->vx);
            t->py = (int16_t)(cy + t->vy);
            if (t->px < 0) t->px = 0;
            if (t->py < 0) t->py = 0;
            if (t->px > 1919) t->px = 1919;
            if (t->py > 1079) t->py = 1079;
            t->x0 = dets[i].x0;
            t->y0 = dets[i].y0;
            t->x1 = dets[i].x1;
            t->y1 = dets[i].y1;
            t->age = 0;
            used_t[best] = 1;
            used_d[i] = 1;
        }
    }
    /* Two FPGA boxes: do not steal the first TID by 300 px distance. */
    for (i = 0; nd < 2 && i < nd && i < T3_MAX_TRK; i++) {
        int best = -1;
        int best_d2 = 300 * 300;
        int16_t cx, cy;
        if (used_d[i])
            continue;
        cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
        cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
        for (j = 0; j < T3_MAX_TRK; j++) {
            int dx, dy, d2;
            if (!s_trk[j].used || used_t[j])
                continue;
            dx = (int)cx - (int)s_trk[j].cx;
            dy = (int)cy - (int)s_trk[j].cy;
            d2 = dx * dx + dy * dy;
            if (d2 < best_d2) {
                best_d2 = d2;
                best = j;
            }
        }
        if (best >= 0) {
            t3_trk_t *t = &s_trk[best];
            t->vx = (int16_t)(cx - t->cx);
            t->vy = (int16_t)(cy - t->cy);
            t->cx = cx;
            t->cy = cy;
            t->px = (int16_t)(cx + t->vx);
            t->py = (int16_t)(cy + t->vy);
            if (t->px < 0) t->px = 0;
            if (t->py < 0) t->py = 0;
            if (t->px > 1919) t->px = 1919;
            if (t->py > 1079) t->py = 1079;
            t->x0 = dets[i].x0;
            t->y0 = dets[i].y0;
            t->x1 = dets[i].x1;
            t->y1 = dets[i].y1;
            t->age = 0;
            used_t[best] = 1;
            used_d[i] = 1;
        }
    }
    for (i = 0; i < nd && i < T3_MAX_TRK; i++) {
        int s;
        t3_trk_t *t;
        if (used_d[i])
            continue;
        s = alloc_slot();
        if (s < 0)
            continue;
        t = &s_trk[s];
        t->used = 1;
        t->age = 0;
        t->tid = s_next_tid++;
        if (s_next_tid == 0) s_next_tid = 1;
        t->x0 = dets[i].x0;
        t->y0 = dets[i].y0;
        t->x1 = dets[i].x1;
        t->y1 = dets[i].y1;
        t->cx = (int16_t)((dets[i].x0 + dets[i].x1) >> 1);
        t->cy = (int16_t)((dets[i].y0 + dets[i].y1) >> 1);
        t->vx = 0;
        t->vy = 0;
        t->px = t->cx;
        t->py = t->cy;
    }
    for (j = 0; j < T3_MAX_TRK; j++) {
        if (!s_trk[j].used)
            continue;
        if (!used_t[j]) {
            s_trk[j].age++;
            s_trk[j].px = (int16_t)(s_trk[j].cx + s_trk[j].vx);
            s_trk[j].py = (int16_t)(s_trk[j].cy + s_trk[j].vy);
            if (s_trk[j].age >= MISS_MAX)
                s_trk[j].used = 0;
        }
        if (s_trk[j].used && nout < T3_MAX_TRK)
            dst[nout++] = s_trk[j];
    }
    (void)IOU_NUM;
    (void)IOU_DEN;
    return nout;
}

void t3_make_thumb(const uint8_t *g96, uint8_t *th)
{
    int y, x;
    for (y = 0; y < T3_THUMB_H; y++)
        for (x = 0; x < T3_THUMB_W; x++)
            th[y * T3_THUMB_W + x] = g96[(y * 2) * 96 + (x * 2)];
}
