"""Run official pdti8 MobileNetV1 on the 6 static 96x96 images. No camera, no official hex."""
from __future__ import annotations

import re
import sys
from pathlib import Path

import numpy as np

SRC = Path(
    r"D:\FPGA\cursor\prj_38\01-ref\06-ref_vhdl\tinyml-main"
    r"\tinyml_hello_world\Ti60F225_tinyml_hello_world"
    r"\embedded_sw\SapphireSoc\software\standalone\tinyml_pdti8\src\model"
)
OUT = Path(__file__).resolve().parent / "out"
REF = [
    (113, -113, "person"),
    (-57, 57, "no_person"),
    (93, -93, "person"),
    (57, -57, "person"),
    (-51, 51, "no_person"),
    (-111, 111, "no_person"),
]


def parse_c_bytes(path: Path, name: str) -> bytes:
    text = path.read_text(encoding="utf-8", errors="ignore")
    m = re.search(
        rf"{re.escape(name)}\s*\[[^\]]*\]\s*=\s*\{{(.*?)\}};",
        text,
        re.S,
    )
    if not m:
        raise SystemExit(f"array {name} not found in {path}")
    nums = re.findall(r"0x[0-9a-fA-F]+|\d+", m.group(1))
    return bytes(int(n, 0) & 0xFF for n in nums)


def as_int8(raw: bytes) -> np.ndarray:
    return np.frombuffer(raw, dtype=np.uint8).view(np.int8).copy()


def u8_minus_128(raw: bytes) -> np.ndarray:
    return (np.frombuffer(raw, dtype=np.uint8).astype(np.int16) - 128).astype(np.int8)


def load_interpreter(model_path: Path):
    errors = []
    try:
        from ai_edge_litert.interpreter import Interpreter

        return Interpreter(model_path=str(model_path))
    except Exception as exc:
        errors.append(exc)
    try:
        import tensorflow as tf

        return tf.lite.Interpreter(model_path=str(model_path))
    except Exception as exc:
        errors.append(exc)
    try:
        from tflite_runtime.interpreter import Interpreter

        return Interpreter(model_path=str(model_path))
    except Exception as exc:
        errors.append(exc)
    raise SystemExit("need ai-edge-litert / tensorflow / tflite-runtime: " + str(errors))


def main() -> int:
    OUT.mkdir(exist_ok=True)
    model_bin = parse_c_bytes(
        SRC / "mobilenetv1_person_detect_model_data.cc",
        "mobilenetv1_person_detect_model_data",
    )
    raw_path = OUT / "pdti8.tflite"
    raw_path.write_bytes(model_bin)
    from _patch_qdim import patch_file

    model_path = OUT / "pdti8_fixed.tflite"
    patch_file(raw_path, model_path)
    print(f"model {len(model_bin)} bytes -> {model_path}")

    cases = [
        ("OUTPUT_0 person TFLM", as_int8(parse_c_bytes(SRC / "person_image_data.cc", "g_person_data"))),
        ("OUTPUT_1 no_person TFLM", as_int8(parse_c_bytes(SRC / "no_person_image_data.cc", "g_no_person_data"))),
        ("OUTPUT_2 people1", u8_minus_128(parse_c_bytes(SRC / "people1_data.h", "people1_data"))),
        ("OUTPUT_3 people2", u8_minus_128(parse_c_bytes(SRC / "people2_data.h", "people2_data"))),
        ("OUTPUT_4 no_people1", u8_minus_128(parse_c_bytes(SRC / "no_people1_data.h", "no_people1_data"))),
        ("OUTPUT_5 no_people2", u8_minus_128(parse_c_bytes(SRC / "no_people2_data.h", "no_people2_data"))),
    ]

    itp = load_interpreter(model_path)
    itp.allocate_tensors()
    inp = itp.get_input_details()[0]
    out = itp.get_output_details()[0]
    print("input", inp["shape"], inp["dtype"], "output", out["shape"], out["dtype"])

    ok = 0
    lines = []
    for i, ((name, img), (ref_p, ref_n, expect)) in enumerate(zip(cases, REF)):
        if img.size != 96 * 96:
            raise SystemExit(f"{name} size {img.size}")
        x = img.reshape(inp["shape"])
        itp.set_tensor(inp["index"], x)
        itp.invoke()
        y = itp.get_tensor(out["index"]).reshape(-1).astype(np.int32)
        no_person, person = int(y[0]), int(y[1])
        decide = "person" if person > no_person else "no_person"
        match_sign = decide == expect
        ok += int(match_sign)
        line = (
            f"[{name}] person={person} no_person={no_person} "
            f"decide={decide} expect={expect} "
            f"ref=({ref_p},{ref_n}) {'OK' if match_sign else 'DIFF'}"
        )
        print(line)
        lines.append(line)

    summary = f"decision match {ok}/6 (score may differ from TFLM+accel ref)"
    print(summary)
    (OUT / "result.txt").write_text("\n".join(lines + [summary]) + "\n", encoding="utf-8")
    return 0 if ok == 6 else 1


if __name__ == "__main__":
    sys.exit(main())
