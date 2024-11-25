#include <stdio.h>
#include <stdlib.h>
#include "avl.h"

static int max(int a, int b) {
	return (a > b) ? a : b;
}

static int get_balance(AVLNode* node) {
	if (!node) return 0;
	return avl_height(node->left) - avl_height(node->right);
}

static AVLNode* right_rotate(AVLNode* y) {
	AVLNode* x = y->left;
	AVLNode* T2 = x->right;

	x->right = y;
	y->left = T2;

	y->height = max(avl_height(y->left), avl_height(y->right)) + 1;
	x->height = max(avl_height(x->left), avl_height(x->right)) + 1;

	return x;
}

static AVLNode* left_rotate(AVLNode* x) {
	AVLNode* y = x->right;
	AVLNode* T2 = y->left;

	y->left = x;
	x->right = T2;

	x->height = max(avl_height(x->left), avl_height(x->right)) + 1;
	y->height = max(avl_height(y->left), avl_height(y->right)) + 1;

	return y;
}

AVLNode* avl_create_node(Station* station) {
	AVLNode* node = (AVLNode*)malloc(sizeof(AVLNode));
	if (!node) return NULL;

	node->station = station;
	node->left = NULL;
	node->right = NULL;
	node->height = 1;
	return node;
}

int avl_height(AVLNode* node) {
	if (!node) return 0;
	return node->height;
}

AVLNode* avl_insert(AVLNode* root, Station* station) {
	if (!root) return avl_create_node(station);

	int cmp = station_compare(station, root->station);
	if (cmp < 0)
		root->left = avl_insert(root->left, station);
	else if (cmp > 0)
		root->right = avl_insert(root->right, station);
	else
		return root;

	root->height = max(avl_height(root->left), avl_height(root->right)) + 1;

	int balance = get_balance(root);

	// Cas Left Left
	if (balance > 1 && station_compare(station, root->left->station) < 0)
		return right_rotate(root);

	// Cas Right Right
	if (balance < -1 && station_compare(station, root->right->station) > 0)
		return left_rotate(root);

	// Cas Left Right
	if (balance > 1 && station_compare(station, root->left->station) > 0) {
		root->left = left_rotate(root->left);
		return right_rotate(root);
	}

	// Cas Right Left
	if (balance < -1 && station_compare(station, root->right->station) < 0) {
		root->right = right_rotate(root->right);
		return left_rotate(root);
	}

	return root;
}

void avl_destroy(AVLNode* root) {
	if (root) {
		avl_destroy(root->left);
		avl_destroy(root->right);
		station_destroy(root->station);
		free(root);
	}
}

void avl_print_inorder(AVLNode* root) {
	if (root) {
		avl_print_inorder(root->left);
		station_print(root->station);
		avl_print_inorder(root->right);
	}
}
