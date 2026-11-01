#!/usr/bin/env python3
# FPGA 192.168.10.10:5000  bidirectional UDP (8TUN)
# RGB is Q8.8 (256 = 1.00x). Gray-card button reads center 128x128 means.
import socket
import struct
import sys
import threading

try:
    from PyQt5.QtCore import Qt, pyqtSignal, QObject, QTimer
    from PyQt5.QtWidgets import (
        QApplication, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
        QSlider, QSpinBox, QLineEdit, QPushButton, QGridLayout, QGroupBox
    )
except ImportError:
    from PyQt6.QtCore import Qt, pyqtSignal, QObject, QTimer
    from PyQt6.QtWidgets import (
        QApplication, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
        QSlider, QSpinBox, QLineEdit, QPushButton, QGridLayout, QGroupBox
    )
    Qt.Horizontal = Qt.Orientation.Horizontal

MAGIC = b"8TUN"
FPGA_IP = "192.168.10.10"
BIND_IP = "192.168.10.12"
FPGA_PORT = 5000
CMD_W, CMD_R, CMD_A, CMD_H = 0x57, 0x52, 0x41, 0x48
REG_R, REG_G, REG_B, REG_AG, REG_CAM = 0x00, 0x01, 0x02, 0x10, 0x20
REG_MR, REG_MG, REG_MB, REG_MF, REG_MP = 0x30, 0x31, 0x32, 0x33, 0x34
Q88_1X, Q88_MIN, Q88_MAX = 256, 64, 1024


def pack_msg(cmd, seq, reg, data):
    return struct.pack("<4sBBBBI4x", MAGIC, cmd, seq, reg, 4, data & 0xFFFFFFFF)


def unpack_msg(buf):
    if len(buf) < 12:
        return None
    if buf[0:4] != MAGIC:
        return None
    cmd, seq, reg, ln, data = struct.unpack_from("<BBBBI", buf, 4)
    return cmd, seq, reg, data


def q88_text(v):
    return "%d  (%.3fx)" % (v, v / 256.0)


class UdpLink(QObject):
    ack = pyqtSignal(int, int, int, int)
    status = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.seq = 0
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            self.sock.bind((BIND_IP, FPGA_PORT))
            bind_ok = BIND_IP
        except OSError:
            self.sock.bind(("", FPGA_PORT))
            bind_ok = "0.0.0.0"
        self.sock.settimeout(0.3)
        self._run = True
        threading.Thread(target=self._rx, daemon=True).start()
        self.status.emit("已绑定 %s:%d，拖滑条即下发" % (bind_ok, FPGA_PORT))

    def _rx(self):
        while self._run:
            try:
                data, addr = self.sock.recvfrom(256)
            except socket.timeout:
                continue
            except OSError:
                break
            msg = unpack_msg(data)
            if not msg:
                continue
            cmd, seq, reg, val = msg
            if cmd == CMD_H:
                continue
            if cmd != CMD_A:
                self.status.emit("忽略非ACK 0x%02X 来自 %s" % (cmd, addr[0]))
                continue
            self.ack.emit(seq, reg, val, 1)

    def send(self, cmd, reg, data, ip=FPGA_IP):
        self.seq = (self.seq + 1) & 0xFF
        if self.seq == 0:
            self.seq = 1
        self.sock.sendto(pack_msg(cmd, self.seq, reg, data), (ip, FPGA_PORT))
        self.status.emit("发送 %s  寄存器 %s  数据 %d" % ("写" if cmd == CMD_W else "读", hex(reg), data))
        return self.seq

    def close(self):
        self._run = False
        try:
            self.sock.close()
        except OSError:
            pass


class Main(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("灰卡白平衡 / Q8.8 增益")
        self.link = UdpLink()
        self.link.ack.connect(self.on_ack)
        self.link.status.connect(self.on_status)
        self._pending = {}
        self._busy = False
        self._mean = {REG_MR: None, REG_MG: None, REG_MB: None, REG_MF: None}
        self._cal_busy = False

        lay = QVBoxLayout(self)

        box_net = QGroupBox("网口  FPGA 192.168.10.10:5000  本机有线请设 192.168.10.12")
        row = QHBoxLayout(box_net)
        row.addWidget(QLabel("FPGA IP"))
        self.ip = QLineEdit(FPGA_IP)
        row.addWidget(self.ip)
        btn_ping = QPushButton("Ping")
        btn_ping.clicked.connect(self.do_ping)
        btn_rd = QPushButton("读回全部")
        btn_rd.clicked.connect(self.read_all)
        btn_wr = QPushButton("全部下发")
        btn_wr.clicked.connect(self.write_all)
        row.addWidget(btn_ping)
        row.addWidget(btn_rd)
        row.addWidget(btn_wr)
        lay.addWidget(box_net)

        box_gain = QGroupBox("RGB 数字增益 Q8.8（256=1.00x，64~1024）。模拟增益写 Sensor 0x3E08/09（0~177）")
        grid = QGridLayout(box_gain)
        self.sliders = {}
        self.fb = {}
        self.limits = {}
        for i, (name, reg, mn, mx, init) in enumerate((
            ("R 数字增益", REG_R, Q88_MIN, Q88_MAX, Q88_1X),
            ("G 数字增益", REG_G, Q88_MIN, Q88_MAX, Q88_1X),
            ("B 数字增益", REG_B, Q88_MIN, Q88_MAX, Q88_1X),
            ("模拟增益", REG_AG, 0, 177, 40),
        )):
            grid.addWidget(QLabel(name), i, 0)
            sl = QSlider(Qt.Horizontal)
            sl.setRange(mn, mx)
            sl.setValue(init)
            sl.setPageStep(1 if mx <= 7 else 8)
            sp = QSpinBox()
            sp.setRange(mn, mx)
            sp.setValue(init)
            fb = QLabel("回读 --")
            sl.valueChanged.connect(lambda v, s=sp, r=reg: self._on_ui(r, s, v))
            sp.valueChanged.connect(lambda v, s=sl, r=reg: self._on_ui(r, s, v))
            grid.addWidget(sl, i, 1)
            grid.addWidget(sp, i, 2)
            grid.addWidget(fb, i, 3)
            self.sliders[reg] = (sl, sp)
            self.fb[reg] = fb
            self.limits[reg] = (mn, mx)
        lay.addWidget(box_gain)

        box_cal = QGroupBox("灰卡标定（HDMI 正中红框 256x256，统计在白平衡之前）")
        cal = QVBoxLayout(box_cal)
        rowc = QHBoxLayout()
        b1 = QPushButton("增益打到 1.00x")
        b1.clicked.connect(self.gain_unity)
        b2 = QPushButton("对准灰卡，采集并下发")
        b2.clicked.connect(self.do_gray)
        rowc.addWidget(b1)
        rowc.addWidget(b2)
        cal.addLayout(rowc)
        self.lab_mean = QLabel("均值 --   建议：白纸/灰卡铺满正中红框内侧，别反光、别过曝。")
        self.lab_mean.setWordWrap(True)
        cal.addWidget(self.lab_mean)
        lay.addWidget(box_cal)

        box_cam = QGroupBox("摄像头 I2C 写（任务3通道可复用）")
        cam = QHBoxLayout(box_cam)
        cam.addWidget(QLabel("地址 0x"))
        self.cam_a = QLineEdit("3221")
        cam.addWidget(self.cam_a)
        cam.addWidget(QLabel("数据 0x"))
        self.cam_d = QLineEdit("06")
        cam.addWidget(self.cam_d)
        bw = QPushButton("写入")
        bw.clicked.connect(self.write_cam)
        cam.addWidget(bw)
        lay.addWidget(box_cam)

        self.lab = QLabel("先烧新比特再开本工具。256=原图；绿偏时灰卡采集会抬 R/B。")
        self.lab.setWordWrap(True)
        lay.addWidget(self.lab)

        self.tm = QTimer(self)
        self.tm.setSingleShot(True)
        self.tm.timeout.connect(self._flush)
        self.verify = QTimer(self)
        self.verify.setSingleShot(True)
        self.verify.timeout.connect(self.read_all)
        QTimer.singleShot(400, self.read_all)

    def _ip(self):
        return self.ip.text().strip()

    def _on_ui(self, reg, peer, val):
        if self._busy or self._cal_busy:
            if peer.value() != val:
                peer.blockSignals(True)
                peer.setValue(val)
                peer.blockSignals(False)
            return
        if peer.value() != val:
            peer.blockSignals(True)
            peer.setValue(val)
            peer.blockSignals(False)
        self._pending[reg] = val
        self.tm.start(80)

    def _flush(self):
        ip = self._ip()
        items = list(self._pending.items())
        self._pending.clear()
        for reg, val in items:
            self.link.send(CMD_W, reg, val, ip)
        if items:
            self.verify.start(250)

    def write_reg(self, reg, val):
        self.link.send(CMD_W, reg, val, self._ip())

    def write_all(self):
        ip = self._ip()
        for reg, (sl, _sp) in self.sliders.items():
            self.link.send(CMD_W, reg, sl.value(), ip)
        self.verify.start(250)

    def gain_unity(self):
        ip = self._ip()
        for reg in (REG_R, REG_G, REG_B):
            self.link.send(CMD_W, reg, Q88_1X, ip)
        self._set_slider(REG_R, Q88_1X)
        self._set_slider(REG_G, Q88_1X)
        self._set_slider(REG_B, Q88_1X)
        self.verify.start(250)

    def write_cam(self):
        try:
            addr = int(self.cam_a.text(), 16) & 0xFFFF
            data = int(self.cam_d.text(), 16) & 0xFF
        except ValueError:
            self.lab.setText("摄像头寄存器请填十六进制")
            return
        self.link.send(CMD_W, REG_CAM, (addr << 16) | data, self._ip())

    def read_all(self):
        ip = self._ip()
        for r in (REG_R, REG_G, REG_B, REG_AG, REG_MR, REG_MG, REG_MB, REG_MF, REG_MP):
            self.link.send(CMD_R, r, 0, ip)

    def do_gray(self):
        if self._cal_busy:
            return
        self._cal_busy = True
        self.lab_mean.setText("采集中：先把增益打到 1.00x，等两帧再读中心均值…")
        ip = self._ip()
        for reg in (REG_R, REG_G, REG_B):
            self.link.send(CMD_W, reg, Q88_1X, ip)
        self._set_slider(REG_R, Q88_1X)
        self._set_slider(REG_G, Q88_1X)
        self._set_slider(REG_B, Q88_1X)
        QTimer.singleShot(280, self._cal_read)

    def _cal_read(self):
        self._mean = {REG_MR: None, REG_MG: None, REG_MB: None, REG_MF: None}
        ip = self._ip()
        for r in (REG_MR, REG_MG, REG_MB, REG_MF, REG_MP):
            self.link.send(CMD_R, r, 0, ip)
        QTimer.singleShot(250, self._cal_apply)

    def _cal_apply(self):
        r, g, b = self._mean[REG_MR], self._mean[REG_MG], self._mean[REG_MB]
        self._cal_busy = False
        if r is None or g is None or b is None:
            self.lab_mean.setText("没读到中心均值。本机网口是否 192.168.10.12，比特是否已烧新版？")
            return
        if min(r, g, b) < 8:
            self.lab_mean.setText("均值太暗 R=%d G=%d B=%d，加灯或提高曝光后再采。" % (r, g, b))
            return
        if max(r, g, b) > 250:
            self.lab_mean.setText("均值接近饱和 R=%d G=%d B=%d，灰卡别反光、略降曝光再采。" % (r, g, b))
            return
        kr = int(round(256.0 * g / float(r)))
        kg = Q88_1X
        kb = int(round(256.0 * g / float(b)))
        kr = max(Q88_MIN, min(Q88_MAX, kr))
        kb = max(Q88_MIN, min(Q88_MAX, kb))
        ip = self._ip()
        self.link.send(CMD_W, REG_R, kr, ip)
        self.link.send(CMD_W, REG_G, kg, ip)
        self.link.send(CMD_W, REG_B, kb, ip)
        self._set_slider(REG_R, kr)
        self._set_slider(REG_G, kg)
        self._set_slider(REG_B, kb)
        bake = "上电默认可写成  R=%d  G=%d  B=%d   （%.3fx / %.3fx / %.3fx）" % (
            kr, kg, kb, kr / 256.0, kg / 256.0, kb / 256.0)
        self.lab_mean.setText(
            "灰卡均值 R=%d G=%d B=%d  帧=%s。已下发 %s。看红框里是不是中性灰。"
            % (r, g, b, self._mean.get(REG_MF), bake)
        )
        self.verify.start(300)

    def do_ping(self):
        import subprocess
        ip = self._ip()
        try:
            p = subprocess.run(
                ["ping", "-n", "1", "-S", BIND_IP, "-w", "800", ip],
                capture_output=True, text=True, timeout=3
            )
            ok = p.returncode == 0
            self.lab.setText(("Ping %s 成功" if ok else "Ping %s 失败，检查本机有线是否 192.168.10.12") % ip)
        except Exception as e:
            self.lab.setText("Ping 失败: %s" % e)

    def _set_slider(self, reg, val):
        sl, sp = self.sliders[reg]
        self._busy = True
        sl.blockSignals(True)
        sp.blockSignals(True)
        sl.setValue(val)
        sp.setValue(val)
        sl.blockSignals(False)
        sp.blockSignals(False)
        self._busy = False

    def on_ack(self, seq, reg, val, _ok):
        if reg == REG_MP:
            self._mean[REG_MR] = (val >> 16) & 0xFF
            self._mean[REG_MG] = (val >> 8) & 0xFF
            self._mean[REG_MB] = val & 0xFF
            return
        if reg in self._mean:
            self._mean[reg] = val & 0xFFFF if reg == REG_MF else val & 0xFF
            return
        if reg not in self.sliders:
            return
        mn, mx = self.limits[reg]
        if val < mn or val > mx:
            self.fb[reg].setText("回读忽略 %d" % val)
            return
        txt = q88_text(val) if reg in (REG_R, REG_G, REG_B) else ("回读 %d" % val)
        self.fb[reg].setText(txt)
        sl, sp = self.sliders[reg]
        self._busy = True
        sl.blockSignals(True)
        sp.blockSignals(True)
        sl.setValue(val)
        sp.setValue(val)
        sl.blockSignals(False)
        sp.blockSignals(False)
        self._busy = False

    def on_status(self, s):
        if not self._cal_busy:
            self.lab.setText(s)

    def closeEvent(self, e):
        self.link.close()
        super().closeEvent(e)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    w = Main()
    w.resize(720, 520)
    w.show()
    sys.exit(app.exec_())
