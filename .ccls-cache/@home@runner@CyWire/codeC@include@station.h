#ifndef STATION_H
#define STATION_H

typedef struct {
	char *id;           // Identifiant de la station
	double capacity;    // Capacité en kWh
	double consumption; // Consommation en kWh
} Station;

// Fonctions de gestion des stations
Station* station_create(const char* id, double capacity, double consumption);
void station_destroy(Station* station);
int station_compare(const Station* s1, const Station* s2);
void station_print(const Station* station);

#endif
