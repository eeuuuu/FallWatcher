@echo off
setlocal
call C:\Efinity\2025.2\bin\setup.bat
set PY=python
set WRAP=D:\FPGA\cursor\prj_38\04-tool\_ftdi_pgm_skip_bad_usb.py
set URL=ftdi://0x0403:0x6011:1:1/2
set FLI=C:\Efinity\2025.2\pgm\fli\titanium\u10660A79.bit
set STUB=D:\FPGA\cursor\prj_38\03-risc-v\soc\software\standalone\flash_stub\build\flash_stub_efx.hex
set APP=D:\FPGA\cursor\prj_38\03-risc-v\soc\software\standalone\hello\build\hello_app.hex
echo load JTAG-SPI bridge
%PY% "%WRAP%" "%FLI%" -m jtag -u %URL% --jtag_clock_freq 6000000
if errorlevel 1 exit /b 1
echo stub -^> flash 0x380000
%PY% "%WRAP%" "%STUB%" -m jtag_bridge --jtag_bridge_mode all --address 0x380000 -u %URL% --jtag_clock_freq 6000000
if errorlevel 1 exit /b 1
echo hello -^> flash 0x390000
%PY% "%WRAP%" "%APP%" -m jtag_bridge --jtag_bridge_mode all --address 0x390000 -u %URL% --jtag_clock_freq 6000000
if errorlevel 1 exit /b 1
echo Flash app OK.
