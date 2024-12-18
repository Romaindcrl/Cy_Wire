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

validate_params "$station_type" "$consumer_type"

if [ ! -f "$input_file" ]; then
    echo "Erreur: Le fichier $input_file n'existe pas."
    echo "Temps d'exécution: 0.0sec"
    exit 1
fi

mkdir -p tmp
mkdir -p graphs
rm -rf tmp/*
mkdir -p tmp/filtered_data
mkdir -p graphs/consumption_stats

if [ ! -f "codeC/bin/c-wire" ]; then
    (cd codeC && make clean && make)
    if [ $? -ne 0 ]; then
        echo "Erreur de compilation du programme C"
        echo "Temps d'exécution: 0.0sec"
        exit 1
    fi
fi

process_start_time=$(date +%s.%N)

raw_input="tmp/filtered_data/raw_input_for_c.csv"
echo "PowerPlant;HVB;HVA;LV;Company;Individual;Capacity;Load" > "$raw_input"

awk -F';' -v st="$station_type" -v ct="$consumer_type" -v ppid="$power_plant_id" '
NR > 1 {
    if (ppid != "" && $1 != ppid) {
        next
    }

    if (st == "hvb" && ct == "comp") {
        # On garde les lignes des HVB stations et des consommations entreprises HVB
        if (($2 != "-" && $5 == "-" && $6 == "-" && $7 != "-") ||  # station HVB
            ($2 != "-" && $5 != "-" && $8 != "-")) {              # consommateur entreprise HVB
            print $0
        }
    } else if (st == "hva" && ct == "comp") {
        # Lignes de stations HVA et consommateurs entreprises HVA
        if (($3 != "-" && $5 == "-" && $6 == "-" && $7 != "-") ||  # station HVA
            ($3 != "-" && $5 != "-" && $8 != "-")) {               # consommateur entreprise HVA
            print $0
        }
    } else if (st == "lv" && ct == "comp") {
        # Lignes de stations LV et consommateurs entreprises LV
        if (($4 != "-" && $5 == "-" && $6 == "-" && $7 != "-") ||   # station LV
            ($4 != "-" && $5 != "-" && $8 != "-")) {                # consommateur entreprise LV
            print $0
        }
    } else if (st == "lv" && ct == "indiv") {
        # Lignes de stations LV et consommateurs particuliers LV
        if (($4 != "-" && $5 == "-" && $6 == "-" && $7 != "-") ||   # station LV
            ($4 != "-" && $6 != "-" && $8 != "-")) {                # consommateur particulier LV
            print $0
        }
    } else if (st == "lv" && ct == "all") {
        # Lignes de stations LV et tous consommateurs LV (entreprises ou particuliers)
        if (($4 != "-" && $5 == "-" && $6 == "-" && $7 != "-") ||   # station LV
            ($4 != "-" && $8 != "-")) {                             # consommateur LV (entreprise ou particulier)
            print $0
        }
    }
}
' "$input_file" >> "$raw_input"

final_input_for_c="tmp/filtered_data/input_for_c.csv"
echo "Station:Capacité:Consommation" > "$final_input_for_c"

awk -F';' -v st="$station_type" -v ct="$consumer_type" '
NR>1 {
    station_id = "-"
    capacity = 0
    cons = 0

    if (st == "hvb" && ct == "comp") {
        # station HVB: $2 != "-" et entreprise connectée à HVB: $2 != "-" et $5 != "-"
        # Pour les stations HVB, station_id = $2
        # Pour les consommateurs HVB, station_id = $2 (pas $5!)
        if ($2 != "-" && $5 == "-" && $6 == "-") {
            # Station HVB
            station_id = $2
            capacity = ($7 == "-" ? 0 : $7)
            cons = 0
        } else if ($2 != "-" && $5 != "-") {
            # Consommateur entreprise HVB
            station_id = $2
            capacity = 0
            cons = ($8 == "-" ? 0 : $8)
        }

    } else if (st=="hva" && ct=="comp") {
        # Station HVA: $3 != "-"
        # Consommateur HVA: $3 != "-" et $5 != "-"
        # station_id = $3 pour les deux cas
        if ($3 != "-" && $5 == "-" && $6 == "-") {
            # Station HVA
            station_id = $3
            capacity = ($7=="-"?0:$7)
            cons = 0
        } else if ($3 != "-" && $5 != "-") {
            # Consommateur entreprise HVA
            station_id = $3
            capacity = 0
            cons = ($8=="-"?0:$8)
        }

    } else if (st=="lv") {
        # Station LV: $4 != "-"
        # Consommateurs LV (entreprise ou particulier): toujours station_id = $4
        if (ct=="comp") {
            if ($4 != "-" && $5=="-" && $6=="-" && $7 != "-") {
                # Station LV
                station_id = $4
                capacity = ($7=="-"?0:$7)
                cons = 0
            } else if ($4 != "-" && $5 != "-") {
                # Entreprise LV
                station_id = $4
                capacity = 0
                cons = ($8=="-"?0:$8)
            }
        } else if (ct=="indiv") {
            if ($4 != "-" && $5=="-" && $6=="-" && $7 != "-") {
                # Station LV
                station_id = $4
                capacity = ($7=="-"?0:$7)
                cons = 0
            } else if ($4 != "-" && $6 != "-") {
                # Particulier LV
                station_id = $4
                capacity = 0
                cons = ($8=="-"?0:$8)
            }
        } else if (ct=="all") {
            if ($4 != "-" && $5=="-" && $6=="-" && $7 != "-") {
                # Station LV
                station_id = $4
                capacity = ($7=="-"?0:$7)
                cons = 0
            } else if ($4 != "-" && $8 != "-") {
                # Consommateur LV (entreprise ou particulier)
                station_id = $4
                capacity = 0
                cons = ($8=="-"?0:$8)
            }
        }
    }

    if (station_id != "-") {
        print station_id ":" capacity ":" cons
    }
}' "$raw_input" >> "$final_input_for_c"

./codeC/bin/c-wire "$final_input_for_c" "tmp/filtered_data/result_c.csv" "$station_type" "$consumer_type"
if [ $? -ne 0 ]; then
    echo "Erreur: Le programme C a échoué"
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

final_file="tmp/filtered_data/${station_type}_${consumer_type}"
if [ -n "$power_plant_id" ]; then
    final_file="${final_file}_${power_plant_id}"
fi
final_file="${final_file}.csv"

header=$(head -n 1 tmp/filtered_data/result_c.csv)
tail -n +2 tmp/filtered_data/result_c.csv | sort -t: -k2,2n > tmp/filtered_data/sorted.csv
echo "$header" > "$final_file"
cat tmp/filtered_data/sorted.csv >> "$final_file"

if [ "$station_type" == "lv" ] && [ "$consumer_type" == "all" ]; then
    minmax_file="tmp/filtered_data/lv_all_minmax.csv"
    echo "Station:Capacité:Consommation:Difference(Capacity-Consumption)" > "$minmax_file"

    awk -F':' 'NR>1 {
        diff = $2 - $3
        print $1":"$2":"$3":"diff
    }' "$final_file" > tmp/filtered_data/diff.csv

    # Tri par valeur absolue de la différence
    head_10=$(sort -t: -k4,4n tmp/filtered_data/diff.csv | head -n 10)
    tail_10=$(sort -t: -k4,4n tmp/filtered_data/diff.csv | tail -n 10)

    echo "$head_10" >> "$minmax_file"
    echo "$tail_10" >> "$minmax_file"

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

plot "tmp/filtered_data/lv_all_minmax.csv" using (column(4)<0?-column(4):1/0):xtic(1) with boxes lc rgb "red" title "Surcharge (kWh)", \
     "" using (column(4)>=0?column(4):1/0) with boxes lc rgb "green" title "Sous-charge (kWh)"
EOF

    if command -v gnuplot >/dev/null 2>&1; then
        gnuplot graphs/consumption_stats/plot_script.gnu
    else
        echo "GnuPlot n'est pas installé. Aucun graphique ne sera généré."
    fi
fi

end_time=$(date +%s.%N)
execution_time=$(awk "BEGIN {print $end_time - $process_start_time}")
echo "Temps d'exécution: ${execution_time}sec"
exit 0
