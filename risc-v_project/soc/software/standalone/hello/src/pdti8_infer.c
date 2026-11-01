#include "pdti8_infer.h"
#include "http.h"

static int32_t qapply(int32_t x, int32_t m, int32_t shift)
{
    int64_t ab = (int64_t)x * (int64_t)m + (1LL << 30);
    int32_t h = (int32_t)(ab >> 31);
    if (shift < 0)
        return h >> (-shift);
    if (shift > 0)
        return h << shift;
    return h;
}

static int8_t sat8(int32_t x)
{
    if (x > 127) return 127;
    if (x < -128) return -128;
    return (int8_t)x;
}

static int8_t buf0[48 * 48 * 16];
static int8_t buf1[48 * 48 * 16];

static void dw3(const int8_t *src, int8_t *dst,
    int ih, int iw, int ic, int dm, int stride,
    int izp, int ozp,
    const int8_t *w, const int32_t *b, const int32_t *m, const int32_t *s)
{
    int oc = ic * dm;
    int oh = (ih + stride - 1) / stride;
    int ow = (iw + stride - 1) / stride;
    int pad = ((oh - 1) * stride + 3 - ih);
    if (pad < 0) pad = 0;
    int ph = pad / 2;
    int oy, ox, oc_i, ky, kx;
    for (oy = 0; oy < oh; oy++) {
        for (ox = 0; ox < ow; ox++) {
            for (oc_i = 0; oc_i < oc; oc_i++) {
                int32_t acc = b[oc_i];
                int in_c = oc_i / dm;
                for (ky = 0; ky < 3; ky++) {
                    int iy = oy * stride + ky - ph;
                    if ((unsigned)iy >= (unsigned)ih) continue;
                    for (kx = 0; kx < 3; kx++) {
                        int ix = ox * stride + kx - ph;
                        if ((unsigned)ix >= (unsigned)iw) continue;
                        acc += (src[(iy * iw + ix) * ic + in_c] - izp) *
                               w[(ky * 3 + kx) * oc + oc_i];
                    }
                }
                acc = qapply(acc, m[oc_i], s[oc_i]) + ozp;
                dst[(oy * ow + ox) * oc + oc_i] = sat8(acc);
            }
        }
        if ((oy & 7) == 0)
            http_poll();
    }
}

static void conv1x1(const int8_t *src, int8_t *dst,
    int ih, int iw, int ic, int oc,
    int izp, int ozp,
    const int8_t *w, const int32_t *b, const int32_t *m, const int32_t *s)
{
    int n = ih * iw;
    int i, oc_i, c;
    for (i = 0; i < n; i++) {
        const int8_t *px = src + i * ic;
        int8_t *py = dst + i * oc;
        for (oc_i = 0; oc_i < oc; oc_i++) {
            int32_t acc = b[oc_i];
            const int8_t *ww = w + oc_i * ic;
            for (c = 0; c < ic; c++)
                acc += (px[c] - izp) * ww[c];
            acc = qapply(acc, m[oc_i], s[oc_i]) + ozp;
            py[oc_i] = sat8(acc);
        }
        if ((i & 63) == 0)
            http_poll();
    }
}

static void avgpool_valid3(const int8_t *src, int8_t *dst, int ic,
    int izp, int ozp, int32_t mult, int32_t shift)
{
    int c, y, x;
    for (c = 0; c < ic; c++) {
        int32_t acc = 0;
        for (y = 0; y < 3; y++)
            for (x = 0; x < 3; x++)
                acc += src[(y * 3 + x) * ic + c] - izp;
        dst[c] = sat8(qapply(acc, mult, shift) + ozp);
    }
}

extern const int8_t pd_w0[];
extern const int32_t pd_b0[];
extern const int32_t pd_m0[];
extern const int32_t pd_s0[];
extern const int8_t pd_w1[];
extern const int32_t pd_b1[];
extern const int32_t pd_m1[];
extern const int32_t pd_s1[];
extern const int8_t pd_w2[];
extern const int32_t pd_b2[];
extern const int32_t pd_m2[];
extern const int32_t pd_s2[];
extern const int8_t pd_w3[];
extern const int32_t pd_b3[];
extern const int32_t pd_m3[];
extern const int32_t pd_s3[];
extern const int8_t pd_w4[];
extern const int32_t pd_b4[];
extern const int32_t pd_m4[];
extern const int32_t pd_s4[];
extern const int8_t pd_w5[];
extern const int32_t pd_b5[];
extern const int32_t pd_m5[];
extern const int32_t pd_s5[];
extern const int8_t pd_w6[];
extern const int32_t pd_b6[];
extern const int32_t pd_m6[];
extern const int32_t pd_s6[];
extern const int8_t pd_w7[];
extern const int32_t pd_b7[];
extern const int32_t pd_m7[];
extern const int32_t pd_s7[];
extern const int8_t pd_w8[];
extern const int32_t pd_b8[];
extern const int32_t pd_m8[];
extern const int32_t pd_s8[];
extern const int8_t pd_w9[];
extern const int32_t pd_b9[];
extern const int32_t pd_m9[];
extern const int32_t pd_s9[];
extern const int8_t pd_w10[];
extern const int32_t pd_b10[];
extern const int32_t pd_m10[];
extern const int32_t pd_s10[];
extern const int8_t pd_w11[];
extern const int32_t pd_b11[];
extern const int32_t pd_m11[];
extern const int32_t pd_s11[];
extern const int8_t pd_w12[];
extern const int32_t pd_b12[];
extern const int32_t pd_m12[];
extern const int32_t pd_s12[];
extern const int8_t pd_w13[];
extern const int32_t pd_b13[];
extern const int32_t pd_m13[];
extern const int32_t pd_s13[];
extern const int8_t pd_w14[];
extern const int32_t pd_b14[];
extern const int32_t pd_m14[];
extern const int32_t pd_s14[];
extern const int8_t pd_w15[];
extern const int32_t pd_b15[];
extern const int32_t pd_m15[];
extern const int32_t pd_s15[];
extern const int8_t pd_w16[];
extern const int32_t pd_b16[];
extern const int32_t pd_m16[];
extern const int32_t pd_s16[];
extern const int8_t pd_w17[];
extern const int32_t pd_b17[];
extern const int32_t pd_m17[];
extern const int32_t pd_s17[];
extern const int8_t pd_w18[];
extern const int32_t pd_b18[];
extern const int32_t pd_m18[];
extern const int32_t pd_s18[];
extern const int8_t pd_w19[];
extern const int32_t pd_b19[];
extern const int32_t pd_m19[];
extern const int32_t pd_s19[];
extern const int8_t pd_w20[];
extern const int32_t pd_b20[];
extern const int32_t pd_m20[];
extern const int32_t pd_s20[];
extern const int8_t pd_w21[];
extern const int32_t pd_b21[];
extern const int32_t pd_m21[];
extern const int32_t pd_s21[];
extern const int8_t pd_w22[];
extern const int32_t pd_b22[];
extern const int32_t pd_m22[];
extern const int32_t pd_s22[];
extern const int8_t pd_w23[];
extern const int32_t pd_b23[];
extern const int32_t pd_m23[];
extern const int32_t pd_s23[];
extern const int8_t pd_w24[];
extern const int32_t pd_b24[];
extern const int32_t pd_m24[];
extern const int32_t pd_s24[];
extern const int8_t pd_w25[];
extern const int32_t pd_b25[];
extern const int32_t pd_m25[];
extern const int32_t pd_s25[];
extern const int8_t pd_w26[];
extern const int32_t pd_b26[];
extern const int32_t pd_m26[];
extern const int32_t pd_s26[];
extern const int8_t pd_w28[];
extern const int32_t pd_b28[];
extern const int32_t pd_m28[];
extern const int32_t pd_s28[];

void pdti8_run(const int8_t *in96, int8_t *person, int8_t *no_person)
{
    const int8_t *src = in96;
    int8_t *dst = buf0;
    dw3(src, dst, 96, 96, 1, 8, 2, -1, -128, pd_w0, pd_b0, pd_m0, pd_s0);
    http_poll();
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 48, 48, 8, 1, 1, -128, -128, pd_w1, pd_b1, pd_m1, pd_s1);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 48, 48, 8, 16, -128, -128, pd_w2, pd_b2, pd_m2, pd_s2);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 48, 48, 16, 1, 2, -128, -128, pd_w3, pd_b3, pd_m3, pd_s3);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 24, 24, 16, 32, -128, -128, pd_w4, pd_b4, pd_m4, pd_s4);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 24, 24, 32, 1, 1, -128, -128, pd_w5, pd_b5, pd_m5, pd_s5);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 24, 24, 32, 32, -128, -128, pd_w6, pd_b6, pd_m6, pd_s6);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 24, 24, 32, 1, 2, -128, -128, pd_w7, pd_b7, pd_m7, pd_s7);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 12, 12, 32, 64, -128, -128, pd_w8, pd_b8, pd_m8, pd_s8);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 12, 12, 64, 1, 1, -128, -128, pd_w9, pd_b9, pd_m9, pd_s9);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 12, 12, 64, 64, -128, -128, pd_w10, pd_b10, pd_m10, pd_s10);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 12, 12, 64, 1, 2, -128, -128, pd_w11, pd_b11, pd_m11, pd_s11);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 64, 128, -128, -128, pd_w12, pd_b12, pd_m12, pd_s12);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w13, pd_b13, pd_m13, pd_s13);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w14, pd_b14, pd_m14, pd_s14);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w15, pd_b15, pd_m15, pd_s15);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w16, pd_b16, pd_m16, pd_s16);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w17, pd_b17, pd_m17, pd_s17);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w18, pd_b18, pd_m18, pd_s18);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w19, pd_b19, pd_m19, pd_s19);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w20, pd_b20, pd_m20, pd_s20);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 1, -128, -128, pd_w21, pd_b21, pd_m21, pd_s21);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 6, 6, 128, 128, -128, -128, pd_w22, pd_b22, pd_m22, pd_s22);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 6, 6, 128, 1, 2, -128, -128, pd_w23, pd_b23, pd_m23, pd_s23);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 3, 3, 128, 256, -128, -128, pd_w24, pd_b24, pd_m24, pd_s24);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    dw3(src, dst, 3, 3, 256, 1, 1, -128, -128, pd_w25, pd_b25, pd_m25, pd_s25);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 3, 3, 256, 256, -128, -128, pd_w26, pd_b26, pd_m26, pd_s26);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    avgpool_valid3(src, dst, 256, -128, -128, 1908874354, -3);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    conv1x1(src, dst, 1, 1, 256, 2, -128, -1, pd_w28, pd_b28, pd_m28, pd_s28);
    src = dst; dst = (dst == buf0) ? buf1 : buf0;
    *no_person = src[0];
    *person = src[1];
}
