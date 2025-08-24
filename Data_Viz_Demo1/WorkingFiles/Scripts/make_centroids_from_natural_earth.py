
import sys, json
from pathlib import Path
import pandas as pd

USAGE = """
Usage:
  python make_centroids_from_natural_earth.py <ne_admin0_label_points.csv> [out_dir]

Input CSV must contain columns (case-insensitive): ISO_A3, LONGITUDE, LATITUDE
Outputs:
  centroids.csv  -> Code, lon, lat, x_norm, y_norm
  centroids.json -> { ISO3: [x_norm, y_norm] }
"""

def pick(colnames, *cands):
    cl = [c.lower() for c in colnames]
    for c in cands:
        if c.lower() in cl: return colnames[cl.index(c.lower())]
    raise SystemExit(f"Missing required column among: {colnames}")

def main():
    if len(sys.argv) < 2:
        print(USAGE)
        sys.exit(1)
    src = Path(sys.argv[1])
    out_dir = Path(sys.argv[2]) if len(sys.argv) >= 3 else Path.cwd()

    df = pd.read_csv(src)
    colnames = list(df.columns)
    col_iso  = pick(colnames, "ISO_A3","iso_a3","adm0_a3")
    col_lon  = pick(colnames, "LONGITUDE","longitude","LONG","long")
    col_lat  = pick(colnames, "LATITUDE","latitude","LAT","lat")

    # ISO-3 only
    df[col_iso] = df[col_iso].astype(str).str.upper()
    df = df[df[col_iso].str.match(r"^[A-Z]{3}$")]

    # Normalize to equirectangular [0..1]
    def x_norm(lon): return (float(lon) + 180.0) / 360.0
    def y_norm(lat): return (90.0 - float(lat)) / 180.0

    df["x_norm"] = df[col_lon].astype(float).apply(x_norm)
    df["y_norm"] = df[col_lat].astype(float).apply(y_norm)

    out_dir.mkdir(parents=True, exist_ok=True)
    csv_path = out_dir / "centroids.csv"
    df_out = df[[col_iso, col_lon, col_lat, "x_norm", "y_norm"]].copy()
    df_out.columns = ["Code","lon","lat","x_norm","y_norm"]
    df_out.to_csv(csv_path, index=False)

    j = { row["Code"]: [round(row["x_norm"], 6), round(row["y_norm"], 6)] for _, row in df_out.iterrows() }
    with open(out_dir/"centroids.json","w") as f:
        json.dump(j, f, indent=2)

    print(f"✅ Wrote {csv_path} and {out_dir/'centroids.json'}")

if __name__ == "__main__":
    main()
