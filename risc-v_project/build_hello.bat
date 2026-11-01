@echo off
setlocal
set IDE=D:\program\efinity-riscv-ide-2025.2
set BSP=efinix/EfxSapphireSoc
set PATH=%IDE%\toolchain\bin;%IDE%\build_tools\bin;%IDE%\openocd\bin;%PATH%
cd /d "%~dp0soc\software\standalone\hello"
make %*
if errorlevel 1 exit /b 1
echo Built: %CD%\build\hello.elf
