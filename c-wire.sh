#!/bin/bash

# Fonction d'affichage de l'aide
display_help() {
    echo "Usage: $0 <chemin_fichier> <type_station> <type_consommateur> [identifiant_centrale] [-h]"
    echo
    echo "Arguments obligatoires:"
    echo "  chemin_fichier       : Chemin vers le fichier CSV d'entrée"
    echo "  type_station         : hvb, hva, ou lv"
    echo "  type_consommateur    : comp, indiv, ou all"
    echo
    echo "Arguments optionnels:"
    echo "  identifiant_centrale : Numéro de la centrale à analyser"
    echo "  -h                   : Affiche cette aide"
    exit 1
}

# Fonction de validation des paramètres
validate_params() {
    local station=$1
    local consumer=$2

    case "$consumer" in
        "comp"|"indiv"|"all")
            ;;
        *)
            echo "Erreur: Type de consommateur invalide. Valeurs acceptées : comp, indiv, all"
            exit 1
            ;;
    esac

    if [[ "$station" == "hvb" && ("$consumer" == "all" || "$consumer" == "indiv") ]]; then
        echo "Erreur: Combinaison interdite - hvb ne peut pas être utilisé avec all ou indiv"
        exit 1
    fi

    if [[ "$station" == "hva" && ("$consumer" == "all" || "$consumer" == "indiv") ]]; then
        echo "Erreur: Combinaison interdite - hva ne peut pas être utilisé avec all ou indiv"
        exit 1
    fi
}

# Vérification de l'option d'aide
for arg in "$@"; do
    if [ "$arg" == "-h" ]; then
        display_help
    fi
done

# Vérification du nombre d'arguments
if [ $# -lt 3 ]; then
    echo "Erreur: Nombre d'arguments insuffisant"
    display_help
fi

# Récupération des arguments
input_file=$1
station_type=$2
consumer_type=$3
power_plant_id=${4:-""}

# Validation des paramètres
validate_params "$station_type" "$consumer_type"

# Vérification de l'existence du fichier d'entrée
if [ ! -f "$input_file" ]; then
    echo "Erreur: Le fichier $input_file n'existe pas"
    exit 1
fi

# Création des dossiers nécessaires
mkdir -p tmp/filtered_data
mkdir -p graphs/consumption_stats

# Nettoyage du dossier tmp
rm -rf tmp/filtered_data/*

# Compilation du programme C si nécessaire
if [ ! -f "codeC/bin/c-wire" ]; then
    cd codeC
    make clean
    make
    if [ $? -ne 0 ]; then
        echo "Erreur de compilation"
        exit 1
    fi
    cd ..
fi

# Début du chronomètre
start_time=$(date +%s.%N)

# Définition du fichier de sortie
output_file="tmp/filtered_data/${station_type}_${consumer_type}${power_plant_id:+_}${power_plant_id}.csv"

# Filtrage des données selon les paramètres
case $station_type in
    "hvb")
        awk -F';' '
        BEGIN { OFS=":"; print "Station:Capacité:Consommation" }
        {
            if (NR > 1 && $2 != "-") {
                station = $2
                if ($7 != "-") capacities[station] = $7
                if ($8 != "-") consumptions[station] = $8
            }
        }
        END {
            for (station in capacities) {
                print station, capacities[station], consumptions[station]
            }
        }' "$input_file" > "$output_file"
        ;;
    "hva")
        awk -F';' '
        BEGIN { OFS=":"; print "Station:Capacité:Consommation" }
        {
            if (NR > 1 && $3 != "-") {
                station = $3
                if ($7 != "-") capacities[station] = $7
                if ($8 != "-") consumptions[station] = $8
            }
        }
        END {
            for (station in capacities) {
                print station, capacities[station], consumptions[station]
            }
        }' "$input_file" > "$output_file"
        ;;
    "lv")
        awk -F';' '
        BEGIN { OFS=":"; print "Station:Capacité:Consommation" }
        {
            if (NR > 1 && $4 != "-") {
                station = $4
                if ($7 != "-") capacities[station] = $7
                if ($8 != "-") consumptions[station] += $8
            }
        }
        END {
            for (station in capacities) {
                print station, capacities[station], consumptions[station]
            }
        }' "$input_file" > "$output_file"
        ;;
    *)
        echo "Erreur: Type de station invalide"
        display_help
        ;;
esac

# Gestion des 10 stations les plus et les moins chargées
minmax_file="tmp/filtered_data/${station_type}_${consumer_type}_minmax.csv"
echo "Station:Capacité:Consommation" > "$minmax_file"

# Top 10 stations avec la consommation la plus élevée
sort -t: -k3,3nr "$output_file" | head -n 10 >> "$minmax_file"

# Bottom 10 stations avec la consommation la plus faible
sort -t: -k3,3n "$output_file" | head -n 10 >> "$minmax_file"

# Mettre à jour le fichier de sortie pour le graphique
output_file="$minmax_file"

# Vérification que le fichier filtré a été créé
if [ ! -f "$output_file" ]; then
    echo "Erreur: Le fichier filtré n'a pas été créé"
    exit 1
fi

# Appel du programme C
./codeC/bin/c-wire "$output_file"

# Génération des graphiques avec GnuPlot
if command -v gnuplot >/dev/null 2>&1; then
    graph_file="graphs/consumption_stats/consumption_graph_${station_type}_${consumer_type}.png"
    echo "Génération du graphique : $graph_file"

    cat > graphs/consumption_stats/plot_script.gnu << EOF
set terminal png size 1200,800
set output "$graph_file"
set style data histograms
set style fill solid 0.8 border -1
set boxwidth 0.7
set title "Consommation et Capacité (${station_type} - ${consumer_type})"
set xlabel "Stations"
set ylabel "Énergie (kWh)"
set grid ytics
set xtics rotate by -45
set datafile separator ":"

# Tracer les données
plot "$output_file" using 2:xtic(1) title "Capacité (kWh)" lc rgb "blue", \
     "$output_file" using 3 title "Consommation (kWh)" lc rgb "orange"
EOF

    gnuplot graphs/consumption_stats/plot_script.gnu
else
    echo "Erreur: GnuPlot n'est pas installé."
fi

# Fin du chronomètre
end_time=$(date +%s.%N)
execution_time=$(echo "$end_time - $start_time" | bc)
echo "Temps d'exécution: ${execution_time}sec"
