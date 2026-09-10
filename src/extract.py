import pandas as pd
from pathlib import Path

# Project root
ROOT = Path(__file__).resolve().parent.parent

# Raw data folder
DATA_DIR = ROOT / "data" / "raw"

# Load all CSV files
datasets = {
    "bookings": pd.read_csv(DATA_DIR / "bookings.csv"),
    "goals": pd.read_csv(DATA_DIR / "goals.csv"),
    "matches": pd.read_csv(DATA_DIR / "matches-selected-columns.csv"),
    "players": pd.read_csv(DATA_DIR / "players.csv"),
    "teams": pd.read_csv(DATA_DIR / "teams.csv"),
    "standings": pd.read_csv(DATA_DIR / "tournament_standings.csv"),
    "tournaments": pd.read_csv(DATA_DIR / "tournaments.csv")
}

print("=" * 80)

for name, df in datasets.items():
    print(f"\n{name.upper()}")
    print("-" * 80)
    print(f"Rows: {df.shape[0]}")
    print(f"Columns: {df.shape[1]}")
    print("\nColumn Names:")
    print(df.columns.tolist())

print("=" * 80)