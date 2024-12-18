#include "../include/avl.h"
#include "../include/parser.h"
#include "../include/station.h"
#include "../include/stats.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Le main prend désormais 5 arguments:
// 1: fichier_csv_entree
// 2: fichier_csv_sortie
// 3: station_type (hvb, hva, lv)
// 4: consumer_type (comp, indiv, all)
// Exemple:
// ./c-wire input_for_c.csv result_c.csv lv all
int main(int argc, char *argv[]) {
  if (argc != 5) {
    fprintf(stderr,
            "Usage: %s <fichier_csv_entree> <fichier_csv_sortie> "
            "<station_type> <consumer_type>\n",
            argv[0]);
    return 1;
  }

  const char *input_file = argv[1];
  const char *output_file = argv[2];
  const char *station_type = argv[3];
  const char *consumer_type = argv[4];

  AVLNode *root = parse_csv_file(input_file);
  if (!root) {
    // Aucune donnée trouvée, on crée un fichier vide avec juste l'en-tête
    // standard
    StatsData *empty_stats = stats_create(station_type, consumer_type);
    if (empty_stats) {
      stats_write_to_file(empty_stats, output_file);
      stats_destroy(empty_stats);
    }
    fprintf(stderr, "Aucune donnée correspondante - fichier vide créé.\n");
    return 0;
  }

  // Calcul des stats
  StatsData *stats = stats_create(station_type, consumer_type);
  if (!stats) {
    avl_destroy(root);
    return 3;
  }

  stats_compute(stats, root);

  // Écriture des résultats dans le fichier de sortie
  stats_write_to_file(stats, output_file);

  // Si lv all, on produit le fichier lv_all_minmax.csv
  if (strcmp(station_type, "lv") == 0 && strcmp(consumer_type, "all") == 0) {
    // On suppose que l'utilisateur veut le fichier lv_all_minmax dans le même
    // dossier ou dans un chemin défini. À adapter selon les besoins.
    char minmax_file[1024];
    snprintf(minmax_file, sizeof(minmax_file), "%s_minmax.csv", output_file);
    stats_write_minmax_file(stats, minmax_file);
  }

  // Affichage du résumé
  stats_print_summary(stats);

  // Libération
  stats_destroy(stats);
  avl_destroy(root);

  return 0;
}
