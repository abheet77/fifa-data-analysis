"""Transform raw FIFA data into a cleaner format for analysis."""

from __future__ import annotations

import pandas as pd


def clean_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """Return a copy of the dataframe with basic cleaning applied."""
    cleaned = df.copy()
    for col in cleaned.columns:
        if cleaned[col].dtype == "object":
            cleaned[col] = cleaned[col].astype(str).str.strip()
    return cleaned
