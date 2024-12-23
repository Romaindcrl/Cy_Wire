#include "../include/avl.h"
#include "../include/station.h"
#include <stdio.h>
#include <stdlib.h>

static int max(int a, int b) { return (a > b) ? a : b; }

static int get_balance(AVLNode *node) {
  if (!node)
    return 0;
  return avl_height(node->left) - avl_height(node->right);
}

static AVLNode *right_rotate(AVLNode *y) {
  AVLNode *x = y->left;
  AVLNode *T2 = x->right;

  x->right = y;
  y->left = T2;

  y->height = max(avl_height(y->left), avl_height(y->right)) + 1;
  x->height = max(avl_height(x->left), avl_height(x->right)) + 1;

  return x;
}

static AVLNode *left_rotate(AVLNode *x) {
  AVLNode *y = x->right;
  AVLNode *T2 = y->left;

  y->left = x;
  x->right = T2;

  x->height = max(avl_height(x->left), avl_height(x->right)) + 1;
  y->height = max(avl_height(y->left), avl_height(y->right)) + 1;

  return y;
}

AVLNode *avl_create_node(Station *station) {
  AVLNode *node = (AVLNode *)malloc(sizeof(AVLNode));
  if (!node)
    return NULL;

  node->station = station;
  node->left = NULL;
  node->right = NULL;
  node->height = 1;
  return node;
}

int avl_height(AVLNode *node) {
  if (!node)
    return 0;
  return node->height;
}

AVLNode *avl_insert(AVLNode *root, Station *station) {
  if (!root)
    return avl_create_node(station);

  int cmp = station_compare(station, root->station);
  if (cmp < 0) {
    root->left = avl_insert(root->left, station);
  } else if (cmp > 0) {
    root->right = avl_insert(root->right, station);
  } else {
    // Station déjà présente (même ID)
    // On met à jour les données de la station existante.
    // Par exemple, on additionne la consommation.
    root->station->consumption += station->consumption;

    // Si la capacité est définie uniquement à la création de la station,
    // vous pouvez ignorer la mise à jour de la capacité ou vérifier s'il y a
    // une nouvelle info. root->station->capacity = (root->station->capacity ==
    // 0) ? station->capacity : root->station->capacity;

    // On libère la station en trop, car on ne l'insère pas
    station_destroy(station);
    return root;
  }

  root->height = max(avl_height(root->left), avl_height(root->right)) + 1;

  int balance = get_balance(root);

  // Cas d’équilibrage identiques à avant
  if (balance > 1 && station_compare(station, root->left->station) < 0)
    return right_rotate(root);

  if (balance < -1 && station_compare(station, root->right->station) > 0)
    return left_rotate(root);

  if (balance > 1 && station_compare(station, root->left->station) > 0) {
    root->left = left_rotate(root->left);
    return right_rotate(root);
  }

  if (balance < -1 && station_compare(station, root->right->station) < 0) {
    root->right = right_rotate(root->right);
    return left_rotate(root);
  }

  return root;
}

void avl_destroy(AVLNode *root) {
  if (root) {
    avl_destroy(root->left);
    avl_destroy(root->right);
    station_destroy(root->station);
    free(root);
  }
}

void avl_print_inorder(AVLNode *root) {
  if (root) {
    avl_print_inorder(root->left);
    station_print(root->station);
    avl_print_inorder(root->right);
  }
}

void avl_inorder(AVLNode *root, void (*process)(Station *, void *),
                 void *user_data) {
  if (!root)
    return;
  avl_inorder(root->left, process, user_data);
  process(root->station, user_data);
  avl_inorder(root->right, process, user_data);
}
