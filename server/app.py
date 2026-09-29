"""
Server Flask buat nerima data PZEM dari ESP32.

Jalanin:
    pip install flask
    set API_KEY=isi_key_lu          (Windows CMD)
    $env:API_KEY="isi_key_lu"       (Windows PowerShell)
    export API_KEY=isi_key_lu       (Linux/Mac)
    python app.py

Endpoint:
    POST /api/data              -> dipanggil ESP32 (wajib API key)
    GET  /api/data              -> liat data terakhir (wajib API key)
                                  ?limit=500&before_id=123 buat ambil halaman
                                  riwayat yang lebih lama
    GET  /                      -> dashboard sederhana (tanpa key, auto refresh)
    GET  /health                -> cek server hidup
"""
import hmac
import os
import sqlite3
from datetime import datetime

from flask import Flask, g, jsonify, request

app = Flask(__name__)

# Key sengaja dibuat pendek (<60 karakter) biar aman di EEPROM lama.
# Bikin key acak:  python -c "import secrets; print(secrets.token_hex(16))"
#
# Tidak ada nilai bawaan: key asli hanya boleh datang dari environment. Kalau
# ada default di dalam berkas ini, satu-satunya cara mencabut kebocorannya
# adalah rewrite riwayat, dan key yang bocor ke mirror tidak bisa dicabut sama
# sekali. Server juga lebih mudah salah diagnosa karena berhenti saat start
# dengan pesan jelas, bukan diam-diam menerima semua permintaan.
API_KEY = os.environ.get("API_KEY", "").strip()
if not API_KEY:
    raise SystemExit(
        "API_KEY belum di-set. Jalankan:\n"
        "  export API_KEY=$(python -c \"import secrets; print(secrets.token_hex(16))\")"
    )
DB_PATH = os.environ.get("DB_PATH", "data.db")

# False = ESP32 boleh POST tanpa header key (firmware lama). GET tetap wajib key.
REQUIRE_KEY_POST = False

FIELDS = ["voltage", "current", "power", "energy", "frequency", "pf"]


# ---------- Database ----------
def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(_exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    with sqlite3.connect(DB_PATH) as db:
        db.execute(
            """CREATE TABLE IF NOT EXISTS pzem (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                created_at TEXT NOT NULL,
                voltage REAL, current REAL, power REAL,
                energy REAL, frequency REAL, pf REAL
            )"""
        )


# ---------- Auth ----------
def extract_key():
    """Terima key dari beberapa format header sekaligus."""
    auth = request.headers.get("Authorization", "")
    if auth.lower().startswith("bearer "):
        return auth[7:].strip()
    return (
        request.headers.get("x-api-key")
        or request.headers.get("apikey")
        or request.args.get("api_key")
        or ""
    ).strip()


def key_valid():
    return hmac.compare_digest(extract_key().encode(), API_KEY.encode())


def deny():
    """Balas 401 + cetak key yang diterima, biar kelihatan header nyampe atau nggak."""
    got = extract_key()
    print(f"[401] key diterima: panjang={len(got)} awal='{got[:4]}' | "
          f"key server: panjang={len(API_KEY)} awal='{API_KEY[:4]}' | "
          f"header: {[h for h in request.headers.keys() if h.lower() in ('authorization', 'x-api-key', 'apikey')]}",
          flush=True)
    return jsonify(error="API key salah atau tidak ada"), 401


# ---------- Routes ----------
@app.route("/health")
def health():
    return jsonify(status="ok")


@app.route("/api/data", methods=["POST"])
def receive():
    if REQUIRE_KEY_POST and not key_valid():
        return deny()

    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        return jsonify(error="Body harus JSON"), 400

    missing = [f for f in FIELDS if f not in body]
    if missing:
        return jsonify(error="Field kurang", missing=missing), 422

    try:
        values = [float(body[f]) for f in FIELDS]
    except (TypeError, ValueError):
        return jsonify(error="Semua field harus angka"), 422

    now = datetime.now().isoformat(timespec="seconds")
    db = get_db()
    db.execute(
        "INSERT INTO pzem (created_at, voltage, current, power, energy, frequency, pf) "
        "VALUES (?,?,?,?,?,?,?)",
        [now, *values],
    )
    db.commit()
    print(f"[{now}] {dict(zip(FIELDS, values))}")
    return jsonify(status="ok", saved_at=now), 201


@app.route("/api/data", methods=["GET"])
def latest():
    if not key_valid():
        return deny()
    limit = min(request.args.get("limit", 20, type=int), 500)
    # before_id bikin aplikasi bisa jalanin seluruh riwayat: halaman berikutnya
    # meminta id yang lebih kecil dari baris terakhir halaman ini.
    before_id = request.args.get("before_id", type=int)
    sql = "SELECT * FROM pzem"
    params = []
    if before_id is not None:
        sql += " WHERE id < ?"
        params.append(before_id)
    sql += " ORDER BY id DESC LIMIT ?"
    params.append(limit)
    rows = get_db().execute(sql, params).fetchall()
    return jsonify([dict(r) for r in rows])


def cell(row, key, spec):
    """Format satu kolom REAL, toleran terhadap NULL.

    Kolom di tabel sengaja tidak NOT NULL: baris lama atau baris yang ditulis
    di luar jalur POST bisa punya NULL di sini. `f"{None:.1f}"` melempar
    TypeError dan membuat seluruh halaman / jadi 500, jadi NULL ditampilkan
    sebagai '-' di sini.
    """
    value = row[key]
    if value is None:
        return "-"
    try:
        return format(float(value), spec)
    except (TypeError, ValueError):
        return "-"


@app.route("/")
def dashboard():
    row = get_db().execute("SELECT * FROM pzem ORDER BY id DESC LIMIT 1").fetchone()
    if row is None:
        body = "<p>Belum ada data masuk dari ESP32.</p>"
    else:
        body = (
            f"<p>Update terakhir: <b>{row['created_at']}</b></p><table>"
            f"<tr><td>Tegangan</td><td>{cell(row, 'voltage', '.1f')} V</td></tr>"
            f"<tr><td>Arus</td><td>{cell(row, 'current', '.3f')} A</td></tr>"
            f"<tr><td>Daya</td><td>{cell(row, 'power', '.1f')} W</td></tr>"
            f"<tr><td>Energi</td><td>{cell(row, 'energy', '.3f')} kWh</td></tr>"
            f"<tr><td>Frekuensi</td><td>{cell(row, 'frequency', '.1f')} Hz</td></tr>"
            f"<tr><td>PF</td><td>{cell(row, 'pf', '.2f')}</td></tr></table>"
        )
    return (
        "<!doctype html><meta charset=utf-8>"
        "<meta name=viewport content='width=device-width,initial-scale=1'>"
        "<meta http-equiv=refresh content=5><title>Monitor PZEM</title>"
        "<style>body{font-family:Arial;margin:30px}td{padding:6px 16px 6px 0}</style>"
        f"<h2>Monitor PZEM</h2>{body}"
    )   

@app.after_request
def add_cors(resp):
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, x-api-key"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return resp

init_db()

if __name__ == "__main__":
    # host 0.0.0.0 wajib supaya ESP32 (device lain di WiFi) bisa akses
    app.run(host="0.0.0.0", port=5000, debug=False)