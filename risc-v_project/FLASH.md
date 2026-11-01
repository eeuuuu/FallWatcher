# Flash 固化

本文件是 `05-backup\V0046\FLASH.md` 的现场副本。步骤以归档目录为准。

分区：FPGA `@0x000000`，stub `@0x380000`，hello `@0x390000`。  
hello 用 `--base 0x1000`，**不要** `--min-size 4096`。

```
03-risc-v\program_flash_hello.bat
05-backup\V0046\restore_flash.bat
```

上电后 UDP/WEB 不通，先看 `FLASH.md` 里的“走过的错”，不要只 SRAM 烧 hello。
