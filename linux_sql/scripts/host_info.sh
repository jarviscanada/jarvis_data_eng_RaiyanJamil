#!/bin/bash

# Setup and validate arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Check # of args
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Save machine statistics in MB and current machine hostname to variables
hostname=$(hostname -f)

# Retrieve variables
hostname=$(hostname -f)
cpu_number=$(lscpu  | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(lscpu  | egrep "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(lscpu | grep -oP "^Model name:\K.*" | xargs)
cpu_mhz=$(grep -m1 "cpu MHz" /proc/cpuinfo | awk '{printf "%.2f\n", $4}')
l2_cache=$(cat /sys/devices/system/cpu/cpu0/cache/index2/size | sed 's/K//')
total_mem=$(vmstat --unit M | tail -1 | awk '{print $4}')

# Current time in `2019-11-26 14:40:19` UTC format
timestamp=$(TZ=UTC vmstat -t | awk '{print $18, $19}' | tail -n1 | xargs)

# PSQL command: Inserts server usage data into host_info table
# Note: be careful with double and single quotes
insert_stmt="INSERT INTO host_info (hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem) VALUES('$hostname', '$cpu_number', '$cpu_architecture', '$cpu_model', '$cpu_mhz', '$l2_cache', '$timestamp', '$total_mem');"

#set up env var for psql cmd
export PGPASSWORD=$psql_password 
#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?
