"""Dump official pdti8 MobileNet to C INT8 kernels. Verify 6/6 in numpy first."""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import tflite
from tflite.Conv2DOptions import Conv2DOptions
from tflite.DepthwiseConv2DOptions import DepthwiseConv2DOptions
from tflite.Pool2DOptions import Pool2DOptions

from run_static import as_int8, load_interpreter, parse_c_bytes, u8_minus_128
from _patch_qdim import patch_file

SRC = Path(
    r"D:\FPGA\cursor\prj_38\01-ref\06-ref_vhdl\tinyml-main"
    r"\tinyml_hello_world\Ti60F225_tinyml_hello_world"
    r"\embedded_sw\SapphireSoc\software\standalone\tinyml_pdti8\src\model"
)
OUT = Path(__file__).resolve().parent / "out"
HELLO = Path(r"D:\FPGA\cursor\prj_38\03-risc-v\soc\software\standalone\hello\src")


def quantize_multiplier(real: float) -> tuple[int, int]:
    if real == 0.0:
        return 0, 0
    q, shift = math.frexp(real)
    q_fixed = int(round(q * (1 << 31)))
    if q_fixed == (1 << 31):
        q_fixed //= 2
        shift += 1
    if shift < -31:
        return 0, 0
    return q_fixed, shift


def srdhm(a: int, b: int) -> int:
    overflow = a == b == -2147483648
    ab = a * b
    nudge = (1 << 30) if ab >= 0 else (1 - (1 << 30))
    return 2147483647 if overflow else int((ab + nudge) >> 31)


def qapply(x: int, mult: int, shift: int) -> int:
    left = shift if shift > 0 else 0
    right = 0 if shift > 0 else -shift
    return srdhm(x * (1 << left), mult) >> right


def sat_i8(x: int) -> int:
    return max(-128, min(127, x))


def same_pad(n: int, k: int, s: int) -> tuple[int, int]:
    out = (n + s - 1) // s
    pad = max(0, (out - 1) * s + k - n)
    return out, pad // 2


def tensor_blob(model, t):
    shape = [t.Shape(i) for i in range(t.ShapeLength())]
    buf = model.Buffers(t.Buffer())
    data = bytes(buf.DataAsNumpy()) if buf.DataLength() else b""
    q = t.Quantization()
    scales = [float(q.Scale(i)) for i in range(q.ScaleLength())] if q else [1.0]
    zps = [int(q.ZeroPoint(i)) for i in range(q.ZeroPointLength())] if q else [0]
    if t.Type() == 9:
        arr = np.frombuffer(data, np.int8).copy().reshape(shape) if data else None
    elif t.Type() == 2:
        arr = np.frombuffer(data, np.int32).copy().reshape(shape) if data else None
    else:
        arr = None
    return shape, scales, zps, arr


def conv_ref(x, w, b, stride, zp_in, zp_out, mult, shift):
    ih, iw, ic = x.shape
    oc, kh, kw, _ic = w.shape
    oh, ph = same_pad(ih, kh, stride)
    ow, pw = same_pad(iw, kw, stride)
    y = np.empty((oh, ow, oc), np.int8)
    for oy in range(oh):
        for ox in range(ow):
            for oc_i in range(oc):
                acc = int(b[oc_i])
                for ky in range(kh):
                    iy = oy * stride + ky - ph
                    if iy < 0 or iy >= ih:
                        continue
                    for kx in range(kw):
                        ix = ox * stride + kx - pw
                        if ix < 0 or ix >= iw:
                            continue
                        xin = x[iy, ix].astype(np.int32) - zp_in
                        win = w[oc_i, ky, kx].astype(np.int32)
                        acc += int(np.dot(xin, win))
                acc = qapply(acc, int(mult[oc_i]), int(shift[oc_i])) + zp_out
                y[oy, ox, oc_i] = sat_i8(acc)
    return y


def dw_ref(x, w, b, stride, zp_in, zp_out, mult, shift, dm):
    ih, iw, ic = x.shape
    kh, kw = w.shape[1], w.shape[2]
    oc = ic * dm
    oh, ph = same_pad(ih, kh, stride)
    ow, pw = same_pad(iw, kw, stride)
    y = np.empty((oh, ow, oc), np.int8)
    for oy in range(oh):
        for ox in range(ow):
            for oc_i in range(oc):
                acc = int(b[oc_i])
                in_c = oc_i // dm
                for ky in range(kh):
                    iy = oy * stride + ky - ph
                    if iy < 0 or iy >= ih:
                        continue
                    for kx in range(kw):
                        ix = ox * stride + kx - pw
                        if ix < 0 or ix >= iw:
                            continue
                        acc += (int(x[iy, ix, in_c]) - zp_in) * int(w[0, ky, kx, oc_i])
                acc = qapply(acc, int(mult[oc_i]), int(shift[oc_i])) + zp_out
                y[oy, ox, oc_i] = sat_i8(acc)
    return y


def pool_ref(x, zp_in, scale_in, zp_out, scale_out):
    ih, iw, ic = x.shape
    y = np.empty((1, 1, ic), np.int8)
    count = ih * iw
    real_m, sh = quantize_multiplier((scale_in / scale_out) / count)
    for c in range(ic):
        acc = int(np.sum(x[:, :, c].astype(np.int32) - zp_in))
        acc = qapply(acc, real_m, sh) + zp_out
        y[0, 0, c] = sat_i8(acc)
    return y


def emit_c_array(fp, name, arr, typ):
    flat = np.asarray(arr).reshape(-1)
    fp.write(f"const {typ} {name}[{flat.size}] = {{\n")
    for i, v in enumerate(flat):
        if i % 16 == 0:
            fp.write("  ")
        fp.write(f"{int(v)},")
        fp.write("\n" if i % 16 == 15 else " ")
    if flat.size % 16:
        fp.write("\n")
    fp.write("};\n\n")


def main() -> int:
    OUT.mkdir(exist_ok=True)
    raw = parse_c_bytes(SRC / "mobilenetv1_person_detect_model_data.cc", "mobilenetv1_person_detect_model_data")
    (OUT / "pdti8.tflite").write_bytes(raw)
    fixed = OUT / "pdti8_fixed.tflite"
    patch_file(OUT / "pdti8.tflite", fixed)
    model = tflite.Model.GetRootAsModel(raw, 0)
    g = model.Subgraphs(0)
    tensors = []
    for i in range(g.TensorsLength()):
        tensors.append(tensor_blob(model, g.Tensors(i)))

    layers = []
    for i in range(g.OperatorsLength()):
        op = g.Operators(i)
        bcode = model.OperatorCodes(op.OpcodeIndex()).BuiltinCode()
        ins = [op.Inputs(j) for j in range(op.InputsLength())]
        outs = [op.Outputs(j) for j in range(op.OutputsLength())]
        tab = op.BuiltinOptions()
        if bcode == 4:
            o = DepthwiseConv2DOptions()
            o.Init(tab.Bytes, tab.Pos)
            layers.append({"kind": "dw", "ins": ins, "outs": outs, "stride": o.StrideW(), "dm": o.DepthMultiplier()})
        elif bcode == 3:
            o = Conv2DOptions()
            o.Init(tab.Bytes, tab.Pos)
            layers.append({"kind": "conv", "ins": ins, "outs": outs, "stride": o.StrideW(), "dm": 1})
        elif bcode == 1:
            o = Pool2DOptions()
            o.Init(tab.Bytes, tab.Pos)
            layers.append({"kind": "pool", "ins": ins, "outs": outs, "stride": o.StrideW(), "dm": 1})
        elif bcode in (22, 25):
            layers.append({"kind": "skip", "ins": ins, "outs": outs, "stride": 1, "dm": 1})
        else:
            raise SystemExit(f"unknown op {bcode}")

    cases = [
        as_int8(parse_c_bytes(SRC / "person_image_data.cc", "g_person_data")),
        as_int8(parse_c_bytes(SRC / "no_person_image_data.cc", "g_no_person_data")),
        u8_minus_128(parse_c_bytes(SRC / "people1_data.h", "people1_data")),
        u8_minus_128(parse_c_bytes(SRC / "people2_data.h", "people2_data")),
        u8_minus_128(parse_c_bytes(SRC / "no_people1_data.h", "no_people1_data")),
        u8_minus_128(parse_c_bytes(SRC / "no_people2_data.h", "no_people2_data")),
    ]
    expect = ["person", "no_person", "person", "person", "no_person", "no_person"]

    def run_net(img: np.ndarray) -> tuple[int, int]:
        acts = {88: img.reshape(96, 96, 1).astype(np.int8)}
        for li, ly in enumerate(layers):
            if ly["kind"] == "skip":
                acts[ly["outs"][0]] = acts[ly["ins"][0]].reshape(-1)[:2] if ly["kind"] else acts[ly["ins"][0]]
                if ly["kind"] == "skip" and model.OperatorCodes(g.Operators(li).OpcodeIndex()).BuiltinCode() == 22:
                    acts[ly["outs"][0]] = acts[ly["ins"][0]].reshape(-1)
                continue
            xin = acts[ly["ins"][0]]
            if xin.ndim == 1:
                xin = xin.reshape(1, 1, -1)
            if xin.ndim == 4:
                xin = xin.reshape(xin.shape[1], xin.shape[2], xin.shape[3])
            if ly["kind"] == "pool":
                _s, sc_in, zp_in, _ = tensors[ly["ins"][0]]
                _so, sc_out, zp_out, _ = tensors[ly["outs"][0]]
                acts[ly["outs"][0]] = pool_ref(xin, zp_in[0], sc_in[0], zp_out[0], sc_out[0])
                continue
            w_id, b_id = ly["ins"][1], ly["ins"][2]
            _ws, wsc, wzp, w = tensors[w_id]
            _bs, _bsc, _bzp, b = tensors[b_id]
            _is, isc, izp, _ = tensors[ly["ins"][0]]
            _os, osc, ozp, _ = tensors[ly["outs"][0]]
            oc = w.shape[0] if ly["kind"] == "conv" else w.shape[-1]
            mult, sh = [], []
            for c in range(oc):
                m, s = quantize_multiplier(isc[0] * wsc[c] / osc[0])
                mult.append(m)
                sh.append(s)
            if ly["kind"] == "conv":
                y = conv_ref(xin, w, b, ly["stride"], izp[0], ozp[0], mult, sh)
            else:
                y = dw_ref(xin, w, b, ly["stride"], izp[0], ozp[0], mult, sh, ly["dm"])
            acts[ly["outs"][0]] = y
        # logits before softmax: tensor 31 or last conv 28
        logits = acts.get(28)
        if logits is None:
            logits = acts.get(31)
        logits = np.asarray(logits).reshape(-1)
        return int(logits[1]), int(logits[0])

    print("numpy ref (first image only, then 6)...")
    ok = 0
    lines = []
    for i, (img, exp) in enumerate(zip(cases, expect)):
        person, nop = run_net(img)
        dec = "person" if person > nop else "no_person"
        hit = dec == exp
        ok += int(hit)
        line = f"[{i}] person={person} no_person={nop} {dec} expect={exp} {'OK' if hit else 'DIFF'}"
        print(line, flush=True)
        lines.append(line)
    print(f"numpy decision {ok}/6")
    (OUT / "numpy_ref.txt").write_text("\n".join(lines) + f"\n{ok}/6\n", encoding="utf-8")

    # Emit C regardless; board self-test is the final judge.
    HELLO.mkdir(exist_ok=True)
    wfp = (HELLO / "pdti8_w.c").open("w", encoding="utf-8")
    wfp.write('#include "pdti8_infer.h"\n#include <stdint.h>\n\n')
    layer_meta = []
    for li, ly in enumerate(layers):
        if ly["kind"] in ("skip", "pool"):
            if ly["kind"] == "pool":
                _is, isc, izp, _ = tensors[ly["ins"][0]]
                _os, osc, ozp, _ = tensors[ly["outs"][0]]
                layer_meta.append(ly | {"isc": isc[0], "osc": osc[0], "izp": izp[0], "ozp": ozp[0]})
            else:
                layer_meta.append(ly)
            continue
        w_id, b_id = ly["ins"][1], ly["ins"][2]
        _ws, wsc, wzp, w = tensors[w_id]
        _bs, _bsc, _bzp, b = tensors[b_id]
        _is, isc, izp, _ = tensors[ly["ins"][0]]
        os, osc, ozp, _ = tensors[ly["outs"][0]]
        oc = int(w.shape[0] if ly["kind"] == "conv" else w.shape[-1])
        mult, sh = [], []
        for c in range(oc):
            m, s = quantize_multiplier(isc[0] * wsc[c] / osc[0])
            mult.append(m)
            sh.append(s)
        emit_c_array(wfp, f"pd_w{li}", w, "int8_t")
        emit_c_array(wfp, f"pd_b{li}", b, "int32_t")
        emit_c_array(wfp, f"pd_m{li}", mult, "int32_t")
        emit_c_array(wfp, f"pd_s{li}", sh, "int32_t")
        in_shape = tensors[ly["ins"][0]][0]
        layer_meta.append(
            ly
            | {
                "wname": f"pd_w{li}",
                "bname": f"pd_b{li}",
                "mname": f"pd_m{li}",
                "sname": f"pd_s{li}",
                "ih": int(in_shape[-3] if len(in_shape) == 4 else in_shape[0]),
                "iw": int(in_shape[-2] if len(in_shape) == 4 else in_shape[1]),
                "ic": int(in_shape[-1]),
                "oc": oc,
                "kh": int(w.shape[1] if ly["kind"] == "dw" else w.shape[1]),
                "kw": int(w.shape[2] if ly["kind"] == "dw" else w.shape[2]),
                "izp": int(izp[0]),
                "ozp": int(ozp[0]),
                "oh": int(os[-3] if len(os) == 4 else 1),
                "ow": int(os[-2] if len(os) == 4 else 1),
            }
        )
    emit_c_array(wfp, "pd_img_person", cases[0], "int8_t")
    emit_c_array(wfp, "pd_img_noperson", cases[1], "int8_t")
    wfp.close()

    h = HELLO / "pdti8_infer.h"
    h.write_text(
        "#pragma once\n#include <stdint.h>\n"
        "void pdti8_run(const int8_t *in96, int8_t *person, int8_t *no_person);\n"
        "extern const int8_t pd_img_person[9216];\n"
        "extern const int8_t pd_img_noperson[9216];\n",
        encoding="utf-8",
    )

    cfp = (HELLO / "pdti8_infer.c").open("w", encoding="utf-8")
    cfp.write(r'''#include "pdti8_infer.h"

static int32_t srdhm(int32_t a, int32_t b)
{
    int64_t ab = (int64_t)a * (int64_t)b;
    int64_t nudge = (ab >= 0) ? (1LL << 30) : (1LL - (1LL << 30));
    if (a == -2147483647-1 && b == a)
        return 2147483647;
    return (int32_t)((ab + nudge) >> 31);
}

static int32_t qapply(int32_t x, int32_t m, int32_t shift)
{
    int left = shift > 0 ? shift : 0;
    int right = shift > 0 ? 0 : -shift;
    return srdhm(x << left, m) >> right;
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

''')
    # externs
    for li, ly in enumerate(layer_meta):
        if "wname" in ly:
            cfp.write(f"extern const int8_t {ly['wname']}[];\n")
            cfp.write(f"extern const int32_t {ly['bname']}[];\n")
            cfp.write(f"extern const int32_t {ly['mname']}[];\n")
            cfp.write(f"extern const int32_t {ly['sname']}[];\n")
    cfp.write("\nvoid pdti8_run(const int8_t *in96, int8_t *person, int8_t *no_person)\n{\n")
    cfp.write("    const int8_t *src = in96;\n    int8_t *dst = buf0;\n")
    ping = 0
    for li, ly in enumerate(layer_meta):
        if ly["kind"] == "skip":
            continue
        if ly["kind"] == "pool":
            m, s = quantize_multiplier((ly["isc"] / ly["osc"]) / 9.0)
            cfp.write(f"    avgpool_valid3(src, dst, 256, {ly['izp']}, {ly['ozp']}, {m}, {s});\n")
            cfp.write("    src = dst; dst = (dst == buf0) ? buf1 : buf0;\n")
            continue
        if ly["kind"] == "dw":
            cfp.write(
                f"    dw3(src, dst, {ly['ih']}, {ly['iw']}, {ly['ic']}, {ly['dm']}, {ly['stride']}, "
                f"{ly['izp']}, {ly['ozp']}, {ly['wname']}, {ly['bname']}, {ly['mname']}, {ly['sname']});\n"
            )
        else:
            # last conv is 1x1, all pointwise are 1x1. Conv0 is DW not conv.
            cfp.write(
                f"    conv1x1(src, dst, {ly['oh']}, {ly['ow']}, {ly['ic']}, {ly['oc']}, "
                f"{ly['izp']}, {ly['ozp']}, {ly['wname']}, {ly['bname']}, {ly['mname']}, {ly['sname']});\n"
            )
        cfp.write("    src = dst; dst = (dst == buf0) ? buf1 : buf0;\n")
        ping ^= 1
    cfp.write("    *no_person = src[0];\n    *person = src[1];\n}\n")
    cfp.close()
    print("wrote", HELLO / "pdti8_w.c", HELLO / "pdti8_infer.c")
    return 0 if ok == 6 else 1


if __name__ == "__main__":
    raise SystemExit(main())
