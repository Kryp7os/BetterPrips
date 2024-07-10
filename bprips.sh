#!/bin/bash

############################
##  Methods
############################

expand_cidr() {
    local cidr=$1
    local ip=$(echo $cidr | cut -d '/' -f 1)
    local prefix=$(echo $cidr | cut -d '/' -f 2)
    local IFS=.
    local -a octets=($ip)
    local bin_ip=""

    for octet in "${octets[@]}"; do
        bin_ip+=$(echo "obase=2; $octet" | bc | awk '{printf "%08d", $0}')
    done

    local num_ips=$(( 1 << (32 - prefix) ))
    local range_start=$(echo "ibase=2; $bin_ip" | bc)
    local range_end=$((range_start + num_ips - 1))

    for (( ip=range_start; ip<=range_end; ip++ )); do
        local ip1=$((ip>>24 & 0xFF))
        local ip2=$((ip>>16 & 0xFF))
        local ip3=$((ip>>8 & 0xFF))
        local ip4=$((ip & 0xFF))
        echo "${ip1}.${ip2}.${ip3}.${ip4}"
    done
}

#############################
##  MAIN
#############################
if [ $# -eq 0 ]; then
    echo "No arguments provided. Usage: $0 -f <inputfile>"
    exit 1
fi

while getopts ":f:" opt; do
    case $opt in
        f)
            file="$OPTARG"
            if [ ! -f "$file" ]; then
                echo "File not found: $file"
                exit 1
            fi
            while IFS= read -r line; do
                if echo "$line" | grep -q '/'; then  # Check if the line contains a CIDR notation
                    expand_cidr "$line"
                else
                    echo "$line"  # Output the line as is if it's not a CIDR notation
                fi
            done < "$file"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
