"""Set quantized_dimension=0 on rank-1 tensors. LiteRT rejects qdim=3 on 1D bias."""
from pathlib import Path
import tflite


def patch_file(src: Path, dst: Path) -> int:
    data = bytearray(Path(src).read_bytes())
    model = tflite.Model.GetRootAsModel(bytes(data), 0)
    g = model.Subgraphs(0)
    patched = 0
    for i in range(g.TensorsLength()):
        t = g.Tensors(i)
        q = t.Quantization()
        if q is None or t.ShapeLength() != 1 or q.QuantizedDimension() != 3:
            continue
        tab = q._tab
        off = tab.Offset(16)
        if off == 0:
            off = tab.Offset(14)
        if off == 0:
            continue
        pos = tab.Pos + off
        data[pos : pos + 4] = (0).to_bytes(4, "little", signed=True)
        patched += 1
    Path(dst).write_bytes(data)
    return patched


if __name__ == "__main__":
    src = Path(r"D:\FPGA\cursor\prj_38\03-risc-v\p2_pdti8_static\out\pdti8.tflite")
    dst = Path(r"D:\FPGA\cursor\prj_38\03-risc-v\p2_pdti8_static\out\pdti8_fixed.tflite")
    print("patched", patch_file(src, dst), "->", dst)
