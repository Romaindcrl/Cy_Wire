#include "../include/parser.h"
#include "../include/avl.h"
#include "../include/station.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 1024
#define INPUT_DELIMITER ":"

static void trim(char *str) {
  if (!str)
    return;
  char *start = str;
  while (*start == ' ' || *start == '\t')
    start++;
  if (start != str)
    memmove(str, start, strlen(start) + 1);

  char *end = str + strlen(str) - 1;
  while (end > str &&
         (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r'))
    end--;
  *(end + 1) = '\0';
}

char **split_line(char *line, const char *delimiter, int *count) {
  *count = 0;
  char **tokens = NULL;

  char *token = strtok(line, delimiter);
  while (token) {
    tokens = realloc(tokens, (*count + 1) * sizeof(char *));
    if (!tokens)
      return NULL;

    trim(token);
    tokens[*count] = strdup(token);
    if (!tokens[*count]) {
      free_split_result(tokens, *count);
      return NULL;
    }

    (*count)++;
    token = strtok(NULL, delimiter);
  }

  return tokens;
}

void free_split_result(char **tokens, int count) {
  if (tokens) {
    for (int i = 0; i < count; i++) {
      free(tokens[i]);
    }
    free(tokens);
  }
}

AVLNode *parse_csv_file(const char *filename) {
  FILE *file = fopen(filename, "r");
  if (!file) {
    fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier %s\n", filename);
    return NULL;
  }

  char line[MAX_LINE_LENGTH];
  AVLNode *root = NULL;
  int line_count = 0;
  int header_processed = 0;

  while (fgets(line, sizeof(line), file)) {
    if (line[0] == '\0' || strcmp(line, "\n") == 0) {
      // Ligne vide ou juste un saut de ligne, on ignore
      continue;
    }
    line_count++;

    // Suppression du \n
    line[strcspn(line, "\n")] = 0;

    // Première ligne = en-tête
    if (!header_processed) {
      header_processed = 1;
      // On attend "Station:Capacité:Consommation"
      if (strcmp(line, "Station:Capacité:Consommation") != 0) {
        fprintf(stderr, "Erreur: En-tête invalide. Attendu: "
                        "Station:Capacité:Consommation\n");
        fclose(file);
        return NULL;
      }
      continue;
    }

    int token_count;
    char *line_copy = strdup(line);
    char **tokens = split_line(line_copy, INPUT_DELIMITER, &token_count);
    if (!tokens) {
      fprintf(stderr, "Erreur: Échec du split à la ligne %d\n", line_count);
      free(line_copy);
      continue;
    }

    if (token_count != 3) {
      fprintf(stderr,
              "Erreur: Ligne %d: nombre de champs incorrect (%d, attendu 3)\n",
              line_count, token_count);
      free_split_result(tokens, token_count);
      free(line_copy);
      continue;
    }

    char *id = tokens[0];
    char *cap_str = tokens[1];
    char *cons_str = tokens[2];

    char *endptr;
    double capacity = strtod(cap_str, &endptr);
    if (*endptr != '\0') {
      fprintf(stderr, "Erreur: Capacité invalide à la ligne %d\n", line_count);
      free_split_result(tokens, token_count);
      free(line_copy);
      continue;
    }

    double consumption = strtod(cons_str, &endptr);
    if (*endptr != '\0') {
      fprintf(stderr, "Erreur: Consommation invalide à la ligne %d\n",
              line_count);
      free_split_result(tokens, token_count);
      free(line_copy);
      continue;
    }

    Station *station = station_create(id, capacity, consumption);
    if (!station) {
      fprintf(stderr, "Erreur: Échec de création de station à la ligne %d\n",
              line_count);
      free_split_result(tokens, token_count);
      free(line_copy);
      continue;
    }

    root = avl_insert(root, station);

    free_split_result(tokens, token_count);
    free(line_copy);
  }

  fclose(file);
  return root;
}
