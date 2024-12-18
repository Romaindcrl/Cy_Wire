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

plot "tmp/filtered_data/lv_all_minmax.csv" using (column(4)<0?-column(4):1/0):xtic(1) with boxes lc rgb "red" title "Surcharge (kWh)",      "" using (column(4)>=0?column(4):1/0) with boxes lc rgb "green" title "Sous-charge (kWh)"
