#include "task3.h"
#include "bsp.h"

#define GRAY_BINSTAT (IO_APB_SLAVE_0_INPUT + 0x1C)
#define GRAY_BIN     (IO_APB_SLAVE_0_INPUT + 0x20)

#define T3_MAGIC0 0x38
#define T3_MAGIC1 0x54
#define T3_MAGIC2 0x45
#define T3_MAGIC3 0x56
#define T3_VER    1
#define T3_EVT    0
#define T3_THUMB  1
#define T3_EVT_SZ 256
#define T3_PKT_SZ 256
#define T3_CHUNK  240

static void put_u16(uint8_t *p, uint16_t v)
{
    p[0] = (uint8_t)v;
    p[1] = (uint8_t)(v >> 8);
}

static void put_u32(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)v;
    p[1] = (uint8_t)(v >> 8);
    p[2] = (uint8_t)(v >> 16);
    p[3] = (uint8_t)(v >> 24);
}

void t3_send_bytes(const uint8_t *p, unsigned n)
{
    unsigned i;
    for (i = 0; i < n; i++) {
        unsigned spin = 0;
        while (read_u32(GRAY_BINSTAT) & 1u) {
            spin++;
            if (spin > 2000000u)
                return;
        }
        write_u32((uint32_t)p[i], GRAY_BIN);
    }
}

void t3_send_event(uint32_t seq, uint32_t t_ms, uint8_t evt, uint8_t score,
                   uint8_t pd_on, uint8_t conf, uint8_t sht, uint8_t ta, uint8_t to,
                   uint8_t lp, uint16_t fr, uint16_t infer_ms,
                   const t3_trk_t *trk, int ntrk,
                   uint16_t bx0, uint16_t by0, uint16_t bx1, uint16_t by1,
                   uint8_t mot, uint8_t has_thumb, uint8_t voice)
{
    uint8_t pkt[T3_EVT_SZ];
    int i, n;
    for (i = 0; i < T3_EVT_SZ; i++)
        pkt[i] = 0;
    pkt[0] = T3_MAGIC0;
    pkt[1] = T3_MAGIC1;
    pkt[2] = T3_MAGIC2;
    pkt[3] = T3_MAGIC3;
    pkt[4] = T3_VER;
    pkt[5] = T3_EVT;
    pkt[6] = (uint8_t)((lp ? 1 : 0) | (has_thumb ? 2 : 0) | (mot ? 4 : 0) | (voice ? 8 : 0));
    n = ntrk;
    if (n > T3_MAX_TRK) n = T3_MAX_TRK;
    if (n < 0) n = 0;
    pkt[7] = (uint8_t)n;
    put_u32(&pkt[8], seq);
    put_u32(&pkt[12], t_ms);
    pkt[16] = evt;
    pkt[17] = score;
    pkt[18] = pd_on;
    pkt[19] = conf;
    pkt[20] = sht;
    pkt[21] = ta;
    pkt[22] = to;
    pkt[23] = (uint8_t)n;
    put_u16(&pkt[24], fr);
    put_u16(&pkt[26], infer_ms);
    if (n > 0) {
        put_u16(&pkt[28], (uint16_t)trk[0].px);
        put_u16(&pkt[30], (uint16_t)trk[0].py);
    }
    for (i = 0; i < n; i++) {
        uint8_t *q = &pkt[32 + i * 16];
        put_u16(&q[0], trk[i].tid);
        q[2] = trk[i].age;
        q[3] = 0;
        put_u16(&q[4], trk[i].x0);
        put_u16(&q[6], trk[i].y0);
        put_u16(&q[8], trk[i].x1);
        put_u16(&q[10], trk[i].y1);
        put_u16(&q[12], (uint16_t)trk[i].cx);
        put_u16(&q[14], (uint16_t)trk[i].cy);
    }
    put_u16(&pkt[96], T3_THUMB_W);
    put_u16(&pkt[98], T3_THUMB_H);
    pkt[100] = has_thumb ? (uint8_t)((T3_THUMB_N + T3_CHUNK - 1) / T3_CHUNK) : 0;
    put_u16(&pkt[104], bx0);
    put_u16(&pkt[106], by0);
    put_u16(&pkt[108], bx1);
    put_u16(&pkt[110], by1);
    t3_send_bytes(pkt, T3_EVT_SZ);
}

void t3_send_thumb(uint32_t seq, const uint8_t *th)
{
    uint8_t pkt[T3_PKT_SZ];
    unsigned off = 0;
    uint8_t idx = 0;
    uint8_t nch = (uint8_t)((T3_THUMB_N + T3_CHUNK - 1) / T3_CHUNK);
    while (off < T3_THUMB_N) {
        unsigned i, n = T3_THUMB_N - off;
        if (n > T3_CHUNK) n = T3_CHUNK;
        for (i = 0; i < T3_PKT_SZ; i++)
            pkt[i] = 0;
        pkt[0] = T3_MAGIC0;
        pkt[1] = T3_MAGIC1;
        pkt[2] = T3_MAGIC2;
        pkt[3] = T3_MAGIC3;
        pkt[4] = T3_VER;
        pkt[5] = T3_THUMB;
        pkt[6] = idx;
        pkt[7] = nch;
        put_u32(&pkt[8], seq);
        put_u16(&pkt[12], (uint16_t)off);
        put_u16(&pkt[14], (uint16_t)n);
        for (i = 0; i < n; i++)
            pkt[16 + i] = th[off + i];
        t3_send_bytes(pkt, T3_PKT_SZ);
        off += n;
        idx++;
    }
}

void t3_tx_settle(void)
{
    volatile unsigned i;
    for (i = 0; i < 300000u; i++)
        ;
}
