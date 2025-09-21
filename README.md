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

battery_level = [40, 80, 30, 90, 50, 20, 95, 85, 35, 100, 75, 25, 60, 88, 92];
battery_capacity = [100,100,100,100,100,100,100,100,100,100,100,100,100,100,100];
charging_rate = [10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];

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
