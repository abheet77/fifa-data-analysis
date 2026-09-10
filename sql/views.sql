CREATE OR REPLACE VIEW vw_team_statistics AS
WITH goal_totals AS (
    SELECT
        team_id,
        COUNT(*) AS goals_scored,
        COUNT(*) FILTER (WHERE own_goal = 1) AS own_goals,
        COUNT(*) FILTER (WHERE penalty = 1) AS penalty_goals
    FROM goals
    GROUP BY team_id
),
booking_totals AS (
    SELECT
        team_id,
        COUNT(*) AS total_bookings,
        COUNT(*) FILTER (WHERE yellow_card) AS yellow_cards,
        COUNT(*) FILTER (WHERE red_card) AS red_cards,
        COUNT(*) FILTER (WHERE second_yellow_card) AS second_yellow_cards,
        COUNT(*) FILTER (WHERE sending_off) AS sending_offs
    FROM bookings
    GROUP BY team_id
),
standing_totals AS (
    SELECT
        team_id,
        COUNT(*) AS tournament_entries,
        MIN(position) AS best_finish,
        ROUND(AVG(position)::NUMERIC, 2) AS avg_finish_position,
        COUNT(*) FILTER (WHERE position = 1) AS tournament_wins,
        COUNT(*) FILTER (WHERE position <= 4) AS top_four_finishes
    FROM tournament_standings
    GROUP BY team_id
)
SELECT
    tm.team_id,
    tm.team_name,
    tm.team_code,
    tm.federation_name,
    tm.region_name,
    tm.confederation_id,
    tm.confederation_name,
    tm.confederation_code,
    COALESCE(gt.goals_scored, 0) AS goals_scored,
    COALESCE(gt.own_goals, 0) AS own_goals,
    COALESCE(gt.penalty_goals, 0) AS penalty_goals,
    COALESCE(bt.total_bookings, 0) AS total_bookings,
    COALESCE(bt.yellow_cards, 0) AS yellow_cards,
    COALESCE(bt.red_cards, 0) AS red_cards,
    COALESCE(bt.second_yellow_cards, 0) AS second_yellow_cards,
    COALESCE(bt.sending_offs, 0) AS sending_offs,
    COALESCE(st.tournament_entries, 0) AS tournament_entries,
    st.best_finish,
    st.avg_finish_position,
    COALESCE(st.tournament_wins, 0) AS tournament_wins,
    COALESCE(st.top_four_finishes, 0) AS top_four_finishes
FROM teams AS tm
LEFT JOIN goal_totals AS gt
    ON tm.team_id = gt.team_id
LEFT JOIN booking_totals AS bt
    ON tm.team_id = bt.team_id
LEFT JOIN standing_totals AS st
    ON tm.team_id = st.team_id;

CREATE OR REPLACE VIEW vw_player_statistics AS
WITH goal_totals AS (
    SELECT
        player_id,
        COUNT(*) AS goals_scored,
        COUNT(*) FILTER (WHERE own_goal = 1) AS own_goals,
        COUNT(*) FILTER (WHERE penalty = 1) AS penalty_goals
    FROM goals
    GROUP BY player_id
),
booking_totals AS (
    SELECT
        player_id,
        COUNT(*) AS total_bookings,
        COUNT(*) FILTER (WHERE yellow_card) AS yellow_cards,
        COUNT(*) FILTER (WHERE red_card) AS red_cards,
        COUNT(*) FILTER (WHERE second_yellow_card) AS second_yellow_cards,
        COUNT(*) FILTER (WHERE sending_off) AS sending_offs
    FROM bookings
    GROUP BY player_id
)
SELECT
    p.player_id,
    p.family_name,
    p.given_name,
    CONCAT_WS(' ', p.given_name, p.family_name) AS player_name,
    p.birth_date,
    p.goal_keeper,
    p.defender,
    p.midfielder,
    p.forward,
    p.count_tournaments,
    COALESCE(gt.goals_scored, 0) AS goals_scored,
    COALESCE(gt.own_goals, 0) AS own_goals,
    COALESCE(gt.penalty_goals, 0) AS penalty_goals,
    COALESCE(bt.total_bookings, 0) AS total_bookings,
    COALESCE(bt.yellow_cards, 0) AS yellow_cards,
    COALESCE(bt.red_cards, 0) AS red_cards,
    COALESCE(bt.second_yellow_cards, 0) AS second_yellow_cards,
    COALESCE(bt.sending_offs, 0) AS sending_offs
FROM players AS p
LEFT JOIN goal_totals AS gt
    ON p.player_id = gt.player_id
LEFT JOIN booking_totals AS bt
    ON p.player_id = bt.player_id;

CREATE OR REPLACE VIEW vw_tournament_statistics AS
WITH match_totals AS (
    SELECT
        tournament_id,
        COUNT(*) AS match_count,
        COUNT(*) FILTER (WHERE group_stage) AS group_stage_matches,
        COUNT(*) FILTER (WHERE knockout_stage) AS knockout_stage_matches,
        COUNT(*) FILTER (WHERE replayed) AS replayed_matches
    FROM matches
    GROUP BY tournament_id
),
goal_totals AS (
    SELECT
        tournament_id,
        COUNT(*) AS total_goals,
        COUNT(*) FILTER (WHERE own_goal = 1) AS own_goals,
        COUNT(*) FILTER (WHERE penalty = 1) AS penalty_goals
    FROM goals
    GROUP BY tournament_id
),
booking_totals AS (
    SELECT
        tournament_id,
        COUNT(*) AS total_bookings,
        COUNT(*) FILTER (WHERE yellow_card) AS yellow_cards,
        COUNT(*) FILTER (WHERE red_card) AS red_cards,
        COUNT(*) FILTER (WHERE second_yellow_card) AS second_yellow_cards,
        COUNT(*) FILTER (WHERE sending_off) AS sending_offs
    FROM bookings
    GROUP BY tournament_id
),
standing_totals AS (
    SELECT
        tournament_id,
        COUNT(*) AS teams_ranked
    FROM tournament_standings
    GROUP BY tournament_id
)
SELECT
    t.tournament_id,
    t.tournament_name,
    t.year,
    t.start_date,
    t.end_date,
    t.host_country,
    t.winner,
    t.host_won,
    t.count_teams,
    t.group_stage,
    t.second_group_stage,
    t.final_round,
    t.round_of_16,
    t.quarter_finals,
    t.semi_finals,
    t.third_place_match,
    t.final,
    COALESCE(mt.match_count, 0) AS match_count,
    COALESCE(mt.group_stage_matches, 0) AS group_stage_matches,
    COALESCE(mt.knockout_stage_matches, 0) AS knockout_stage_matches,
    COALESCE(mt.replayed_matches, 0) AS replayed_matches,
    COALESCE(gt.total_goals, 0) AS total_goals,
    COALESCE(gt.own_goals, 0) AS own_goals,
    COALESCE(gt.penalty_goals, 0) AS penalty_goals,
    ROUND(COALESCE(gt.total_goals, 0)::NUMERIC / NULLIF(mt.match_count, 0), 2) AS goals_per_match,
    COALESCE(bt.total_bookings, 0) AS total_bookings,
    COALESCE(bt.yellow_cards, 0) AS yellow_cards,
    COALESCE(bt.red_cards, 0) AS red_cards,
    COALESCE(bt.second_yellow_cards, 0) AS second_yellow_cards,
    COALESCE(bt.sending_offs, 0) AS sending_offs,
    COALESCE(st.teams_ranked, 0) AS teams_ranked
FROM tournaments AS t
LEFT JOIN match_totals AS mt
    ON t.tournament_id = mt.tournament_id
LEFT JOIN goal_totals AS gt
    ON t.tournament_id = gt.tournament_id
LEFT JOIN booking_totals AS bt
    ON t.tournament_id = bt.tournament_id
LEFT JOIN standing_totals AS st
    ON t.tournament_id = st.tournament_id;

CREATE OR REPLACE VIEW vw_match_summary AS
WITH goal_totals AS (
    SELECT
        match_id,
        COUNT(*) AS total_goals,
        COUNT(*) FILTER (WHERE own_goal = 1) AS own_goals,
        COUNT(*) FILTER (WHERE penalty = 1) AS penalty_goals
    FROM goals
    GROUP BY match_id
),
booking_totals AS (
    SELECT
        match_id,
        COUNT(*) AS total_bookings,
        COUNT(*) FILTER (WHERE yellow_card) AS yellow_cards,
        COUNT(*) FILTER (WHERE red_card) AS red_cards,
        COUNT(*) FILTER (WHERE second_yellow_card) AS second_yellow_cards,
        COUNT(*) FILTER (WHERE sending_off) AS sending_offs
    FROM bookings
    GROUP BY match_id
)
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
    COALESCE(gt.total_goals, 0) AS total_goals,
    COALESCE(gt.own_goals, 0) AS own_goals,
    COALESCE(gt.penalty_goals, 0) AS penalty_goals,
    COALESCE(bt.total_bookings, 0) AS total_bookings,
    COALESCE(bt.yellow_cards, 0) AS yellow_cards,
    COALESCE(bt.red_cards, 0) AS red_cards,
    COALESCE(bt.second_yellow_cards, 0) AS second_yellow_cards,
    COALESCE(bt.sending_offs, 0) AS sending_offs
FROM matches AS m
INNER JOIN tournaments AS t
    ON m.tournament_id = t.tournament_id
LEFT JOIN goal_totals AS gt
    ON m.match_id = gt.match_id
LEFT JOIN booking_totals AS bt
    ON m.match_id = bt.match_id;
