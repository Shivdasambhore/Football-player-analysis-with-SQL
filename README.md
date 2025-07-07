# Football-player-analysis-with-SQL
Advanced SQL project analyzing player, club, league, and national team performance using the 2024/25 football dataset from Kaggle.

## Project Overview

This SQL-driven analysis covers:
- Player performance (goals, assists, defensive actions)
- Club dynamics and trio combinations
- League-wise quality and style comparison
- Youth development trends
- Nation-wise talent distribution
- Position-specific rankings and best XIs

  
## Dataset Source

**Title:** Football Players Stats 2024/2025  
**Source:** [Kaggle Dataset by Hubert Sidorowicz](https://www.kaggle.com/datasets/hubertsidorowicz/football-players-stats-2024-2025)  
**Size:** ~17,000 Players  
**Coverage:** Player demographics, match stats, passing, defending, progression, possession, goalkeeper metrics, etc.

## Individual player analysis
- Top 5 Best Goalkeepers from all league (this is based on Save % and Clean Sheets)
- Top 10 Scorers (by Goals)
- Top 10 Scorers (Gls per 90 mins, min 900 mins)
- Top 10 Most Relied Upon Players (which playes Most % Minutes Played for Club)
- Best Midfielders with attacking output (here we consider Assists, Key Passes, xA)
-  Best 10 Emerging Players in Each League (which age is less than 23, Ranked by Goal and assist per 90 min)
- player which covered most distance (Top 10 as % of Team Minutes)
- Best 10 Ball Recoverers (per 90 mins)
- Best Player at Each Position
- Top 5 Most Creative Players (in which use Assist, xA, KP, PPA — per 90 mins)

## Club level analysis
- Club which having most attacking threat with all player (Gls per 90 mins across all players)
- here we get best defensder on bases of Weighted Defense Index ( which include Tackles, Interceptions, Clean Sheets, Goals Against)
- Club which are Heavy Reliance on Single Player’s Contribution
- club which having very low independ depandancy on single player in attacking area.
- Creativity Index Per Club ( in which we consider Key Passes, xA, Passes Into Penalty Area ane check then over per 90 min)
- Defensive Discipline Score (in which we consider club having total Low no of cards and won high no of tackles)
- Emerging Talent Index Per Club (which age is less than 23, we check their stats like goal and assist per 90 min)
- Emerging Defensive Talent Index per Club
- Club Ball Progression Score (which include Carries and Progressive Passes)
- Best Overall Club Index (Combined Offense, Defense, Creativity, Youth)
- Best Midfield Trio Per Club (2 attacking midfield and 1 is defencive)


