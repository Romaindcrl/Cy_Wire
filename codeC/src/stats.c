#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "stats.h"

#define OUTPUT_DELIMITER ':'

static void insert_sorted_station(Station** array, int size, Station* station, int is_ascending) {
	int i;
	double station_value = station->capacity;  // Tri par capacité

	for (i = size - 1; i >= 0; i--) {
		if (!array[i] || (is_ascending ? 
			(array[i]->capacity > station_value) : 
			(array[i]->capacity < station_value))) {
			if (i < size - 1) {
				array[i + 1] = array[i];
			}
		} else {
			break;
		}
	}

	if (i + 1 < size) {
		array[i + 1] = station;
	}
}

StatsData* stats_create(void) {
	StatsData* stats = (StatsData*)malloc(sizeof(StatsData));
	if (!stats) return NULL;

	stats->total_consumption = 0.0;
	stats->total_capacity = 0.0;
	stats->station_count = 0;
	stats->max_stations = MAX_STATIONS;

	stats->all_stations = (Station**)calloc(MAX_STATIONS, sizeof(Station*));
	stats->top_stations = (Station**)calloc(TOP_N, sizeof(Station*));
	stats->bottom_stations = (Station**)calloc(TOP_N, sizeof(Station*));

	if (!stats->all_stations || !stats->top_stations || !stats->bottom_stations) {
		stats_destroy(stats);
		return NULL;
	}

	return stats;
}

void stats_destroy(StatsData* stats) {
	if (stats) {
		free(stats->all_stations);
		free(stats->top_stations);
		free(stats->bottom_stations);
		free(stats);
	}
}

static void process_node_stats(StatsData* stats, Station* station) {
	if (!stats || !station) return;

	stats->total_consumption += station->consumption;
	stats->total_capacity += station->capacity;

	if (stats->station_count < stats->max_stations) {
		stats->all_stations[stats->station_count] = station;
		insert_sorted_station(stats->top_stations, TOP_N, station, 0);
		insert_sorted_station(stats->bottom_stations, TOP_N, station, 1);
		stats->station_count++;
	}
}

void stats_compute(StatsData* stats, AVLNode* root) {
	if (!stats || !root) return;

	stats->total_consumption = 0.0;
	stats->total_capacity = 0.0;
	stats->station_count = 0;

	memset(stats->all_stations, 0, MAX_STATIONS * sizeof(Station*));
	memset(stats->top_stations, 0, TOP_N * sizeof(Station*));
	memset(stats->bottom_stations, 0, TOP_N * sizeof(Station*));

	AVLNode* current = root;
	while (current) {
		process_node_stats(stats, current->station);
		current = current->right;  // Parcours in-order
	}
}

// ... (reste du code inchangé)

void stats_write_to_file(const StatsData* stats, const char* base_filename) {
	if (!stats || !base_filename) return;

	char output_filename[256];
	snprintf(output_filename, sizeof(output_filename), "%s_stats.csv", base_filename);

	FILE* file = fopen(output_filename, "w");
	if (!file) {
		fprintf(stderr, "Erreur: Impossible de créer le fichier %s\n", output_filename);
		return;
	}

	// En-tête
	fprintf(file, "Station%cCapacité%cConsommation\n", 
			OUTPUT_DELIMITER, OUTPUT_DELIMITER);

	// Écriture des données triées par capacité
	for (int i = 0; i < stats->station_count; i++) {
		Station* s = stats->top_stations[i];
		if (s) {
			fprintf(file, "%s%c%.2f%c%.2f\n", 
					s->id, OUTPUT_DELIMITER, 
					s->capacity, OUTPUT_DELIMITER, 
					s->consumption);
		}
	}

	fclose(file);
}

void stats_write_minmax_file(const StatsData* stats, const char* filename) {
	if (!stats || !filename) return;

	FILE* file = fopen(filename, "w");
	if (!file) {
		fprintf(stderr, "Erreur: Impossible de créer le fichier %s\n", filename);
		return;
	}

	// En-tête
	fprintf(file, "Station%cCapacité%cConsommation\n", 
			OUTPUT_DELIMITER, OUTPUT_DELIMITER);

	// Top 10 plus grandes consommations
	fprintf(file, "\n# Top 10 plus grandes consommations:\n");
	for (int i = 0; i < TOP_N && stats->top_stations[i]; i++) {
		Station* s = stats->top_stations[i];
		fprintf(file, "%s%c%.2f%c%.2f\n", 
				s->id, OUTPUT_DELIMITER, 
				s->capacity, OUTPUT_DELIMITER, 
				s->consumption);
	}

	// Top 10 plus petites consommations
	fprintf(file, "\n# Top 10 plus petites consommations:\n");
	for (int i = 0; i < TOP_N && stats->bottom_stations[i]; i++) {
		Station* s = stats->bottom_stations[i];
		fprintf(file, "%s%c%.2f%c%.2f\n", 
				s->id, OUTPUT_DELIMITER, 
				s->capacity, OUTPUT_DELIMITER, 
				s->consumption);
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
		printf("Taux d'utilisation: %.2f%%\n", 
			   (stats->total_consumption / stats->total_capacity) * 100);
	}
}