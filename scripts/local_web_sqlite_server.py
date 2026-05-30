#!/usr/bin/env python3
"""Servidor local para servir build/web e expor API SQLite para desenvolvimento.

Uso:
  python scripts/local_web_sqlite_server.py --port 8080
"""

from __future__ import annotations

import argparse
import json
import socket
import sqlite3
import threading
from datetime import datetime, timezone
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse


def _get_lan_ips() -> list[str]:
    """Retorna IPs de rede local (exclui loopback)."""
    ips: list[str] = []
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ip = info[4][0]
            if not ip.startswith("127."):
                ips.append(ip)
    except Exception:
        pass
    # Fallback: conecta a DNS do Google sem enviar dados
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            if ip and not ip.startswith("127.") and ip not in ips:
                ips.append(ip)
    except Exception:
        pass
    return list(dict.fromkeys(ips))  # preserva ordem, remove duplicatas


def _json_response(handler: SimpleHTTPRequestHandler, status: int, payload: dict) -> None:
    body = json.dumps(payload, ensure_ascii=True).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    # Permite que o Flutter web (COEP: require-corp) consuma respostas da API.
    handler.send_header("Cross-Origin-Resource-Policy", "same-site")
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.end_headers()
    handler.wfile.write(body)


def _read_json_body(handler: SimpleHTTPRequestHandler) -> dict:
    length = int(handler.headers.get("Content-Length", "0"))
    if length <= 0:
        return {}
    raw = handler.rfile.read(length)
    try:
        data = json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"JSON invalido: {exc}") from exc
    if not isinstance(data, dict):
        raise ValueError("JSON deve ser um objeto")
    return data


class LocalWebSqliteHandler(SimpleHTTPRequestHandler):
    """Serve arquivos estaticos e endpoints API para SQLite."""

    server_version = "LocalWebSqlite/1.0"

    def __init__(self, *args, db: sqlite3.Connection, db_lock: threading.Lock, **kwargs):
        self._db = db
        self._db_lock = db_lock
        super().__init__(*args, **kwargs)

    def end_headers(self) -> None:
        # Necessario para SharedArrayBuffer (Flutter WASM / skwasm multithread).
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)

        if parsed.path == "/flutter_bootstrap.js":
            return self._handle_flutter_bootstrap()

        if parsed.path == "/api/health":
            return self._handle_health()

        if parsed.path == "/api/info":
            return self._handle_info()

        if parsed.path == "/api/kv":
            return self._handle_get_kv(parsed.query)

        if parsed.path == "/api/kv/all":
            return self._handle_list_kv()

        return super().do_GET()

    def _handle_flutter_bootstrap(self) -> None:
        base_dir = Path(self.directory or ".")
        bootstrap_path = base_dir / "flutter_bootstrap.js"
        wasm_runtime_exists = (base_dir / "main.dart.mjs").exists()

        if not bootstrap_path.exists():
            _json_response(self, HTTPStatus.NOT_FOUND, {"error": "flutter_bootstrap.js nao encontrado"})
            return

        content = bootstrap_path.read_text(encoding="utf-8")

        # Em alguns ambientes o build pode sair sem main.dart.mjs. Forcamos
        # o renderer CanvasKit para usar main.dart.js e evitar tela em branco.
        if not wasm_runtime_exists and 'config: { renderer: "canvaskit" }' not in content:
            marker = "_flutter.loader.load({"
            replacement = '_flutter.loader.load({\n  config: { renderer: "canvaskit" },'
            if marker in content:
                content = content.replace(marker, replacement, 1)

        body = content.encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "application/javascript; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)

        if parsed.path == "/api/kv":
            return self._handle_set_kv()

        if parsed.path == "/api/sql":
            return self._handle_exec_sql()

        _json_response(self, HTTPStatus.NOT_FOUND, {"error": "endpoint nao encontrado"})

    def _handle_health(self) -> None:
        with self._db_lock:
            row = self._db.execute("select sqlite_version() as version").fetchone()
            total = self._db.execute("select count(*) from app_kv").fetchone()[0]

        _json_response(
            self,
            HTTPStatus.OK,
            {
                "ok": True,
                "server_time_utc": datetime.now(timezone.utc).isoformat(),
                "sqlite_version": row[0],
                "kv_rows": total,
            },
        )

    def _handle_info(self) -> None:
        """Retorna IPs de rede da máquina — usado pelo Flutter para montar o QR code."""
        lan_ips = _get_lan_ips()
        port = self.server.server_address[1]
        _json_response(
            self,
            HTTPStatus.OK,
            {
                "port": port,
                "lan_ips": lan_ips,
                "urls": [f"http://{ip}:{port}" for ip in lan_ips],
            },
        )

    def _handle_get_kv(self, query: str) -> None:
        params = parse_qs(query)
        key = (params.get("key") or [""])[0].strip()
        if not key:
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": "parametro key e obrigatorio"})
            return

        with self._db_lock:
            row = self._db.execute(
                "select key, value, updated_at from app_kv where key = ?", (key,)
            ).fetchone()

        if row is None:
            _json_response(self, HTTPStatus.NOT_FOUND, {"error": "chave nao encontrada", "key": key})
            return

        _json_response(
            self,
            HTTPStatus.OK,
            {"key": row[0], "value": row[1], "updated_at": row[2]},
        )

    def _handle_list_kv(self) -> None:
        with self._db_lock:
            rows = self._db.execute(
                "select key, value, updated_at from app_kv order by key"
            ).fetchall()

        _json_response(
            self,
            HTTPStatus.OK,
            {
                "items": [
                    {"key": key, "value": value, "updated_at": updated_at}
                    for key, value, updated_at in rows
                ]
            },
        )

    def _handle_set_kv(self) -> None:
        try:
            payload = _read_json_body(self)
        except ValueError as exc:
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": str(exc)})
            return

        key = str(payload.get("key", "")).strip()
        if not key:
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": "campo key e obrigatorio"})
            return

        value = str(payload.get("value", ""))
        now = datetime.now(timezone.utc).isoformat()

        with self._db_lock:
            self._db.execute(
                """
                insert into app_kv(key, value, updated_at)
                values (?, ?, ?)
                on conflict(key) do update set
                    value = excluded.value,
                    updated_at = excluded.updated_at
                """,
                (key, value, now),
            )
            self._db.commit()

        _json_response(self, HTTPStatus.OK, {"ok": True, "key": key, "value": value, "updated_at": now})

    def _handle_exec_sql(self) -> None:
        try:
            payload = _read_json_body(self)
        except ValueError as exc:
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": str(exc)})
            return

        sql = str(payload.get("sql", "")).strip()
        if not sql:
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": "campo sql e obrigatorio"})
            return

        # Endpoint apenas para desenvolvimento local.
        if ";" in sql.strip().rstrip(";"):
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": "apenas uma instrucao SQL por chamada"})
            return

        try:
            with self._db_lock:
                cur = self._db.execute(sql)
                columns = [col[0] for col in (cur.description or [])]
                rows = cur.fetchall() if cur.description else []
                if not cur.description:
                    self._db.commit()
            _json_response(
                self,
                HTTPStatus.OK,
                {
                    "ok": True,
                    "columns": columns,
                    "rows": [list(row) for row in rows],
                    "row_count": len(rows),
                },
            )
        except sqlite3.Error as exc:
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": f"sqlite error: {exc}"})


def _init_db(db: sqlite3.Connection) -> None:
    db.execute(
        """
        create table if not exists app_kv (
            key text primary key,
            value text not null,
            updated_at text not null
        )
        """
    )
    db.commit()


def main() -> None:
    parser = argparse.ArgumentParser(description="Servidor local build/web + SQLite")
    parser.add_argument("--port", type=int, default=8080, help="Porta HTTP local (padrao: 8080)")
    parser.add_argument(
        "--web-dir",
        default="build/web",
        help="Diretorio de arquivos estaticos (padrao: build/web)",
    )
    parser.add_argument(
        "--db-path",
        default="local/app.db",
        help="Caminho do banco SQLite (padrao: local/app.db)",
    )
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    web_dir = (project_root / args.web_dir).resolve()
    db_path = (project_root / args.db_path).resolve()

    if not web_dir.exists():
        raise SystemExit(f"Diretorio web nao encontrado: {web_dir}")

    db_path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(db_path, check_same_thread=False)
    _init_db(db)
    db_lock = threading.Lock()

    handler = partial(LocalWebSqliteHandler, directory=str(web_dir), db=db, db_lock=db_lock)
    server = ThreadingHTTPServer(("0.0.0.0", args.port), handler)

    lan_ips = _get_lan_ips()
    print("Servidor pronto")
    print(f"  Local:  http://127.0.0.1:{args.port}")
    for ip in lan_ips:
        print(f"  Rede:   http://{ip}:{args.port}  ← use este IP no QR code")
    print(f"  Health: http://127.0.0.1:{args.port}/api/health")
    print(f"  Info:   http://127.0.0.1:{args.port}/api/info")
    print(f"  SQLite: {db_path}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nEncerrando servidor...")
    finally:
        server.server_close()
        db.close()


if __name__ == "__main__":
    main()
