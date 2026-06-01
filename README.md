# Futsal Performance Analytics
### Real Match Data · PostgreSQL + PostGIS · Power BI

---

## Overview

End-to-end performance analytics system built on **real Futsal match data — self-logged during a live professional game** using a custom event coding system designed from scratch.

This is not a public dataset. Every row was recorded manually during an actual match.

---

## What Makes This Different

Most sports analytics projects download data from public APIs or Kaggle.

This project starts one step earlier — **designing how to capture the data in the first place**, then building the entire analysis pipeline on top of it.

---

## Dataset

| Property | Value |
|---|---|
| Total events logged | 599 |
| Players tracked | 9 |
| Match halves | 2 |
| Fields captured | 13 |
| Data source | Self-logged during live match |

### Event Coding System (Designed from scratch)

| Code | Event |
|---|---|
| PS | Pass Successful |
| PF | Pass Failed |
| SS | Shot On-Target |
| SF | Shot Off-Target |
| INT | Interception |
| LO | Lost Ball |
| SV | Save |
| G | Goal Scored |
| CON | Goal Conceded |

### Fields Captured Per Event

```
Match_id · Half · Display_Min · Display_Sec · Full_sec
Player_id · Reciever_id · Event_X · Event_Y
Reciever_X · Reciever_Y · Event_id · Pressure
```

`Event_X/Y` and `Reciever_X/Y` — spatial coordinates on the pitch for every action.
`Pressure` — whether the player was under defensive pressure at the moment of action.

---

## Analysis Modules

### 1. Performance Summary
- Total actions per player
- Goals, shots on target, successful passes, interceptions
- Events performed under pressure per player

### 2. Weakness Profiling
- Possession losses per player
- Pass failure rate per player
- Shots off target per player

### 3. Time-Based Analysis
- Game tempo — event frequency per minute window
- Mistake-to-shot chain — time between error and resulting shot (1–10 second window)
- Defensive transition timing using LEAD window function

### 4. Goal Involvement
- Goal scorer identification
- Assist and pre-assist tracking using LAG window functions

### 5. Spatial Zone Analysis
- Pitch divided into Attacking / Middle / Defending thirds
- Most active player per zone
- Zone distribution percentages across full match

### 6. Pass Distance & Progression
- Euclidean distance calculated per pass
- Progressive pass percentage — passes moving toward goal
- Pass lane geometry using PostGIS ST_MakeLine

### 7. Pressure Analysis
- Success rate under defensive pressure
- Pressure vs non-pressure performance comparison

### 8. AI Insight Generation
- Automated natural language match report
- Shot quality score based on distance from goal
- Pass fail rate classification
- Attacking volume assessment

---

## Tech Stack

| Category | Tool |
|---|---|
| Database | PostgreSQL |
| Spatial Extension | PostGIS |
| Query Language | SQL (CTEs, Window Functions, Views) |
| Visualization | Power BI |
| Spatial Analysis | ST_MakeLine, ST_Point, ST_SetSRID |
| Data Format | CSV / Excel |

---

## Key SQL Techniques Used

```sql
-- Window Functions
LAG(player_id, 1) OVER (ORDER BY full_sec) AS assist_player

-- CTEs
WITH recovery_diff AS (...)

-- PostGIS Spatial
ST_MakeLine(
    ST_SetSRID(ST_Point(event_x, event_y), 4326),
    ST_SetSRID(ST_Point(reciever_x, reciever_y), 4326)
) AS geom

-- Automated Insight Generation
'The team showed ' || volume_text || ', with ' || shot_text || '...'

-- Normalization
defence_zone * 100.0 / NULLIF(MAX(defence_zone) OVER(), 0) AS defence_norm
```

---

## Repository Structure

```
futsal_analysis/
│
├── data/
│   ├── raw/
│   │   └── futsal_data.csv          ← Original self-logged match data
│   └── processed/
│       └── (exported query outputs)
│
├── sql/
│   └── futsal_analysis.sql          ← Complete analysis queries
│
├── powerbi/
│   └── PB_futsal_analysis.pbix      ← Power BI dashboard file
│
├── assets/
│   └── (pass lane visualizations per player)
│
├── docs/
│   └── methodology.md               ← Data collection methodology
│
└── README.md
```

---

## Power BI Dashboard

Dashboard includes:
- Player radar charts (normalized across Defence / Midfield / Attack / Passing / Weakness)
- Pass lane visualizations per player
- Event distribution charts
- Pressure performance comparison
- Zone activity heatmap

---

## Methodology

Data was collected during a live professional Futsal match using a custom manual logging system. For each observable event:

1. Time was recorded (minute + second + full match second)
2. Player performing the action was identified by jersey number
3. Action type was coded using the event coding system
4. Pitch coordinates were estimated for event location and receiver location
5. Defensive pressure (Yes/No) was assessed at moment of action

This methodology captures spatial, temporal, and contextual data simultaneously — enabling analysis types not possible with standard event-only datasets.

---

## Author

**Om Narawade**
BSc Data Science — Savitribai Phule Pune University, Pune
[LinkedIn](https://www.linkedin.com/in/om-narawade-0a992a248)
