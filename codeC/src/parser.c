#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"

#define MAX_LINE_LENGTH 1024
#define INPUT_DELIMITER ":"

// Fonction utilitaire pour nettoyer une chaîne
static void trim(char* str) {
	if (!str) return;
	char* start = str;
	while (*start == ' ' || *start == '\t') start++;
	if (start != str) memmove(str, start, strlen(start) + 1);

	char* end = str + strlen(str) - 1;
	while (end > str && (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r')) end--;
	*(end + 1) = '\0';
}

char** split_line(char* line, const char* delimiter, int* count) {
	*count = 0;
	char** tokens = NULL;

	char* token = strtok(line, delimiter);
	while (token) {
		tokens = realloc(tokens, (*count + 1) * sizeof(char*));
		if (!tokens) return NULL;

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

void free_split_result(char** tokens, int count) {
	if (tokens) {
		for (int i = 0; i < count; i++) {
			free(tokens[i]);
		}
		free(tokens);
	}
}

AVLNode* parse_csv_file(const char* filename) {
	FILE* file = fopen(filename, "r");
	if (!file) {
		fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier %s\n", filename);
		return NULL;
	}

	char line[MAX_LINE_LENGTH];
	AVLNode* root = NULL;
	int line_count = 0;
	int header_processed = 0;

	while (fgets(line, sizeof(line), file)) {
		line_count++;

		// Ignorer la ligne d'en-tête
		if (!header_processed) {
			header_processed = 1;
			continue;
		}

		// Supprimer le retour à la ligne
		line[strcspn(line, "\n")] = 0;

		int token_count;
		char** tokens = split_line(line, INPUT_DELIMITER, &token_count);

		if (tokens && token_count >= 3) {
			// Conversion des valeurs avec vérification
			char* endptr;
			double capacity = strtod(tokens[1], &endptr);
			if (*endptr != '\0') {
				fprintf(stderr, "Erreur: Capacité invalide à la ligne %d\n", line_count);
				free_split_result(tokens, token_count);
				continue;
			}

			double consumption = strtod(tokens[2], &endptr);
			if (*endptr != '\0') {
				fprintf(stderr, "Erreur: Consommation invalide à la ligne %d\n", line_count);
				free_split_result(tokens, token_count);
				continue;
			}

			// Création et insertion de la station
			Station* station = station_create(tokens[0], capacity, consumption);
			if (station) {
				root = avl_insert(root, station);
				if (!root) {
					fprintf(stderr, "Erreur: Échec de l'insertion dans l'AVL\n");
					station_destroy(station);
				}
			}
		}

		free_split_result(tokens, token_count);
	}

	fclose(file);
	return root;
}