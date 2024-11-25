#ifndef AVL_H
#define AVL_H

#include "station.h"

typedef struct AVLNode {
	Station* station;
	struct AVLNode* left;
	struct AVLNode* right;
	int height;
} AVLNode;

// Fonctions de gestion de l'arbre AVL
AVLNode* avl_create_node(Station* station);
AVLNode* avl_insert(AVLNode* root, Station* station);
void avl_destroy(AVLNode* root);
int avl_height(AVLNode* node);
void avl_print_inorder(AVLNode* root);

#endif
