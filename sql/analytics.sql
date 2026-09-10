--------------------------------------------------
-- Basic Exploration
--------------------------------------------------

-- Tournament coverage and historical range.
SELECT tournament_id, tournament_name, year, host_country, winner, count_teams
FROM tournaments
ORDER BY year;

-- Largest tournaments by number of participating teams.
SELECT tournament_name, year, count_teams
FROM tournaments
ORDER BY count_teams DESC, year DESC
LIMIT 10;

-- Team distribution by confederation.
SELECT confederation_name, COUNT(*) AS team_count
FROM teams
GROUP BY confederation_name
ORDER BY team_count DESC;

-- Data completeness check for player birth dates.
SELECT player_id, CONCAT_WS(' ', given_name, family_name) AS player_name
FROM players
WHERE birth_date IS NULL
ORDER BY player_name
LIMIT 25;

-- Match count by stage.
SELECT stage_name, COUNT(*) AS match_count
FROM matches
GROUP BY stage_name
ORDER BY match_count DESC, stage_name;

--------------------------------------------------
-- Business KPI Queries
--------------------------------------------------

-- Teams with the most historical goals.
SELECT tm.team_name, tm.confederation_name, COUNT(g.goal_id) AS goals_scored
FROM goals AS g
INNER JOIN teams AS tm ON g.team_id = tm.team_id
GROUP BY tm.team_name, tm.confederation_name
ORDER BY goals_scored DESC, tm.team_name
LIMIT 20;

-- Top individual goal scorers.
SELECT p.player_id, CONCAT_WS(' ', p.given_name, p.family_name) AS player_name, COUNT(g.goal_id) AS goals_scored
FROM goals AS g
INNER JOIN players AS p ON g.player_id = p.player_id
GROUP BY p.player_id, player_name
ORDER BY goals_scored DESC, player_name
LIMIT 20;

-- Highest-scoring tournaments by total goals and goals per match.
SELECT
    t.tournament_name,
    t.year,
    COUNT(g.goal_id) AS total_goals,
    COUNT(DISTINCT m.match_id) AS match_count,
    ROUND(COUNT(g.goal_id)::NUMERIC / NULLIF(COUNT(DISTINCT m.match_id), 0), 2) AS goals_per_match
FROM tournaments AS t
LEFT JOIN matches AS m ON t.tournament_id = m.tournament_id
LEFT JOIN goals AS g ON m.match_id = g.match_id
GROUP BY t.tournament_name, t.year
HAVING COUNT(DISTINCT m.match_id) > 0
ORDER BY total_goals DESC, goals_per_match DESC
LIMIT 10;

-- Host countries that won their own World Cup.
SELECT tournament_name, year, host_country, winner
FROM tournaments
WHERE host_won::TEXT::BOOLEAN
ORDER BY year;

-- Confederations with the best historical finishing performance.
SELECT
    tm.confederation_name,
    COUNT(*) AS tournament_team_entries,
    ROUND(AVG(ts.position)::NUMERIC, 2) AS avg_finish_position,
    MIN(ts.position) AS best_finish
FROM tournament_standings AS ts
INNER JOIN teams AS tm ON ts.team_id = tm.team_id
GROUP BY tm.confederation_name
HAVING COUNT(*) >= 5
ORDER BY avg_finish_position, best_finish;

-- Most-carded players using PostgreSQL FILTER syntax.
SELECT
    p.player_id,
    CONCAT_WS(' ', p.given_name, p.family_name) AS player_name,
    COUNT(b.booking_id) AS total_bookings,
    COUNT(*) FILTER (WHERE b.yellow_card) AS yellow_cards,
    COUNT(*) FILTER (WHERE b.red_card) AS red_cards,
    COUNT(*) FILTER (WHERE b.second_yellow_card) AS second_yellow_cards
FROM bookings AS b
INNER JOIN players AS p ON b.player_id = p.player_id
GROUP BY p.player_id, player_name
ORDER BY total_bookings DESC, red_cards DESC, player_name
LIMIT 20;

-- Most disciplined teams by bookings per tournament with a booking.
SELECT
    tm.team_name,
    COUNT(b.booking_id) AS total_bookings,
    COUNT(DISTINCT b.tournament_id) AS tournaments_with_bookings,
    ROUND(COUNT(b.booking_id)::NUMERIC / NULLIF(COUNT(DISTINCT b.tournament_id), 0), 2) AS bookings_per_tournament
FROM teams AS tm
LEFT JOIN bookings AS b ON tm.team_id = b.team_id
GROUP BY tm.team_name
HAVING COUNT(b.booking_id) > 0
ORDER BY bookings_per_tournament, total_bookings, tm.team_name
LIMIT 20;

--------------------------------------------------
-- Advanced Analytics
--------------------------------------------------

-- Goal type mix: penalty, own goal, and open play.
SELECT
    CASE
        WHEN penalty::TEXT::BOOLEAN THEN 'Penalty'
        WHEN own_goal::TEXT::BOOLEAN THEN 'Own goal'
        ELSE 'Open play'
    END AS goal_type,
    COUNT(*) AS goal_count
FROM goals
GROUP BY goal_type
ORDER BY goal_count DESC;

-- Own goals by tournament.
SELECT
    t.tournament_name,
    t.year,
    COUNT(*) FILTER (WHERE g.own_goal::TEXT::BOOLEAN) AS own_goals
FROM tournaments AS t
LEFT JOIN goals AS g ON t.tournament_id = g.tournament_id
GROUP BY t.tournament_name, t.year
HAVING COUNT(*) FILTER (WHERE g.own_goal::TEXT::BOOLEAN) > 0
ORDER BY own_goals DESC, t.year;

-- Goals by decade.
SELECT
    (t.year / 10) * 10 AS decade,
    COUNT(g.goal_id) AS total_goals,
    COUNT(DISTINCT t.tournament_id) AS tournaments_played,
    ROUND(COUNT(g.goal_id)::NUMERIC / NULLIF(COUNT(DISTINCT t.tournament_id), 0), 2) AS goals_per_tournament
FROM tournaments AS t
LEFT JOIN goals AS g ON t.tournament_id = g.tournament_id
GROUP BY decade
ORDER BY decade;

-- Goals by match period with percentage contribution.
SELECT
    match_period,
    COUNT(*) AS goal_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_goals
FROM goals
GROUP BY match_period
ORDER BY goal_count DESC;

-- Knockout-stage goal production by stage.
SELECT
    m.stage_name,
    COUNT(g.goal_id) AS total_goals
FROM matches AS m
INNER JOIN goals AS g ON m.match_id = g.match_id
WHERE m.knockout_stage
GROUP BY m.stage_name
ORDER BY total_goals DESC, m.stage_name;

-- Group-stage versus knockout-stage goals per match.
SELECT
    CASE
        WHEN m.group_stage THEN 'Group stage'
        WHEN m.knockout_stage THEN 'Knockout stage'
        ELSE 'Other'
    END AS competition_phase,
    COUNT(g.goal_id) AS total_goals,
    COUNT(DISTINCT m.match_id) AS match_count,
    ROUND(COUNT(g.goal_id)::NUMERIC / NULLIF(COUNT(DISTINCT m.match_id), 0), 2) AS goals_per_match
FROM matches AS m
LEFT JOIN goals AS g ON m.match_id = g.match_id
GROUP BY competition_phase
ORDER BY goals_per_match DESC;

-- Combined team scorecard using CTEs for goals, bookings, and standings.
WITH goal_totals AS (
    SELECT team_id, COUNT(*) AS goals_scored
    FROM goals
    GROUP BY team_id
),
booking_totals AS (
    SELECT team_id, COUNT(*) AS bookings_received
    FROM bookings
    GROUP BY team_id
),
standing_totals AS (
    SELECT
        team_id,
        COUNT(*) AS tournament_entries,
        MIN(position) AS best_finish
    FROM tournament_standings
    GROUP BY team_id
)
SELECT
    tm.team_name,
    COALESCE(gt.goals_scored, 0) AS goals_scored,
    COALESCE(bt.bookings_received, 0) AS bookings_received,
    COALESCE(st.tournament_entries, 0) AS tournament_entries,
    st.best_finish
FROM teams AS tm
LEFT JOIN goal_totals AS gt ON tm.team_id = gt.team_id
LEFT JOIN booking_totals AS bt ON tm.team_id = bt.team_id
LEFT JOIN standing_totals AS st ON tm.team_id = st.team_id
ORDER BY goals_scored DESC, tournament_entries DESC
LIMIT 25;

--------------------------------------------------
-- Views
--------------------------------------------------

-- Reusable match-level reporting view.
CREATE OR REPLACE VIEW vw_match_summary AS
SELECT
    m.match_id,
    m.tournament_id,
    t.tournament_name,
    t.year,
    m.match_name,
    m.stage_name,
    m.group_name,
    m.group_stage,
    m.knockout_stage,
    m.replayed,
    COUNT(DISTINCT g.goal_id) AS total_goals,
    COUNT(DISTINCT b.booking_id) AS total_bookings
FROM matches AS m
INNER JOIN tournaments AS t ON m.tournament_id = t.tournament_id
LEFT JOIN goals AS g ON m.match_id = g.match_id
LEFT JOIN bookings AS b ON m.match_id = b.match_id
GROUP BY
    m.match_id,
    t.tournament_name,
    t.year;

-- Reusable team statistics view.
CREATE OR REPLACE VIEW vw_team_statistics AS
WITH goal_totals AS (
    SELECT team_id, COUNT(*) AS goals_scored FROM goals GROUP BY team_id
),
booking_totals AS (
    SELECT team_id, COUNT(*) AS bookings_received FROM bookings GROUP BY team_id
),
standing_totals AS (
    SELECT
        team_id,
        COUNT(*) AS tournament_entries,
        MIN(position) AS best_finish,
        ROUND(AVG(position)::NUMERIC, 2) AS avg_finish_position
    FROM tournament_standings
    GROUP BY team_id
)
SELECT
    tm.team_id, tm.team_name, tm.team_code, tm.confederation_name,
    COALESCE(gt.goals_scored, 0) AS goals_scored,
    COALESCE(bt.bookings_received, 0) AS bookings_received,
    COALESCE(st.tournament_entries, 0) AS tournament_entries,
    st.best_finish, st.avg_finish_position
FROM teams AS tm
LEFT JOIN goal_totals AS gt ON tm.team_id = gt.team_id
LEFT JOIN booking_totals AS bt ON tm.team_id = bt.team_id
LEFT JOIN standing_totals AS st ON tm.team_id = st.team_id;

-- Reusable player statistics view.
CREATE OR REPLACE VIEW vw_player_statistics AS
WITH goal_totals AS (
    SELECT player_id, COUNT(*) AS goals_scored FROM goals GROUP BY player_id
),
booking_totals AS (
    SELECT
        player_id,
        COUNT(*) AS bookings_received,
        COUNT(*) FILTER (WHERE yellow_card) AS yellow_cards,
        COUNT(*) FILTER (WHERE red_card) AS red_cards,
        COUNT(*) FILTER (WHERE second_yellow_card) AS second_yellow_cards
    FROM bookings
    GROUP BY player_id
)
SELECT
    p.player_id, CONCAT_WS(' ', p.given_name, p.family_name) AS player_name,
    p.birth_date, p.goal_keeper, p.defender, p.midfielder, p.forward, p.count_tournaments,
    COALESCE(gt.goals_scored, 0) AS goals_scored,
    COALESCE(bt.bookings_received, 0) AS bookings_received,
    COALESCE(bt.yellow_cards, 0) AS yellow_cards,
    COALESCE(bt.red_cards, 0) AS red_cards,
    COALESCE(bt.second_yellow_cards, 0) AS second_yellow_cards
FROM players AS p
LEFT JOIN goal_totals AS gt ON p.player_id = gt.player_id
LEFT JOIN booking_totals AS bt ON p.player_id = bt.player_id;

-- Reusable tournament statistics view.
CREATE OR REPLACE VIEW vw_tournament_statistics AS
WITH match_totals AS (
    SELECT tournament_id, COUNT(*) AS match_count FROM matches GROUP BY tournament_id
),
goal_totals AS (
    SELECT tournament_id, COUNT(*) AS total_goals FROM goals GROUP BY tournament_id
),
booking_totals AS (
    SELECT tournament_id, COUNT(*) AS total_bookings FROM bookings GROUP BY tournament_id
)
SELECT
    t.tournament_id, t.tournament_name, t.year, t.host_country, t.winner, t.host_won, t.count_teams,
    COALESCE(mt.match_count, 0) AS match_count,
    COALESCE(gt.total_goals, 0) AS total_goals,
    COALESCE(bt.total_bookings, 0) AS total_bookings,
    ROUND(COALESCE(gt.total_goals, 0)::NUMERIC / NULLIF(mt.match_count, 0), 2) AS goals_per_match
FROM tournaments AS t
LEFT JOIN match_totals AS mt ON t.tournament_id = mt.tournament_id
LEFT JOIN goal_totals AS gt ON t.tournament_id = gt.tournament_id
LEFT JOIN booking_totals AS bt ON t.tournament_id = bt.tournament_id;

-- View-based tournament KPI query.
SELECT tournament_name, year, total_goals, goals_per_match
FROM vw_tournament_statistics
ORDER BY total_goals DESC, goals_per_match DESC
LIMIT 10;

--------------------------------------------------
-- Indexes
--------------------------------------------------

-- Indexes for common goal joins and leaderboards.
CREATE INDEX IF NOT EXISTS idx_goals_tournament_id ON goals (tournament_id);
CREATE INDEX IF NOT EXISTS idx_goals_match_id ON goals (match_id);
CREATE INDEX IF NOT EXISTS idx_goals_team_id ON goals (team_id);
CREATE INDEX IF NOT EXISTS idx_goals_player_id ON goals (player_id);
CREATE INDEX IF NOT EXISTS idx_goals_tournament_match ON goals (tournament_id, match_id);

-- Indexes for common booking joins and disciplinary reports.
CREATE INDEX IF NOT EXISTS idx_bookings_tournament_id ON bookings (tournament_id);
CREATE INDEX IF NOT EXISTS idx_bookings_team_id ON bookings (team_id);
CREATE INDEX IF NOT EXISTS idx_bookings_player_id ON bookings (player_id);
CREATE INDEX IF NOT EXISTS idx_bookings_tournament_team ON bookings (tournament_id, team_id);

-- Indexes for match phase and standings analysis.
CREATE INDEX IF NOT EXISTS idx_matches_tournament_id ON matches (tournament_id);
CREATE INDEX IF NOT EXISTS idx_matches_knockout_stage ON matches (knockout_stage);
CREATE INDEX IF NOT EXISTS idx_matches_stage_name ON matches (stage_name);
CREATE INDEX IF NOT EXISTS idx_matches_tournament_stage ON matches (tournament_id, stage_name);
CREATE INDEX IF NOT EXISTS idx_tournament_standings_team_id ON tournament_standings (team_id);
CREATE INDEX IF NOT EXISTS idx_tournament_standings_position ON tournament_standings (position);

--------------------------------------------------
-- Window Functions
--------------------------------------------------

-- Combined player ranking with ROW_NUMBER, RANK, and DENSE_RANK.
SELECT
    ROW_NUMBER() OVER (ORDER BY goals_scored DESC, player_name) AS row_num,
    RANK() OVER (ORDER BY goals_scored DESC) AS goal_rank,
    DENSE_RANK() OVER (ORDER BY goals_scored DESC) AS dense_goal_rank,
    player_id,
    player_name,
    goals_scored,
    bookings_received
FROM vw_player_statistics
WHERE goals_scored > 0
ORDER BY goal_rank, player_name
LIMIT 30;

-- Confederation-level team ranking using DENSE_RANK.
SELECT
    confederation_name,
    team_name,
    goals_scored,
    DENSE_RANK() OVER (
        PARTITION BY confederation_name
        ORDER BY goals_scored DESC
    ) AS confederation_goal_rank
FROM vw_team_statistics
ORDER BY confederation_name, confederation_goal_rank, team_name;

-- Tournament goal trend with LAG, LEAD, and running totals.
SELECT
    tournament_name,
    year,
    total_goals,
    LAG(total_goals) OVER (ORDER BY year) AS previous_tournament_goals,
    LEAD(total_goals) OVER (ORDER BY year) AS next_tournament_goals,
    total_goals - LAG(total_goals) OVER (ORDER BY year) AS goal_change,
    SUM(total_goals) OVER (
        ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_goals
FROM vw_tournament_statistics
ORDER BY year;

--------------------------------------------------
-- EXPLAIN ANALYZE
--------------------------------------------------

-- Execution plan for view-based team goal rankings using idx_goals_team_id inside the view.
EXPLAIN ANALYZE
SELECT
    team_name,
    goals_scored,
    bookings_received
FROM vw_team_statistics
ORDER BY goals_scored DESC
LIMIT 20;

-- Execution plan for tournament scoring analysis using tournament and goal indexes.
EXPLAIN ANALYZE
SELECT
    tournament_name,
    year,
    total_goals,
    match_count,
    goals_per_match
FROM vw_tournament_statistics
ORDER BY total_goals DESC;

-- Execution plan for knockout-stage scoring using match phase and goal-match indexes.
EXPLAIN ANALYZE
SELECT
    m.stage_name,
    COUNT(g.goal_id) AS total_goals
FROM matches AS m
INNER JOIN goals AS g
    ON m.match_id = g.match_id
WHERE m.knockout_stage
GROUP BY m.stage_name
ORDER BY total_goals DESC;
