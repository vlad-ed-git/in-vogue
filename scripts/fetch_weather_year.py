#!/usr/bin/env python3
"""Fetch a year of hourly weather in ten cities for the recommender's tests.

    python3 scripts/fetch_weather_year.py      # writes test/fixtures/weather_year.json.gz

Open-Meteo's archive (reanalysis, no key), October 1, 2025 to September 30, 2026, in each city's
local time. The five days the design checks by hand (Denver Sep 3, Berlin Sep 26, New York Aug 26,
Chicago Jan 20, Shanghai Aug 5) fall inside it. Only the hours the occasions use, 07:00 to 23:00, are
kept, as integers: feels-like and amounts in tenths, gusts in km/h. The archive has no precipitation
probability, so an hour with an amount counts as certain.
"""
import gzip
import json
import time
import urllib.request
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "test" / "fixtures" / "weather_year.json.gz"
START, END = "2025-10-01", "2026-09-30"
FIRST_HOUR, LAST_HOUR = 7, 23
CITIES = [
    ("Denver", 39.74, -104.99),
    ("Chicago", 41.88, -87.63),
    ("New York", 40.71, -74.01),
    ("Seattle", 47.61, -122.33),
    ("London", 51.51, -0.13),
    ("Berlin", 52.52, 13.40),
    ("Moscow", 55.76, 37.62),
    ("Dubai", 25.20, 55.27),
    ("Shanghai", 31.23, 121.47),
    ("Sydney", -33.87, 151.21),
]
FIELDS = {
    "feelsLike": ("apparent_temperature", 10),
    "precipitation": ("precipitation", 10),
    "snowfall": ("snowfall", 10),
    "gusts": ("wind_gusts_10m", 1),
    "code": ("weather_code", 1),
}


def fetch(lat, lon):
    hourly = ",".join(name for name, _ in FIELDS.values())
    url = (f"https://archive-api.open-meteo.com/v1/archive?latitude={lat}&longitude={lon}"
           f"&start_date={START}&end_date={END}&hourly={hourly}&timezone=auto")
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=120) as response:
                return json.load(response)
        except OSError:
            time.sleep(5 * (attempt + 1))
    raise SystemExit(f"could not fetch {lat},{lon}")


def main():
    cities = []
    for name, lat, lon in CITIES:
        data = fetch(lat, lon)
        hours = data["hourly"]
        keep = [i for i, t in enumerate(hours["time"]) if FIRST_HOUR <= int(t[11:13]) <= LAST_HOUR]
        city = {"name": name, "latitude": lat, "longitude": lon, "from": START,
                "hours": {"first": FIRST_HOUR, "last": LAST_HOUR}}
        for key, (field, scale) in FIELDS.items():
            city["hours"][key] = [round((hours[field][i] or 0) * scale) for i in keep]
        days = len(keep) // (LAST_HOUR - FIRST_HOUR + 1)
        cities.append(city)
        print(f"{name}: {days} days")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(gzip.compress(json.dumps({"cities": cities}, separators=(",", ":")).encode(), mtime=0))
    print(f"wrote {OUT.relative_to(OUT.parents[2])} ({OUT.stat().st_size / 1e3:.0f} KB)")


if __name__ == "__main__":
    main()
