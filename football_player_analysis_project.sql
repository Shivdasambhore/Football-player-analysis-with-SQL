
-- Top 5 Best Goalkeepers from all league (this is based on Save % and Clean Sheets)
SELECT 
    Player, Club, Save_per, CS, GA, Matches_played
FROM football_data
WHERE Pos LIKE '%GK%' AND Matches_played > 10
ORDER BY Save_per DESC, CS DESC
LIMIT 5;

-- Top 10 Scorers (by Goals)
SELECT 
    Player, Club, Pos, Gls
FROM football_data
ORDER BY CAST(Gls AS UNSIGNED) DESC
LIMIT 10;

-- Top 10 Scorers (Gls per 90 mins, min 900 mins)
SELECT 
    Player, Club, Gls, Min,
    ROUND(Gls * 90.0 / NULLIF(Min, 0), 2) AS Gls_per_90
FROM football_data
WHERE Min >= 900
ORDER BY Gls_per_90 DESC
LIMIT 10;

-- Top 10 Most Relied Upon Players (which playes Most % Minutes Played for Club)
SELECT 
    Player, Club, Min, ful_matche_played, Matches_played,
    ROUND((Min / (Matches_played * 90.0)) * 100, 2) AS Match_completed_percentage
FROM football_data
WHERE Matches_played >= 10
ORDER BY match_completed_percentage DESC
LIMIT 10;


-- Best Midfielders with attacking output (here we consider Assists, Key Passes, xA)
SELECT 
    Player, Club,G_and_A ,KP, Ast, xA,
    ROUND((KP * 0.4 + Ast * 0.4 + xA * 0.2), 2) AS Midfield_Creativity
FROM football_data
WHERE Pos LIKE '%MF%' AND Matches_played > 10
ORDER BY Midfield_Creativity DESC
LIMIT 10;

--  Best 10 Emerging Players in Each League (which age is less than 23, Ranked by Goal and assist per 90 min)
SELECT *
FROM (
    SELECT 
        Player, League, Age, Club, Gls, Ast, Min,
        ROUND((Gls + Ast) * 90.0 / NULLIF(Min, 0), 2) AS GA_per_90,
        RANK() OVER (PARTITION BY League ORDER BY (Gls + Ast) * 90.0 / NULLIF(Min, 0) DESC) AS rnk
    FROM football_data
    WHERE Age < 23 AND Min >= 900
) t
WHERE rnk <= 10
ORDER BY League, GA_per_90 DESC;

-- player which covered most distance (Top 10 as % of Team Minutes)
SELECT 
    Player, Club, Matches_played, Min, TotDist,
    ROUND(TotDist / NULLIF(Min, 0), 2) AS Distance_per_min
FROM football_data
WHERE Min >= 900
ORDER BY Distance_per_min DESC
LIMIT 10;

-- Best 10 Ball Recoverers (per 90 mins)
SELECT 
    Player, Club, Rec, Min,
    ROUND(Rec * 90.0 / NULLIF(Min, 0), 2) AS Rec_per_90
FROM football_data
WHERE Min >= 900
ORDER BY Rec_per_90 DESC
LIMIT 10;

-- Best Player at Each Position 
SELECT *
FROM (
    SELECT 
        Player, Pos, Club, Gls, Ast, Min,
        ROUND((Gls + Ast) * 90.0 / NULLIF(Min, 0), 2) AS GA_per90,
        RANK() OVER (PARTITION BY Pos ORDER BY (Gls + Ast) * 90.0 / NULLIF(Min, 0) DESC) AS rnk
    FROM football_data
    WHERE Min >= 900  -- Played at least 10 full matches
) t
WHERE rnk =1;

-- Top 5 Most Creative Players (in which use Assist, xA, KP, PPA — per 90 mins)
SELECT 
    Player, Club, Min, KP, Ast, xA, PPA,
    ROUND((KP + Ast + xA + PPA) * 90.0 / NULLIF(Min, 0), 2) AS Creativity_Index
FROM football_data
WHERE Min >= 900
ORDER BY Creativity_Index DESC
LIMIT 5;
-- Total Goals & Assists per Club
SELECT 
    Club,
    SUM(Gls) AS Total_Goals,
    SUM(Ast) AS Total_Assists
FROM football_data
GROUP BY Club
ORDER BY Total_Goals DESC;


-- Club analysis

-- Club which having most attacking threat with all player (Gls per 90 mins across all players)
SELECT 
    Club,
    League,
    ROUND(SUM(Gls * 90.0 / NULLIF(Min, 0)), 2) AS Total_Goal_per_90
FROM football_data
WHERE Min >= 900
GROUP BY Club, League
ORDER BY Total_Goal_per_90 DESC;

-- here we get best defensder on bases of Weighted Defense Index ( which include Tackles, Interceptions, Clean Sheets, Goals Against)
SELECT 
    Club,
    SUM(Tkl + 'Int') AS Def_Actions,
    SUM(CS) AS Clean_Sheets,
    SUM(GA) AS Goals_Conceded,
    ROUND((SUM(Tkl + 'Int') + SUM(CS) * 2) / NULLIF(SUM(GA), 0), 2) AS Defense_Index
FROM football_data
GROUP BY Club
HAVING SUM(GA) > 0
ORDER BY Defense_Index DESC;

-- Club which are Heavy Reliance on Single Player’s Contribution
WITH club_total AS (
    SELECT Club, SUM(G_and_A) AS total_ga FROM football_data GROUP BY Club
), top_player AS (
    SELECT Club, Player, G_and_A,
           RANK() OVER (PARTITION BY Club ORDER BY G_and_A DESC) AS rnk
    FROM football_data
)
SELECT 
    tp.Club, tp.Player, tp.G_and_A, ct.total_ga,
    ROUND(tp.G_and_A / ct.total_ga * 100, 2) AS Contribution_Percentage
FROM top_player tp
JOIN club_total ct ON tp.Club = ct.Club
WHERE rnk = 1 AND ct.total_ga > 0
ORDER BY Contribution_Percentage DESC;

-- club which having very low independ depandancy on single player in attacking area.
WITH club_total AS (
    SELECT Club, SUM(G_and_A) AS total_ga
    FROM football_data
    GROUP BY Club
),
top_contributors AS (
    SELECT 
        Club, Player, G_and_A,
        RANK() OVER (PARTITION BY Club ORDER BY G_and_A DESC) AS rnk
    FROM football_data
),
top_player_contribution AS (
    SELECT 
        tp.Club,
        tp.Player AS Top_Player,
        tp.G_and_A AS Top_Player_GA,
        ct.total_ga,
        ROUND(tp.G_and_A / ct.total_ga * 100, 2) AS Contribution_Percentage
    FROM top_contributors tp
    JOIN club_total ct ON tp.Club = ct.Club
    WHERE tp.rnk = 1 AND ct.total_ga > 0
)
SELECT *
FROM top_player_contribution
WHERE Contribution_Percentage < 25  
ORDER BY Contribution_Percentage ASC;

-- Creativity Index Per Club ( in which we consider Key Passes, xA, Passes Into Penalty Area ane check then over per 90 min)
SELECT 
    Club,
    ROUND(SUM((KP + xA + PPA) * 90.0 / NULLIF(Min, 0)), 2) AS Creativity_Index
FROM football_data
WHERE Min >= 900
GROUP BY Club
ORDER BY Creativity_Index DESC;

-- Defensive Discipline Score (in which we consider club having total Low no of cards and won high no of tackles)
SELECT 
    Club,
    SUM(yellow_card + Red_card) AS Cards,
    SUM(TklW) AS Tackles_Won,
    ROUND(SUM(TklW) / NULLIF(SUM(yellow_card + Red_card), 0), 2) AS Discipline_Score
FROM football_data
WHERE Matches_played > 10
GROUP BY Club
ORDER BY Discipline_Score DESC;

-- Emerging Talent Index Per Club (which age is less than 23, we check their stats like goal and assist per 90 min)
SELECT 
    Club,
    COUNT(*) AS U23_Count,
    ROUND(SUM(G_and_A * 90.0 / NULLIF(Min, 0)), 2) AS U23_GA_per_90
FROM football_data
WHERE Age < 23 AND Min >= 600
GROUP BY Club
ORDER BY U23_GA_per_90 DESC;

-- Emerging Defensive Talent Index per Club
WITH young_defenders AS (
    SELECT 
        Club,
        Player,
        Age,
        Min,
        Tkl, 'Int', Rec, Clr,
        (Tkl + 'Int' + Rec + Clr) * 90.0 / NULLIF(Min, 0) AS Defensive_Index_per_90
    FROM football_data
    WHERE Age < 23 
      AND Min >= 600
      AND (Pos LIKE '%DF%' OR Pos LIKE '%DM%' OR Pos LIKE '%MF%')
),
club_defensive_index AS (
    SELECT 
        Club,
        COUNT(*) AS U23_Defensive_Players,
        ROUND(AVG(Defensive_Index_per_90), 2) AS Avg_Def_Talent_Index,
        ROUND(SUM(Defensive_Index_per_90), 2) AS Total_Def_Talent_Index
    FROM young_defenders
    GROUP BY Club
)
SELECT *
FROM club_defensive_index
ORDER BY Total_Def_Talent_Index DESC
LIMIT 10;

-- Club Ball Progression Score (which include Carries and Progressive Passes)
SELECT 
    Club,
    ROUND(SUM((PrgC + PrgP + PrgR) * 90.0 / NULLIF(Min, 0)), 2) AS Progression_Score
FROM football_data
WHERE Min >= 900
GROUP BY Club
ORDER BY Progression_Score DESC;

-- Best Overall Club Index (Combined Offense, Defense, Creativity, Youth)
SELECT 
    Club,
    ROUND(SUM((G_and_A + PrgP + TklW + Rec + KP + xA + CrsPA) * 90.0 / NULLIF(Min, 0)), 2) AS Club_Performance_Score
FROM football_data
WHERE Min >= 900
GROUP BY Club
ORDER BY Club_Performance_Score DESC;

-- Best Midfield Trio Per Club (2 attacking midfield and 1 is defencive)
WITH midfielders AS (
    SELECT 
        Player, Club, Pos, G_and_A, xA, KP, Tkl, 'Int', Rec, Min
    FROM football_data
    WHERE Pos LIKE '%MF%' AND Min >= 600
),
attacking_mfs AS (
    SELECT 
        Player, Club,
        G_and_A, xA, KP,
        RANK() OVER (PARTITION BY Club ORDER BY (G_and_A + xA + KP) DESC) AS atk_rank
    FROM midfielders
),
defensive_mfs AS (
    SELECT 
        Player, Club,
        Tkl, 'Int', Rec,
        RANK() OVER (PARTITION BY Club ORDER BY (Tkl + 'Int' + Rec) DESC) AS def_rank
    FROM midfielders
),
club_trios AS (
    SELECT 
        a1.Club,
        a1.Player AS Attacker_1,
        a2.Player AS Attacker_2,
        d.Player AS Defender,
        (a1.G_and_A + a1.xA + a1.KP +
         a2.G_and_A + a2.xA + a2.KP +
         d.Tkl + d.Int + d.Rec) AS Trio_Score
    FROM attacking_mfs a1
    JOIN attacking_mfs a2 
        ON a1.Club = a2.Club AND a1.Player <> a2.Player AND a2.atk_rank = 2
    JOIN defensive_mfs d 
        ON a1.Club = d.Club AND d.def_rank = 1
    WHERE 
        a1.atk_rank = 1
        AND d.Player NOT IN (a1.Player, a2.Player)
)
SELECT *
FROM club_trios
ORDER BY Trio_Score DESC
LIMIT 10;


-- League 

-- Most Physical League

SELECT 
    League,
    SUM(TotDist + Tkl + 'Int' + Rec) AS Physical_Index
FROM football_data
GROUP BY League
ORDER BY Physical_Index DESC;

-- Technical Quality Score (Pass Accuracy + Carries)
SELECT 
    League,
    ROUND(AVG(Cmp_per), 2) AS Avg_Pass_Accuracy,
    ROUND(SUM(Carries * 90.0 / NULLIF(Min, 0)), 2) AS Carries_per_90,
    ROUND(AVG(Cmp_per) + (SUM(Carries * 90.0 / NULLIF(Min, 0)) / COUNT(*)), 2) AS Technical_Quality_Score
FROM football_data
WHERE Min >= 900
GROUP BY League
ORDER BY Technical_Quality_Score DESC;

-- Best 3 Attacking Clubs in Each League

WITH club_attacking AS (
    SELECT 
        League, Club, 
        SUM(Gls) AS Total_Goal,
        RANK() OVER (PARTITION BY League ORDER BY SUM(Gls) DESC) AS rank_in_league
    FROM football_data
    GROUP BY League, Club
)
SELECT *
FROM club_attacking
WHERE rank_in_league <= 3
ORDER BY League, rank_in_league;

-- Most Defensive League

SELECT 
    League,
    SUM(Tkl + 'Int' + Rec) AS Total_Defense,
    SUM(CS) AS Clean_Sheets,
    SUM(GA) AS Goals_Conceded
FROM football_data
GROUP BY League
ORDER BY Total_Defense DESC, Goals_Conceded ASC;

-- Goalkeeper Performance Index
SELECT 
    League,
    ROUND(AVG(Save_per), 2) AS Avg_Save_Per,
    SUM(PKsv) AS Penalty_Saves,
    SUM(CS) AS Clean_Sheets,
    ROUND((AVG(Save_per) + (SUM(PKsv) + SUM(CS)) / COUNT(*)) / 2, 2) AS GK_Performance_Index
FROM football_data
WHERE Pos LIKE '%GK%'
GROUP BY League
ORDER BY GK_Performance_Index DESC;

-- Youth Development League Score (U-23 per 90 Performance)
SELECT 
    League,
    COUNT(*) AS U23_Players,
    ROUND(SUM((G_and_A + xA + KP) * 90.0 / NULLIF(Min, 0)), 2) AS U23_Impact_per_90
FROM football_data
WHERE Age < 23 AND Min >= 600
GROUP BY League
ORDER BY U23_Impact_per_90 DESC;

-- Best Playing XI in 4-3-3 Formation for Each League

WITH players_ranked AS (
    SELECT *,
        CASE 
            WHEN Pos LIKE '%DF%' THEN 'DEF'
            WHEN Pos LIKE '%MF%' THEN 'MID'
            WHEN Pos LIKE '%FW%' THEN 'FWD'
            WHEN Pos LIKE '%GK%' THEN 'GK'
            ELSE NULL
        END AS role,
        RANK() OVER (PARTITION BY League, 
                     CASE 
                        WHEN Pos LIKE '%DF%' THEN 'DEF'
                        WHEN Pos LIKE '%MF%' THEN 'MID'
                        WHEN Pos LIKE '%FW%' THEN 'FWD'
                        WHEN Pos LIKE '%GK%' THEN 'GK'
                     END ORDER BY (G_and_A + xA + KP + Tkl + 'Int' + Rec) DESC) AS pos_rank
    FROM football_data
    WHERE Min >= 600
),
final_xi AS (
    SELECT * 
    FROM players_ranked
    WHERE (role = 'GK' AND pos_rank = 1)
       OR (role = 'DEF' AND pos_rank <= 4)
       OR (role = 'MID' AND pos_rank <= 3)
       OR (role = 'FWD' AND pos_rank <= 3)
)
SELECT League, role, Player, Club, Pos, G_and_A, xA, KP, Tkl, 'Int', Rec
FROM final_xi
ORDER BY League, 
         CASE 
            WHEN role = 'GK' THEN 1
            WHEN role = 'DEF' THEN 2
            WHEN role = 'MID' THEN 3
            WHEN role = 'FWD' THEN 4
         END, pos_rank;


-- league categories into differernt tier (Elite,Competitive,Emerging)

WITH base_stats AS (
    SELECT 
        League,
        COUNT(*) AS total_players,
        SUM(G_and_A * 90.0 / NULLIF(Min, 0)) AS GA_per90,
        SUM((xA + KP + PPA) * 90.0 / NULLIF(Min, 0)) AS Creativity_per90,
        SUM((Tkl + 'Int' + Rec) * 90.0 / NULLIF(Min, 0)) AS Defense_per90,
        SUM((PrgC + PrgP + PrgR) * 90.0 / NULLIF(Min, 0)) AS Progression_per90,
        -- Subquery to calculate U23 contribution
        (SELECT SUM((G_and_A + xA + KP) * 90.0 / NULLIF(Min, 0))
         FROM football_data AS f2
         WHERE f2.League = f1.League AND Age < 23 AND Min >= 900
        ) AS U23_Impact,
        AVG(Cmp_per) AS Pass_Accuracy,
        -- Use conditional average for GK Save%
        AVG(CASE WHEN Pos LIKE '%GK%' THEN Save_per ELSE NULL END) AS GK_Save
    FROM football_data AS f1
    WHERE Min >= 900
    GROUP BY League
),
ranked_leagues AS (
    SELECT *,
        RANK() OVER (ORDER BY GA_per90 DESC) AS r1,
        RANK() OVER (ORDER BY Creativity_per90 DESC) AS r2,
        RANK() OVER (ORDER BY Defense_per90 DESC) AS r3,
        RANK() OVER (ORDER BY Progression_per90 DESC) AS r4,
        RANK() OVER (ORDER BY U23_Impact DESC) AS r5,
        RANK() OVER (ORDER BY Pass_Accuracy DESC) AS r6,
        RANK() OVER (ORDER BY GK_Save DESC) AS r7
    FROM base_stats
),
composite_score AS (
    SELECT 
        League,
        ROUND((
            r1 * 1.2 +
            r2 * 1.1 +
            r3 * 1.0 +
            r4 * 1.0 +
            r5 * 1.0 +
            r6 * 0.8 +
            r7 * 0.9
        ) / 7.0, 2) AS League_Score
    FROM ranked_leagues
),
final_tiers AS (
    SELECT *,
        NTILE(3) OVER (ORDER BY League_Score ASC) AS Tier
    FROM composite_score
)
SELECT 
    League,
    League_Score,
    CASE 
        WHEN Tier = 1 THEN 'Tier 1  (Elite)'
        WHEN Tier = 2 THEN 'Tier 2  (Competitive)'
        ELSE 'Tier 3  (Emerging)'
    END AS League_Tier
FROM final_tiers
ORDER BY League_Score ASC;

-- Nationwise Analysis

-- Top 5 National Teams Having Best 3 Attacking Players

WITH attacker_score AS (
  SELECT 
    Nation,
    Player,
    G_and_A,
    RANK() OVER (PARTITION BY Nation ORDER BY G_and_A DESC) AS rk
  FROM football_data
  WHERE Pos LIKE '%FW%' OR Pos LIKE '%W%' OR Pos LIKE '%AM%'  -- Forward roles
),
top3_sum AS (
  SELECT 
    Nation,
    SUM(G_and_A) AS Top3_Attacker_GA
  FROM attacker_score
  WHERE rk <= 3
  GROUP BY Nation
)
SELECT *
FROM top3_sum
ORDER BY Top3_Attacker_GA DESC
LIMIT 5;

-- Nation With Most Players Across All Leagues
SELECT 
    Nation,
    COUNT(*) AS Total_Players
FROM football_data
GROUP BY Nation
ORDER BY Total_Players DESC
LIMIT 10;

-- Emerging National Talent Index (U-23 Only)

SELECT 
    Nation,
    COUNT(*) AS U23_Players,
    ROUND(AVG((G_and_A + Tkl + 'Int' + Rec + KP + xA) * 90.0 / NULLIF(Min, 0)), 2) AS Avg_Talent_Score
FROM football_data
WHERE Age < 23 AND Min >= 600
GROUP BY Nation
HAVING U23_Players >= 3
ORDER BY Avg_Talent_Score DESC;

-- Which Nation Produces the Most Players in a Specific Position (for this we us midfield)
SELECT 
    Nation,
    COUNT(*) AS Midfielders
FROM football_data
WHERE Pos LIKE '%MF%'
GROUP BY Nation
ORDER BY Midfielders DESC
LIMIT 10;

-- Best Goalkeeper-Producing Nations
SELECT 
    Nation,
    COUNT(*) AS GK_Count,
    ROUND(AVG(Save_per), 2) AS Avg_Save_Per,
    SUM(CS) AS Total_Clean_Sheets,
    SUM(PKsv) AS Total_Penalty_Saves
FROM football_data
WHERE Pos LIKE '%GK%'
GROUP BY Nation
HAVING GK_Count >= 2
ORDER BY Avg_Save_Per DESC, Total_Clean_Sheets DESC
LIMIT 10;

-- Best Playing XI for a Specific Nation (e.g. Spain) in 4-3-3 Formation

WITH player_roles AS (
  SELECT *,
    CASE 
      WHEN Pos LIKE '%GK%' THEN 'GK'
      WHEN Pos LIKE '%DF%' THEN 'DEF'
      WHEN Pos LIKE '%MF%' THEN 'MID'
      WHEN Pos LIKE '%FW%' OR Pos LIKE '%W%' THEN 'FWD'
    END AS role
  FROM football_data
  WHERE Nation = 'ESP' AND Min >= 600
),
ranked_players AS (
  SELECT *,
    RANK() OVER (
      PARTITION BY role 
      ORDER BY (G_and_A + xA + KP + Tkl + 'Int' + Rec) DESC
    ) AS role_rank
  FROM player_roles
),
best11 AS (
  SELECT * 
  FROM ranked_players
  WHERE 
    (role = 'GK' AND role_rank = 1) OR
    (role = 'DEF' AND role_rank <= 4) OR
    (role = 'MID' AND role_rank <= 3) OR
    (role = 'FWD' AND role_rank <= 3)
)
SELECT 
  Player, Pos, Club, role, G_and_A, xA, KP, Tkl, 'Int', Rec
FROM best11
ORDER BY 
  CASE 
    WHEN role = 'GK' THEN 1
    WHEN role = 'DEF' THEN 2
    WHEN role = 'MID' THEN 3
    WHEN role = 'FWD' THEN 4
  END, role_rank;
  
  