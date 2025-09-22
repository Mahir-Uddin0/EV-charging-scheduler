# ⚡ EV Charging Scheduler – Constraint Programming Model (MiniZinc)

This project implements an Electric Vehicle (EV) charging scheduler using **MiniZinc**. It schedules EVs to available charging stations over time slots while minimizing the total travel distance. The model considers constraints like battery level, charging rate, station availability, power and plug capacities.
## Introduction
As the adoption of Electric Vehicles (EVs) increases globally, efficient charging management has become a major challenge. EVs need to be charged at appropriate times and locations while ensuring that charging stations are not overloaded. Traditional manual or first-come-first-serve scheduling is not sufficient for large-scale operations such as ride-sharing fleets, logistics companies, or smart city infrastructures.  

To address this, automated AI-driven scheduling systems are required. These systems must account for real-world constraints like limited charging plugs, varying power capacities, and fluctuating battery levels of EVs. Moreover, optimizing charging schedules can reduce energy costs, minimize vehicle downtime, and extend battery health.  

This project presents a **constraint programming approach** using **MiniZinc** to solve the EV charging scheduling problem. By modeling vehicles, stations, and charging slots as decision variables, the system automatically generates an optimized charging plan.

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

---

## 📥 Inputs

All input values are defined in a separate `.dzn` data file. Example variables:

### 🚗 EV Parameters

| Variable           | Type                     | Description                                               |
|--------------------|--------------------------|-----------------------------------------------------------|
| `n_vehicles`       | `int`                    | Number of EVs                                             |
| `battery_level`    | `array[int]`             | Current battery levels in percentage                      |
| `battery_capacity` | `array[int]`             | Full battery capacities in kWh                            |
| `charging_rate`    | `array[int]`             | Charging rate per time slot (in kWh)                      |
| `min_threshold`    | `int`                    | Threshold battery level under which EVs must be charged   |
| `vehicle_x`, `vehicle_y` | `array[int]`       | Coordinates of each EV                                    |

### 🔌 Station Parameters

| Variable           | Type                     | Description                                               |
|--------------------|--------------------------|-----------------------------------------------------------|
| `n_stations`       | `int`                    | Number of charging stations                               |
| `slot_capacity`    | `array[int]`             | Number of plugs per station                               |
| `power_capacity`   | `array[int]`             | Max power per time slot per station (kWh)                 |
| `station_x`, `station_y` | `array[int]`       | Coordinates of each station                               |
| `available_slots`  | `array[station, timeslot] of bool` | Availability of stations over time                       |

### 🕐 Time Parameters

| Variable         | Type     | Description                        |
|------------------|----------|------------------------------------|
| `n_timeslots`    | `int`    | Number of time slots available     |

---

## 📊 Decision Variable

```minizinc
array[1..n_vehicles, 1..n_stations, 1..n_timeslots] of var 0..1: assign;
```
## Derived Values
- needs_charge
- demand
- distance

---

## 🔒 Constraints
- Vehicles that do not need charging are not assigned.  
- A vehicle’s total received charge must meet or exceed its demand.  
- Total charging rate per station per time slot ≤ station power capacity.  
- Number of vehicles per station per time slot ≤ slot capacity.  
- If a station is unavailable in a time slot, no vehicles are assigned.  
- A vehicle can only be assigned to one station per time slot.  
- Charging continuity: once a vehicle starts charging, it continues in subsequent slots.  

---

## 🎯 Objective
The primary objective is to **minimize the total charging time and maximize station utilization**, while ensuring all constraints are satisfied.  

---

## 📥 Example Input (Playground.dzn)

```minizinc
n_vehicles = 15;
n_stations = 5;
n_timeslots = 6;

battery_level = [20, 35, 28, 45, 25, 15, 60, 30, 18, 33, 50, 22, 29, 40, 31];
battery_capacity = [50, 60, 55, 50, 65, 70, 60, 55, 50, 60, 50, 70, 55, 65, 60];
charging_rate = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
min_threshold = 30;

vehicle_x = [2, 4, 5, 3, 6, 1, 7, 3, 6, 4, 8, 2, 5, 7, 3];
vehicle_y = [1, 2, 3, 1, 4, 3, 2, 5, 2, 6, 1, 4, 5, 3, 2];

station_x = [2, 6, 4, 7, 3];
station_y = [5, 2, 1, 4, 3];

power_capacity = [40, 50, 35, 60, 45];
slot_capacity = [2, 4, 3, 5, 3];

available_slots = array2d(1..5, 1..6,
[
  true,  true,  true,  true,  false, false,   % Station 1
  true,  true,  true,  true,  true,  true,    % Station 2
  true,  false, true,  true,  false, true,    % Station 3
  true,  true,  true,  true,  true,  true,    % Station 4
  true,  true,  false, true,  true,  false    % Station 5
]);
```

## Example Output


EV Charging Schedule (Tabular Format):
---------------------------------------
Vehicle		| Status		| Station	| Time Slot(s)
--------	|-----------------------|---------------|----------------
Vehicle 1	| Charging Required	| Station 4	| Slot 3-6
Vehicle 2	| Sufficient Battery	| N/A		| N/A
Vehicle 3	| Charging Required	| Station 4	| Slot 3-6
Vehicle 4	| Sufficient Battery	| N/A		| N/A
Vehicle 5	| Charging Required	| Station 4	| Slot 2-6
Vehicle 6	| Charging Required	| Station 2	| Slot 1-6
Vehicle 7	| Sufficient Battery	| N/A		| N/A
Vehicle 8	| Sufficient Battery	| N/A		| N/A
Vehicle 9	| Charging Required	| Station 2	| Slot 2-6
Vehicle 10	| Sufficient Battery	| N/A		| N/A
Vehicle 11	| Sufficient Battery	| N/A		| N/A
Vehicle 12	| Charging Required	| Station 2	| Slot 1-6
Vehicle 13	| Charging Required	| Station 2	| Slot 3-6
Vehicle 14	| Sufficient Battery	| N/A		| N/A
Vehicle 15	| Sufficient Battery	| N/A		| N/A
----------

