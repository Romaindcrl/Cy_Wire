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

plot "tmp/filtered_data/lv_all_minmax.csv" using 2:xtic(1) title "Capacité (kWh)" lc rgb "blue",      "tmp/filtered_data/lv_all_minmax.csv" using 3 title "Consommation (kWh)" lc rgb "orange"
