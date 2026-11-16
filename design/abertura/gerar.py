"""Gera as imagens JPEG da tela de abertura a partir de abertura.html.

    pip install pillow
    python design/abertura/gerar.py

Roda sozinho nos workflows que publicam o app (release-android.yml e
web.yml), antes do build. Funciona no Windows, Linux e macOS; precisa do
Google Chrome, Chromium ou Edge e de internet (fontes do Google Fonts).
"""

import os
import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
HTML = (HERE / "abertura.html").as_uri()
OUT = ROOT / "assets" / "images"

LAYOUTS = {"mobile": (1080, 1920), "desktop": (1920, 1080)}
QUALITY = 88


def find_browser() -> str:
    candidates = [
        os.environ.get("CHROME_PATH"),
        shutil.which("google-chrome"),
        shutil.which("google-chrome-stable"),
        shutil.which("chromium"),
        shutil.which("chromium-browser"),
        shutil.which("chrome"),
        shutil.which("msedge"),
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    ]
    for path in candidates:
        if path and Path(path).exists():
            return path
    sys.exit("Erro: Chrome, Chromium ou Edge não encontrado (ou defina CHROME_PATH).")


def chrome(browser: str, *args: str) -> str:
    base = [
        browser,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--virtual-time-budget=10000",
    ]
    # Em servidores Linux (GitHub Actions) o sandbox do Chrome não está disponível.
    if platform.system() == "Linux":
        base.append("--no-sandbox")
    result = subprocess.run(
        base + list(args), capture_output=True, text=True, encoding="utf-8",
        errors="replace", timeout=120,
    )
    return result.stdout


def main() -> None:
    browser = find_browser()

    # Confere se as fontes da arte carregaram (sem elas, a arte sairia com a
    # fonte padrão do sistema). A página marca <body data-fonts="ok">.
    dom = chrome(browser, "--dump-dom", f"{HTML}#mobile")
    if 'data-fonts="ok"' not in dom:
        sys.exit("Erro: as fontes da arte não carregaram (sem internet?).")

    with tempfile.TemporaryDirectory() as tmp:
        for name, (width, height) in LAYOUTS.items():
            png = Path(tmp) / f"{name}.png"
            chrome(
                browser,
                f"--window-size={width},{height}",
                f"--screenshot={png}",
                f"{HTML}#{name}",
            )
            if not png.exists():
                sys.exit(f"Erro: o navegador não gerou a imagem {name}.")

            with Image.open(png) as image:
                if image.size != (width, height):
                    sys.exit(f"Erro: {name} saiu com {image.size}, esperado {(width, height)}.")
                dest = OUT / f"abertura_{name}.jpg"
                image.convert("RGB").save(
                    dest, "JPEG", quality=QUALITY, optimize=True, progressive=True,
                )
            print(f"OK: {dest.relative_to(ROOT)} ({dest.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
