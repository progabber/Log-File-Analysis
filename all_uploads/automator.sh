#!/bin/bash

# Your code goes here.
if [[ $# -ne 2 ]]; then
	echo 'Usage: ./automator.sh <path-to-src.txt> <path-to-data_dir>'
	exit 1
fi

SRC="$1"
DATA_DIR="$2"

mkdir -p processed

while read -r file; do
	if [[ -e "${DATA_DIR}/${file}" ]]; then
		cp "${DATA_DIR}/${file}" processed
	fi
done < $SRC

PROC_FILES=$(ls processed)

for myfile in $PROC_FILES; do
	count=0

	while read -r line; do
		if [[ ${line:0:1} == f ]]; then
			(( count++ ))
		fi
	done < "processed/$myfile"

	awk '
	/^T/{
		a = $3
		b = $4
		c = 0
		for (i=2; i <= $2; i++){
			c = 2*b + 3*a
			a = b
			b = c
		}
		if ($2 == 0){
			print $0, $3
		}
		else if($2 == 1){
			print $0, $4
		}
		else{
			print $0, c
		}
	}
	/^factorial/{
		print
	}
	' "processed/${myfile}" > "processed/${count}_${myfile}"
	rm "processed/${myfile}" 
done



