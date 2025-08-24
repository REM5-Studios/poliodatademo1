
import json, sys
from pathlib import Path

USAGE = """
Usage:
  python check_integrity.py <countries.json> <centroids.json> <years_dir>

Checks:
  - countries.json codes == centroids.json codes (exact match)
  - each year file contains ONLY codes that exist in both
  - reports any discrepancies
"""

def load_json(p):
    with open(p) as f: return json.load(f)

def main():
    if len(sys.argv) < 4:
        print(USAGE)
        sys.exit(1)
    countries = load_json(sys.argv[1])
    centroids = load_json(sys.argv[2])
    years_dir = Path(sys.argv[3])

    codes_c = set(countries.keys())
    codes_t = set(centroids.keys())

    missing_in_centroids = sorted(list(codes_c - codes_t))
    extra_in_centroids   = sorted(list(codes_t - codes_c))

    print("== Code Parity: countries vs centroids ==")
    print(f"countries: {len(codes_c)} codes, centroids: {len(codes_t)} codes")
    if missing_in_centroids: print(f"  Missing in centroids: {missing_in_centroids}")
    if extra_in_centroids:   print(f"  Extra in centroids: {extra_in_centroids}")
    if not missing_in_centroids and not extra_in_centroids:
        print("  ✅ Exact match")

    print("\n== Year Files ==")
    for yp in sorted(years_dir.glob("*.json")):
        y = yp.stem
        ydata = load_json(yp)
        keys = set(ydata.keys())
        bad = sorted(list(keys - codes_c))
        missing = sorted(list(keys - codes_t))
        if bad or missing:
            print(f"  {y}:")
            if bad:     print(f"    Codes not in countries.json: {bad[:20]}{'...' if len(bad)>20 else ''}")
            if missing: print(f"    Codes not in centroids.json: {missing[:20]}{'...' if len(missing)>20 else ''}")
        else:
            print(f"  {y}: ✅ all codes valid")

    print("\nDone.")

if __name__ == "__main__":
    main()
