#pragma once
#include <stdint.h>

#define T3_MAX_TRK  4
#define T3_THUMB_W  48
#define T3_THUMB_H  48
#define T3_THUMB_N  (T3_THUMB_W * T3_THUMB_H)
#define T3_GRAY_N   9216

typedef struct {
    uint16_t x0, y0, x1, y1;
    uint16_t area;
} t3_det_t;

typedef struct {
    uint16_t tid;
    uint8_t  used;
    uint8_t  age;
    uint16_t x0, y0, x1, y1;
    int16_t  cx, cy;
    int16_t  vx, vy;
    int16_t  px, py;
} t3_trk_t;

void t3_track_init(void);
void t3_track_clear(void);
int  t3_blobs(const uint8_t *g96, const uint8_t *prev96, t3_det_t *out, int maxn);
void t3_add_box(t3_det_t *out, int *nd, int maxn, int x0, int y0, int x1, int y1);
void t3_add_box_force(t3_det_t *out, int *nd, int maxn, int x0, int y0, int x1, int y1);
int  t3_is_extra(const t3_det_t *pri, const t3_det_t *b);
int  t3_update(const t3_det_t *dets, int nd, t3_trk_t *dst);

void t3_make_thumb(const uint8_t *g96, uint8_t *th);
void t3_send_bytes(const uint8_t *p, unsigned n);
void t3_send_event(uint32_t seq, uint32_t t_ms, uint8_t evt, uint8_t score,
                   uint8_t pd_on, uint8_t conf, uint8_t sht, uint8_t ta, uint8_t to,
                   uint8_t lp, uint16_t fr, uint16_t infer_ms,
                   const t3_trk_t *trk, int ntrk,
                   uint16_t bx0, uint16_t by0, uint16_t bx1, uint16_t by1,
                   uint8_t mot, uint8_t has_thumb, uint8_t voice);
void t3_send_thumb(uint32_t seq, const uint8_t *th);
void t3_tx_settle(void);
