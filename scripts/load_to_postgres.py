"""
load_to_postgres.py
Loads every data/raw/ontime_*.csv.gz file into raw.flights using COPY.
Skips files already recorded in raw.load_log, so it is safe to rerun.
"""

import gzip
from getpass import getpass
from pathlib import Path

import psycopg2

DATA_DIR = Path("data/raw")
DB = dict(host="localhost", port=5432, dbname="flights", user="postgres")


def main():
    conn = psycopg2.connect(**DB, password=getpass("Postgres password: "))
    conn.autocommit = False
    cur = conn.cursor()

    cur.execute("SELECT file_name FROM raw.load_log")
    done = {r[0] for r in cur.fetchall()}

    files = sorted(DATA_DIR.glob("ontime_*.csv.gz"))
    print(f"Found {len(files)} files, {len(done)} already loaded.\n")

    for f in files:
        if f.name in done:
            continue
        try:
            with gzip.open(f, "rt", encoding="utf-8") as fh:
                cur.copy_expert(
                    "COPY raw.flights FROM STDIN WITH (FORMAT csv, HEADER true)",
                    fh,
                )
            rows = cur.rowcount
            cur.execute(
                "INSERT INTO raw.load_log (file_name, row_count) VALUES (%s, %s)",
                (f.name, rows),
            )
            conn.commit()
            print(f"  loaded {f.name}: {rows:,} rows")
        except Exception as e:
            conn.rollback()
            print(f"  FAILED {f.name}: {e}")

    cur.execute("SELECT COUNT(*) FROM raw.flights")
    print(f"\nTotal rows in raw.flights: {cur.fetchone()[0]:,}")
    conn.close()


if __name__ == "__main__":
    main()