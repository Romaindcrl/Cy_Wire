Script projet de preing-2 : CY_Wire

Ce script Shell (c-wire.sh) a été conçu pour filtrer et analyser des données relatives à la distribution d’électricité à partir d’un fichier CSV volumineux. Les données incluent différentes catégories d’acteurs :

Les centrales (PowerPlant)

Les stations HV-B

Les stations HV-A

Les postes LV

Les consommateurs finaux (entreprises et particuliers)

Le but est de produire, à partir d’un jeu de données filtré, des fichiers résumant la capacité de chaque station et la consommation totale de leurs consommateurs.

Utilisation

Prérequis

Assurez-vous que votre environnement exécute Bash et dispose des outils nécessaires tels que awk.
Si vous souhaitez générer des graphiques (notamment pour le cas lv all), installez également gnuplot :

Pour gnuplot : https://doc.ubuntu-fr.org/gnuplot

Pour awk : Généralement présent par défaut sous Unix.

Options

Le script offre plusieurs options permettant de filtrer les données par type de station et type de consommateur :

type_station : hvb, hva, lv

type_consommateur : comp (entreprises), indiv (particuliers), all (tous)

Important :

Pour hvb et hva, seules les entreprises sont connectées, donc comp est l’unique choix valide. Les options all et indiv sont interdites.

Pour lv, toutes les options (comp, indiv, all) sont autorisées.

HVB : Stations Haute Tension B

Analyser les stations HV-B (hvb) et leurs consommateurs (entreprises, comp).

Le résultat présente chaque station HV-B, sa capacité, et la consommation totale de ses entreprises connectées.

HVA : Stations Haute Tension A

Analyser les stations HV-A (hva) et leurs consommateurs (entreprises, comp).

Le résultat présente chaque station HV-A, sa capacité, et la consommation totale de ses entreprises connectées.

LV : Postes Basse Tension

Analyser les postes LV (lv) et leurs consommateurs.

lv comp : entreprises uniquement

lv indiv : particuliers uniquement

lv all : tous les consommateurs

Le résultat présente chaque poste LV, sa capacité, et la consommation totale de ses consommateurs.

Dans le cas lv all, un fichier supplémentaire lv_all_minmax.csv est généré, présentant les 10 postes les plus chargés et les 10 moins chargés, et un graphique est produit si gnuplot est installé.

Filtrage par Identifiant de Centrale

De manière optionnelle, vous pouvez spécifier un identifiant de centrale (un nombre), afin de n’analyser que les données relatives à cette centrale.

Exécution du script

Pour exécuter le script, ouvrez un terminal et lancez la commande suivante :

./c-wire.sh [-h] <fichier_csv> <type_station> <type_consommateur> [identifiant_centrale]

Exemples :

./c-wire.sh -h

# Affiche l'aide



./c-wire.sh input/input.csv hvb comp

# Analyse les stations HV-B et entreprises connectées, toutes centrales confondues.



./c-wire.sh input/input.csv lv all 2

# Analyse les postes LV et tous les consommateurs pour la centrale n°2.

# Génère également lv_all_minmax.csv et un graphique associé.

Planning

5.12.2023 :

Lecture du projet

Création du fichier c-wire.sh

11.12.2023 :

Ajout du filtrage et traitement pour HV-B (hvb comp)

Premier essai lent

Optimisation avec awk pour tenir les contraintes de temps

12.12.2023 :

Ajout du filtrage et traitement pour HV-A (hva comp)

Ajout du filtrage par centrale (option identifiant_centrale)

Commandes awk optimisées pour rester sous les contraintes de temps

18.12.2023 :

Implémentation du traitement LV (lv comp, lv indiv)

Tests de performance et ajustements

19.12.2023 :

Mise en place de lv all : génération du fichier minmax (lv_all_minmax.csv) et test de performance

Ajout du graphique avec gnuplot pour lv all

Tests, corrections, finalisation des options

26.12.2023 et 28.12.2023 :

Début de la rédaction et mise en forme du README

Ajout de commentaires dans le code

Semaines du 1/01/2024 et 8/01/2024 :

Aucune modification, projet stable et fonctionnel

Ce planning retrace les étapes principales de développement et d’optimisation du script. Le projet final respecte les contraintes de temps et génère des résultats exploitables sous forme de fichiers et, pour certains cas, de graphiques.

