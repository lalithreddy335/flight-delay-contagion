"""
download_bts.py
Downloads BTS Reporting Carrier On-Time Performance data (2021-2025),
keeps only the columns needed for the Flight Delay Contagion analysis,
and saves one gzipped CSV per month to data/raw/.
"""

import io
import time
import zipfile
from pathlib import Path

import pandas as pd
import requests

YEARS = range(2021, 2026)
MONTHS = range(1, 13)
OUT_DIR = Path("data/raw")
URL = ("https://transtats.bts.gov/PREZIP/"
       "On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{y}_{m}.zip")

KEEP_COLS = [
    "Year", "Month", "DayofMonth", "DayOfWeek", "FlightDate",
    "Reporting_Airline", "Tail_Number", "Flight_Number_Reporting_Airline",
    "Origin", "OriginCityName", "OriginState",
    "Dest", "DestCityName", "DestState", "Distance",
    "CRSDepTime", "DepTime", "DepDelay", "DepDelayMinutes", "DepDel15",
    "TaxiOut", "WheelsOff",
    "WheelsOn", "TaxiIn", "CRSArrTime", "ArrTime",
    "ArrDelay", "ArrDelayMinutes", "ArrDel15",
    "Cancelled", "CancellationCode", "Diverted",
    "CRSElapsedTime", "ActualElapsedTime", "AirTime",
    "CarrierDelay", "WeatherDelay", "NASDelay",
    "SecurityDelay", "LateAircraftDelay",
]

HEADERS = {"User-Agent": "Mozilla/5.0 (flight-delay-contagion portfolio project)"}


def download_month(year, month, retries=3):
    out_file = OUT_DIR / f"ontime_{year}_{month:02d}.csv.gz"
    if out_file.exists():
        print(f"  skip {year}-{month:02d} (already downloaded)")
        return 0

    url = URL.format(y=year, m=month)
    for attempt in range(1, retries + 1):
        try:
            resp = requests.get(url, headers=HEADERS, timeout=300)
            resp.raise_for_status()
            with zipfile.ZipFile(io.BytesIO(resp.content)) as zf:
                csv_name = next(n for n in zf.namelist() if n.endswith(".csv"))
                with zf.open(csv_name) as f:
                    df = pd.read_csv(f, usecols=lambda c: c in KEEP_COLS,
                                     low_memory=False)
            df = df[[c for c in KEEP_COLS if c in df.columns]]
            df.to_csv(out_file, index=False, compression="gzip")
            print(f"  done {year}-{month:02d}: {len(df):,} rows")
            return len(df)
        except Exception as e:
            print(f"  attempt {attempt} failed for {year}-{month:02d}: {e}")
            time.sleep(10 * attempt)

    print(f"  GAVE UP on {year}-{month:02d}; rerun the script later")
    return 0


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    total = 0
    for y in YEARS:
        print(f"\n=== {y} ===")
        for m in MONTHS:
            total += download_month(y, m)
    print(f"\nFinished. New rows downloaded this run: {total:,}")
    print(f"Files in {OUT_DIR}: {len(list(OUT_DIR.glob('*.csv.gz')))} / 60")


if __name__ == "__main__":
    main()