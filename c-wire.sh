#!/bin/bash

display_help() {
    echo "Usage: $0 <chemin_fichier> <type_station> <type_consommateur> [identifiant_centrale] [-h]"
    echo
    echo "Ce script permet de traiter un fichier CSV contenant des données de distribution d'énergie."
    echo "Il filtre puis calcule les consommations associées aux différentes stations (hvb, hva, lv)"
    echo "et types de consommateurs (comp, indiv, all), et produit des fichiers CSV ainsi que des graphiques."
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

for arg in "$@"; do
    if [ "$arg" == "-h" ]; then
        display_help
    fi
done

if [ $# -lt 3 ]; then
    echo "Erreur: Nombre d'arguments insuffisant."
    display_help
fi

echo "Étape 1 : Initialisation des variables..."
input_file=$1
station_type=$2
consumer_type=$3
power_plant_id=${4:-""}

validate_params() {
    local station=$1
    local consumer=$2
    case "$station" in
        "hvb"|"hva"|"lv")
            ;;
        *)
            echo "Erreur: Type de station invalide ($station). Valeurs acceptées : hvb, hva, lv"
            display_help
            ;;
    esac
    case "$consumer" in
        "comp"|"indiv"|"all")
            ;;
        *)
            echo "Erreur: Type de consommateur invalide ($consumer). Valeurs acceptées : comp, indiv, all"
            display_help
            ;;
    esac
    if [[ "$station" == "hvb" && ("$consumer" == "all" || "$consumer" == "indiv") ]]; then
        echo "Erreur: Combinaison interdite - hvb ne peut pas être utilisé avec all ou indiv"
        display_help
    fi
    if [[ "$station" == "hva" && ("$consumer" == "all" || "$consumer" == "indiv") ]]; then
        echo "Erreur: Combinaison interdite - hva ne peut pas être utilisé avec all ou indiv"
        display_help
    fi
}

echo "Étape 2 : Validation des paramètres..."
validate_params "$station_type" "$consumer_type"

if [ ! -f "$input_file" ]; then
    echo "Erreur: Le fichier $input_file n'existe pas."
    echo "Temps d'exécution: 0.0sec"
    exit 1
fi

echo "Étape 3 : Préparation de l'environnement de travail..."
mkdir -p tmp
mkdir -p graphs
mkdir -p output
rm -rf tmp/*
mkdir -p tmp/filtered_data
mkdir -p graphs/consumption_stats

echo "Étape 4 : Vérification du binaire C..."
if [ ! -f "codeC/bin/c-wire" ]; then
    echo "Compilation du programme C..."
    (cd codeC && make clean && make)
    if [ $? -ne 0 ]; then
        echo "Erreur de compilation du programme C"
        echo "Temps d'exécution: 0.0sec"
        exit 1
    fi
fi

process_start_time=$(date +%s.%N)
echo "Étape 5 : Filtrage et préparation du fichier pour le programme C..."

final_input_for_c="tmp/filtered_data/input_for_c.csv"

awk -F';' -v st="$station_type" -v ct="$consumer_type" -v ppid="$power_plant_id" '
BEGIN {
    print "Station:Capacité:Consommation"
}
NR > 1 {
    if (ppid != "" && $1 != ppid) {
        next
    }
    station_id = "-"
    capacity = 0
    cons = 0
    if (st == "hvb" && ct == "comp") {
        if (($2 != "-" && $5 == "-" && $6 == "-") || ($2 != "-" && $5 != "-")) {
            if ($5 == "-") {
                station_id = $2
                capacity = ($7 == "-" ? 0 : $7)
                cons = 0
            } else {
                station_id = $2
                capacity = 0
                cons = ($8 == "-" ? 0 : $8)
            }
        }
    }
    else if (st == "hva" && ct == "comp") {
        if (($3 != "-" && $5 == "-" && $6 == "-") || ($3 != "-" && $5 != "-")) {
            if ($5 == "-") {
                station_id = $3
                capacity = ($7 == "-" ? 0 : $7)
                cons = 0
            } else {
                station_id = $3
                capacity = 0
                cons = ($8 == "-" ? 0 : $8)
            }
        }
    }
    else if (st == "lv") {
        if (ct=="comp") {
            if (($4 != "-" && $5 == "-" && $6 == "-") || ($4 != "-" && $5 != "-")) {
                if ($5 == "-") {
                    station_id = $4
                    capacity = ($7 == "-" ? 0 : $7)
                    cons = 0
                } else {
                    station_id = $4
                    capacity = 0
                    cons = ($8 == "-" ? 0 : $8)
                }
            }
        }
        else if (ct=="indiv") {
            if (($4 != "-" && $5 == "-" && $6 == "-") || ($4 != "-" && $6 != "-")) {
                if ($6 == "-") {
                    station_id = $4
                    capacity = ($7 == "-" ? 0 : $7)
                    cons = 0
                } else {
                    station_id = $4
                    capacity = 0
                    cons = ($8 == "-" ? 0 : $8)
                }
            }
        }
        else if (ct=="all") {
            if (($4 != "-" && $5 == "-" && $6 == "-") || ($4 != "-" && $8 != "-")) {
                if ($5 == "-" && $6 == "-") {
                    station_id = $4
                    capacity = ($7 == "-" ? 0 : $7)
                    cons = 0
                } else {
                    station_id = $4
                    capacity = 0
                    cons = ($8 == "-" ? 0 : $8)
                }
            }
        }
    }
    if (station_id != "-") {
        print station_id ":" capacity ":" cons
    }
}
' "$input_file" > "$final_input_for_c"

echo "Étape 6 : Exécution du programme C..."
./codeC/bin/c-wire "$final_input_for_c" "tmp/filtered_data/result_c.csv" "$station_type" "$consumer_type"
if [ $? -ne 0 ]; then
    echo "Erreur: Le programme C a échoué"
    end_time=$(date +%s.%N)
    execution_time=$(awk -v start="$process_start_time" -v end="$end_time" 'BEGIN { print end - start }')
    echo "Temps d'exécution: ${execution_time}sec"
    exit 1
fi

if [ ! -f "tmp/filtered_data/result_c.csv" ]; then
    echo "Erreur: Le programme C n'a pas créé le fichier result_c.csv"
    end_time=$(date +%s.%N)
    execution_time=$(awk -v start="$process_start_time" -v end="$end_time" 'BEGIN { print end - start }')
    echo "Temps d'exécution: ${execution_time}sec"
    exit 1
fi

echo "Étape 7 : Finalisation du fichier CSV..."

final_file="output/${station_type}_${consumer_type}"
if [ -n "$power_plant_id" ]; then
    final_file="${final_file}_${power_plant_id}"
fi
final_file="${final_file}.csv"

header=$(head -n 1 tmp/filtered_data/result_c.csv)
tail -n +2 tmp/filtered_data/result_c.csv > tmp/filtered_data/data_noheader.csv
echo "$header" > "$final_file"
cat tmp/filtered_data/data_noheader.csv >> "$final_file"

if [ "$station_type" == "lv" ] && [ "$consumer_type" == "all" ]; then
    echo "Étape 8 : Calcul des min/max et génération d'un graphique..."
    minmax_file="output/lv_all_minmax.csv"
    echo "Station:Capacité:Consommation:Difference(Capacity-Consumption)" > "$minmax_file"
    awk -F':' 'NR>1 {
        diff = $2 - $3
        print $1":"$2":"$3":"diff
    }' "$final_file" > tmp/filtered_data/diff.csv
    total_lines=$(wc -l < tmp/filtered_data/diff.csv)
    if [ $total_lines -ge 20 ]; then
        head_10=$(sort -t: -k4,4n tmp/filtered_data/diff.csv | head -n 10)
        tail_10=$(sort -t: -k4,4n tmp/filtered_data/diff.csv | tail -n 10)
        echo "$head_10" >> "$minmax_file"
        echo "$tail_10" >> "$minmax_file"
    else
        sort -t: -k4,4n tmp/filtered_data/diff.csv >> "$minmax_file"
    fi
    cat > graphs/consumption_stats/plot_script.gnu << EOF
set terminal png size 1400,800
set output "graphs/consumption_stats/consumption_graph_lv_all_minmax.png"
set title "Les 10 postes LV les plus chargés et les 10 moins chargés (lv - all)"
set xlabel "Stations"
set ylabel "Énergie (kWh) [échelle logarithmique]"
set grid ytics
set xtics rotate by -45
set logscale y
set style fill solid border -1
set boxwidth 0.7
set datafile separator ":"
plot "output/lv_all_minmax.csv" using (column(4)<0?-column(4):1/0):xtic(1) with boxes lc rgb "red" title "Surcharge (kWh)", \
     "" using (column(4)>=0?column(4):1/0) with boxes lc rgb "green" title "Sous-charge (kWh)"
EOF
    if command -v gnuplot >/dev/null 2>&1; then
        gnuplot graphs/consumption_stats/plot_script.gnu
    else
        echo "GnuPlot n'est pas installé. Aucun graphique ne sera généré."
    fi
fi

echo "Étape 9 : Nettoyage et affichage du temps d'exécution..."
end_time=$(date +%s.%N)
execution_time=$(awk -v start="$process_start_time" -v end="$end_time" 'BEGIN { print end - start }')
echo "Temps d'exécution: ${execution_time}sec"
exit 0