#!/bin/bash

# Chemin vers le fichier de données d'entrée
INPUT_FILE="input/data.csv"

# Vérification que le fichier d'entrée existe
if [ ! -f "$INPUT_FILE" ]; then
    echo "Le fichier $INPUT_FILE est manquant. Veuillez le placer dans le répertoire 'input'."
    exit 1
fi

# Liste des paramètres valides et invalides
STATIONS=("hvb" "hva" "lv")
CONSUMERS=("comp" "indiv" "all")
INVALID_COMBOS=("hvb:all" "hvb:indiv" "hva:all" "hva:indiv")
POWER_PLANT_IDS=("1" "2" "3" "")

# Fonction pour exécuter une commande et sauvegarder les résultats
run_test() {
    local cmd="$1"
    local description="$2"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local test_dir="tests/${description// /_}_$timestamp"

    mkdir -p "$test_dir"

    echo "[TEST] $description"
    echo "$cmd"

    # Exécution de la commande avec répertoire temporaire et redirection des sorties
    TMP_DIR="$test_dir/tmp"
    OUTPUT_DIR="$test_dir/output"
    GRAPHS_DIR="$test_dir/graphs"

    mkdir -p "$TMP_DIR" "$OUTPUT_DIR" "$GRAPHS_DIR"

    TMP_DIR="$TMP_DIR" OUTPUT_DIR="$OUTPUT_DIR" GRAPHS_DIR="$GRAPHS_DIR" eval "$cmd" > "$test_dir/stdout.log" 2> "$test_dir/stderr.log"

    # Copie des fichiers de sortie et graphiques dans le dossier de test
    if [ -d "tmp" ]; then
        cp -r tmp/* "$TMP_DIR/"
    fi
    if [ -d "output" ]; then
        cp -r output/* "$OUTPUT_DIR/"
    fi
    if [ -d "graphs" ]; then
        cp -r graphs/* "$GRAPHS_DIR/"
    fi

    echo "Résultats enregistrés dans $test_dir"
    echo "-----------------------"
}

# Tests valides : toutes les combinaisons valides de station et consommateur
for station in "${STATIONS[@]}"; do
    for consumer in "${CONSUMERS[@]}"; do
        if [[ ! " ${INVALID_COMBOS[@]} " =~ "${station}:${consumer}" ]]; then
            for plant_id in "${POWER_PLANT_IDS[@]}"; do
                desc="Test_valide_station=${station}_consommateur=${consumer}_centrale=${plant_id}"
                cmd="./c-wire.sh $INPUT_FILE $station $consumer $plant_id"
                run_test "$cmd" "$desc"
            done
        fi
    done
done

# Tests invalides : combinaisons interdites
for combo in "${INVALID_COMBOS[@]}"; do
    station=$(echo "$combo" | cut -d: -f1)
    consumer=$(echo "$combo" | cut -d: -f2)
    desc="Test_invalide_combinaison_station=${station}_consommateur=${consumer}"
    cmd="./c-wire.sh $INPUT_FILE $station $consumer"
    run_test "$cmd" "$desc"
done

# Test de l'option d'aide
run_test "./c-wire.sh -h" "Test_aide"

# Test avec un fichier inexistant
run_test "./c-wire.sh missing_file.csv hvb comp" "Test_fichier_inexistant"

# Test avec trop peu d'arguments
run_test "./c-wire.sh $INPUT_FILE hvb" "Test_arguments_insuffisants"

# Test avec trop d'arguments
run_test "./c-wire.sh $INPUT_FILE hvb comp 1 extra_arg" "Test_trop_arguments"

# Résumé
echo "Tous les tests ont été exécutés."
