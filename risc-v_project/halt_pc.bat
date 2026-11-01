@echo off
setlocal
set IDE=D:\program\efinity-riscv-ide-2025.2
set PATH=%IDE%\openocd\bin;%PATH%
cd /d D:\FPGA\cursor\prj_38\03-risc-v\soc\bsp\efinix\EfxSapphireSoc\openocd
openocd.exe -f ftdi_ti.cfg -f debug_ti.cfg -c "halt" -c "reg pc" -c "reg ra" -c "mdw 0x00001000 4" -c shutdown
