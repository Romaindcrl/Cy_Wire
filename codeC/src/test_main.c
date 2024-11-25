#include <stdio.h>
#include <stdlib.h>
#include <string.h> 
#include <assert.h>
#include "avl.h"
#include "station.h"
#include "parser.h"
#include "stats.h"



void test_station() {
	printf("Test des fonctions Station...\n");

	Station* s = station_create("TEST1", 1000.0, 800.0);
	assert(s != NULL);
	assert(s->capacity == 1000.0);
	assert(s->consumption == 800.0);
	assert(strcmp(s->id, "TEST1") == 0);

	Station* s2 = station_create("TEST2", 2000.0, 1500.0);
	assert(station_compare(s, s2) < 0);

	station_destroy(s);
	station_destroy(s2);
	printf("Tests Station réussis\n");
}

void test_avl() {
	printf("Test des fonctions AVL...\n");

	AVLNode* root = NULL;
	Station* s1 = station_create("TEST1", 1000.0, 800.0);
	Station* s2 = station_create("TEST2", 2000.0, 1500.0);
	Station* s3 = station_create("TEST3", 1500.0, 1200.0);

	root = avl_insert(root, s1);
	root = avl_insert(root, s2);
	root = avl_insert(root, s3);

	assert(avl_height(root) >= 1);
	assert(avl_height(root) <= 2);

	avl_destroy(root);
	printf("Tests AVL réussis\n");
}

void test_stats() {
	printf("Test des fonctions Stats...\n");

	StatsData* stats = stats_create();
	assert(stats != NULL);
	assert(stats->station_count == 0);
	assert(stats->total_capacity == 0.0);
	assert(stats->total_consumption == 0.0);

	AVLNode* root = NULL;
	Station* s1 = station_create("TEST1", 1000.0, 800.0);
	root = avl_insert(root, s1);

	stats_compute(stats, root);
	assert(stats->station_count == 1);
	assert(stats->total_capacity == 1000.0);
	assert(stats->total_consumption == 800.0);

	avl_destroy(root);
	stats_destroy(stats);
	printf("Tests Stats réussis\n");
}

int main() {
	printf("Début des tests unitaires...\n\n");

	test_station();
	test_avl();
	test_stats();

	printf("\nTous les tests ont réussi !\n");
	return 0;
}
