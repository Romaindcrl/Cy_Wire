#ifndef STATS_H
#define STATS_H

#include "avl.h"

#define TOP_N 10

typedef struct {
  double total_consumption;
  double total_capacity;
  int station_count;
  int station_alloc;

  Station **all_stations; // Tableau dynamique pour toutes les stations

  char station_type[8];  // hvb, hva, lv
  char consumer_type[8]; // comp, indiv, all
} StatsData;

// Déclarations des fonctions
StatsData *stats_create(const char *station_type, const char *consumer_type);
void stats_destroy(StatsData *stats);
void stats_compute(StatsData *stats, AVLNode *root);
void stats_write_to_file(const StatsData *stats, const char *base_filename);
void stats_write_minmax_file(const StatsData *stats, const char *filename);
void stats_print_summary(const StatsData *stats);

#endif
