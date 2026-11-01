#include "http.h"
#include "bsp.h"
#include <string.h>

#define TCP_BASE   IO_APB_SLAVE_0_INPUT
#define REG_ARM    (TCP_BASE + 0x38)
#define REG_STAT   (TCP_BASE + 0x40)
#define REG_RXB    (TCP_BASE + 0x44)
#define REG_TXB    (TCP_BASE + 0x48)
#define REG_KICK   (TCP_BASE + 0x4C)
#define REG_TXRST  (TCP_BASE + 0x50)

#define ST_LEN     0x0FFFu
#define ST_RXV     0x1000u
#define ST_TXB     0x2000u

#define ETH_HDR    14
#define IP_HDR     20
#define TCP_HDR    20
#define L2         (ETH_HDR + IP_HDR + TCP_HDR)

static const uint8_t local_mac[6] = {0x00, 0x0A, 0x35, 0x01, 0xFE, 0xC0};
static const uint8_t local_ip[4]  = {192, 168, 10, 10};

enum { LISTEN = 0, SYN_RCVD, ESTAB };

static int      tcp_st;
static uint8_t  peer_mac[6];
static uint8_t  peer_ip[4];
static uint16_t peer_port;
static uint32_t snd_nxt, rcv_nxt, iss;
static uint16_t ip_id;
#define TX_MAX     4096u
#define BMP_OFF    1078u
#define BMP_SZ     3382u

static uint8_t  rxbuf[2048];
static uint8_t  txbuf[4096];
static uint8_t  http_pkt[8192];
static uint8_t  thumb[48 * 48];
static int      have_thumb;

static char st_evt[16] = "空闲";
static int  st_score, st_pd_on, st_pd, st_lp, st_sht, st_ta, st_to;
static int  st_ntrk, st_ms, st_x0, st_y0, st_x1, st_y1, st_voice, st_arm;
static char hist[8][96];
static int  hist_n, hist_i;

static uint32_t crc32_eth(const uint8_t *p, unsigned n)
{
    uint32_t c = 0xFFFFFFFFu;
    unsigned i, b;
    for (i = 0; i < n; i++) {
        c ^= p[i];
        for (b = 0; b < 8; b++)
            c = (c & 1u) ? (c >> 1) ^ 0xEDB88320u : (c >> 1);
    }
    return ~c;
}

static uint16_t inet_cksum(const uint8_t *p, int n, uint32_t extra)
{
    uint32_t s = extra;
    int i;
    for (i = 0; i < n - 1; i += 2)
        s += ((uint32_t)p[i] << 8) | p[i + 1];
    if (n & 1)
        s += (uint32_t)p[n - 1] << 8;
    while (s >> 16)
        s = (s & 0xffffu) + (s >> 16);
    return (uint16_t)~s;
}

static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
static void put32(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);  p[3] = (uint8_t)v;
}
static uint16_t get16(const uint8_t *p) { return ((uint16_t)p[0] << 8) | p[1]; }
static uint32_t get32(const uint8_t *p)
{
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | p[3];
}

static int tx_busy(void) { return (read_u32(REG_STAT) & ST_TXB) ? 1 : 0; }

static void tx_frame(uint8_t *frame, unsigned n)
{
    unsigned i;
    uint32_t crc;
    unsigned spin = 0;
    while (tx_busy()) {
        if (++spin > 2000000u)
            return;
    }
    if (n < 60) {
        for (i = n; i < 60; i++)
            frame[i] = 0;
        n = 60;
    }
    if (n + 4u > TX_MAX)
        return;
    crc = crc32_eth(frame, n);
    frame[n + 0] = (uint8_t)crc;
    frame[n + 1] = (uint8_t)(crc >> 8);
    frame[n + 2] = (uint8_t)(crc >> 16);
    frame[n + 3] = (uint8_t)(crc >> 24);
    n += 4;
    write_u32(1, REG_TXRST);
    for (i = 0; i < n; i++)
        write_u32(frame[i], REG_TXB);
    write_u32(n, REG_KICK);
}

static void send_tcp(uint8_t flags, const uint8_t *payload, unsigned plen)
{
    uint8_t *f = txbuf;
    unsigned i;
    uint32_t extra;
    unsigned ip_len = IP_HDR + TCP_HDR + plen;

    memcpy(f + 0, peer_mac, 6);
    memcpy(f + 6, local_mac, 6);
    f[12] = 0x08; f[13] = 0x00;

    f[14] = 0x45; f[15] = 0x00;
    put16(f + 16, (uint16_t)ip_len);
    put16(f + 18, ++ip_id);
    f[20] = 0x40; f[21] = 0x00;
    f[22] = 64; f[23] = 6;
    f[24] = 0; f[25] = 0;
    memcpy(f + 26, local_ip, 4);
    memcpy(f + 30, peer_ip, 4);
    put16(f + 24, inet_cksum(f + 14, IP_HDR, 0));

    put16(f + 34, 80);
    put16(f + 36, peer_port);
    put32(f + 38, snd_nxt);
    put32(f + 42, rcv_nxt);
    f[46] = 0x50;
    f[47] = flags;
    put16(f + 48, 4096);
    f[50] = 0; f[51] = 0;
    f[52] = 0; f[53] = 0;
    if (plen && payload)
        memcpy(f + L2, payload, plen);

    extra = ((uint32_t)local_ip[0] << 8) | local_ip[1];
    extra += ((uint32_t)local_ip[2] << 8) | local_ip[3];
    extra += ((uint32_t)peer_ip[0] << 8) | peer_ip[1];
    extra += ((uint32_t)peer_ip[2] << 8) | peer_ip[3];
    extra += 6u;
    extra += (uint32_t)(TCP_HDR + plen);
    put16(f + 50, inet_cksum(f + 34, TCP_HDR + (int)plen, extra));

    tx_frame(f, L2 + plen);
    if (flags & 0x02)
        snd_nxt += 1;
    if (flags & 0x01)
        snd_nxt += 1;
    snd_nxt += plen;
    (void)i;
}

/* One Ethernet frame must stay <= 1518. 1400B MSS keeps IP+TCP+payload under MTU. */
#define TCP_MSS 1400u
static void send_tcp_body(const uint8_t *payload, unsigned plen)
{
    unsigned off = 0;
    if (!plen) {
        send_tcp(0x19, 0, 0);
        return;
    }
    while (off < plen) {
        unsigned n = plen - off;
        uint8_t flags = 0x18;
        if (n > TCP_MSS)
            n = TCP_MSS;
        if (off + n >= plen)
            flags = 0x19;
        send_tcp(flags, payload + off, n);
        off += n;
    }
}

static unsigned uitoa(char *d, unsigned v)
{
    char tmp[12];
    unsigned n = 0, i = 0;
    if (v == 0) { d[0] = '0'; return 1; }
    while (v) { tmp[n++] = (char)('0' + (v % 10)); v /= 10; }
    while (n) d[i++] = tmp[--n];
    return i;
}

static unsigned append(char *d, unsigned n, const char *s)
{
    while (*s) d[n++] = *s++;
    return n;
}

static unsigned kv(char *d, unsigned n, const char *k, const char *id)
{
    n = append(d, n, "<div class=kv><span>");
    n = append(d, n, k);
    n = append(d, n, "</span><b id=");
    n = append(d, n, id);
    n = append(d, n, ">");
    return n;
}

static unsigned build_index(char *d)
{
    unsigned n = 0;
    int k;
    n = append(d, n, "<!doctype html><html><head><meta charset=utf-8><title>智能监护</title>");
    n = append(d, n, "<style>");
    n = append(d, n, "body{margin:0;background:#0c1218;color:#e7eef5;font:15px/1.45 Segoe UI,sans-serif}");
    n = append(d, n, ".w{max-width:1040px;margin:0 auto;padding:22px}");
    n = append(d, n, "h1{margin:0;font-size:22px;letter-spacing:.06em}");
    n = append(d, n, ".s{color:#8aa0b4;margin:4px 0 18px}");
    n = append(d, n, ".g{display:grid;grid-template-columns:260px 1fr 1fr;gap:12px}");
    n = append(d, n, ".c{background:#15202b;border:1px solid #2b3c4d;border-radius:12px;padding:14px 16px}");
    n = append(d, n, ".c h2{margin:0 0 10px;font-size:12px;color:#79c4dc;letter-spacing:.14em}");
    n = append(d, n, ".kv{display:flex;justify-content:space-between;padding:7px 0;border-bottom:1px solid #243342}");
    n = append(d, n, ".kv b{color:#fff;font-weight:600}");
    n = append(d, n, "#v{width:100%;max-width:228px;aspect-ratio:1;image-rendering:pixelated;border-radius:8px;background:#0a0f14;display:block}");
    n = append(d, n, ".b{display:inline-block;margin:6px 6px 0 0;padding:8px 12px;background:#1d3a4c;color:#d9f3ff;border-radius:8px;text-decoration:none}");
    n = append(d, n, "pre{margin:0;color:#b7c6d4;white-space:pre-wrap}");
    n = append(d, n, ".span{grid-column:1/-1}</style></head><body><div class=w>");
    n = append(d, n, "<h1>智能监护系统</h1>");
    n = append(d, n, "<p class=s>192.168.10.10 · 视觉 / 红外 / 环境 三路融合</p>");
    n = append(d, n, "<p class=s>人员演示须距摄像头 2 米以上</p><div class=g>");

    n = append(d, n, "<div class=c><h2>实时画面</h2><img id=v src=/t.bmp width=228 height=228 alt=preview></div>");

    n = append(d, n, "<div class=c><h2>事件状态</h2>");
    n = kv(d, n, "当前事件", "e"); n = append(d, n, st_evt); n = append(d, n, "</b></div>");
    n = kv(d, n, "融合置信度", "sc"); n += uitoa(d + n, (unsigned)st_score); n = append(d, n, "</b></div>");
    n = kv(d, n, "语音在播", "vo"); n += uitoa(d + n, (unsigned)st_voice); n = append(d, n, "</b></div></div>");

    n = append(d, n, "<div class=c><h2>人体检测</h2>");
    n = kv(d, n, "TinyML 有人", "tm"); n += uitoa(d + n, (unsigned)st_pd_on);
    n = append(d, n, " / "); n += uitoa(d + n, (unsigned)st_pd); n = append(d, n, "</b></div>");
    n = kv(d, n, "轨迹数量", "nk"); n += uitoa(d + n, (unsigned)st_ntrk); n = append(d, n, "</b></div>");
    n = kv(d, n, "推理耗时 ms", "ms"); n += uitoa(d + n, (unsigned)st_ms); n = append(d, n, "</b></div></div>");

    n = append(d, n, "<div class=c><h2>环境传感</h2>");
    n = kv(d, n, "芯片结温 TA", "ta"); n += uitoa(d + n, (unsigned)st_ta); n = append(d, n, " ℃</b></div>");
    n = kv(d, n, "目标温度 TO", "to"); n += uitoa(d + n, (unsigned)st_to); n = append(d, n, " ℃</b></div>");
    n = kv(d, n, "空气温湿度", "sh"); n += uitoa(d + n, (unsigned)st_sht); n = append(d, n, " ℃</b></div></div>");

    n = append(d, n, "<div class=c><h2>目标跟踪</h2>");
    n = kv(d, n, "主目标框", "bx"); n += uitoa(d + n, (unsigned)st_x0);
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y0);
    n = append(d, n, " – "); n += uitoa(d + n, (unsigned)st_x1);
    n = append(d, n, ","); n += uitoa(d + n, (unsigned)st_y1); n = append(d, n, "</b></div>");
    n = kv(d, n, "低功耗", "lp"); n += uitoa(d + n, (unsigned)st_lp); n = append(d, n, "</b></div></div>");

    n = append(d, n, "<div class=c><h2>警戒使能</h2>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/a?1');return false\">开启警戒</a>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/a?0');return false\">关闭警戒</a>");
    n = kv(d, n, "当前", "ar");
    n = append(d, n, st_arm ? "已开启 入框响" : "已关闭 入框不响");
    n = append(d, n, "</b></div></div>");

    n = append(d, n, "<div class=c><h2>评委口播</h2>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/p?13');return false\">欢迎</a>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/p?14');return false\">介绍</a>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/p?16');return false\">开始</a>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/p?26');return false\">请看HDMI</a>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/p?27');return false\">请看网页</a>");
    n = append(d, n, "<a class=b href=# onclick=\"fetch('/p?15');return false\">结束</a></div>");

    n = append(d, n, "<div class='c span'><h2>事件历史</h2><pre id=h>");
    for (k = 0; k < hist_n; k++) {
        int idx = (hist_i - 1 - k);
        if (idx < 0) idx += 8;
        n = append(d, n, hist[idx]);
        n = append(d, n, "\n");
    }
    n = append(d, n, "</pre></div></div></div>");
    n = append(d, n, "<script>(function(){function t(){var i=new Image();");
    n = append(d, n, "i.onload=function(){v.src=i.src;fetch('/s').then(function(r){return r.json()}).then(function(j){");
    n = append(d, n, "e.textContent=j.evt;sc.textContent=j.score;vo.textContent=j.voice;");
    n = append(d, n, "tm.textContent=j.pd_on+' / '+j.pd;nk.textContent=j.ntrk;ms.textContent=j.ms;");
    n = append(d, n, "ta.textContent=j.ta+' ℃';to.textContent=j.to+' ℃';sh.textContent=j.sht+' ℃';");
    n = append(d, n, "bx.textContent=j.x0+','+j.y0+' – '+j.x1+','+j.y1;lp.textContent=j.lp;");
    n = append(d, n, "if(window.ar)ar.textContent=j.arm==1?'已开启 入框响':'已关闭 入框不响';");
    n = append(d, n, "h.textContent=(j.evt+' '+j.score+' '+j.ta+'/'+j.to+'\\n'+h.textContent).split('\\n').slice(0,8).join('\\n')");
    n = append(d, n, "}).finally(function(){setTimeout(t,2000)})};");
    n = append(d, n, "i.onerror=function(){setTimeout(t,2000)};i.src='/t.bmp?'+Date.now()}setTimeout(t,2000)})()</script>");
    n = append(d, n, "</body></html>");
    d[n] = 0;
    return n;
}

static unsigned build_json(char *d)
{
    unsigned n = 0;
    n = append(d, n, "{\"evt\":\""); n = append(d, n, st_evt);
    n = append(d, n, "\",\"score\":"); n += uitoa(d + n, (unsigned)st_score);
    n = append(d, n, ",\"pd_on\":"); n += uitoa(d + n, (unsigned)st_pd_on);
    n = append(d, n, ",\"pd\":"); n += uitoa(d + n, (unsigned)st_pd);
    n = append(d, n, ",\"ta\":"); n += uitoa(d + n, (unsigned)st_ta);
    n = append(d, n, ",\"to\":"); n += uitoa(d + n, (unsigned)st_to);
    n = append(d, n, ",\"sht\":"); n += uitoa(d + n, (unsigned)st_sht);
    n = append(d, n, ",\"lp\":"); n += uitoa(d + n, (unsigned)st_lp);
    n = append(d, n, ",\"ntrk\":"); n += uitoa(d + n, (unsigned)st_ntrk);
    n = append(d, n, ",\"ms\":"); n += uitoa(d + n, (unsigned)st_ms);
    n = append(d, n, ",\"x0\":"); n += uitoa(d + n, (unsigned)st_x0);
    n = append(d, n, ",\"y0\":"); n += uitoa(d + n, (unsigned)st_y0);
    n = append(d, n, ",\"x1\":"); n += uitoa(d + n, (unsigned)st_x1);
    n = append(d, n, ",\"y1\":"); n += uitoa(d + n, (unsigned)st_y1);
    n = append(d, n, ",\"voice\":"); n += uitoa(d + n, (unsigned)st_voice);
    st_arm = (int)(read_u32(REG_ARM) & 1u);
    n = append(d, n, ",\"arm\":"); n += uitoa(d + n, (unsigned)st_arm);
    n = append(d, n, "}");
    d[n] = 0;
    return n;
}

static void http_reply(const char *ctype, const uint8_t *body, unsigned blen)
{
    char hdr[192];
    unsigned hn = 0;
    hn = append(hdr, hn, "HTTP/1.0 200 OK\r\nContent-Type: ");
    hn = append(hdr, hn, ctype);
    hn = append(hdr, hn, "\r\nContent-Length: ");
    hn += uitoa(hdr + hn, blen);
    hn = append(hdr, hn, "\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n");
    if (hn + blen > sizeof(http_pkt))
        return;
    memcpy(http_pkt, hdr, hn);
    if (blen)
        memcpy(http_pkt + hn, body, blen);
    send_tcp_body(http_pkt, hn + blen);
}

static int path_eq(const char *path, const char *want)
{
    unsigned i = 0;
    while (want[i]) {
        if (path[i] != want[i])
            return 0;
        i++;
    }
    return path[i] == 0 || path[i] == '?' || path[i] == '#';
}

static int path_has(const char *path, const char *needle)
{
    unsigned i, j;
    for (i = 0; path[i]; i++) {
        for (j = 0; needle[j] && path[i + j] == needle[j]; j++)
            ;
        if (!needle[j])
            return 1;
    }
    return 0;
}

static void put16le(uint8_t *p, uint16_t v)
{
    p[0] = (uint8_t)v;
    p[1] = (uint8_t)(v >> 8);
}
static void put32le(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)v;
    p[1] = (uint8_t)(v >> 8);
    p[2] = (uint8_t)(v >> 16);
    p[3] = (uint8_t)(v >> 24);
}

static unsigned build_bmp(uint8_t *d)
{
    unsigned i;
    memset(d, 0, 54);
    d[0] = 'B';
    d[1] = 'M';
    put32le(d + 2, BMP_SZ);
    put32le(d + 10, BMP_OFF);
    put32le(d + 14, 40);
    put32le(d + 18, 48);
    put32le(d + 22, (uint32_t)-48);
    put16le(d + 26, 1);
    put16le(d + 28, 8);
    put32le(d + 34, 48u * 48u);
    put32le(d + 46, 256);
    put32le(d + 50, 256);
    for (i = 0; i < 256; i++) {
        d[54 + i * 4 + 0] = (uint8_t)i;
        d[54 + i * 4 + 1] = (uint8_t)i;
        d[54 + i * 4 + 2] = (uint8_t)i;
        d[54 + i * 4 + 3] = 0;
    }
    if (have_thumb)
        memcpy(d + BMP_OFF, thumb, 48u * 48u);
    else
        memset(d + BMP_OFF, 0x40, 48u * 48u);
    return BMP_SZ;
}

static void handle_get(const uint8_t *data, unsigned n)
{
    char path[32];
    unsigned i = 0, j = 0;
    static uint8_t page[8192];
    unsigned pn;
    while (i + 4 < n && !(data[i] == 'G' && data[i + 1] == 'E' && data[i + 2] == 'T' && data[i + 3] == ' '))
        i++;
    if (i + 4 >= n) {
        http_reply("text/plain", (const uint8_t *)"ok", 2);
        return;
    }
    i += 4;
    while (i < n && data[i] == ' ')
        i++;
    path[0] = 0;
    j = 0;
    while (i < n && data[i] != ' ' && data[i] != '\r' && data[i] != '\n' && j < 30) {
        path[j++] = (char)data[i++];
        path[j] = 0;
    }
    if (path[0] == 0) {
        path[0] = '/';
        path[1] = 0;
    }
    if (path[0] == '/' && path[1] == 'p' && (path[2] == '?' || path[2] == 0)) {
        unsigned t = 0, k = 0;
        if (path[2] == '?') {
            if (path[3] == 't' && path[4] == '=')
                k = 5;
            else
                k = 3;
            while (path[k] >= '0' && path[k] <= '9') {
                t = t * 10u + (unsigned)(path[k] - '0');
                k++;
            }
        }
        if (t >= 1u && t <= 40u)
            write_u32(t, TCP_BASE + 0x28);
        http_reply("text/plain", (const uint8_t *)"ok", 2);
    } else if (path[0] == '/' && path[1] == 'a') {
        int set = -1;
        if ((path[2] == '?' && path[3] == '1') || (path[2] == '1' && path[3] == 0))
            set = 1;
        else if ((path[2] == '?' && path[3] == '0') || (path[2] == '0' && path[3] == 0))
            set = 0;
        if (set >= 0) {
            write_u32((uint32_t)set, REG_ARM);
            st_arm = (int)(read_u32(REG_ARM) & 1u);
        }
        http_reply("text/plain", (const uint8_t *)(st_arm ? "1" : "0"), 1);
    } else if (path_eq(path, "/t.bmp") || path_eq(path, "/t") || path_eq(path, "/t.pgm")
        || path_has(path, "/t.b") || (path[0] == '/' && path[1] == 't' && path[2] == 0)) {
        pn = build_bmp(page);
        http_reply("image/bmp", page, pn);
    } else if (path_eq(path, "/status.json") || path_eq(path, "/s") || path_has(path, "status.json")) {
        pn = build_json((char *)page);
        http_reply("application/json", page, pn);
    } else if (path_eq(path, "/favicon.ico") || path_has(path, "favicon")) {
        http_reply("text/plain", (const uint8_t *)"", 0);
    } else {
        pn = build_index((char *)page);
        http_reply("text/html", page, pn);
    }
}

void http_set_status(const char *evt, int score, int pd_on, int pd, int lp,
                     int sht, int ta, int to, int ntrk, int infer_ms,
                     int x0, int y0, int x1, int y1, int voice)
{
    unsigned n = 0;
    {
        unsigned k = 0;
        const char *e = evt ? evt : "空闲";
        while (k < 15 && e[k]) { st_evt[k] = e[k]; k++; }
        st_evt[k] = 0;
    }
    st_score = score; st_pd_on = pd_on; st_pd = pd; st_lp = lp;
    st_sht = sht; st_ta = ta; st_to = to; st_ntrk = ntrk; st_ms = infer_ms;
    st_x0 = x0; st_y0 = y0; st_x1 = x1; st_y1 = y1;
    st_voice = voice ? 1 : 0;
    n = append(hist[hist_i], 0, st_evt);
    hist[hist_i][n++] = ' ';
    n += uitoa(hist[hist_i] + n, (unsigned)st_score);
    hist[hist_i][n++] = ' ';
    n += uitoa(hist[hist_i] + n, (unsigned)st_ta);
    hist[hist_i][n++] = '/';
    n += uitoa(hist[hist_i] + n, (unsigned)st_to);
    hist[hist_i][n] = 0;
    hist_i = (hist_i + 1) & 7;
    if (hist_n < 8) hist_n++;
}

void http_set_thumb(const uint8_t *th48, unsigned n)
{
    unsigned i;
    if (!th48) return;
    if (n > sizeof(thumb)) n = sizeof(thumb);
    for (i = 0; i < n; i++)
        thumb[i] = th48[i];
    have_thumb = 1;
}

void http_poll(void)
{
    unsigned hop;
    for (hop = 0; hop < 6; hop++) {
        uint32_t st = read_u32(REG_STAT);
        unsigned n, i, ihl, doff, tcp_off, pay_off, pay_len, ip_tot, tcp_seg;
        uint8_t flags;
        uint32_t seq;
        const uint8_t *ip, *tcp, *pay;

        if (!(st & ST_RXV))
            return;
        n = st & ST_LEN;
        if (n > sizeof(rxbuf)) n = sizeof(rxbuf);
        for (i = 0; i < n; i++)
            rxbuf[i] = (uint8_t)read_u32(REG_RXB);
        write_u32(1, REG_STAT);

        if (n < 54) continue;
        ip = rxbuf + 14;
        ihl = (ip[0] & 0x0f) * 4;
        if (ihl < 20) continue;
        tcp_off = 14 + ihl;
        if (n < tcp_off + 20) continue;
        tcp = rxbuf + tcp_off;
        if (get16(tcp + 2) != 80)
            continue;
        doff = ((tcp[12] >> 4) & 0x0f) * 4;
        if (doff < 20) continue;
        ip_tot = get16(ip + 2);
        tcp_seg = (ip_tot > ihl) ? (ip_tot - ihl) : 0;
        pay_off = tcp_off + doff;
        pay_len = (tcp_seg > doff) ? (tcp_seg - doff) : 0;
        if (pay_off + pay_len > n)
            pay_len = (n > pay_off) ? (n - pay_off) : 0;
        pay = rxbuf + pay_off;
        flags = tcp[13];
        seq = get32(tcp + 4);

        if (flags & 0x04) {
            tcp_st = LISTEN;
            continue;
        }

        if (flags & 0x02) {
            memcpy(peer_mac, rxbuf + 6, 6);
            memcpy(peer_ip, ip + 12, 4);
            peer_port = get16(tcp);
            rcv_nxt = seq + 1;
            iss += 64000u;
            snd_nxt = iss;
            tcp_st = SYN_RCVD;
            send_tcp(0x12, 0, 0);
            continue;
        }

        if (peer_port && get16(tcp) != peer_port)
            continue;

        if (tcp_st == SYN_RCVD && (flags & 0x10))
            tcp_st = ESTAB;

        if (pay_len) {
            rcv_nxt = seq + pay_len;
            handle_get(pay, pay_len);
            tcp_st = LISTEN;
            return;
        }
        if (flags & 0x01) {
            rcv_nxt = seq + 1;
            send_tcp(0x11, 0, 0);
            tcp_st = LISTEN;
        }
    }
}
