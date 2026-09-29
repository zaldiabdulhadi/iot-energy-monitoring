#!/usr/bin/env python3
"""
Ekspor `data.db` (tabel pzem) ke CSV dengan format yang sama persis dengan
ekspor sampel mentah di aplikasi (`EnergyRawCsvExporter`).

Format kanonik, dipakai juga oleh app dan test:
    id;waktu;tegangan_v;arus_a;daya_w;energi_kwh;frekuensi_hz;pf

- Pemisah kolom ';', desimal koma, UTF-8 + BOM supaya langsung benar saat
  dibuka di Excel versi Indonesia.
- Urut `id` naik: sampel paling lama di atas, sama seperti urutan di app.
- Desimal mengikuti `cell()` di `app.py`: tegangan 1 angka, arus 3, daya 1,
  energi 3, frekuensi 1, pf 2.
- Nilai NULL ditulis sebagai sel kosong, bukan 0.

Baca read-only, jadi aman dijalankan sementara server Flask hidup.

Pemakaian:
    python3 server/export_csv.py                 # -> server/pzem.csv
    python3 server/export_csv.py keluar.csv      # -> keluar.csv
    python3 server/export_csv.py --db db/coba.db # membaca database lain
"""
import argparse
import csv
import os
import sqlite3

# Desimal per kolom, senama dengan kolom yang ada di tabel pzem.
_DECIMALS = {
    "voltage": 1,
    "current": 3,
    "power": 1,
    "energy": 3,
    "frequency": 1,
    "pf": 2,
}

# Kolom sesuai urutan header, tabel memakai nama Inggris.
_KEYS = ["id", "created_at", "voltage", "current", "power", "energy", "frequency", "pf"]

HEADER = [
    "id", "waktu", "tegangan_v", "arus_a",
    "daya_w", "energi_kwh", "frekuensi_hz", "pf",
]


def fmt(value, decimals):
    """Satu angka dengan desimal koma; NULL dan nilai rusak jadi sel kosong."""
    if value is None:
        return ""
    try:
        return format(float(value), ".%df" % decimals).replace(".", ",")
    except (TypeError, ValueError):
        return ""


def row_values(row):
    return [
        str(row["id"]),
        "" if row["created_at"] is None else str(row["created_at"]),
        fmt(row["voltage"], _DECIMALS["voltage"]),
        fmt(row["current"], _DECIMALS["current"]),
        fmt(row["power"], _DECIMALS["power"]),
        fmt(row["energy"], _DECIMALS["energy"]),
        fmt(row["frequency"], _DECIMALS["frequency"]),
        fmt(row["pf"], _DECIMALS["pf"]),
    ]


def export_rows(db_path, out_path):
    """Menulis CSV dari [out_path]; mengembalikan (jumlah baris, waktu awal, waktu akhir)."""
    uri = "file:%s?mode=ro" % db_path
    with sqlite3.connect(uri, uri=True) as db:
        db.row_factory = sqlite3.Row
        rows = db.execute(
            "SELECT id, created_at, voltage, current, power, energy, frequency, pf "
            "FROM pzem ORDER BY id ASC"
        ).fetchall()

    with open(out_path, "w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle, delimiter=";", lineterminator="\n")
        writer.writerow(HEADER)
        writer.writerows(row_values(r) for r in rows)

    first = rows[0]["created_at"] if rows else ""
    last = rows[-1]["created_at"] if rows else ""
    return len(rows), first, last


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(
        description="Ubah data.db (tabel pzem) menjadi CSV sampel mentah.",
    )
    parser.add_argument(
        "output",
        nargs="?",
        default=os.path.join(script_dir, "pzem.csv"),
        help="lokasi berkas CSV (default: %(default)s)",
    )
    parser.add_argument(
        "--db",
        default=os.path.join(script_dir, "data.db"),
        help="lokasi database sqlite (default: %(default)s)",
    )
    args = parser.parse_args()

    count, first, last = export_rows(args.db, args.output)
    if count == 0:
        print("Tidak ada baris di tabel pzem; file tidak dibuat: %s" % args.output)
        return 1

    print("Menulis %d sampel ke %s" % (count, args.output))
    print("Rentang waktu: %s .. %s" % (first, last))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())