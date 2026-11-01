@echo off
setlocal
set IDE=D:\program\efinity-riscv-ide-2025.2
set PATH=%IDE%\openocd\bin;%PATH%
set ELF=%~dp0soc\software\standalone\hello\build\hello.elf
if not exist "%ELF%" (
  echo missing %ELF%
  exit /b 1
)
cd /d "%~dp0soc\bsp\efinix\EfxSapphireSoc\openocd"
openocd.exe -f ftdi_ti.cfg -f debug_ti.cfg -c "load_image {%ELF%}" -c "mww 0xF9000000 0x0000100F" -c "mww 0xF9000004 0x000012B7" -c "mww 0xF9000008 0x00028067" -c "soft_reset_halt" -c "mdw 0xF9000000 3" -c "mdw 0x00001000 2" -c "reg pc" -c "resume" -c shutdown
