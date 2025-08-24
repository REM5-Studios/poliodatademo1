#!/usr/bin/env python3
"""
Check integrity between countries.csv, centroids.json, and year CSV files
"""

import json
import csv
import sys
from pathlib import Path

def load_csv_codes(filename):
    """Load country codes from CSV file"""
    codes = {}
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            codes[row['Code']] = row['Entity']
    return codes

def load_json(filename):
    """Load JSON file"""
    with open(filename, 'r') as f:
        return json.load(f)

def main():
    # Load countries from CSV
    countries = load_csv_codes('../../Resources/Data/countries.csv')
    codes_c = set(countries.keys())
    
    # Load centroids from JSON
    centroids = load_json('../../Resources/Data/centroids.json')
    codes_t = set(centroids.keys())
    
    # Compare countries vs centroids
    missing_in_centroids = sorted(list(codes_c - codes_t))
    extra_in_centroids = sorted(list(codes_t - codes_c))
    
    print("== Code Parity: countries vs centroids ==")
    print(f"countries.csv: {len(codes_c)} codes")
    print(f"centroids.json: {len(codes_t)} codes")
    
    if missing_in_centroids:
        print(f"\n❌ Missing in centroids: {len(missing_in_centroids)}")
        print(f"   {missing_in_centroids}")
    
    if extra_in_centroids:
        print(f"\n⚠️  Extra in centroids: {len(extra_in_centroids)}")
        print(f"   {extra_in_centroids[:10]}{'...' if len(extra_in_centroids) > 10 else ''}")
    
    if not missing_in_centroids and not extra_in_centroids:
        print("\n✅ Exact match!")
    
    # Check year files
    print("\n== Year Files ==")
    for year in [2000, 2001, 2002]:
        filename = f"../../Resources/Data/years/year_{year}.csv"
        year_codes = set()
        
        with open(filename, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                year_codes.add(row['Code'])
        
        bad = sorted(list(year_codes - codes_c))
        missing = sorted(list(year_codes - codes_t))
        
        if bad or missing:
            print(f"\n{year}:")
            if bad:
                print(f"  ❌ Codes not in countries.csv: {bad}")
            if missing:
                print(f"  ❌ Codes not in centroids.json: {missing}")
        else:
            print(f"{year}: ✅ all codes valid")
    
    print("\n== Summary ==")
    if not missing_in_centroids:
        print("✅ All countries have centroids")
    else:
        print(f"❌ Need to add {len(missing_in_centroids)} countries to centroids")
    
    print(f"\nTotal countries ready for visualization: {len(codes_c & codes_t)}")

if __name__ == "__main__":
    main()
