import pandas as pd
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data" / "raw"

files = [
    "bookings.csv",
    "goals.csv",
    "matches-selected-columns.csv",
    "players.csv",
    "teams.csv",
    "tournament_standings.csv",
    "tournaments.csv"
]

for file in files:
    print("=" * 100)
    print(file.upper())

    df = pd.read_csv(DATA_DIR / file)

    print("\nShape:")
    print(df.shape)

    print("\nData Types:")
    print(df.dtypes)

    print("\nMissing Values:")
    print(df.isnull().sum())

    print("\nDuplicate Rows:")
    print(df.duplicated().sum())