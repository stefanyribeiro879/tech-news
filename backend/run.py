"""Inicia a API.

Uso (dentro da pasta backend):
    python run.py                 # http://127.0.0.1:8000, recarrega ao salvar
    python run.py --host 0.0.0.0  # acessível pelo celular/emulador na mesma rede
    python run.py --port 9000 --no-reload
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent
VENV_DIR = BACKEND_DIR / ".venv"
VENV_PYTHON = VENV_DIR / ("Scripts/python.exe" if os.name == "nt" else "bin/python")


def main() -> None:
    parser = argparse.ArgumentParser(description="Inicia o backend do Tech News.")
    parser.add_argument("--host", default="127.0.0.1", help="padrão: 127.0.0.1")
    parser.add_argument("--port", type=int, default=8000, help="padrão: 8000")
    parser.add_argument("--no-reload", action="store_true", help="não reinicia ao salvar arquivos")
    args = parser.parse_args()

    # Se o .venv existe mas não está ativado, roda de novo usando o Python dele.
    if VENV_PYTHON.exists() and Path(sys.prefix).resolve() != VENV_DIR.resolve():
        sys.exit(subprocess.call([str(VENV_PYTHON), __file__, *sys.argv[1:]]))

    try:
        import uvicorn
    except ImportError:
        sys.exit(
            "uvicorn não encontrado. Instale as dependências:\n"
            "  python -m venv .venv\n"
            "  .venv\\Scripts\\python -m pip install -r requirements-dev.txt"
        )

    os.chdir(BACKEND_DIR)  # para achar o pacote app/ e o arquivo .env
    print(f"Documentação: http://127.0.0.1:{args.port}/docs")
    uvicorn.run("app.main:app", host=args.host, port=args.port, reload=not args.no_reload)


if __name__ == "__main__":
    main()
