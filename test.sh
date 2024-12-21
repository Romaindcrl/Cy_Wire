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

# Fonction pour exécuter une commande et vérifier le résultat
run_test() {
    local cmd="$1"
    local description="$2"
    echo "[TEST] $description"
    echo "$cmd"
    eval "$cmd"
    echo "-----------------------"
}

# Tests valides : toutes les combinaisons valides de station et consommateur
for station in "${STATIONS[@]}"; do
    for consumer in "${CONSUMERS[@]}"; do
        if [[ ! " ${INVALID_COMBOS[@]} " =~ "${station}:${consumer}" ]]; then
            for plant_id in "${POWER_PLANT_IDS[@]}"; do
                desc="Test valide: station=$station, consommateur=$consumer, centrale=${plant_id}"
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
    desc="Test invalide: combinaison interdite station=$station, consommateur=$consumer"
    cmd="./c-wire.sh $INPUT_FILE $station $consumer"
    run_test "$cmd" "$desc"
done

# Test de l'option d'aide
run_test "./c-wire.sh -h" "Test de l'aide"

# Test avec un fichier inexistant
run_test "./c-wire.sh missing_file.csv hvb comp" "Test avec fichier inexistant"

# Test avec trop peu d'arguments
run_test "./c-wire.sh $INPUT_FILE hvb" "Test avec arguments insuffisants"

# Test avec trop d'arguments
run_test "./c-wire.sh $INPUT_FILE hvb comp 1 extra_arg" "Test avec trop d'arguments"

# Résumé
echo "Tous les tests ont été exécutés."
