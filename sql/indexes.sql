-- Example indexes

CREATE INDEX IF NOT EXISTS idx_matches_home_team ON matches (home_team);
CREATE INDEX IF NOT EXISTS idx_players_team ON players (team);
