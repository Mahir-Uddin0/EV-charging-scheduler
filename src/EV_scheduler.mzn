% ================================
% EV Charging Scheduler
% ================================

% --------- Inputs ---------
int: n_vehicles;  % No. of vehicles
int: n_stations;  % No. of stations
int: n_timeslots; % No. of timeslots

array[1..n_vehicles] of int: battery_level;     % Battery level in percentage of each vehicle
array[1..n_vehicles] of int: battery_capacity;  % Battery capacity in KWh of each vehicle
int: min_threshold;                             % Battery percentage threshold below which vehicle needs charging
array[1..n_vehicles] of int: charging_rate;     % Charging rate in KWh per timeslot
array[1..n_stations] of int: power_capacity;    % Maximum total energy in kWh that a station can deliver to all EVs per time slot.
array[1..n_stations] of int: slot_capacity;     % Maximum number of EVs that can simultaneously plug in at a station in a given time slot.
array[1..n_stations, 1..n_timeslots] of bool: available_slots;  % % Availability of each station at each time slot (true = available, false = unavailable)

array[1..n_vehicles] of int: vehicle_x;         % X coordinates of each vehicle
array[1..n_vehicles] of int: vehicle_y;         % Y coordinates of each vehicle
array[1..n_stations] of int: station_x;         % X coordinates of each station
array[1..n_stations] of int: station_y;         % Y coordinates of each station

% --------- Derived Distance Matrix ---------
% Calculates each vehicle distance with each station
array[1..n_vehicles, 1..n_stations] of int: distance =
  array2d(1..n_vehicles, 1..n_stations, [ abs(vehicle_x[v] - station_x[s]) + abs(vehicle_y[v] - station_y[s]) | v in 1..n_vehicles, s in 1..n_stations ]);

% --------- Derived Values ---------
% Give true value to vehicles which needs charge and false to those who don't
array[1..n_vehicles] of bool: needs_charge =
  [ battery_level[v] < min_threshold | v in 1..n_vehicles ];

% Calculates charge demands of vehicles in KW if their battery is below min threshold
array[1..n_vehicles] of int: demand =
  [ if battery_level[v] < min_threshold then
      battery_capacity[v] * (100 - battery_level[v]) div 100
    else 0
  endif
  | v in 1..n_vehicles ];

% --------- Decision Variable ---------
% The model will solve this 3d matrix where it tells whose vehicle to charge at which station in which time slot
array[1..n_vehicles, 1..n_stations, 1..n_timeslots] of var 0..1: assign;

% --------- Constraints ---------

% The vehicles which don't need charging will be assigned 0 in the assign matrix.
constraint forall(v in 1..n_vehicles, s in 1..n_stations, t in 1..n_timeslots) (not needs_charge[v] -> assign[v,s,t] = 0);

% This constraint ensures that the total charge a vehicle receives from the assigned stations & time slots will be at least equal to the demand
constraint forall(v in 1..n_vehicles where needs_charge[v]) 
                 ( sum(s in 1..n_stations, t in 1..n_timeslots)(assign[v,s,t] * charging_rate[v]) >= demand[v] );

% A charging station fixed charging power capacity at a given time slot. In a given station, in a given time slot, the total charging rate in KW,
% for a station should not exceed the station's power capacity.
constraint forall(s in 1..n_stations, t in 1..n_timeslots) 
                 ( sum(v in 1..n_vehicles)(assign[v,s,t] * charging_rate[v]) <= power_capacity[s] );

% In a given time slot, the total number of vehicles getting charged in a particular station should not exceed its slot capacity.
constraint forall(s in 1..n_stations, t in 1..n_timeslots)
                 ( sum(v in 1..n_vehicles)(assign[v,s,t]) <= slot_capacity[s] );

% If a station in a given time slot doesn't have available slots, then no EV should be scheduled to charge at that station and time.
constraint forall(v in 1..n_vehicles, s in 1..n_stations, t in 1..n_timeslots) 
                 (not available_slots[s,t] -> assign[v,s,t] = 0);

% A vehicle in a given time slot can only be assigned to only one station.
constraint forall(v in 1..n_vehicles, t in 1..n_timeslots)
                 ( sum(s in 1..n_stations)(assign[v,s,t]) <= 1 );

% If a vehicle starts charging at a station in time slot t, it should continue charging in t+1.
constraint forall(v in 1..n_vehicles, s in 1..n_stations)
                 ( forall(t in 1..n_timeslots-1) (assign[v,s,t+1] >= assign[v,s,t]) );

% --------- Objective ---------
var int: total_distance = sum(v in 1..n_vehicles, s in 1..n_stations, t in 1..n_timeslots) (assign[v,s,t] * distance[v,s]);

solve minimize total_distance;

% --------- Output ---------
output [
  "EV Charging Schedule (Tabular Format):\n",
  "---------------------------------------\n",
  "Vehicle\t\t| Status\t\t| Station\t| Time Slot(s)\n",
  "--------\t|-----------------------|---------------|----------------\n"
] ++
[
  let {
    set of int: active_slots = {t | s in 1..n_stations, t in 1..n_timeslots where fix(assign[v,s,t]) = 1},
    int: start_slot = if card(active_slots) > 0 then min(active_slots) else 0 endif,
    int: end_slot   = if card(active_slots) > 0 then max(active_slots) else 0 endif,
    int: station = if start_slot > 0 then sum(s in 1..n_stations where fix(assign[v,s,start_slot]) = 1)(s) else 0 endif
  } in
  if needs_charge[v] then
    "Vehicle \(v)\t| Charging Required\t| Station \(station)\t| Slot \(start_slot)-\(end_slot)\n"
  else
    "Vehicle \(v)\t| Sufficient Battery\t| N/A\t\t| N/A\n"
  endif
  | v in 1..n_vehicles
];


