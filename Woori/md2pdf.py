#!/usr/bin/env python3
"""Markdown → PDF 변환 — Woori 목장 나눔 자료용.

Trading/src/md2pdf.py 의 Chrome CDP 렌더링 기법을 가져와 목장 나눔 문서에 맞춤.
마크다운 → HTML → Chrome 헤드리스(CDP) → PDF.

사용법:
    python3 md2pdf.py "<input.md>" ["<output.pdf>"]
출력 경로 미지정 시 입력 .md 옆에 같은 이름의 .pdf 생성.

의존성: markdown, websocket-client (pip install markdown websocket-client), Google Chrome.
"""
from __future__ import annotations

import base64
import json
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 목장 나눔 자료 — 함께 보기 좋은 가독성 위주 CSS (Trading 기법 차용, 교회 문서 톤)
CSS = r"""
@page { size: A4; margin: 12mm; }

body {
  font-family: 'Apple SD Gothic Neo', 'Pretendard', 'Noto Sans KR', -apple-system, BlinkMacSystemFont, sans-serif;
  font-size: 11pt;
  line-height: 1.6;
  color: #2a2a2e;
  background: #ffffff;
  margin: 0;
  word-break: keep-all;
  overflow-wrap: break-word;
  -webkit-font-smoothing: antialiased;
  letter-spacing: -0.005em;
}

h1 {
  font-size: 21pt;
  font-weight: 800;
  color: #ffffff;
  background: #1f3a5c;
  padding: 15px 24px;
  border-radius: 8px;
  margin: 0 0 4px 0;
  letter-spacing: -0.3px;
}
h1 + p {
  font-size: 10pt;
  margin: 0 0 18px 4px;
}

h2 {
  font-size: 14pt;
  font-weight: 700;
  color: #1f3a5c;
  background: #eef2f7;
  border-left: 5px solid #1f3a5c;
  padding: 9px 16px;
  border-radius: 0 6px 6px 0;
  margin: 20px 0 10px 0;
}

h3 {
  font-size: 12.5pt;
  font-weight: 700;
  color: #1f3a5c;
  margin: 16px 0 7px 0;
  padding-bottom: 5px;
  border-bottom: 1.5px solid #d4dde8;
}

h4 {
  font-size: 11pt;
  font-weight: 700;
  color: #8a6a35;
  margin: 16px 0 0 0;
  padding: 7px 13px;
  background: #f6f1e6;
  border-radius: 6px 6px 0 0;
}

p { margin: 6px 0; }

strong { color: #1f3a5c; font-weight: 700; }
em { font-style: normal; color: #8a6a35; font-weight: 600; }

/* 성경 본문 — 크림색 카드 */
blockquote {
  background: #faf6ea;
  border-left: 4px solid #8a6a35;
  padding: 12px 18px;
  margin: 12px 0;
  border-radius: 6px;
  font-size: 10.5pt;
  line-height: 1.85;
}
blockquote p { margin: 3px 0; }
blockquote strong { color: #8a6a35; }

/* 함께 나눌 질문 — h4 바로 뒤 목록을 박스로 묶음 */
h4 + ol {
  margin: 0 0 14px 0;
  padding: 11px 18px 11px 40px;
  background: #f6f1e6;
  border-radius: 0 0 6px 6px;
  break-inside: avoid;
}
h4 + ol li { margin: 6px 0; }

ul, ol { margin: 8px 0; padding-left: 26px; }
li { margin: 5px 0; break-inside: avoid; }
ul li::marker { color: #8a6a35; }
ol li::marker { color: #8a6a35; font-weight: 700; }

hr { border: none; border-top: 1px solid #d4dde8; margin: 18px 0; }

h1, h2, h3, h4 { break-after: avoid; page-break-after: avoid; }
.page-break { break-before: page; page-break-before: always; height: 0; margin: 0; }
.page-break + h2, .page-break + h3 { margin-top: 0; }

table { width: 100%; border-collapse: collapse; margin: 10px 0 14px 0; font-size: 10pt; break-inside: avoid; }
th { background: #1f3a5c; color: #ffffff; font-weight: 700; text-align: left; padding: 7px 10px; border: 1px solid #1f3a5c; }
td { padding: 6px 10px; border: 1px solid #d4dde8; vertical-align: top; }
tr:nth-child(even) td { background: #f6f8fb; }

.key { background: #eef2f7; border-left: 4px solid #1f3a5c; padding: 9px 14px; margin: 10px 0 13px 0; border-radius: 0 6px 6px 0; font-weight: 600; color: #1f3a5c; break-inside: avoid; }
"""

FOOTER_TEMPLATE = (
    '<div style="font-size:8pt;color:#9aa7b4;width:100%;text-align:center;'
    'font-family:sans-serif;">'
    '<span class="pageNumber"></span> / <span class="totalPages"></span>'
    '</div>'
)
HEADER_TEMPLATE = "<span></span>"


def md_to_html(md_text: str) -> str:
    """마크다운 → HTML (GFM 테이블·코드블록 지원)."""
    import markdown

    return markdown.markdown(md_text, extensions=["tables", "fenced_code"])


def _free_port() -> int:
    with socket.socket() as s:
        s.bind(("", 0))
        return s.getsockname()[1]


def chrome_cdp_pdf(html_path: str, out_pdf: str) -> None:
    """Chrome 헤드리스(CDP)로 HTML 파일 → PDF (Trading npc_briefing_pdf 기법)."""
    if not Path(CHROME).exists():
        raise RuntimeError(f"Chrome 없음: {CHROME}")

    import websocket  # websocket-client

    port = _free_port()
    proc = subprocess.Popen(
        [
            CHROME, "--headless=new", "--disable-gpu", "--no-sandbox",
            "--no-first-run", "--no-default-browser-check",
            "--remote-allow-origins=*", f"--remote-debugging-port={port}",
            f"file://{html_path}",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        ws_url = None
        for _ in range(30):
            try:
                resp = urllib.request.urlopen(f"http://localhost:{port}/json")
                for t in json.loads(resp.read()):
                    if t.get("type") == "page":
                        ws_url = t["webSocketDebuggerUrl"]
                        break
                if ws_url:
                    break
            except (OSError, json.JSONDecodeError):
                pass
            time.sleep(0.3)
        if not ws_url:
            raise RuntimeError("Chrome CDP 연결 실패")

        ws = websocket.create_connection(ws_url, timeout=20)

        def send(method, params=None, cmd_id=1):
            msg = {"id": cmd_id, "method": method}
            if params:
                msg["params"] = params
            ws.send(json.dumps(msg))
            while True:
                r = json.loads(ws.recv())
                if r.get("id") == cmd_id:
                    return r

        send("Page.enable", cmd_id=1)
        time.sleep(0.9)
        result = send(
            "Page.printToPDF",
            params={
                "displayHeaderFooter": True,
                "headerTemplate": HEADER_TEMPLATE,
                "footerTemplate": FOOTER_TEMPLATE,
                "printBackground": True,
                "paperWidth": 8.27,
                "paperHeight": 11.69,
                "marginTop": 0.47,
                "marginBottom": 0.47,
                "marginLeft": 0.47,
                "marginRight": 0.47,
            },
            cmd_id=2,
        )
        ws.close()
        if "result" not in result or "data" not in result["result"]:
            raise RuntimeError(f"PDF 생성 실패: {result}")
        Path(out_pdf).write_bytes(base64.b64decode(result["result"]["data"]))
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def convert(md_path: Path, out_path: Path | None = None) -> Path:
    """단일 .md → .pdf 변환."""
    md_text = md_path.read_text(encoding="utf-8")
    if not md_text.strip():
        raise ValueError(f"빈 파일: {md_path}")
    html_body = md_to_html(md_text)
    title = md_path.stem
    full_html = (
        '<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8">'
        f"<title>{title}</title><style>{CSS}</style></head>"
        f"<body>{html_body}</body></html>"
    )
    out = out_path or md_path.with_suffix(".pdf")
    with tempfile.NamedTemporaryFile(
        "w", suffix=".html", delete=False, encoding="utf-8"
    ) as f:
        f.write(full_html)
        tmp = Path(f.name)
    try:
        chrome_cdp_pdf(str(tmp), str(out))
    finally:
        tmp.unlink(missing_ok=True)
    return out


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print("사용법: python3 md2pdf.py <input.md> [output.pdf]")
        return 1
    md_path = Path(args[0]).expanduser()
    if not md_path.exists():
        print(f"파일 없음: {md_path}")
        return 1
    out_path = Path(args[1]).expanduser() if len(args) > 1 else None
    result = convert(md_path, out_path)
    size_kb = result.stat().st_size / 1024
    print(f"✅ PDF 생성: {result}  ({size_kb:.0f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
