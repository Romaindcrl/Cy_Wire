set terminal png size 1200,800
set output "graphs/consumption_stats/consumption_graph_hva_comp.png"
set style data histograms
set style fill solid 0.8 border -1
set boxwidth 0.7
set title "Consommation et Capacité (hva - comp)"
set xlabel "Stations"
set ylabel "Énergie (kWh)"
set grid ytics
set xtics rotate by -45
set datafile separator ":"

# Tracer les données
plot "tmp/filtered_data/hva_comp_minmax.csv" using 2:xtic(1) title "Capacité (kWh)" lc rgb "blue",      "tmp/filtered_data/hva_comp_minmax.csv" using 3 title "Consommation (kWh)" lc rgb "orange"
