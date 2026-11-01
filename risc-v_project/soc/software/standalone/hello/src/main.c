#include "bsp.h"
#include "riscv.h"
#include "pdti8_infer.h"
#include "task3.h"
#include "http.h"

#define GRAY_FRAME  (IO_APB_SLAVE_0_INPUT + 0x4)
#define GRAY_STAT   (IO_APB_SLAVE_0_INPUT + 0x8)
#define GRAY_EVT    (IO_APB_SLAVE_0_INPUT + 0xC)
#define GRAY_PD     (IO_APB_SLAVE_0_INPUT + 0x10)
#define GRAY_BOX0   (IO_APB_SLAVE_0_INPUT + 0x14)
#define GRAY_BOX1   (IO_APB_SLAVE_0_INPUT + 0x18)
#define GRAY_BOX2   (IO_APB_SLAVE_0_INPUT + 0x30)
#define GRAY_BOX3   (IO_APB_SLAVE_0_INPUT + 0x34)
#define GRAY_VOICE  (IO_APB_SLAVE_0_INPUT + 0x24)
#define GRAY_VPLAY  (IO_APB_SLAVE_0_INPUT + 0x28)
#define GRAY_LP     (IO_APB_SLAVE_0_INPUT + 0x2C)

static const char *evt_name(uint32_t code)
{
    switch (code) {
    case 1: return "运动";
    case 2: return "红外";
    case 3: return "进入";
    case 4: return "跌倒";
    case 5: return "过热";
    default: return "空闲";
    }
}

static int pose_said, said_multi, said_person, last_ntrk, vcool, idle_arm;

static int pose_track(int code, int bw, int bh, int y0, int y1, int vx)
{
    /* No 00017 stand. Pose only on IN — leftover MOT box on empty stays silent. */
    if (code != 3)
        return 0;
    if (vx > 24 || vx < -24)
        return 19;
    if (bh < 280 && y1 > 500 && y0 > 200)
        return 33;
    if (bh < 400 && y0 > 180)
        return 18;
    return 0;
}

static uint8_t gray_now[T3_GRAY_N];
static uint8_t gray_prev[T3_GRAY_N];
static uint8_t thumb[T3_THUMB_N];
static int8_t  live_img[T3_GRAY_N];
static int     voice_hold;

static int voice_update(int code)
{
    if (code == 3 || code == 4 || code == 5)
        voice_hold = 8;
    if (voice_hold > 0) {
        voice_hold--;
        return 1;
    }
    return 0;
}

static void read_gray(void)
{
    uint32_t i;
    for (i = 0; i < T3_GRAY_N; i++) {
        uint32_t p = read_u32(IO_APB_SLAVE_0_INPUT + 0x1000 + (i << 2)) & 0xff;
        gray_now[i] = (uint8_t)p;
        live_img[i] = (int8_t)((int)p - 128);
    }
}

void main()
{
    int8_t person, nop;
    uint32_t n, t0, dt, seq;
    int pd_sticky, pd_miss, empty_cnt, lp, lp_prev, nobox_cnt;
    int have_prev;
    uint32_t last_lp_tx;

    csr_write(mstatus, 0);
    csr_write(mie, 0);

    bsp_printf("pdti8 selftest start\r\n");
    t0 = clint_getTimeLow(SYSTEM_CLINT_CTRL);
    pdti8_run(pd_img_person, &person, &nop);
    dt = clint_getTimeLow(SYSTEM_CLINT_CTRL) - t0;
    bsp_printf("static person p=%d n=%d\r\n", (int)person, (int)nop);
    if (person > nop)
        bsp_printf("static person OK\r\n");
    else
        bsp_printf("static person FAIL\r\n");
    (void)dt;

    pdti8_run(pd_img_noperson, &person, &nop);
    bsp_printf("static noperson p=%d n=%d %s\r\n",
               (int)person, (int)nop,
               (person < nop) ? "OK" : "FAIL");

    t3_track_init();
    n = 0;
    seq = 0;
    pd_sticky = 0;
    pd_miss = 0;
    empty_cnt = 0;
    lp = 0;
    lp_prev = 0;
    nobox_cnt = 0;
    have_prev = 0;
    person = 0;
    nop = 0;
    voice_hold = 0;
    last_lp_tx = 0;
    idle_arm = 0;
    bsp_printf("voice UART J7-38/37 + I2C mux J7-39/40\r\n");
    {
        int vself = 0;
        voice_hold = 0;
        vself = voice_update(4);
        if (vself)
            bsp_printf("voice selftest OK\r\n");
        else
            bsp_printf("voice selftest FAIL\r\n");
        voice_hold = 0;
    }

    while (1) {
        http_poll();
        uint32_t fr = read_u32(GRAY_FRAME) & 0xffff;
        uint32_t st = read_u32(GRAY_STAT);
        uint32_t ev = read_u32(GRAY_EVT);
        uint32_t b0 = read_u32(GRAY_BOX0);
        uint32_t b1 = read_u32(GRAY_BOX1);
        uint32_t b2 = read_u32(GRAY_BOX2);
        uint32_t b3 = read_u32(GRAY_BOX3);
        uint32_t score = st & 0xff;
        uint32_t ta = (st >> 8) & 0xff;
        uint32_t to = (st >> 16) & 0xff;
        uint32_t sht = (st >> 24) & 0xff;
        uint32_t code = (ev >> 1) & 7;
        uint32_t mot = (ev >> 4) & 1;
        uint32_t box2_on = (ev >> 5) & 1;
        uint32_t x0 = b0 & 0x7ff, y0 = (b0 >> 16) & 0x7ff;
        uint32_t x1 = b1 & 0x7ff, y1 = (b1 >> 16) & 0x7ff;
        uint32_t x0b = b2 & 0x7ff, y0b = (b2 >> 16) & 0x7ff;
        uint32_t x1b = b3 & 0x7ff, y1b = (b3 >> 16) & 0x7ff;
        uint32_t vv = read_u32(GRAY_VOICE);
        uint32_t lpr = read_u32(GRAY_LP);
        uint32_t vtrk = vv & 0xffff;
        uint32_t vrx = (vv >> 16) & 1;
        uint32_t vsw = (vv >> 17) & 1;
        uint32_t t_ms, pd_on, pd_sc, i, s, mn, mx;
        t3_det_t dets[T3_MAX_TRK];
        t3_det_t blobs[T3_MAX_TRK];
        t3_trk_t trks[T3_MAX_TRK];
        int nd, ntrk, nblob, bi, run_nn, fus_evt, fus_box, voice, box2_vis;
        uint32_t bw, bh, bw2, bh2;
        uint8_t has_thumb;

        fus_evt = (code == 1 || code == 3 || code == 4);
        bw = (x1 > x0) ? (x1 - x0) : 0;
        bh = (y1 > y0) ? (y1 - y0) : 0;
        fus_box = fus_evt && (bw > 80) && (bh > 40);

        if (!fus_box && code != 4)
            nobox_cnt++;
        else
            nobox_cnt = 0;
        if (nobox_cnt >= 3)
            pd_sticky = 0;
        lp = (int)(lpr & 1u);
        if (lp && !lp_prev)
            write_u32(11, GRAY_VPLAY);
        if (!lp && lp_prev)
            write_u32(12, GRAY_VPLAY);
        lp_prev = lp;

        voice = voice_update((int)code);

        /* Empty: keep HDMI/sensors, never run TinyML, thin UDP. FPGA box wakes us. */
        if (lp && !fus_box && code != 4) {
            t3_track_clear();
            ntrk = 0;
            dt = 0;
            pd_on = 0;
            pd_sc = 0;
            write_u32(0, GRAY_PD);
            t_ms = clint_getTimeLow(SYSTEM_CLINT_CTRL) / (SYSTEM_CLINT_HZ / 1000u);
            if ((t_ms - last_lp_tx) >= 400u) {
                last_lp_tx = t_ms;
                t3_send_event(seq, t_ms, (uint8_t)code, (uint8_t)score,
                              0, 0, (uint8_t)sht, (uint8_t)ta, (uint8_t)to,
                              1, (uint16_t)fr, 0,
                              trks, 0, (uint16_t)x0, (uint16_t)y0, (uint16_t)x1, (uint16_t)y1,
                              (uint8_t)mot, 0, (uint8_t)voice);
                t3_tx_settle();
                http_set_status(evt_name(code), (int)score, 0, 0, 1,
                                (int)sht, (int)ta, (int)to, 0, 0,
                                (int)x0, (int)y0, (int)x1, (int)y1, voice);
                bsp_printf("EVT %s lp=1 voice=%d vrx=%d vsw=%d vtk=%d ms=0 n=%d\r\n",
                           evt_name(code), voice, (int)vrx, (int)vsw, (int)vtrk, (int)n);
                seq++;
            }
            n++;
            continue;
        }

        read_gray();
        nd = 0;
        bw2 = (x1b > x0b) ? (x1b - x0b) : 0;
        bh2 = (y1b > y0b) ? (y1b - y0b) : 0;
        box2_vis = box2_on || ((bw2 > 80) && (bh2 > 40));
        if (fus_box)
            t3_add_box(dets, &nd, T3_MAX_TRK, (int)x0, (int)y0, (int)x1, (int)y1);
        if (box2_vis && (bw2 > 40) && (bh2 > 20))
            t3_add_box_force(dets, &nd, T3_MAX_TRK,
                             (int)x0b, (int)y0b, (int)x1b, (int)y1b);
        /* HDMI red boxes are FPGA-only. Do not invent extra gray96 blobs —
         * that reported 多人 while only one person had a red box. */
        if (!fus_box) {
            t3_track_clear();
            ntrk = 0;
        } else
            ntrk = t3_update(dets, nd, trks);

        run_nn = 1;
        dt = 0;
        if (run_nn) {
            t0 = clint_getTimeLow(SYSTEM_CLINT_CTRL);
            pdti8_run(live_img, &person, &nop);
            dt = clint_getTimeLow(SYSTEM_CLINT_CTRL) - t0;
            {
                int pd = (int)person - (int)nop;
                if (pd >= 20) {
                    pd_sticky = 1;
                    pd_miss = 0;
                    lp = 0;
                } else if (pd <= -30) {
                    pd_miss++;
                    if (pd_miss >= 3)
                        pd_sticky = 0;
                } else
                    pd_miss = 0;
                /* No heat: coat/hanger TinyML must not stick. Living body has TO. */
                if ((ta >= 8) && (ta <= 40) && (to <= ta + 3))
                    pd_sticky = 0;
            }
        }

        pd_on = pd_sticky ? 1 : 0;
        {
            int pd = (int)person - (int)nop;
            if (pd < 0) pd = -pd;
            if (pd > 127) pd = 127;
            pd_sc = (uint32_t)pd;
        }
        write_u32((pd_on << 8) | pd_sc, GRAY_PD);

        if (vcool > 0)
            vcool--;
        /* 00010 follows HDMI box2. Do not wait out a leftover 00017 cool. */
        if (box2_vis && !lp && (int)code != 4) {
            idle_arm = 0;
            if (vtrk == 10)
                said_multi = 1;
            else if (!said_multi) {
                write_u32(10, GRAY_VPLAY);
                pose_said = 1;
                said_person = 1;
                vcool = 8;
            }
        } else if (((int)code == 0 || lp) && !box2_vis) {
            /* Rearm only after 8 idle/LP ticks so a 1–2 frame IDL flicker
             * does not replay pose/multi. After 00010 skip pose. */
            if (idle_arm < 8)
                idle_arm++;
            if (idle_arm >= 8) {
                pose_said = 0;
                said_multi = 0;
                said_person = 0;
            }
        } else if (!lp && vcool == 0) {
            int vx0 = (ntrk > 0) ? (int)trks[0].vx : 0;
            int ptrk;
            idle_arm = 0;
            if (ntrk >= 2 && !said_multi && (int)code != 4) {
                write_u32(10, GRAY_VPLAY);
                said_multi = 1;
                pose_said = 1;
                said_person = 1;
                vcool = 16;
            } else if (pd_on && !said_person && (int)code == 1) {
                write_u32(8, GRAY_VPLAY);
                said_person = 1;
                vcool = 16;
            } else if (pd_on && fus_box && !pose_said && (int)code == 3) {
                ptrk = pose_track((int)code, (int)bw, (int)bh,
                                  (int)y0, (int)y1, vx0);
                if (ptrk) {
                    write_u32((uint32_t)ptrk, GRAY_VPLAY);
                    pose_said = 1;
                    said_person = 1;
                    vcool = 16;
                }
            }
        } else if (!lp) {
            idle_arm = 0;
        }
        last_ntrk = ntrk;

        s = 0; mn = 255; mx = 0;
        for (i = 0; i < T3_GRAY_N; i++) {
            uint32_t p = gray_now[i];
            s += p;
            if (p < mn) mn = p;
            if (p > mx) mx = p;
        }

        t_ms = clint_getTimeLow(SYSTEM_CLINT_CTRL) / (SYSTEM_CLINT_HZ / 1000u);
        has_thumb = 1;
        t3_make_thumb(gray_now, thumb);
        t3_send_event(seq, t_ms, (uint8_t)code, (uint8_t)score,
                      (uint8_t)pd_on, (uint8_t)pd_sc, (uint8_t)sht, (uint8_t)ta, (uint8_t)to,
                      (uint8_t)lp, (uint16_t)fr, (uint16_t)(dt / (SYSTEM_CLINT_HZ / 1000u)),
                      trks, ntrk, (uint16_t)x0, (uint16_t)y0, (uint16_t)x1, (uint16_t)y1,
                      (uint8_t)mot, has_thumb, (uint8_t)voice);
        if (has_thumb)
            t3_send_thumb(seq, thumb);
        t3_tx_settle();
        http_set_status(evt_name(code), (int)score, (int)pd_on, (int)pd_sc, lp,
                        (int)sht, (int)ta, (int)to, ntrk,
                        (int)(dt / (SYSTEM_CLINT_HZ / 1000u)),
                        (int)x0, (int)y0, (int)x1, (int)y1, voice);
        if (has_thumb)
            http_set_thumb(thumb, T3_THUMB_N);
        http_poll();

        bsp_printf(
            "EVT %s s=%d pd=%d/%d on=%d lp=%d voice=%d vrx=%d vsw=%d vtk=%d ntrk=%d b2=%d mean=%d fr=%d sht=%d ta=%d to=%d mot=%d box=%d,%d-%d,%d tid=%d px=%d,%d ms=%d n=%d\r\n",
            evt_name(code), (int)score, (int)person, (int)nop, (int)pd_on, lp, voice,
            (int)vrx, (int)vsw, (int)vtrk, ntrk, (int)box2_vis,
            (int)(s / T3_GRAY_N), (int)fr,
            (int)sht, (int)ta, (int)to, (int)mot,
            (int)x0, (int)y0, (int)x1, (int)y1,
            (ntrk > 0) ? (int)trks[0].tid : 0,
            (ntrk > 0) ? (int)trks[0].px : 0,
            (ntrk > 0) ? (int)trks[0].py : 0,
            (int)(dt / (SYSTEM_CLINT_HZ / 1000u)), (int)n);

        for (i = 0; i < T3_GRAY_N; i++)
            gray_prev[i] = gray_now[i];
        have_prev = 1;
        seq++;
        n++;
    }
}
