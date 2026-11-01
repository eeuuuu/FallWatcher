import sys
import time
from pyftdi.serialext import serial_for_url

urls = [
    "ftdi://0x0403:0x6011:1:1/3",
    "ftdi://0x0403:0x6011:1:1/4",
    "ftdi://0x0403:0x6011:1:1/1",
]

for url in urls:
    print("TRY", url)
    try:
        port = serial_for_url(url, baudrate=115200, timeout=0.4)
    except Exception as e:
        print("  open fail:", e)
        continue
    try:
        t0 = time.time()
        buf = b""
        while time.time() - t0 < 3.0:
            chunk = port.read(256)
            if chunk:
                buf += chunk
        print("  bytes", len(buf))
        if buf:
            print(buf.decode("ascii", errors="replace"))
            sys.exit(0)
    finally:
        port.close()

print("NO UART DATA")
sys.exit(2)
