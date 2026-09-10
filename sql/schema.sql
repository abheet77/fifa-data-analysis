DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS tournament_standings CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS players CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS tournaments CASCADE;

CREATE TABLE tournaments (
    tournament_id VARCHAR(20) PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    start_date DATE,
    end_date DATE,
    host_country VARCHAR(100),
    winner VARCHAR(100),
    host_won SMALLINT,
    count_teams INT,
    group_stage SMALLINT,
    second_group_stage BOOLEAN,
    final_round BOOLEAN,
    round_of_16 BOOLEAN,
    quarter_finals BOOLEAN,
    semi_finals BOOLEAN,
    third_place_match BOOLEAN,
    final BOOLEAN
);

CREATE TABLE teams (
    team_id VARCHAR(20) PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL,
    team_code VARCHAR(5),
    federation_name VARCHAR(100),
    region_name VARCHAR(100),
    confederation_id VARCHAR(20),
    confederation_name VARCHAR(100),
    confederation_code VARCHAR(10)
);

CREATE TABLE players (
    player_id VARCHAR(30) PRIMARY KEY,
    family_name VARCHAR(100),
    given_name VARCHAR(100),
    birth_date DATE,
    goal_keeper BOOLEAN,
    defender BOOLEAN,
    midfielder BOOLEAN,
    forward BOOLEAN,
    count_tournaments INT
);

CREATE TABLE matches (
    match_id VARCHAR(30) PRIMARY KEY,
    tournament_id VARCHAR(20) NOT NULL,
    match_name VARCHAR(200),
    stage_name VARCHAR(100),
    group_name VARCHAR(100),
    group_stage BOOLEAN,
    knockout_stage BOOLEAN,
    replayed BOOLEAN,

    CONSTRAINT fk_match_tournament
        FOREIGN KEY (tournament_id)
        REFERENCES tournaments(tournament_id)
);

CREATE TABLE goals (
    goal_id VARCHAR(30) PRIMARY KEY,
    tournament_id VARCHAR(20),
    match_id VARCHAR(30),
    team_id VARCHAR(20),
    player_id VARCHAR(30),
    minute_regulation INT,
    minute_stoppage INT,
    match_period VARCHAR(50),
    own_goal SMALLINT,
    penalty SMALLINT,

    CONSTRAINT fk_goal_match
        FOREIGN KEY (match_id)
        REFERENCES matches(match_id),

    CONSTRAINT fk_goal_player
        FOREIGN KEY (player_id)
        REFERENCES players(player_id),

    CONSTRAINT fk_goal_team
        FOREIGN KEY (team_id)
        REFERENCES teams(team_id),

    CONSTRAINT fk_goal_tournament
        FOREIGN KEY (tournament_id)
        REFERENCES tournaments(tournament_id)
);

CREATE TABLE bookings (
    booking_id VARCHAR(30) PRIMARY KEY,
    tournament_id VARCHAR(20),
    match_id VARCHAR(30),
    team_id VARCHAR(20),
    player_id VARCHAR(30),
    minute_regulation INT,
    minute_stoppage INT,
    match_period VARCHAR(50),
    yellow_card BOOLEAN,
    red_card BOOLEAN,
    second_yellow_card BOOLEAN,
    sending_off BOOLEAN,

    CONSTRAINT fk_booking_match
        FOREIGN KEY (match_id)
        REFERENCES matches(match_id),

    CONSTRAINT fk_booking_player
        FOREIGN KEY (player_id)
        REFERENCES players(player_id),

    CONSTRAINT fk_booking_team
        FOREIGN KEY (team_id)
        REFERENCES teams(team_id),

    CONSTRAINT fk_booking_tournament
        FOREIGN KEY (tournament_id)
        REFERENCES tournaments(tournament_id)
);

CREATE TABLE tournament_standings (
    tournament_id VARCHAR(20),
    team_id VARCHAR(20),
    position INT,

    PRIMARY KEY (tournament_id, team_id),

    CONSTRAINT fk_standing_tournament
        FOREIGN KEY (tournament_id)
        REFERENCES tournaments(tournament_id),

    CONSTRAINT fk_standing_team
        FOREIGN KEY (team_id)
        REFERENCES teams(team_id)
);