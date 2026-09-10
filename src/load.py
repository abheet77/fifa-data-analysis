from sqlalchemy import create_engine
from config import DB_CONFIG
from sqlalchemy import text
import pandas as pd


DATABASE_URL = (
    f"postgresql+psycopg2://{DB_CONFIG['user']}:"
    f"{DB_CONFIG['password']}@"
    f"{DB_CONFIG['host']}:"
    f"{DB_CONFIG['port']}/"
    f"{DB_CONFIG['database']}"
)

engine = create_engine(DATABASE_URL)

print("Connected successfully!")


MISSING_VALUES = {"", "not available"}


def load_table(engine, df, table_name, columns, boolean_columns=None):

    if boolean_columns is None:
        boolean_columns = []

    with engine.begin() as conn:

        for _, row in df.iterrows():

            values = {}

            for col in columns:

                value = row[col]

                # Convert NaN and raw missing-value placeholders to None
                if value != value or (
                    isinstance(value, str)
                    and value.strip().lower() in MISSING_VALUES
                ):
                    value = None

                # Convert 0/1 to True/False
                elif col in boolean_columns:
                    value = bool(value)

                values[col] = value

            placeholders = ", ".join(f":{col}" for col in columns)

            sql = text(f"""
                INSERT INTO {table_name}
                ({", ".join(columns)})
                VALUES
                ({placeholders})
            """)

            conn.execute(sql, values)

        print(f"{table_name} loaded successfully!")

    
TABLES = [
    {
        "file": "teams.csv",
        "table": "teams",
        "columns": [
            "team_id",
            "team_name",
            "team_code",
            "federation_name",
            "region_name",
            "confederation_id",
            "confederation_name",
            "confederation_code"
        ],
        "boolean_columns": []
    },
    {
        "file": "tournaments.csv",
        "table": "tournaments",
        "columns": [
            "tournament_id",
            "tournament_name",
            "year",
            "start_date",
            "end_date",
            "host_country",
            "winner",
            "host_won",
            "count_teams",
            "group_stage",
            "second_group_stage",
            "final_round",
            "round_of_16",
            "quarter_finals",
            "semi_finals",
            "third_place_match",
            "final"
        ],
        "boolean_columns": [
            "second_group_stage",
            "final_round",
            "round_of_16",
            "quarter_finals",
            "semi_finals",
            "third_place_match",
            "final"
        ]
    },
    {
    "file": "players.csv",
    "table": "players",
    "columns": [
        "player_id",
        "family_name",
        "given_name",
        "birth_date",
        "goal_keeper",
        "defender",
        "midfielder",
        "forward",
        "count_tournaments"
    ],
    "boolean_columns": [
        "goal_keeper",
        "defender",
        "midfielder",
        "forward"
    ]
    },
    {
    "file": "matches-selected-columns.csv",
    "table": "matches",
    "columns": [
        "match_id",
        "tournament_id",
        "match_name",
        "stage_name",
        "group_name",
        "group_stage",
        "knockout_stage",
        "replayed"
    ],
    "boolean_columns": [
        "group_stage",
        "knockout_stage",
        "replayed"
    ]
    },
    {
    "file": "goals.csv",
    "table": "goals",
    "columns": [
        "goal_id",
        "tournament_id",
        "match_id",
        "team_id",
        "player_id",
        "minute_regulation",
        "minute_stoppage",
        "match_period",
        "own_goal",
        "penalty"
    ],
    "boolean_columns": []
    },
    {
    "file": "bookings.csv",
    "table": "bookings",
    "columns": [
        "booking_id",
        "tournament_id",
        "match_id",
        "team_id",
        "player_id",
        "minute_regulation",
        "minute_stoppage",
        "match_period",
        "yellow_card",
        "red_card",
        "second_yellow_card",
        "sending_off"
    ],
    "boolean_columns": [
        "yellow_card",
        "red_card",
        "second_yellow_card",
        "sending_off"
    ]
    },
    {
    "file": "tournament_standings.csv",
    "table": "tournament_standings",
    "columns": [
        "tournament_id",
        "team_id",
        "position"
    ],
    "boolean_columns": []
}
        
]
for table in TABLES:

    print(f"\nLoading {table['table']}...")

    df = pd.read_csv(f"data/raw/{table['file']}")

    load_table(
        engine,
        df,
        table["table"],
        table["columns"],
        table["boolean_columns"]
    )



