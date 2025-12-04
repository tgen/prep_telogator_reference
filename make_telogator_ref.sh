#!/usr/bin/env bash
#SBATCH -N 1 # number of nodes
#SBATCH -n 4 # number of cores
#SBATCH --mem 32G # memory pool for all cores
#SBATCH -t 0-32:00 # time (D-HH:MM)
#SBATCH -o /scratch/tizatt/slurm/slurm.telogator.%N.%j.out # STDOUT
#SBATCH -e /scratch/tizatt/slurm/slurm.telogator.%N.%j.err # STDERR
#SBATCH --job-name="telogator"
#SBATCH --mail-type=NONE,FAIL # notifications for job done & fail
#SBATCH --mail-user=tizatt@tgen.org # send-to


telogator_path="/home/tizatt/tools/telogator2_dev/make_telogator_ref.py"
#ref="/scratch/tizatt/telogator2/reference/pygmy_brydes_whale/GCA_052818205.1_BalEdn.hic.v1_genomic.chr.fna"
kmers="/home/tizatt/tools/telogator2_dev/resources/kmers.tsv"
#telegator_ref_out="/scratch/tizatt/telogator2/reference/pygmy_brydes_whale/pygmy_brydes_whale_telegator_ref.fa"
conda init
conda activate telogator2

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
