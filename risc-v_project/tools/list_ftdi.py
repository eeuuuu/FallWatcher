import usb.core
import usb.backend.libusb0
import usb.backend.libusb1

b0 = usb.backend.libusb0.get_backend()
b1 = usb.backend.libusb1.get_backend()
print("libusb0", b0)
print("libusb1", b1)
backend = b0 or b1
devs = list(usb.core.find(find_all=True, backend=backend, idVendor=0x0403))
print("ndev", len(devs))
for d in devs:
    print(hex(d.idVendor), hex(d.idProduct), d.bus, d.address)
    try:
        print("  serial", d.serial_number)
    except Exception as e:
        print("  serial err", e)
    try:
        print("  product", d.product)
    except Exception as e:
        print("  product err", e)
    for cfg in d:
        for intf in cfg:
            print("  intf", intf.bInterfaceNumber, "cls", intf.bInterfaceClass, "eps",
                  [(ep.bEndpointAddress, ep.bmAttributes) for ep in intf])
