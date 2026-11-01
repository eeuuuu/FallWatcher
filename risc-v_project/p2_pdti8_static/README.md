# P2 · pdti8 静态图

官方 `tinyml_hello_world` 的 6 张 96×96 灰度图 + MobileNetV1 person detect。
不烧官方 hex，不接摄像头，不并进 HDMI 工程。

```
python run_static.py
```

对照官方 `ref_tinyml_pdti8.txt`。本机 6 张图人/无人判决已全部对上；个别分数和板上加速器差 1～2。
