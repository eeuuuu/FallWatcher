# 03-risc-v

当前跟 HDMI 同一颗 bit（V0014）。不要再烧独立 `03_soc_hello`。

- 入口：`0x00001000`（DDR）
- 打印：`bsp_printf` → APB `0xF8100000` → UDP `192.168.10.10 → 192.168.10.12:5001`
- 串口和 JTAG 共用 FT4232，没有 COM

```
03-risc-v\build_hello.bat
03-risc-v\load_hello.bat
```

电脑开 `04-tool\listen_print.bat`。

`load_hello.bat` 会在 `0xF9000000` 写 I$ flush stub 再 `soft_reset_halt`。不要只 `resume 0x1000`。

回退：

```
05-backup\V0014\restore_sram.bat
05-backup\V0014\restore_hello.bat
```
