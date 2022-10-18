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
            set output "${dir_name}/CPU-usage.png"
            set title "CPU Usage for Process ID $pid"
            plot "$csv_filename" using 2:xticlabels(1) with lines smooth unique lw 2 lt rgb "#4848d6" t "CPU usage"
            set output "${dir_name}/TCP-usage.png"
            set title "TCP Usage for Process ID $pid"
            plot "$csv_filename" using 3:xticlabels(1) with lines smooth unique lw 2 lt rgb "#ed8004" t "TCP usage"
            set output "${dir_name}/thread_count.png"
            set title "Thread count for Process ID $pid"
            plot "$csv_filename" using 4:xticlabels(1) with lines smooth unique lw 2 lt rgb "#48d65b" t "Thread count"

            
EOF
    fi

    echo "Done!"
    exit 0
}

trap "plotGraph" SIGINT SIGTERM SIGKILL

echo "Writing data to CSV file $csv_filename..."
touch $csv_filename

echo "Time,CPU,TCP connections,Thread count" >> $csv_filename

kill -0 $pid > /dev/null 2>&1
pid_exist=$?

while [ $pid_exist == 0 ]; do
    kill -0 $pid > /dev/null 2>&1
    pid_exist=$?

    if [ $pid_exist == 0 ]; then
        timestamp=$(date +"%b %d %H:%M:%S")
        cpu_usage=$(top -b -n 1 | grep -w -E "^ *$pid" | awk '{print $9}')
        tcp_cons=$(lsof -i -a -p $pid -w | tail -n +2 | wc -l)
        tcount=$(ps -o nlwp h $pid | tr -d ' ')

        echo "$timestamp,$cpu_usage,$tcp_cons,$tcount" >> $csv_filename
        sleep 5
    fi
done

plotGraph