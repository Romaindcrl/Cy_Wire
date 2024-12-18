#!/bin/bash

#####################################
# Affichage de l'aide
#####################################
display_help() {
    echo "Usage: $0 <chemin_fichier> <type_station> <type_consommateur> [identifiant_centrale] [-h]"
    echo
    echo "Arguments obligatoires:"
    echo "  chemin_fichier       : Chemin vers le fichier CSV d'entrée (Ex: input/data.csv)"
    echo "  type_station         : hvb, hva, ou lv"
    echo "  type_consommateur    : comp, indiv, ou all"
    echo
    echo "Arguments optionnels:"
    echo "  identifiant_centrale : Numéro de la centrale à analyser"
    echo "  -h                   : Affiche cette aide et ignore les autres paramètres"
    echo
    echo "Règles spécifiques:"
    echo "  - hvb ne peut pas être utilisé avec all ou indiv"
    echo "  - hva ne peut pas être utilisé avec all ou indiv"
    echo
    echo "Exemples:"
    echo "  $0 input/data.csv hvb comp"
    echo "  $0 input/data.csv lv all 2"
    exit 0
}

#####################################
# Début du chronomètre global (avant validation des paramètres)
#####################################
start_time=$(date +%s.%N)

#####################################
# Vérification option d'aide (prioritaire)
#####################################
for arg in "$@"; do
    if [ "$arg" == "-h" ]; then
        display_help
    fi
done

#####################################
# Vérification du nombre d'arguments
#####################################
if [ $# -lt 3 ]; then
    echo "Erreur: Nombre d'arguments insuffisant"
    display_help
fi

#####################################
# Récupération des arguments
#####################################
input_file=$1
station_type=$2
consumer_type=$3
power_plant_id=${4:-""}

#####################################
# Fonction de validation des paramètres
#####################################
validate_params() {
    local station=$1
    local consumer=$2

    # Vérification du type de consommateur
    case "$consumer" in
        "comp"|"indiv"|"all")
            ;;
        *)
            echo "Erreur: Type de consommateur invalide ($consumer). Valeurs acceptées : comp, indiv, all"
            display_help
            ;;
    esac

    # Combinations interdites
    if [[ "$station" == "hvb" && ("$consumer" == "all" || "$consumer" == "indiv") ]]; then
        echo "Erreur: Combinaison interdite - hvb ne peut pas être utilisé avec all ou indiv"
        display_help
    fi

    if [[ "$station" == "hva" && ("$consumer" == "all" || "$consumer" == "indiv") ]]; then
        echo "Erreur: Combinaison interdite - hva ne peut pas être utilisé avec all ou indiv"
        display_help
    fi
}

validate_params "$station_type" "$consumer_type"

#####################################
# Vérification de l'existence du fichier d'entrée
#####################################
if [ ! -f "$input_file" ]; then
    echo "Erreur: Le fichier $input_file n'existe pas"
    # Aucune donnée n'a été traitée, durée = 0.0
    echo "Temps d'exécution: 0.0sec"
    exit 1
fi

#####################################
# Préparation des dossiers
#####################################
mkdir -p tmp
mkdir -p graphs
rm -rf tmp/*
mkdir -p tmp/filtered_data
mkdir -p graphs/consumption_stats

#####################################
# Compilation du programme C si nécessaire
#####################################
if [ ! -f "codeC/bin/c-wire" ]; then
    (cd codeC && make clean && make)
    if [ $? -ne 0 ]; then
        echo "Erreur de compilation du programme C"
        # Aucune donnée n'a été traitée, durée = 0.0
        echo "Temps d'exécution: 0.0sec"
        exit 1
    fi
fi

#####################################
# Début du traitement
#####################################
process_start_time=$(date +%s.%N)

#####################################
# FILTRAGE DES DONNÉES BRUTES
#####################################
raw_input="tmp/filtered_data/raw_input_for_c.csv"
echo "PowerPlant;HVB;HVA;LV;Company;Individual;Capacity;Load" > "$raw_input"

awk -F';' -v st="$station_type" -v ct="$consumer_type" -v ppid="$power_plant_id" '
NR > 1 {
    # Filtre par identifiant de centrale si spécifié
    if (ppid != "" && $1 != ppid) {
        next
    }

    # Filtrage selon type de station et consommateur
    if (st == "hvb" && ct == "comp") {
        if (($2 != "-" && $5 == "-" && $6 == "-" && $7 != "-") || 
            ($2 != "-" && $5 != "-" && $8 != "-")) {
            print $0
        }
    } else if (st == "hva" && ct == "comp") {
        if (($3 != "-" && $5 == "-" && $6 == "-" && $7 != "-") || 
            ($3 != "-" && $5 != "-" && $8 != "-")) {
            print $0
        }
    } else if (st == "lv" && ct == "comp") {
        if (($4 != "-" && $5 == "-" && $6 == "-" && $7 != "-") || 
            ($4 != "-" && $5 != "-" && $8 != "-")) {
            print $0
        }
    } else if (st == "lv" && ct == "indiv") {
        if (($4 != "-" && $5 == "-" && $6 == "-" && $7 != "-") || 
            ($4 != "-" && $6 != "-" && $8 != "-")) {
            print $0
        }
    } else if (st == "lv" && ct == "all") {
        if (($4 != "-" && $5 == "-" && $6 == "-" && $7 != "-") || 
            ($4 != "-" && $8 != "-")) {
            print $0
        }
    }
}
' "$input_file" >> "$raw_input"


#####################################
# Conversion en format pour le programme C
#####################################
final_input_for_c="tmp/filtered_data/input_for_c.csv"
echo "Station:Capacité:Consommation" > "$final_input_for_c"

awk -F';' -v st="$station_type" -v ct="$consumer_type" '
NR>1 {
    station_id = "-"
    capacity = 0
    cons = 0

    if (st == "hvb" && ct == "comp") {
        if ($2 != "-" && $5 == "-" && $6 == "-") {
            station_id = $2
            capacity = ($7 == "-" ? 0 : $7)
            cons = 0
        }
        else if ($2 != "-" && $5 != "-") {
            station_id = $5
            capacity = 0
            cons = ($8 == "-" ? 0 : $8)
        }
    } else if (st=="hva" && ct=="comp") {
        if ($3 != "-" && $5 == "-" && $6 == "-") {
            station_id = $3
            capacity = ($7=="-"?0:$7)
            cons = 0
        } else if ($3 != "-" && $5 != "-") {
            station_id = $5
            capacity = 0
            cons = ($8=="-"?0:$8)
        }
    } else if (st=="lv" && ct=="comp") {
        if ($4 != "-" && $5=="-" && $6=="-" && $7 != "-") {
            station_id = $4
            capacity = ($7=="-"?0:$7)
            cons = 0
        } else if ($4 != "-" && $5 != "-") {
            station_id = $5
            capacity = 0
            cons = ($8=="-"?0:$8)
        }
    } else if (st=="lv" && ct=="indiv") {
        if ($4 != "-" && $5=="-" && $6=="-" && $7 != "-") {
            station_id = $4
            capacity = ($7=="-"?0:$7)
            cons = 0
        } else if ($4 != "-" && $6 != "-") {
            station_id = $6
            capacity = 0
            cons = ($8=="-"?0:$8)
        }
    } else if (st=="lv" && ct=="all") {
        if ($4 != "-" && $5=="-" && $6=="-" && $7 != "-") {
            station_id = $4
            capacity = ($7=="-"?0:$7)
            cons = 0
        } else if ($4 != "-" && $8 != "-") {
            station_id = ($5 != "-" ? $5 : $6)
            capacity = 0
            cons = ($8=="-"?0:$8)
        }
    }

    if (station_id != "-") {
        print station_id ":" capacity ":" cons
    }
}' "$raw_input" >> "$final_input_for_c"

#####################################
# Appel du programme C (envoi également station_type et consumer_type)
#####################################
./codeC/bin/c-wire "$final_input_for_c" "tmp/filtered_data/result_c.csv" "$station_type" "$consumer_type"
if [ $? -ne 0 ]; then
    echo "Erreur: Le programme C a échoué"
    # Afficher le temps écoulé
    end_time=$(date +%s.%N)
    execution_time=$(awk "BEGIN {print $end_time - $process_start_time}")
    echo "Temps d'exécution: ${execution_time}sec"
    exit 1
fi

if [ ! -f "tmp/filtered_data/result_c.csv" ]; then
    echo "Erreur: Le programme C n'a pas créé le fichier result_c.csv"
    end_time=$(date +%s.%N)
    execution_time=$(awk "BEGIN {print $end_time - $process_start_time}")
    echo "Temps d'exécution: ${execution_time}sec"
    exit 1
fi

#####################################
# Trie le fichier par capacité croissante (colonne 2)
#####################################
final_file="tmp/filtered_data/${station_type}_${consumer_type}"
if [ -n "$power_plant_id" ]; then
    final_file="${final_file}_${power_plant_id}"
fi
final_file="${final_file}.csv"

header=$(head -n 1 tmp/filtered_data/result_c.csv)
tail -n +2 tmp/filtered_data/result_c.csv | sort -t: -k2,2n > tmp/filtered_data/sorted.csv
echo "$header" > "$final_file"
cat tmp/filtered_data/sorted.csv >> "$final_file"

#####################################
# Si lv all, création du lv_all_minmax.csv et du graphique
#####################################
if [ "$station_type" == "lv" ] && [ "$consumer_type" == "all" ]; then
    minmax_file="tmp/filtered_data/lv_all_minmax.csv"
    echo "Station:Capacité:Consommation:Difference(Capacity-Consumption)" > "$minmax_file"

    awk -F':' 'NR>1 {
        diff = $2 - $3
        print $1":"$2":"$3":"diff
    }' "$final_file" > tmp/filtered_data/diff.csv

    head_10=$(sort -t: -k4,4n tmp/filtered_data/diff.csv | head -n 10)
    tail_10=$(sort -t: -k4,4n tmp/filtered_data/diff.csv | tail -n 10)

    echo "$head_10" >> "$minmax_file"
    echo "$tail_10" >> "$minmax_file"

    # Génération du script GnuPlot
    cat > graphs/consumption_stats/plot_script.gnu << EOF
set terminal png size 1200,800
set output "graphs/consumption_stats/consumption_graph_lv_all.png"
set style data histograms
set style fill solid 0.8 border -1
set boxwidth 0.7
set title "Les 10 postes LV plus chargés et les 10 moins chargés (lv - all)"
set xlabel "Stations"
set ylabel "Énergie (kWh)"
set grid ytics
set xtics rotate by -45
set datafile separator ":"

plot "tmp/filtered_data/lv_all_minmax.csv" using 2:xtic(1) title "Capacité (kWh)" lc rgb "blue", \
     "tmp/filtered_data/lv_all_minmax.csv" using 3 title "Consommation (kWh)" lc rgb "orange"
EOF

    if command -v gnuplot >/dev/null 2>&1; then
        gnuplot graphs/consumption_stats/plot_script.gnu
    else
        echo "GnuPlot n'est pas installé. Aucun graphique ne sera généré."
    fi
fi

#####################################
# Fin du traitement
#####################################
end_time=$(date +%s.%N)
execution_time=$(awk "BEGIN {print $end_time - $process_start_time}")
echo "Temps d'exécution: ${execution_time}sec"
exit 0
