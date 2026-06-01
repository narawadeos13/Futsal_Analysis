# Data Collection Methodology

## Overview

This document describes how match data was collected for the Futsal Performance Analytics project.

---

## The Problem

Professional Futsal analytics tools either:
- Don't exist at grassroots level
- Are too expensive for local clubs
- Require dedicated tracking hardware

This project solves that by designing a manual logging system that captures enough spatial and contextual data to enable professional-grade analysis.

---

## Event Coding System

Each observable match event is assigned a two or three letter code:

| Code | Event | Spatial Data Captured |
|---|---|---|
| PS | Pass Successful | Event XY + Receiver XY |
| PF | Pass Failed | Event XY only |
| SS | Shot On-Target | Event XY only |
| SF | Shot Off-Target | Event XY only |
| INT | Interception | Event XY only |
| LO | Lost Ball | Event XY only |
| SV | Save | Event XY only |
| G | Goal Scored | Event XY only |
| CON | Goal Conceded | Event XY only |

---

## Fields Logged Per Event

| Field | Description |
|---|---|
| Match_id | Match identifier |
| Half | 1st or 2nd half |
| Display_Min | Countdown minute shown on clock |
| Display_Sec | Countdown second shown on clock |
| Full_sec | Elapsed seconds from match start |
| Player_id | Jersey number of acting player |
| Reciever_id | Jersey number of receiving player (passes only) |
| Event_X | X coordinate of event location on pitch |
| Event_Y | Y coordinate of event location on pitch |
| Reciever_X | X coordinate of receiver location (passes only) |
| Reciever_Y | Y coordinate of receiver location (passes only) |
| Event_id | Event code |
| Pressure | Whether player was under defensive pressure (Yes/No) |

---

## Pitch Coordinate System

The Futsal pitch was divided into a grid system for spatial logging:
- X axis runs along pitch length (0 to 40)
- Y axis runs along pitch width (0 to 25)
- Coordinates estimated visually during live logging

---

## Logging Process

1. Observer positioned with clear sightline to full pitch
2. Each event logged immediately as it occurred
3. Time recorded from match clock
4. Player identified by jersey number
5. Pitch location estimated on grid
6. Pressure assessed at moment of action

---

## Data Quality

- Events logged in real time — no post-match reconstruction
- Data rechecked after match for obvious errors
- Pass Failed reclassification: any PS event with null Receiver_id reclassified as PF
- Timestamp cross-referenced against match video where available

---

## Limitations

- Coordinate estimation introduces spatial error
- Single observer — some simultaneous events may be missed
- Pressure assessment is subjective
- Single match dataset — findings are match-specific

These limitations are acknowledged in the analysis and results are presented accordingly.
