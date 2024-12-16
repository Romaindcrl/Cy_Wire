#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "stats.h"
#include "station.h"
#include "avl.h"

#define OUTPUT_DELIMITER ':'

static void process_node_for_stats(Station* station, void* userdata) {
    StatsData* stats = (StatsData*)userdata;
    if (!stats || !station) return;

    if (stats->station_count < stats->max_stations) {
        stats->all_stations[stats->station_count] = station;
        stats->total_consumption += station->consumption;
        stats->total_capacity += station->capacity;
        stats->station_count++;
    }
}

static int station_compare_qsort(const void* a, const void* b) {
    Station* s1 = *(Station**)a;
    Station* s2 = *(Station**)b;
    return station_compare(s1, s2);
}

StatsData* stats_create(void) {
    StatsData* stats = (StatsData*)malloc(sizeof(StatsData));
    if (!stats) return NULL;

    stats->total_consumption = 0.0;
    stats->total_capacity = 0.0;
    stats->station_count = 0;
    stats->max_stations = MAX_STATIONS;
    stats->all_stations = (Station**)calloc(MAX_STATIONS, sizeof(Station*));
    if (!stats->all_stations) {
        free(stats);
        return NULL;
    }

    return stats;
}

void stats_destroy(StatsData* stats) {
    if (stats) {
        free(stats->all_stations);
        free(stats);
    }
}

void stats_compute(StatsData* stats, AVLNode* root) {
    if (!stats || !root) return;

    stats->total_consumption = 0.0;
    stats->total_capacity = 0.0;
    stats->station_count = 0;
    memset(stats->all_stations, 0, stats->max_stations * sizeof(Station*));

    avl_inorder(root, process_node_for_stats, stats);

    // Tri par capacité
    qsort(stats->all_stations, stats->station_count, sizeof(Station*), station_compare_qsort);
}

void stats_write_to_file(const StatsData* stats, const char* output_file) {
    if (!stats || !output_file) return;

    FILE* file = fopen(output_file, "w");
    if (!file) {
        fprintf(stderr, "Erreur: Impossible de créer le fichier %s\n", output_file);
        return;
    }

    fprintf(file, "Station%cCapacité%cConsommation\n", OUTPUT_DELIMITER, OUTPUT_DELIMITER);
    for (int i = 0; i < stats->station_count; i++) {
        Station* s = stats->all_stations[i];
        fprintf(file, "%s%c%.2f%c%.2f\n", s->id, OUTPUT_DELIMITER, s->capacity, OUTPUT_DELIMITER, s->consumption);
    }

    fclose(file);
}

void stats_print_summary(const StatsData* stats) {
    if (!stats) return;

    printf("\nRésumé des statistiques:\n");
    printf("Nombre de stations: %d\n", stats->station_count);
    printf("Capacité totale: %.2f kWh\n", stats->total_capacity);
    printf("Consommation totale: %.2f kWh\n", stats->total_consumption);
    if (stats->total_capacity > 0) {
        printf("Taux d'utilisation: %.2f%%\n", (stats->total_consumption / stats->total_capacity) * 100.0);
    }
}
