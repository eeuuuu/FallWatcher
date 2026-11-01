"""8TEV UDP 5002 协议：事件 + 48x48 灰度缩略图分片。"""
from __future__ import print_function
import struct

MAGIC = b"8TEV"
VER = 1
PTYPE_EVT = 0
PTYPE_THUMB = 1
EVT_SZ = 128
EVT_WIRE = 256
PKT_SZ = 256
THUMB_W = 48
THUMB_H = 48
THUMB_N = THUMB_W * THUMB_H
CHUNK = 240
EVT_NAME = {0: "IDL", 1: "MOT", 2: "IR", 3: "IN", 4: "FAL", 5: "AC"}
EVT_NAME_ZH = {0: "空闲", 1: "运动", 2: "红外", 3: "进入", 4: "跌倒", 5: "过热"}
BIND_IP = "192.168.10.12"
FPGA_IP = "192.168.10.10"
BIN_PORT = 5002
PRINT_PORT = 5001


def u16(b, o):
    return struct.unpack_from("<H", b, o)[0]


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def put_u16(buf, o, v):
    struct.pack_into("<H", buf, o, v & 0xFFFF)


def put_u32(buf, o, v):
    struct.pack_into("<I", buf, o, v & 0xFFFFFFFF)


def pack_event(seq, t_ms, evt, score, pd_on, conf, sht, ta, to, lp, fr, infer_ms,
               tracks, box, mot=1, has_thumb=1, voice=0):
    pkt = bytearray(EVT_SZ)
    pkt[0:4] = MAGIC
    pkt[4] = VER
    pkt[5] = PTYPE_EVT
    pkt[6] = ((1 if lp else 0) | (2 if has_thumb else 0) | (4 if mot else 0) |
              (8 if voice else 0))
    n = min(len(tracks), 4)
    pkt[7] = n
    put_u32(pkt, 8, seq)
    put_u32(pkt, 12, t_ms)
    pkt[16] = evt & 7
    pkt[17] = score & 255
    pkt[18] = pd_on & 1
    pkt[19] = conf & 255
    pkt[20] = sht & 255
    pkt[21] = ta & 255
    pkt[22] = to & 255
    pkt[23] = n
    put_u16(pkt, 24, fr)
    put_u16(pkt, 26, infer_ms)
    if n:
        put_u16(pkt, 28, tracks[0].get("px", tracks[0].get("cx", 0)))
        put_u16(pkt, 30, tracks[0].get("py", tracks[0].get("cy", 0)))
    for i, t in enumerate(tracks[:4]):
        q = 32 + i * 16
        put_u16(pkt, q, t.get("tid", i + 1))
        pkt[q + 2] = t.get("age", 0)
        put_u16(pkt, q + 4, t.get("x0", 0))
        put_u16(pkt, q + 6, t.get("y0", 0))
        put_u16(pkt, q + 8, t.get("x1", 0))
        put_u16(pkt, q + 10, t.get("y1", 0))
        put_u16(pkt, q + 12, t.get("cx", 0))
        put_u16(pkt, q + 14, t.get("cy", 0))
    put_u16(pkt, 96, THUMB_W)
    put_u16(pkt, 98, THUMB_H)
    nch = (THUMB_N + CHUNK - 1) // CHUNK if has_thumb else 0
    pkt[100] = nch
    put_u16(pkt, 104, box[0])
    put_u16(pkt, 106, box[1])
    put_u16(pkt, 108, box[2])
    put_u16(pkt, 110, box[3])
    return bytes(pkt).ljust(EVT_WIRE, b"\x00")


def pack_thumb_chunks(seq, gray48):
    data = bytes(gray48)
    if len(data) < THUMB_N:
        data = data + bytes(THUMB_N - len(data))
    data = data[:THUMB_N]
    nch = (THUMB_N + CHUNK - 1) // CHUNK
    out = []
    for idx in range(nch):
        off = idx * CHUNK
        n = min(CHUNK, THUMB_N - off)
        pkt = bytearray(PKT_SZ)
        pkt[0:4] = MAGIC
        pkt[4] = VER
        pkt[5] = PTYPE_THUMB
        pkt[6] = idx
        pkt[7] = nch
        put_u32(pkt, 8, seq)
        put_u16(pkt, 12, off)
        put_u16(pkt, 14, n)
        pkt[16:16 + n] = data[off:off + n]
        out.append(bytes(pkt))
    return out


def _align_magic(buf):
    if buf is None:
        return None
    buf = bytes(buf)
    if buf[:4] == MAGIC:
        return buf
    z = 0
    while z < 4 and z < len(buf) and buf[z] == 0:
        z += 1
    if z and buf[z:z + 4] == MAGIC:
        return buf[z:] + bytes(z)
    return buf


def parse_packet(buf):
    buf = _align_magic(buf)
    if buf is None or len(buf) < 8 or buf[0:4] != MAGIC:
        return None
    ver, ptype = buf[4], buf[5]
    if ver != VER:
        return None
    if ptype == PTYPE_EVT:
        if len(buf) < EVT_SZ:
            return None
        n = buf[7]
        tracks = []
        for i in range(min(n, 4)):
            q = 32 + i * 16
            tracks.append({
                "tid": u16(buf, q),
                "age": buf[q + 2],
                "x0": u16(buf, q + 4),
                "y0": u16(buf, q + 6),
                "x1": u16(buf, q + 8),
                "y1": u16(buf, q + 10),
                "cx": u16(buf, q + 12),
                "cy": u16(buf, q + 14),
            })
        flags = buf[6]
        return {
            "type": "event",
            "seq": u32(buf, 8),
            "t_ms": u32(buf, 12),
            "evt": buf[16],
            "evt_name": EVT_NAME.get(buf[16], "?"),
            "evt_name_zh": EVT_NAME_ZH.get(buf[16], "?"),
            "score": buf[17],
            "pd_on": buf[18],
            "conf": buf[19],
            "sht": buf[20],
            "ta": buf[21],
            "to": buf[22],
            "lp": flags & 1,
            "has_thumb": (flags >> 1) & 1,
            "mot": (flags >> 2) & 1,
            "voice": (flags >> 3) & 1,
            "fr": u16(buf, 24),
            "infer_ms": u16(buf, 26),
            "px": u16(buf, 28),
            "py": u16(buf, 30),
            "tracks": tracks,
            "ntrack": n,
            "thumb_w": u16(buf, 96),
            "thumb_h": u16(buf, 98),
            "nchunk": buf[100],
            "box": (u16(buf, 104), u16(buf, 106), u16(buf, 108), u16(buf, 110)),
        }
    if ptype == PTYPE_THUMB:
        if len(buf) < 16:
            return None
        n = u16(buf, 14)
        off = u16(buf, 12)
        return {
            "type": "thumb",
            "seq": u32(buf, 8),
            "idx": buf[6],
            "nchunk": buf[7],
            "offset": off,
            "length": n,
            "data": buf[16:16 + n],
        }
    return None
