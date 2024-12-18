#ifndef PARSER_H
#define PARSER_H

#include "avl.h"

// Fonctions de parsing
AVLNode* parse_csv_file(const char* filename);
char** split_line(char* line, const char* delimiter, int* count);
void free_split_result(char** tokens, int count);

#endif
