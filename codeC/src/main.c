#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"
#include "avl.h"
#include "station.h"
#include "stats.h"

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "Usage: %s <fichier_csv>\n", argv[0]);
		return 1;
	}

	// Création de l'arbre AVL à partir du fichier CSV
	AVLNode* root = parse_csv_file(argv[1]);
	if (!root) {
		fprintf(stderr, "Erreur lors du parsing du fichier\n");
		return 2;
	}

	// Calcul des statistiques
	StatsData* stats = stats_create();
	if (!stats) {
		avl_destroy(root);
		return 3;
	}

	stats_compute(stats, root);

	// Génération des fichiers de sortie
	stats_write_to_file(stats, argv[1]);

	// Si c'est un fichier lv_all, générer aussi le fichier minmax
	if (strstr(argv[1], "lv_all") != NULL) {
		char minmax_filename[256];
		snprintf(minmax_filename, sizeof(minmax_filename), "%s_minmax.csv", argv[1]);
		stats_write_minmax_file(stats, minmax_filename);
	}

	// Affichage du résumé
	stats_print_summary(stats);

	// Libération de la mémoire
	stats_destroy(stats);
	avl_destroy(root);

	return 0;
}