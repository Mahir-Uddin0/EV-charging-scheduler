# ⚡ EV Charging Scheduler – Constraint Programming Model (MiniZinc)

This project implements an Electric Vehicle (EV) charging scheduler using **MiniZinc**. It schedules EVs to available charging stations over time slots while minimizing the total travel distance. The model considers constraints like battery level, charging rate, station availability, power and plug capacities.

---

## 📋 Problem Statement

Given:
- A number of EVs with current battery levels and charging requirements.
- Charging stations with a fixed number of plugs and power capacity.
- Availability of stations at different time slots.
- Coordinates of both EVs and stations.

The model:
- Determines **which EV should charge at which station and at what time slot**.
- Ensures that no station exceeds its plug or power capacity.
- Minimizes the **total distance** traveled by EVs to charge.
- Ensures only EVs below a battery threshold are scheduled.
- Prefers **continuous** charging periods (no fragmentation).


