#ifndef STATS_H
#define STATS_H

#include "avl.h"

#define TOP_N 10
#define MAX_STATIONS 1000

typedef struct {
	double total_consumption;
	double total_capacity;
	int station_count;
	int max_stations;
	Station** all_stations;    // Tableau pour toutes les stations
	Station** top_stations;    // Top 10
	Station** bottom_stations; // Bottom 10
} StatsData;

// Déclarations des fonctions
StatsData* stats_create(void);
void stats_destroy(StatsData* stats);
void stats_compute(StatsData* stats, AVLNode* root);
void stats_write_to_file(const StatsData* stats, const char* base_filename);
void stats_write_minmax_file(const StatsData* stats, const char* filename);
void stats_print_summary(const StatsData* stats);

#endif