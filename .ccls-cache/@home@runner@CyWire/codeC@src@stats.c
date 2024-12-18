#include "../include/stats.h"
#include "../include/avl.h"
#include "../include/station.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define OUTPUT_DELIMITER ':'

static void ensure_capacity(StatsData *stats) {
  if (stats->station_count >= stats->station_alloc) {
    int new_size = stats->station_alloc * 2;
    if (new_size == 0)
      new_size = 1024;
    Station **new_array =
        realloc(stats->all_stations, new_size * sizeof(Station *));
    if (!new_array) {
      fprintf(stderr,
              "Erreur : Réallocation du tableau de stations impossible.\n");
      exit(2); // Erreur mémoire
    }
    stats->all_stations = new_array;
    stats->station_alloc = new_size;
  }
}

static void process_node_for_stats(Station *station, void *userdata) {
  StatsData *stats = (StatsData *)userdata;
  if (!stats || !station)
    return;

  ensure_capacity(stats);
  stats->all_stations[stats->station_count] = station;
  stats->total_consumption += station->consumption;
  stats->total_capacity += station->capacity;
  stats->station_count++;
}

static int station_compare_qsort(const void *a, const void *b) {
  Station *s1 = *(Station **)a;
  Station *s2 = *(Station **)b;
  return station_compare(s1, s2);
}

static int station_compare_by_diff(const void *a, const void *b) {
  Station *s1 = *(Station **)a;
  Station *s2 = *(Station **)b;
  double diff1 = s1->capacity - s1->consumption;
  double diff2 = s2->capacity - s2->consumption;
  if (diff1 < diff2)
    return -1;
  if (diff1 > diff2)
    return 1;
  return 0;
}

StatsData *stats_create(const char *station_type, const char *consumer_type) {
  StatsData *stats = (StatsData *)malloc(sizeof(StatsData));
  if (!stats)
    return NULL;

  stats->total_consumption = 0.0;
  stats->total_capacity = 0.0;
  stats->station_count = 0;
  stats->station_alloc = 0;
  stats->all_stations = NULL;
  strncpy(stats->station_type, station_type, sizeof(stats->station_type) - 1);
  stats->station_type[sizeof(stats->station_type) - 1] = '\0';
  strncpy(stats->consumer_type, consumer_type,
          sizeof(stats->consumer_type) - 1);
  stats->consumer_type[sizeof(stats->consumer_type) - 1] = '\0';

  return stats;
}

void stats_destroy(StatsData *stats) {
  if (stats) {
    free(stats->all_stations);
    free(stats);
  }
}

void stats_compute(StatsData *stats, AVLNode *root) {
  if (!stats || !root)
    return;

  stats->total_consumption = 0.0;
  stats->total_capacity = 0.0;
  stats->station_count = 0;

  avl_inorder(root, process_node_for_stats, stats);

  // Tri par capacité
  qsort(stats->all_stations, stats->station_count, sizeof(Station *),
        station_compare_qsort);
}

void build_header_line(const StatsData *stats, char *header, size_t len) {
  // Selon l'énoncé, l'entête doit être strictement :
  // hvb comp => "Station HVB:Capacité:Consommation (entreprises)"
  // hva comp => "Station HVA:Capacité:Consommation (entreprises)"
  // lv comp  => "Station LV:Capacité:Consommation (entreprises)"
  // lv indiv => "Station LV:Capacité:Consommation (particuliers)"
  // lv all   => "Station LV:Capacité:Consommation (tous)"

  if (strcmp(stats->station_type, "hvb") == 0 &&
      strcmp(stats->consumer_type, "comp") == 0) {
    snprintf(header, len, "Station HVB:Capacité:Consommation (entreprises)");
  } else if (strcmp(stats->station_type, "hva") == 0 &&
             strcmp(stats->consumer_type, "comp") == 0) {
    snprintf(header, len, "Station HVA:Capacité:Consommation (entreprises)");
  } else if (strcmp(stats->station_type, "lv") == 0 &&
             strcmp(stats->consumer_type, "comp") == 0) {
    snprintf(header, len, "Station LV:Capacité:Consommation (entreprises)");
  } else if (strcmp(stats->station_type, "lv") == 0 &&
             strcmp(stats->consumer_type, "indiv") == 0) {
    snprintf(header, len, "Station LV:Capacité:Consommation (particuliers)");
  } else if (strcmp(stats->station_type, "lv") == 0 &&
             strcmp(stats->consumer_type, "all") == 0) {
    snprintf(header, len, "Station LV:Capacité:Consommation (tous)");
  } else {
    // Cas non prévu par l'énoncé, on met un entête par défaut
    // (idéalement, on devrait gérer cela plus strictement,
    //  mais par sécurité on évite un crash)
    snprintf(header, len, "Station:Capacité:Consommation");
  }
}

void stats_write_to_file(const StatsData *stats, const char *output_file) {
  if (!stats || !output_file)
    return;

  FILE *file = fopen(output_file, "w");
  if (!file) {
    fprintf(stderr, "Erreur: Impossible de créer le fichier %s\n", output_file);
    return;
  }

  char header_line[256];
  build_header_line(stats, header_line, sizeof(header_line));
  fprintf(file, "%s\n", header_line);

  for (int i = 0; i < stats->station_count; i++) {
    Station *s = stats->all_stations[i];
    fprintf(file, "%s%c%.2f%c%.2f\n", s->id, OUTPUT_DELIMITER, s->capacity,
            OUTPUT_DELIMITER, s->consumption);
  }

  fclose(file);
}

void stats_write_minmax_file(const StatsData *stats, const char *filename) {
  // Cette fonction est appelée seulement si station_type=lv et
  // consumer_type=all On doit prendre toutes les stations, les trier par
  // (capacity - consumption) Puis prendre les 10 premières et 10 dernières
  if (!stats || !filename)
    return;

  if (stats->station_count == 0) {
    // Aucun enregistrement
    FILE *f = fopen(filename, "w");
    if (f) {
      fprintf(f, "Station:Capacité:Consommation:Diff\n");
      fclose(f);
    }
    return;
  }

  Station **sorted_by_diff = malloc(stats->station_count * sizeof(Station *));
  if (!sorted_by_diff) {
    fprintf(stderr, "Erreur d'allocation pour minmax.\n");
    return;
  }

  memcpy(sorted_by_diff, stats->all_stations,
         stats->station_count * sizeof(Station *));
  qsort(sorted_by_diff, stats->station_count, sizeof(Station *),
        station_compare_by_diff);

  FILE *f = fopen(filename, "w");
  if (!f) {
    fprintf(stderr, "Erreur: Impossible de créer le fichier %s\n", filename);
    free(sorted_by_diff);
    return;
  }

  fprintf(f,
          "Station:Capacité:Consommation:Difference(Capacity-Consumption)\n");

  int count = stats->station_count;
  int top_count = (count < TOP_N) ? count : TOP_N;
  // 10 plus faibles diff (en tête)
  for (int i = 0; i < top_count; i++) {
    Station *s = sorted_by_diff[i];
    double diff = s->capacity - s->consumption;
    fprintf(f, "%s:%.2f:%.2f:%.2f\n", s->id, s->capacity, s->consumption, diff);
  }

  // 10 plus forts diff (en queue)
  if (count > TOP_N) {
    int start = (count - TOP_N < top_count) ? top_count : count - TOP_N;
    for (int i = start; i < count; i++) {
      Station *s = sorted_by_diff[i];
      double diff = s->capacity - s->consumption;
      fprintf(f, "%s:%.2f:%.2f:%.2f\n", s->id, s->capacity, s->consumption,
              diff);
    }
  }

  fclose(f);
  free(sorted_by_diff);
}

void stats_print_summary(const StatsData *stats) {
  if (!stats)
    return;

  printf("\nRésumé des statistiques:\n");
  printf("Nombre de stations: %d\n", stats->station_count);
  printf("Capacité totale: %.2f kWh\n", stats->total_capacity);
  printf("Consommation totale: %.2f kWh\n", stats->total_consumption);
  if (stats->total_capacity > 0) {
    printf("Taux d'utilisation: %.2f%%\n",
           (stats->total_consumption / stats->total_capacity) * 100.0);
  }
}
