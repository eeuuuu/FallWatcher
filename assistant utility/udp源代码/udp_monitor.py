#!/usr/bin/env python3
# 客户界面：UDP 5002 事件+缩略图，5001 CPU 打印。日志最新在上。
from __future__ import print_function
import argparse
import json
import os
import socket
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import protocol as p


def _ensure_stdio():
    # PyInstaller --windowed 时 stdout/stderr 为 None，listen 线程里 print/flush 会直接退出。
    if sys.stdout is None:
        sys.stdout = open(os.devnull, "w")
    if sys.stderr is None:
        sys.stderr = open(os.devnull, "w")

try:
    from PyQt5.QtCore import Qt, QTimer, pyqtSignal, QObject
    from PyQt5.QtGui import QImage, QPixmap, QFont, QColor, QPainter, QPen, QPalette, QTextCursor
    from PyQt5.QtWidgets import (
        QApplication, QWidget, QLabel, QVBoxLayout, QHBoxLayout, QFrame,
        QTableWidget, QTableWidgetItem, QPlainTextEdit, QHeaderView,
        QSplitter, QSizePolicy, QAbstractItemView, QPushButton
    )
    QT5 = True
except ImportError:
    from PyQt6.QtCore import Qt, QTimer, pyqtSignal, QObject
    from PyQt6.QtGui import QImage, QPixmap, QFont, QColor, QPainter, QPen, QPalette, QTextCursor
    from PyQt6.QtWidgets import (
        QApplication, QWidget, QLabel, QVBoxLayout, QHBoxLayout, QFrame,
        QTableWidget, QTableWidgetItem, QPlainTextEdit, QHeaderView,
        QSplitter, QSizePolicy, QAbstractItemView, QPushButton
    )
    QT5 = False

EVT_COLOR = {
    "IDL": "#94a3b8",
    "MOT": "#60a5fa",
    "IR": "#c084fc",
    "IN": "#34d399",
    "FAL": "#f87171",
    "AC": "#fbbf24",
}
EVT_BG = {
    "IDL": "#1e293b",
    "MOT": "#1e3a5f",
    "IR": "#3b1d5c",
    "IN": "#064e3b",
    "FAL": "#7f1d1d",
    "AC": "#78350f",
}

QSS = """
QWidget { background: #0b1220; color: #e8eef7; font-family: "Microsoft YaHei UI", "Segoe UI", sans-serif; }
QLabel { background: transparent; }
QFrame#Card { background: #121a2b; border: 1px solid #243044; border-radius: 10px; }
QFrame#Kpi { background: #121a2b; border: 1px solid #243044; border-radius: 10px; }
QLabel#KpiTitle { color: #8b9cb3; font-size: 12px; }
QLabel#KpiValue { color: #f8fafc; font-size: 22px; font-weight: 700; }
QLabel#EvtName { font-size: 56px; font-weight: 800; }
QLabel#EvtSub { color: #93a4bb; font-size: 13px; }
QTableWidget {
    background: #0f172a; alternate-background-color: #152036;
    gridline-color: #243044; border: none; color: #e8eef7;
}
QHeaderView::section { background: #152036; color: #93a4bb; border: none; padding: 6px; }
QPlainTextEdit {
    background: #0f172a; color: #dbe7f5; border: 1px solid #243044;
    border-radius: 8px; font-family: Consolas, "Sarasa Mono SC", monospace; font-size: 12px;
}
QLabel#Section { color: #93a4bb; font-size: 12px; font-weight: 600; padding: 4px 2px; }
QPushButton#ArmBtn {
    min-width: 280px; min-height: 72px; border-radius: 10px;
    font-size: 20px; font-weight: 800; text-align: left; padding: 10px 18px;
}
QLabel#ArmHint { color: #93a4bb; font-size: 13px; }
QLabel#DemoHint { color: #fbbf24; font-size: 14px; font-weight: 700; }
"""

def _align():
    return Qt.AlignLeft | Qt.AlignVCenter if QT5 else Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter


def _queued():
    return Qt.QueuedConnection if QT5 else Qt.ConnectionType.QueuedConnection


def clean_print_bytes(data):
    if not data:
        return ""
    data = data.replace(b"\x00", b"")
    s = data.decode("ascii", errors="ignore")
    if not s.strip():
        try:
            s = data.decode("gbk", errors="ignore")
        except Exception:
            s = data.decode("latin-1", errors="ignore")
    out = []
    for ch in s:
        o = ord(ch)
        if ch in "\r\n\t" or 32 <= o < 127 or o > 127:
            out.append(ch)
    return "".join(out)


class Hub(QObject):
    updated = pyqtSignal()

    def __init__(self):
        super(Hub, self).__init__()
        self.lock = threading.Lock()
        self.event = None
        self.thumb = bytearray(p.THUMB_N)
        self.thumb_seq = -1
        self.got = [0] * 16
        self.log = []
        self.print_lines = []
        self.print_buf = ""
        self.pkt_n = 0
        self.last_rx = 0.0
        self._emit_t = 0.0
        self.listen = ""
        self.listen_err = ""

    def _kick(self, force=False):
        now = time.time()
        if force or (now - self._emit_t) > 0.08:
            self._emit_t = now
            self.updated.emit()

    def push_bin(self, data, addr):
        msg = p.parse_packet(data)
        if not msg:
            return
        force = False
        with self.lock:
            self.pkt_n += 1
            self.last_rx = time.time()
            if msg["type"] == "event":
                self.event = msg
                line = "%s  seq=%d  人检=%d 置信=%d  TA=%d TO=%d  推理=%dms  框=%s" % (
                    msg["evt_name"], msg["seq"], msg["pd_on"], msg["conf"],
                    msg["ta"], msg["to"], msg["infer_ms"], msg["box"])
                self.log.insert(0, line)
                self.log = self.log[:60]
                force = True
                if msg.get("has_thumb"):
                    self.got = [0] * 16
            elif msg["type"] == "thumb":
                off, n = msg["offset"], msg["length"]
                if off + n <= p.THUMB_N:
                    self.thumb[off:off + n] = msg["data"]
                    self.thumb_seq = msg["seq"]
                    if msg["idx"] < 16:
                        self.got[msg["idx"]] = 1
                    nch = msg.get("nchunk") or 0
                    force = nch and (msg["idx"] + 1 >= nch)
        self._kick(force)

    def push_text(self, data):
        s = clean_print_bytes(data)
        if not s:
            return
        with self.lock:
            self.print_buf += s
            self.print_buf = self.print_buf.replace("\r\n", "\n").replace("\r", "\n")
            if len(self.print_buf) > 8000:
                self.print_buf = self.print_buf[-4000:]
            parts = self.print_buf.split("\n")
            self.print_buf = parts[-1]
            for line in parts[:-1]:
                t = line.strip()
                if t:
                    self.print_lines.insert(0, t)
            self.print_lines = self.print_lines[:80]
        self._kick(True)

    def snapshot(self):
        with self.lock:
            return {
                "event": dict(self.event) if self.event else None,
                "thumb": bytes(self.thumb),
                "thumb_seq": self.thumb_seq,
                "log": list(self.log),
                "print_lines": list(self.print_lines),
                "pkt_n": self.pkt_n,
                "last_rx": self.last_rx,
                "listen": self.listen,
                "listen_err": self.listen_err,
            }


def listen_udp(hub, bind_ip, port, kind):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        try:
            s.bind((bind_ip, port))
            bound = bind_ip
        except OSError:
            s.bind(("", port))
            bound = "0.0.0.0"
    except OSError as e:
        with hub.lock:
            hub.listen_err = "%s %s:%d  %s" % (kind, bind_ip, port, e)
        hub._kick(True)
        return
    with hub.lock:
        bits = (hub.listen + "  " if hub.listen else "") + "%s %s:%d" % (kind, bound, port)
        hub.listen = bits.strip()
    print("listen %s %s:%d" % (kind, bound, port))
    sys.stdout.flush()
    while True:
        data, addr = s.recvfrom(2048)
        if kind == "bin":
            hub.push_bin(data, addr)
        else:
            hub.push_text(data)


def start_web(hub, port):
    try:
        from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    except ImportError:
        from BaseHTTPServer import BaseHTTPRequestHandler
        from SocketServer import ThreadingMixIn
        from http.server import HTTPServer

        class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
            pass

    html = """<!doctype html><meta charset=utf-8>
<title>赛题三 UDP 监控</title>
<style>
body{font-family:sans-serif;background:#0b1220;color:#e8eef7;margin:16px}
.evt{font-size:48px;font-weight:800}
.meta{color:#93a4bb;margin:8px 0 16px}
.grid{display:flex;gap:24px;flex-wrap:wrap}
pre{background:#0f172a;padding:12px;min-width:420px;white-space:pre-wrap}
img{image-rendering:pixelated;width:384px;height:384px;background:#000}
h3{color:#93a4bb;font-size:13px;margin:0 0 8px}
</style>
<div class=evt id=evt>--</div>
<div class=meta id=meta></div>
<div style="color:#fbbf24;font-weight:700;margin:0 0 8px">人员演示须距摄像头 2 米以上</div>
<div class=grid>
<img id=th>
<button id=arm type=button style="display:block;margin:8px 0 4px;min-width:280px;min-height:64px;border:0;border-radius:10px;font-size:20px;font-weight:800;text-align:left;padding:10px 18px;cursor:pointer;background:#334155;color:#e8eef7">警戒使能　已关闭</button>
<div id=armh style="color:#93a4bb;margin:0 0 16px">入框不蜂鸣 · 跌倒/过热仍响 · 点按切换</div>
<div class=grid>
<img id=th>
<div>
<h3>5002 最新在上</h3>
<pre id=log></pre>
<h3>5001 最新在上</h3>
<pre id=prn></pre>
</div>
</div>
<script>
async function tick(){
  const j = await fetch('/api/status').then(r=>r.json());
  const e = j.event;
  document.getElementById('evt').textContent = e ? (e.evt_name_zh || e.evt_name) : '等待 UDP…';
  document.getElementById('evt').style.color = e && e.evt_name==='FAL' ? '#f87171' : '#34d399';
  document.getElementById('meta').textContent = e ?
    ('seq='+e.seq+' 人检='+e.pd_on+' 置信='+e.conf+' 推理='+e.infer_ms+'ms TA='+e.ta+' TO='+e.to+' SHT='+e.sht) : '';
  document.getElementById('log').textContent = (j.log||[]).slice(0,16).join('\\n');
  document.getElementById('prn').textContent = (j.print_lines||[]).slice(0,12).join('\\n');
  document.getElementById('th').src = '/api/thumb?t=' + Date.now();
}
let armOn=0;
function paintArm(){
  const b=document.getElementById('arm'), h=document.getElementById('armh');
  if(armOn){ b.textContent='警戒使能　已开启'; b.style.background='#9a3412'; b.style.color='#fff7ed';
    h.textContent='有人进入即蜂鸣 · 再按关闭 · 跌倒/过热仍响'; }
  else { b.textContent='警戒使能　已关闭'; b.style.background='#334155'; b.style.color='#e8eef7';
    h.textContent='入框不蜂鸣 · 跌倒/过热仍响 · 点按切换'; }
}
async function setArm(on){
  for(let i=0;i<3;i++){
    try {
      await fetch('http://192.168.10.10/a?'+(on?1:0));
      const j=await fetch('http://192.168.10.10/s').then(r=>r.json());
      if((j.arm|0)===(on?1:0)){ armOn=on?1:0; paintArm(); return; }
    } catch(e) {}
  }
  document.getElementById('armh').textContent='板卡未确认，保持原状态';
}
document.getElementById('arm').onclick=function(){ setArm(armOn?0:1); };
paintArm();
setInterval(tick, 400); tick();
</script>"""

    class H(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            return

        def do_GET(self):
            snap = hub.snapshot()
            if self.path.startswith("/api/status"):
                ev = snap["event"]
                if ev:
                    ev = dict(ev)
                body = json.dumps({
                    "event": ev,
                    "log": snap["log"],
                    "print_lines": snap.get("print_lines") or [],
                    "pkt_n": snap["pkt_n"],
                }).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
            if self.path.startswith("/api/thumb"):
                raw = snap["thumb"]
                try:
                    from PIL import Image
                    import io
                    im = Image.frombytes("L", (p.THUMB_W, p.THUMB_H), raw)
                    im = im.resize((384, 384), Image.NEAREST)
                    buf = io.BytesIO()
                    im.save(buf, format="PNG")
                    body = buf.getvalue()
                    ctype = "image/png"
                except Exception:
                    body = raw
                    ctype = "application/octet-stream"
                self.send_response(200)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
            body = html.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    srv = ThreadingHTTPServer(("0.0.0.0", port), H)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    print("web http://127.0.0.1:%d  (board HTTP: http://192.168.10.10/ )" % port)


def kpi_card(title):
    box = QFrame()
    box.setObjectName("Kpi")
    box.setMinimumWidth(140)
    t = QLabel(title)
    t.setObjectName("KpiTitle")
    v = QLabel("--")
    v.setObjectName("KpiValue")
    v.setAlignment(_align())
    lay = QVBoxLayout()
    lay.setContentsMargins(14, 10, 14, 12)
    lay.addWidget(t)
    lay.addWidget(v)
    box.setLayout(lay)
    return box, v


class Win(QWidget):
    arm_done = pyqtSignal(int, int, str)

    def __init__(self, hub):
        super(Win, self).__init__()
        self.hub = hub
        self.setWindowTitle("赛题三  现场监控")
        self.resize(1280, 820)
        self._last_seq = None

        head = QFrame()
        head.setObjectName("Card")
        self.evt = QLabel("等待 5002")
        self.evt.setObjectName("EvtName")
        self.sub = QLabel("最新状态固定在本页顶部；下方日志新→旧")
        self.sub.setObjectName("EvtSub")
        hl = QVBoxLayout()
        hl.setContentsMargins(20, 12, 20, 14)
        self.arm_on = False
        self._arm_busy = False
        self.arm_btn = QPushButton()
        self.arm_btn.setObjectName("ArmBtn")
        self.arm_btn.setCursor(Qt.PointingHandCursor if QT5 else Qt.CursorShape.PointingHandCursor)
        self.arm_btn.clicked.connect(self._toggle_arm)
        self.arm_hint = QLabel()
        self.arm_hint.setObjectName("ArmHint")
        self.demo_hint = QLabel("人员演示须距摄像头 2 米以上")
        self.demo_hint.setObjectName("DemoHint")
        self._paint_arm("入框不蜂鸣 · 跌倒/过热仍响 · 点按切换")
        hl.addWidget(self.evt)
        hl.addWidget(self.sub)
        hl.addWidget(self.arm_btn)
        hl.addWidget(self.arm_hint)
        hl.addWidget(self.demo_hint)
        head.setLayout(hl)

        row = QHBoxLayout()
        row.setSpacing(10)
        self.k_pd, self.v_pd = kpi_card("TinyML 人检")
        self.k_cf, self.v_cf = kpi_card("人检置信")
        self.k_ir, self.v_ir = kpi_card("TA / TO")
        self.k_sht, self.v_sht = kpi_card("SHT ℃")
        self.k_ms, self.v_ms = kpi_card("推理 ms")
        self.k_pk, self.v_pk = kpi_card("包 / 帧")
        for w in (self.k_pd, self.k_cf, self.k_ir, self.k_sht, self.k_ms, self.k_pk):
            row.addWidget(w)

        self.thumb = QLabel()
        self.thumb.setFixedSize(420, 420)
        self.thumb.setStyleSheet("background:#000; border-radius:8px;")
        self.thumb.setAlignment(Qt.AlignCenter if QT5 else Qt.AlignmentFlag.AlignCenter)

        self.table = QTableWidget(4, 7)
        self.table.setHorizontalHeaderLabels(["tid", "x0", "y0", "x1", "y1", "中心", "预测"])
        self.table.horizontalHeader().setSectionResizeMode(
            QHeaderView.Stretch if QT5 else QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().setVisible(False)
        self.table.setEditTriggers(
            QAbstractItemView.NoEditTriggers if QT5 else QAbstractItemView.EditTrigger.NoEditTriggers)
        self.table.setAlternatingRowColors(True)
        self.table.setFocusPolicy(Qt.NoFocus if QT5 else Qt.FocusPolicy.NoFocus)

        left = QFrame()
        left.setObjectName("Card")
        ll = QVBoxLayout()
        ll.setContentsMargins(12, 10, 12, 12)
        cap = QLabel("48×48 缩略图 · 红框=融合  橙框=额外轨迹")
        cap.setObjectName("Section")
        ll.addWidget(cap)
        ll.addWidget(self.thumb, 0, Qt.AlignCenter if QT5 else Qt.AlignmentFlag.AlignCenter)
        left.setLayout(ll)

        right = QFrame()
        right.setObjectName("Card")
        rl = QVBoxLayout()
        rl.setContentsMargins(12, 10, 12, 12)
        cap2 = QLabel("IOU 轨迹")
        cap2.setObjectName("Section")
        rl.addWidget(cap2)
        rl.addWidget(self.table)
        right.setLayout(rl)

        mid = QHBoxLayout()
        mid.addWidget(left, 0)
        mid.addWidget(right, 1)

        self.log = QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setPlaceholderText("5002 事件，最新在最上面")
        self.txt = QPlainTextEdit()
        self.txt.setReadOnly(True)
        self.txt.setPlaceholderText("5001 CPU 打印，最新在最上面")
        wrap = QPlainTextEdit.NoWrap if QT5 else QPlainTextEdit.LineWrapMode.NoWrap
        for ed in (self.log, self.txt):
            ed.setLineWrapMode(wrap)

        logs = QSplitter(Qt.Horizontal if QT5 else Qt.Orientation.Horizontal)
        wlog = QWidget()
        wl = QVBoxLayout()
        wl.setContentsMargins(0, 0, 0, 0)
        t1 = QLabel("5002 事件日志（最新在上）")
        t1.setObjectName("Section")
        wl.addWidget(t1)
        wl.addWidget(self.log)
        wlog.setLayout(wl)
        wtxt = QWidget()
        wt = QVBoxLayout()
        wt.setContentsMargins(0, 0, 0, 0)
        t2 = QLabel("5001 打印（去空字节 / 最新在上）")
        t2.setObjectName("Section")
        wt.addWidget(t2)
        wt.addWidget(self.txt)
        wtxt.setLayout(wt)
        logs.addWidget(wlog)
        logs.addWidget(wtxt)
        logs.setSizes([700, 500])

        lay = QVBoxLayout()
        lay.setContentsMargins(16, 14, 16, 14)
        lay.setSpacing(10)
        lay.addWidget(head)
        lay.addLayout(row)
        lay.addLayout(mid, 0)
        lay.addWidget(logs, 1)
        self.setLayout(lay)
        hub.updated.connect(self.refresh, _queued())
        self.arm_done.connect(self._on_arm_done, _queued())
        QTimer.singleShot(200, self.refresh)
        QTimer.singleShot(400, self._sync_arm)
        self.sync_tm = QTimer(self)
        self.sync_tm.setInterval(2000)
        self.sync_tm.timeout.connect(self._sync_arm)
        self.sync_tm.start()

    _board_lock = threading.Lock()

    def _board(self, path):
        # Raw HTTP/1.0: urllib / proxy 可能把 /a?0 收成 /a，板卡只回当前状态 1。
        with self._board_lock:
            s = socket.create_connection(("192.168.10.10", 80), 1.8)
            try:
                s.settimeout(1.8)
                req = (
                    "GET %s HTTP/1.0\r\nHost: 192.168.10.10\r\n"
                    "Connection: close\r\n\r\n" % path
                ).encode("ascii")
                s.sendall(req)
                data = b""
                while True:
                    chunk = s.recv(4096)
                    if not chunk:
                        break
                    data += chunk
            finally:
                s.close()
        i = data.find(b"\r\n\r\n")
        return data[i + 4:] if i >= 0 else data

    def _paint_arm(self, hint=None):
        if self.arm_on:
            self.arm_btn.setText("警戒使能　　已开启")
            self.arm_btn.setStyleSheet(
                "QPushButton#ArmBtn { background:#9a3412; color:#fff7ed; border:2px solid #fb923c; }")
            default = "有人进入即蜂鸣 · 再按关闭 · 跌倒/过热仍响"
        else:
            self.arm_btn.setText("警戒使能　　已关闭")
            self.arm_btn.setStyleSheet(
                "QPushButton#ArmBtn { background:#334155; color:#e8eef7; border:2px solid #475569; }")
            default = "入框不蜂鸣 · 跌倒/过热仍响 · 点按切换"
        self.arm_hint.setText(hint if hint is not None else default)

    def _toggle_arm(self):
        if self._arm_busy:
            return
        want = 0 if self.arm_on else 1
        self._arm_busy = True
        self.arm_btn.setEnabled(False)
        self.arm_hint.setText("正在写入板卡…")
        threading.Thread(target=self._arm_worker, args=(want,), daemon=True).start()

    def _arm_worker(self, want):
        err = ""
        paths = (("/a?1", "/a?1&x=1") if want else ("/a?0", "/a?0&x=1"))
        for _ in range(4):
            for path in paths:
                try:
                    body = self._board(path)
                    print("arm %s -> %r" % (path, body[:16]))
                    sys.stdout.flush()
                    if body[:1] in (b"0", b"1") and int(body[:1]) == want:
                        raw = self._board("/s")
                        j = json.loads(raw.decode("utf-8"))
                        if int(j.get("arm", -1)) == want:
                            self.arm_done.emit(want, 1, "")
                            return
                        err = "状态未回读到 %d" % want
                    else:
                        err = "板卡返回 %s" % (body[:8],)
                except Exception as e:
                    err = str(e)
            time.sleep(0.35)
        self.arm_done.emit(want, 0, err)

    def _on_arm_done(self, want, ok, err):
        self._arm_busy = False
        self.arm_btn.setEnabled(True)
        if ok:
            self.arm_on = want != 0
            self._paint_arm()
            print("arm -> %d ok" % want)
        else:
            self._paint_arm("板卡未确认，仍是%s  %s" % (
                "已开启" if self.arm_on else "已关闭", err or ""))
            print("arm -> %d FAIL %s" % (want, err))
        sys.stdout.flush()

    def _sync_arm(self):
        if self._arm_busy:
            return
        try:
            raw = self._board("/s")
            j = json.loads(raw.decode("utf-8"))
            on = int(j.get("arm", 0)) != 0
            if on != self.arm_on:
                self.arm_on = on
                self._paint_arm()
        except Exception:
            pass

    def refresh(self):
        snap = self.hub.snapshot()
        ev = snap["event"]
        if not ev:
            if snap.get("listen_err"):
                self.sub.setText("监听失败  " + snap["listen_err"])
            elif snap.get("listen"):
                self.sub.setText("已监听 %s · 等待板卡 192.168.10.10 → 本机 5002" % snap["listen"])
        if ev:
            name = ev["evt_name"]
            self.evt.setText(ev.get("evt_name_zh", name))
            self.evt.setStyleSheet("color:%s; background:%s; padding:4px 12px; border-radius:8px;" % (
                EVT_COLOR.get(name, "#e8eef7"), EVT_BG.get(name, "#1e293b")))
            age = time.time() - snap["last_rx"] if snap["last_rx"] else 0
            self.sub.setText(
                "seq %d · FPGA框 %s · 预测 (%d,%d) · 低功耗 %s · 语音 %s · %.1fs 前收到" % (
                    ev["seq"], ev["box"], ev["px"], ev["py"],
                    "是" if ev["lp"] else "否",
                    "是" if ev.get("voice") else "否", age))
            self.v_pd.setText("有人" if ev["pd_on"] else "无人")
            self.v_pd.setStyleSheet("color:%s; font-size:22px; font-weight:700;" % (
                "#34d399" if ev["pd_on"] else "#94a3b8"))
            self.v_cf.setText(str(ev["conf"]))
            self.v_ir.setText("%d / %d" % (ev["ta"], ev["to"]))
            self.v_sht.setText(str(ev["sht"]))
            self.v_ms.setText(str(ev["infer_ms"]))
            self.v_pk.setText("%d / %d" % (snap["pkt_n"], ev["fr"]))
            for r in range(4):
                for c in range(7):
                    self.table.setItem(r, c, QTableWidgetItem(""))
            bx0, by0, bx1, by1 = ev["box"]
            for i, t in enumerate(ev["tracks"][:4]):
                pred = "%d,%d" % (ev["px"], ev["py"]) if i == 0 else ""
                vals = [str(t["tid"]), str(t["x0"]), str(t["y0"]), str(t["x1"]), str(t["y1"]),
                        "%d,%d" % (t["cx"], t["cy"]), pred]
                for c, v in enumerate(vals):
                    self.table.setItem(i, c, QTableWidgetItem(v))
        self.log.setPlainText("\n".join(snap["log"]))
        self.log.moveCursor(QTextCursor.Start if QT5 else QTextCursor.MoveOperation.Start)
        self.txt.setPlainText("\n".join(snap.get("print_lines") or []))
        self.txt.moveCursor(QTextCursor.Start if QT5 else QTextCursor.MoveOperation.Start)

        img = QImage(snap["thumb"], p.THUMB_W, p.THUMB_H, p.THUMB_W, QImage.Format_Grayscale8)
        pix = QPixmap.fromImage(img).scaled(420, 420, Qt.IgnoreAspectRatio if QT5 else Qt.AspectRatioMode.IgnoreAspectRatio,
                                            Qt.FastTransformation if QT5 else Qt.TransformationMode.FastTransformation)
        if ev and ev["evt_name"] in ("MOT", "IN", "FAL"):
            sx = 420.0 / 1920.0
            sy = 420.0 / 1056.0
            painter = QPainter(pix)
            painter.setRenderHint(QPainter.Antialiasing if QT5 else QPainter.RenderHint.Antialiasing, False)
            bx0, by0, bx1, by1 = ev["box"]
            if (bx1 - bx0) > 80 and (by1 - by0) > 40:
                painter.setPen(QPen(QColor(255, 64, 64), 3))
                painter.drawRect(int(bx0 * sx), int(by0 * sy),
                                 max(2, int((bx1 - bx0) * sx)),
                                 max(2, int((by1 - by0) * sy)))
            painter.setPen(QPen(QColor(255, 176, 64), 2))
            for t in ev["tracks"]:
                tw, th = t["x1"] - t["x0"], t["y1"] - t["y0"]
                ix0, iy0 = max(t["x0"], bx0), max(t["y0"], by0)
                ix1, iy1 = min(t["x1"], bx1), min(t["y1"], by1)
                inter = max(0, ix1 - ix0) * max(0, iy1 - iy0)
                uni = tw * th + (bx1 - bx0) * (by1 - by0) - inter
                iou = (100 * inter // uni) if uni > 0 else 0
                cover = (100 * inter // (tw * th)) if tw * th else 0
                if iou >= 25 or cover >= 40:
                    continue
                painter.drawRect(int(t["x0"] * sx), int(t["y0"] * sy),
                                 max(2, int(tw * sx)), max(2, int(th * sy)))
            if ev["px"] or ev["py"]:
                painter.setPen(QPen(QColor(80, 220, 80), 2))
                painter.drawEllipse(int(ev["px"] * sx) - 5, int(ev["py"] * sy) - 5, 10, 10)
            painter.end()
        self.thumb.setPixmap(pix)


def main():
    _ensure_stdio()
    ap = argparse.ArgumentParser()
    ap.add_argument("--bind", default="0.0.0.0", help="监听地址，0.0.0.0 可同时收板卡和本机仿真")
    ap.add_argument("--port", type=int, default=p.BIN_PORT)
    ap.add_argument("--print-port", type=int, default=p.PRINT_PORT)
    ap.add_argument("--web", type=int, default=8088, help="0 关闭 HTTP")
    ap.add_argument("--no-gui", action="store_true")
    args = ap.parse_args()
    hub = Hub()
    threading.Thread(target=listen_udp, args=(hub, args.bind, args.port, "bin"), daemon=True).start()
    threading.Thread(target=listen_udp, args=(hub, args.bind, args.print_port, "text"), daemon=True).start()
    if args.web:
        start_web(hub, args.web)
    if args.no_gui:
        print("no-gui, Ctrl+C 停")
        while True:
            time.sleep(1)
            snap = hub.snapshot()
            ev = snap["event"]
            if ev:
                print("seq=%d %s ntrk=%d lp=%d" % (ev["seq"], ev["evt_name"], ev["ntrack"], ev["lp"]))
        return
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    pal = QPalette()
    pal.setColor(QPalette.Window if QT5 else QPalette.ColorRole.Window, QColor("#0b1220"))
    app.setStyleSheet(QSS)
    w = Win(hub)
    w.show()
    sys.exit(app.exec_() if hasattr(app, "exec_") else app.exec())


if __name__ == "__main__":
    _ensure_stdio()
    main()
