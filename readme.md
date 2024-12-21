# Projet CY-Wire : Synthèse de Données d’énergie

## Description Générale
Ce projet vise à analyser un vaste jeu de données simulées sur la distribution d'électricité en France.
Le script Shell et le programme C associé permettent de filtrer et synthétiser ces données, en produisant des fichiers résumés et des visualisations graphiques des résultats.

### Fonctionnalités principales
1. **Filtrage des données** : Extraction des informations pertinentes basées sur le type de station et les catégories de consommateurs.
2. **Calcul des consommations** : Utilisation d'un AVL (Arbre binaire de recherche équilibré) pour optimiser les calculs de somme des consommations.
3. **Production de fichiers CSV** : Génération de fichiers récapitulatifs structurés.
4. **Visualisation graphique (Bonus)** : Création de graphiques en barres pour les postes LV les plus et les moins chargés.

## Structure des Données
- **Fichier d'entrée** : CSV volumineux contenant des données sur la distribution et la consommation d’énergie.
  - Colonnes principales : `Power Plant`, `HV-B Station`, `HV-A Station`, `LV Station`, `Company`, `Individual`, `Capacity`, `Load`.
- **Fichiers de sortie** : CSV avec les colonnes :
  - `Station` : Identifiant de la station analysée.
  - `Capacity` : Capacité totale en kWh.
  - `Consumption` : Consommation totale selon le type de consommateur.

## Utilisation

### Prérequis
- **Environnement** : Bash (Linux/Unix)
- **Outils requis** :
  - `awk` (installé par défaut sous Unix).
  - `gnuplot` (pour les graphiques).

### Commandes
Exécutez le script avec la commande suivante :
```
./c-wire.sh <chemin_fichier> <type_station> <type_consommateur> [identifiant_centrale] [-h]
```
#### Paramètres
- `<chemin_fichier>` : Chemin vers le fichier CSV d'entrée (obligatoire).
- `<type_station>` : Type de station (à choisir parmi `hvb`, `hva`, `lv`).
- `<type_consommateur>` : Type de consommateur (à choisir parmi `comp`, `indiv`, `all`).
- `[identifiant_centrale]` : Filtre optionnel pour une centrale spécifique.
- `-h` : Affiche l'aide et ignore les autres arguments.

#### Exemples d’exécution
1. **Analyse des stations HV-B et entreprises connectées :**
   ```
   ./c-wire.sh input/data.csv hvb comp
   ```

2. **Analyse des postes LV pour tous les consommateurs de la centrale n°2 :**
   ```
   ./c-wire.sh input/data.csv lv all 2
   ```

## Fonctionnalités Bonus
- **Graphique pour LV all** : Génère un graphique en barres comparant les 10 postes LV les plus et les moins chargés.
- **Fichiers supplémentaires** :
  - `lv_all_minmax.csv` : Contient les informations sur les 10 postes les plus chargés et les 10 moins chargés.
  - Visualisation graphique exportée au format PNG.

## Planification
- **Filtrage et traitement initial** : Ajout des fonctions de base pour HV-B, HV-A et LV.
- **Optimisation des performances** : Utilisation d'`awk` pour filtrer efficacement les données.
- **Intégration de gnuplot** : Implémentation des graphiques.
- **Rédaction du README** : Documentation complète pour l’utilisateur.

## Structure du Projet
```
.
├── input/               # Contient le fichier de données d'entrée
├── output/              # Fichiers CSV résultants
├── tmp/                 # Données intermédiaires
├── graphs/              # Graphiques générés
├── codeC/               # Code source et exécutable C
├── c-wire.sh            # Script principal
└── README.md            # Documentation utilisateur
```

## Limitations et Améliorations
- **Limitations** : Aucun élément majeur non fonctionnel signalé.
- **Propositions d’amélioration** :
  - Implémentation d’une interface utilisateur graphique (GUI).
  - Ajout d’un système de logs pour un suivi détaillé des traitements.

