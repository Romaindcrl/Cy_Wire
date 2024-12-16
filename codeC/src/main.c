#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"
#include "avl.h"
#include "station.h"
#include "stats.h"

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <fichier_csv_entree> <fichier_csv_sortie>\n", argv[0]);
        return 1;
    }

    const char* input_file = argv[1];
    const char* output_file = argv[2];

AVLNode* root = parse_csv_file(input_file);
if (!root) {
    // Aucune donnée trouvée, on crée un fichier avec juste l'en-tête.
    StatsData* empty_stats = stats_create();
    if (empty_stats) {
        stats_write_to_file(empty_stats, output_file); 
        stats_destroy(empty_stats);
    }
    fprintf(stderr, "Aucune donnée correspondante - fichier vide créé.\n");
    return 0; // pas d'erreur, juste pas de données
}

    // Calcul des stats
    StatsData* stats = stats_create();
    if (!stats) {
        avl_destroy(root);
        return 3;
    }

    stats_compute(stats, root);

    // Écriture des résultats dans le fichier de sortie
    stats_write_to_file(stats, output_file);

    // Affichage du résumé
    stats_print_summary(stats);

    // Libération
    stats_destroy(stats);
    avl_destroy(root);

    return 0;
}
