/*
English Premier League 23-24 Season Data Exploration 
	Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Top 10 Scorers for 23-24 season
-- Shows the top 10 players with the most goals scored on the season

select
	  s.player_name
	, s.team
	, s.goals
from
	premier_league_player_stats s
order by
	s.goals desc
limit
	10
;

-- Top 5 Teams by Non-Penalty Goals
-- Shows the top 5 teams with the highest total number of non-penalty goals scored by players

select
	  s.team
	, sum(s.goals_minus_penalty_goals) as team_non_penalty_goals
from
	premier_league_player_stats s
group by
	s.team
order by
	team_non_penalty_goals desc
limit
	5
;

—- Most Efficient Goal Scorers (Highest Goals per 90mins vs. Expected Goals per 90mins)
—- Identifies the players who outperformed their expected goals the most, i.e, players with the highest difference between goals per 90 minutes and expected goals per 90 minutes

select
	  pn.player_name
	, pn.team
	, pn.minutes
	, pn.goals_per_90
	, pn.exp_goals_per_90
	, (pn.goals_per_90 - pn.exp_goals_per_90) as goal_production_performance
from
	premier_league_stats_per_90 pn
where
	1=1
	and (pn.goals_per_90 - pn.exp_goals_per_90) > 0 -- only includes players who outperformed
	and minutes > 1000 --only includes players who played 1000 minutes or more on the season
order by
	goal_production_performance desc
limit
	10
;

—- Age vs. Offensive Performance
—- Using join to analyze whether older players offensively performed better or worse than younger players
-- Offensive performance based on goals per 90 minutes and assists per 90 minutes

select
	case
		when
			p.age > 27 then 'Players Over 27'
		else
			'Players Under 27'
		end as
			age_group
	, round(avg(pn.goals_per_90), 4) as avg_goals_per_90
	, round(avg(pn.assists_per_90), 4) as avg_assists_per_90
	, round(avg(pn.goals_per_90) + avg(pn.assists_per_90), 4) as combined_avg_per_90
from
	premier_league_stats_per_90 pn
join
	premier_league_players p
		on pn.player_name = p.player_name
group by
	age_group
;


—- Calculating Best Goal-to-Minutes Ratio
—- Identifies the player with the best goal-to-minutes ratio (goals per minute played), only considering players who played at least 1000 minutes

select
	  s.player_name
	, s.goals
	, s.minutes
	, round(cast(s.goals as numeric) / cast(s.minutes as numeric), 5) as goals_per_minute
from
	premier_league_player_stats s
where
	minutes >= 1000
order by
	goals_per_minute desc
limit
	10
;


—- Finding Top Scorers per Position
—- Using a Common Table Expression (CTE) to find the top 3 goal scorers for each position

with goals_per_position as (
    select
          s.player_name
        , s.pos
        , s.goals
        ,row_number() over (partition by s.pos order by s.goals desc) as goal_rank
    from
        premier_league_player_stats s
)
select
      player_name
    , pos
    , goals
from
    goals_per_position
where
    goal_rank <= 3
order by
      pos
    , goal_rank
;

—- Filtering players with high discipline
—- Using a temp table to only show players with no more than 3 yellow cards or 1 red card and finding top 5 scorers from this group

create temp table disciplined_players as
select
      s.player_name
    , s.team
    , s.pos
    , s.goals
    , s.yellow_cards
    , s.red_cards
from
    premier_league_player_stats s
where
    yellow_cards <= 3 and red_cards = 1;

-- Querying the temp table to find the top 5 scorers
select
      player_name
    , team
    , pos
    , goals
from
    disciplined_players
order by
    goals desc
limit
	5
;

—- Creating View to store data for later visualizations

create view player_performance_view as
	with goals_per_minute_cte as (
    	select
        	  s.player_name
        	, s.team
        	, s.pos
        	, s.goals
        	, s.minutes
        	, (s.goals::float / s.minutes::float) as goals_per_minute
    from
        premier_league_player_stats s
    where
        minutes >= 500
)
	select
     	 p.player_name
    	, p.team
    	, p.pos
    	, p.age
    	, case
        	when p.age > 27 then 'Older Players'
        	else 'Younger Players'
    end as 
	 	  age_group
    	, ps90.goals_per_90
    	, ps90.assists_per_90
    	, (ps90.goals_per_90 + ps90.assists_per_90) as total_contributions_per_90
    	, s.yellow_cards
    	, s.red_cards
    	, gpm.goals_per_minute
	from
    	premier_league_player_stats s
join
    premier_league_players p on s.player_name = p.player_name
join
    premier_league_stats_per_90 ps90 on s.player_name = ps90.player_name
join
    goals_per_minute_cte gpm on s.player_name = gpm.player_name
;
