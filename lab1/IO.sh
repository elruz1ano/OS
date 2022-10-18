#!/bin/bash

pid=$1

if [ -z $1 ]; then
    echo "ERROR: Process ID not specified"
    echo
    echo "Usage: $(basename "$0") <PID>"
    exit 1
fi

kill -0 $pid > /dev/null 2>&1
pid_exist=$?

if [ $pid_exist != 0 ]; then
    echo "ERROR: Process ID $PID not found."
    exit 1
fi

current_time=$(date +"%Y_%m_%d_%H%M")
dir_name="data/Io_statistics/${pid}-${current_time}"
csv_filename="${dir_name}/metrics.csv"

mkdir -p $dir_name

function plotGraph() {
    if [ -f $csv_filename ]; then
        echo "Plotting graphs..."
        gnuplot <<- EOF
            set term pngcairo size 1024,800 noenhanced font "Helvetica,10"
            set border ls 50 lt rgb "#939393"
            set border 16 lw 0
            set border 64 lw 0
            set tics nomirror textcolor rgb "#939393"
            set grid ytics lt 1 lc rgb "#d8d8d8" lw 2
            set xtics rotate
            set size 1,0.85
            set datafile separator ","
            set key bmargin center box lt rgb "#d8d8d8" horizontal
            set output "${dir_name}/IO-usage.png"
            set title "IO Usage for Process ID $pid"
            plot "$csv_filename" using 2:xticlabels(1) with lines smooth unique lw 2 lt rgb "#4848d6" t "IO read",\
             "$csv_filename" using 3:xticlabels(1) with lines smooth unique lw 2 lt rgb "#b40000" t "IO write"
            
EOF
    fi

    echo "Done!"
    exit 0
}

trap "plotGraph" SIGINT SIGTERM SIGKILL


echo "Writing data to CSV file $csv_filename..."
touch $csv_filename

echo "Time,IO_read,IO_write" >> $csv_filename

kill -0 $pid > /dev/null 2>&1
pid_exist=$?

while [ $pid_exist == 0 ]; do
    kill -0 $pid > /dev/null 2>&1
    pid_exist=$?

    if [ $pid_exist == 0 ]; then
        timestamp=$(date +"%b %d %H:%M:%S")
        io_read=$(echo "scale=7; 0.00" | bc)
        io_write=$(echo "scale=7; 0.00" | bc)
        pids=$(pstree -p ${pid} | grep -o -E '\(\w+\)' | grep -o -E '\w+')
        for item_pid in ${pids[@]}
        do
            io=$(sudo iotop --only -qqq -b -n 1 -p ${item_pid})
            if [[ "$io" != "" ]]; then
                io_read_cur=$(echo $io | awk '{ print $4 }')
                io_write_cur=$(echo $io | awk '{ print $6 }')

            else
                io_read_cur="0"
                io_write_cur="0"
            fi

            if [[ "io_read_cur" == "" ]]; then
                io_read_cur=$(echo "scale=7; 0.00" | bc)
            fi

            if [[ "io_write_cur" == "" ]]; then
                io_write_cur=$(echo "scale=7; 0.00" | bc)
            fi

            io_read=$(echo "scale=7;$io_read+$io_read_cur" | bc)
            io_write=$(echo "scale=7;$io_write+$io_write_cur" | bc)

        done

        echo "$timestamp,$io_read,$io_write" >> $csv_filename
        sleep 5
    fi

done

plotGraph
