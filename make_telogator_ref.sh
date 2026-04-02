#!/usr/bin/env bash
#SBATCH -N 1 # number of nodes
#SBATCH -n 4 # number of cores
#SBATCH --mem 32G # memory pool for all cores
#SBATCH -t 0-32:00 # time (D-HH:MM)
#SBATCH --job-name="telogator"
#SBATCH --mail-type=NONE,FAIL # notifications for job done & fail


telogator_path="make_telogator_ref.py"

kmers="resources/kmers.tsv"

while getopts r:o:n: flag
do
   case "${flag}" in
	r) ref=${OPTARG};;
	o) output=${OPTARG};;
	n) name=${OPTARG};;
   esac
done

CHROM_LIST=$(grep '^>' "${ref}" | grep -v 'chrUn' | sed 's/^>//' | tr '\n' ',' | sed 's/,$//')
echo $CHROM_LIST
python ${telogator_path} \
	-i ${ref} \
	-o ${output} \
	-s ${name} \
	-c ${CHROM_LIST} \
	-r ${CHROM_LIST} \
        -k ${kmers} \
	--add-tel
