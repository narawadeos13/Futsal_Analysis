CREATE TABLE futsal_raw_data(
Match_id INT,
Half INT,
Display_Min INT,
Display_Sec INT,
Full_sec INT,
Player_id VARCHAR(10),
Reciever_id FLOAT,
Event_X FLOAT,
Event_Y FLOAT,
Reciever_X FLOAT,
Reciever_Y FLOAT,
Event_id VARCHAR(50),
Pressure VARCHAR(50)
);
SELECT * FROM futsal_raw_data LIMIT 10;

ALTER TABLE futsal_raw_data
ADD COLUMN event_name TEXT;

UPDATE futsal_raw_data
SET event_name = 
CASE
 WHEN event_id = 'PS' THEN 'Pass Successful'
 WHEN event_id = 'PF' THEN 'Pass Failed'
 WHEN event_id = 'SS' THEN 'Shot On-target'
 WHEN event_id = 'SF' THEN 'Shot Off-target'
 WHEN event_id = 'INT' THEN 'Interception'
 WHEN event_id = 'LO' THEN 'Lost Ball'
 WHEN event_id = 'SV' THEN 'Save'
 WHEN event_id = 'G' THEN 'Goal Scored'
 WHEN event_id = 'CON' THEN 'Goal Conceded'
 ELSE event_id
END;
 
SELECT * FROM futsal_raw_data LIMIT 10;

--Data Re_checking
UPDATE futsal_raw_data
SET event_id = 'PF'
WHERE event_id = 'PS'
AND reciever_id IS NULL;

SELECT event_name, COUNT(*)
FROM futsal_raw_data
GROUP BY event_name
ORDER by COUNT(*) DESC;  

--Performace Based Analysis
--Performance Summary by each Player
SELECT 
	player_id,
	COUNT(*) AS Total_actions,
	SUM(CASE WHEN event_id = 'G' THEN 1 ELSE 0 END) AS goals,
	SUM(CASE WHEN event_id ='SS' THEN 1 ELSE 0 END) AS shot_on_target,
	SUM(CASE WHEN event_id = 'PS' THEN 1 ELSE 0 END) AS Pass_successful,
	SUM(CASE WHEN event_id ='INT'THEN 1 ELSE 0 END) AS interceptions,
	SUM(CASE WHEN pressure = 'Yes' THEN 1 ELSE 0 END) AS events_under_pressure
FROM futsal_raw_data
GROUP BY player_id
ORDER BY events_under_pressure DESC;

--Weakness of each Players
SELECT
	Player_id,
	SUM(CASE WHEN event_id ='LO' THEN 1 ELSE 0 END) AS possesion_loss,
	SUM(CASE WHEN event_id ='PF' THEN 1 ELSE 0 END) AS pass_failed,
	SUM(CASE WHEN event_id ='SF' THEN 1 ELSE 0 END) AS shot_off_target
FROM futsal_raw_data
GROUP BY player_id;	


--Time Based Analysis
--Game Tempo
SELECT
	(full_sec/60) AS minute_window,
	COUNT(event_id) AS event_count
FROM futsal_raw_data
GROUP BY minute_window
ORDER BY minute_window ASC;

--Mistakes to lead shot
SELECT
	a.player_id AS mistake_maker,
	a.event_id AS mistake_type,
	b.event_id AS result_shot,
	(b.full_sec - a.full_sec) AS seconds_to_shot
FROM futsal_raw_data a
JOIN futsal_raw_data b ON a.match_id = b.match_id
WHERE a.event_id IN ('LO','PF')
	AND b.event_id IN ('SV','CON')
	AND(b.full_sec - a.full_sec) BETWEEN 1 AND 10;

--Goal Involvment
SELECT 
	event_id,
	player_id,
	event_name,
	full_sec,
	LAG(player_id,1) OVER (ORDER BY full_sec) AS assist_player,
	LAG(player_id,2) OVER (ORDER BY full_sec) AS pre_assist_player
FROM futsal_raw_data
WHERE event_id = 'G';

--Defencive Transition
WITH recovery_diff AS (
	SELECT
		player_id,
		event_id,
		full_sec,
		LEAD(full_sec) OVER (ORDER BY full_sec) - full_sec AS time_to_next_event,
		LEAD(event_id) OVER (ORDER BY full_sec) AS next_event
	FROM futsal_raw_data
)
SELECT * FROM recovery_diff
WHERE event_id = 'LO' AND next_event = 'INT';

--Zonal/Spatial Based Analysis
--zones creating
CREATE VIEW match_analysis_zones AS
SELECT
	*,
	CASE 
		WHEN "event_x" <= 14 THEN 'Attacking'
		WHEN "event_x" >14 AND "event_x" <= 28 THEN 'Middle'
		ELSE 'Defending'
	END AS pitch_zone
FROM futsal_raw_data;
SELECT * FROM match_analysis_zones;

--Most Active Player in Attacking Third
SELECT player_id, COUNT(*)
FROM match_analysis_zones
WHERE pitch_zone ='Attacking'
GROUP BY player_id;

--Zonal analysis
SELECT 
	pitch_zone,
	event_count,
	ROUND((event_count*100)/SUM(event_count)OVER(),2) AS percentage
FROM(
	SELECT
		pitch_zone,
		COUNT(*) AS event_count
	FROM match_analysis_zones		
	GROUP BY pitch_zone
)sub
ORDER BY event_count DESC;

--Distance and Progression
SELECT
	player_id,
	event_id,
	ROUND(
		SQRT(
			POWER(reciever_x - event_x,2) +
			POWER(reciever_y - event_y,2)
		)
	)AS pass_distance_ft
FROM futsal_raw_data
WHERE event_id ='PS'
AND reciever_x IS NOT NULL
ORDER BY player_id ASC;

--Presssure analysis
WITH counts AS(
	SELECT 
		COUNT(*) FILTER (WHERE event_id IN ('PS','INT')) AS success,
		COUNT(*) FILTER (WHERE event_id IN ('PS','INT','PF','LO')) AS total_actions
	FROM futsal_raw_data
	WHERE pressure = 'Yes'
)
SELECT success,
total_actions,
((success/total_actions)*100.0) AS pressure_success_rate_pct
FROM counts;

--Spatial Analysis
CREATE EXTENSION postgis;

SELECT PostGIS_Full_Version();
--Passing lanes
CREATE TABLE pass_lines AS
SELECT 
	player_id,
	reciever_id,
	COUNT(*) AS pass_count,
	ST_MakeLine(
		ST_SetSRID(ST_Point(event_x,event_y),4326),
		ST_SetSRID(ST_Point(reciever_x,reciever_y),4326)
	)AS geom
FROM futsal_raw_data
WHERE event_id = 'PS'
GROUP BY player_id, reciever_id,event_x,event_y,
reciever_x,reciever_y;
SELECT * FROM pass_lines;

--Power Bi ready Charts
--player radar chart
CREATE VIEW player_profile AS
SELECT 
	player_id,
	COUNT(*) FILTER(WHERE pitch_zone = 'Defending')AS defence_zone,
	COUNT(*) FILTER(WHERE pitch_zone = 'Attacking')AS attack_zone,
	COUNT(*) FILTER(WHERE pitch_zone = 'Middle')AS middle_zone,
	COUNT(*) FILTER(WHERE event_id = 'PS') AS passing_score,
	COUNT(*) FILTER(WHERE event_id IN ('PF','LO')) AS weakness_score

FROM match_analysis_zones
GROUP BY player_id;
SELECT * FROM player_profile;

--Normalization
SELECT
*,
	defence_zone*100.0/MAX(defence_zone)OVER() AS defence_norm,
	attack_zone*100.0/MAX(attack_zone)OVER() AS attack_norm,
	middle_zone*100.0/MAX(middle_zone)OVER() AS middle_norm,
	passing_score*100.0/MAX(passing_score)OVER() AS passing_norm,
	weakness_score*100.0/MAX(weakness_score)OVER() AS weakness_norm
FROM player_profile;

--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW player_profile_norm AS
SELECT 
    player_id,

    defence_zone * 100.0 / NULLIF(MAX(defence_zone) OVER(),0) AS defence_norm,
    midfield_zone * 100.0 / NULLIF(MAX(midfield_zone) OVER(),0) AS midfield_norm,
    attack_zone * 100.0 / NULLIF(MAX(attack_zone) OVER(),0) AS attack_norm,
    passing_score * 100.0 / NULLIF(MAX(passing_score) OVER(),0) AS passing_norm,
    weakness_score * 100.0 / NULLIF(MAX(weakness_score) OVER(),0) AS weakness_norm

FROM (
    SELECT 
        player_id,

        COUNT(*) FILTER (WHERE pitch_zone = 'Defending') AS defence_zone,
        COUNT(*) FILTER (WHERE pitch_zone = 'Middle') AS midfield_zone,
        COUNT(*) FILTER (WHERE pitch_zone = 'Attacking') AS attack_zone,

        COUNT(*) FILTER (WHERE event_id = 'PS') AS passing_score,
        COUNT(*) FILTER (WHERE event_id IN ('PF','LO',)) AS weakness_score

    FROM match_analysis_zones
    GROUP BY player_id
) base;

CREATE OR REPLACE VIEW player_radar AS
SELECT player_id, 'Defence' AS category, defence_norm AS value FROM player_profile_norm
UNION ALL
SELECT player_id, 'Midfield', midfield_norm FROM player_profile_norm
UNION ALL
SELECT player_id, 'Attack', attack_norm FROM player_profile_norm
UNION ALL
SELECT player_id, 'Passing', passing_norm FROM player_profile_norm
UNION ALL
SELECT player_id, 'Weakness', weakness_norm FROM player_profile_norm;
SELECT * FROM player_radar;

--
CREATE OR REPLACE VIEW player_img AS	
SELECT 
	player_id,
	CASE 
		WHEN player_id = '1' THEN 'https://github.com/narawadeos13/futsal_analysis/blob/main/P_1_pass_lane.png?raw=true'
		WHEN player_id = '10' THEN 'https://github.com/narawadeos13/futsal_analysis/blob/main/P_10_pass_lane.png?raw=true'
		WHEN player_id = '8' THEN 'https://github.com/narawadeos13/futsal_analysis/blob/main/P_8_pass_lane.png?raw=true'
		WHEN player_id = '4' THEN 'https://github.com/narawadeos13/futsal_analysis/blob/main/P_4_pass_lane.png?raw=true'
		WHEN player_id = '16' THEN 'https://github.com/narawadeos13/futsal_analysis/blob/main/P_16_pass_lane.png?raw=true'
		WHEN player_id = '18' THEN 'https://github.com/narawadeos13/futsal_analysis/blob/main/P_18_pass_lane.png?raw=true'
	END AS img_url
FROM futsal_raw_data
WHERE player_id IN ('1','10','4','8','16','18')
GROUP BY player_id;
SELECT * FROM player_img;
----------------------------------------------------------------------------------
--insights tables
--ai insights
CREATE OR REPLACE VIEW match_basic_stat AS
SELECT 
--shot quality 
	AVG(
		CASE
			WHEN event_id IN ('SS','SF') THEN 
			1-(
			SQRT(POWER(event_x - 0,2) + POWER(event_y - 12.5,2))/42
			)
		END
	) AS avg_shot_quality,
--progressive passing
	COUNT(*) FILTER (
		WHERE event_id = 'PS' AND reciever_x < event_x
	)::float
	/ NULLIF(COUNT(*) FILTER(WHERE event_id = 'PS'),0)
	AS progressive_pass_pct,
--total shots
	COUNT(*) FILTER(WHERE event_id IN ('SS','SF')) AS total_shots,
--failed pass rate 
	COUNT(*) FILTER (WHERE event_id ='PF')::float
	/ NULLIF(COUNT(*) FILTER (WHERE event_id IN ('PS','PF')),0)
	AS pass_fail_pct
FROM futsal_raw_data;
SELECT * FROM match_basic_stat;

CREATE OR REPLACE VIEW match_ai_report AS
SELECT 

	CASE 
		WHEN avg_shot_quality < 0.5 THEN 
		'low-quality shooting'
		ELSE
		'good shot selection'
	END AS shot_text,
	CASE
		WHEN progressive_pass_pct < 0.5 THEN 
		'limited progressive passing'
		ELSE
		'strong forward passing'
	END AS pass_text,
	CASE 
		WHEN pass_fail_pct > 0.3 THEN
		'high passing error'
		ElSE
		'controlled passing'
	END AS error_text,
	CASE 
		WHEN total_shots < 40 THEN
		'low attacking volume'
		ELSE 
		'high attacking volume'
	END AS volume_text
FROM match_basic_stat;

CREATE OR REPLACE VIEW match_final_insight AS
SELECT

	'The team showed '
	||volume_text||', with '
	||shot_text|| ' and '
	||pass_text||'. Additionally, '
	||error_text||' influenced overall performance.'
	AS final_insight
FROM match_ai_report;
SELECT * FROM match_final_insight;

CREATE OR REPLACE VIEW event_insights AS
SELECT * FROM(
	VALUES 
	('Goal Conceded','Goals conceded were primarily due to defensive errors 
	and counter-attacks, particularly from defensive zone')
	('Goal Scored','Goals were scored from close-range situations with
	quick execution immediaetly following passing sequences')
	('Interception','A high number of interceptions indicates strong defensive positioning, 
	but limited ball retention reduced overall control')
	('Lost Ball','Most ball losses occurred in low-risk areas;
	however, losses in key defensive zones led to counter-attacks and conceded goals')
	('Pass Failed','Passing was widely distributed across the pitch, indicating high involvement, 
	but defensive stability on the left side remained weak')
	('Save','The goalkeeper demonstrated a high save rate with crucial interventions, 
	though occasional errors contributed to conceded goals')
	('Shot of')
)