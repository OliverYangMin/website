website
# Airline-Disruption-Management
The code of WSDM 2019 Cup

## Classes 
- substantial
### Airport
- airport capacity
- A slot is a period of time within which maximum departures and arrivals are specified. Note that airport closures are modeled as airport slots with zero capacity

### Aircraft
1. Start available time
2. End available time
3. Start available airport
4. End available airport

### Flight
1. departure airport
2. arrival airport
3. duration

### Routes
- airport match, time match and aircraft match

- virtual
### Master

### Label

### Delta


## routine
1. get data for flights, airports and aircrafts,   disruption information
2. for each aircraft, build itself graph and toposort
3. form initial route for each aircraft   -- cancel all disrupted flights
4. solve master 
5. get duals and set duals
6. solve subproblem
7. label extends 
8. dominant
9. cost calculate
10. return route

## Todo
1. formate initial routes for aircraft
2. rewrite master class
