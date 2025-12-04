#!/usr/bin/env bash
#SBATCH -N 1 # number of nodes
#SBATCH -n 4 # number of cores
#SBATCH --mem 32G # memory pool for all cores
#SBATCH -t 0-32:00 # time (D-HH:MM)
#SBATCH -o /scratch/tizatt/slurm/slurm.telogator_ref.%N.%j.out # STDOUT
#SBATCH -e /scratch/tizatt/slurm/slurm.telogator_ref.%N.%j.err # STDERR
#SBATCH --job-name="telogator_ref"
#SBATCH --mail-type=NONE,FAIL # notifications for job done & fail
#SBATCH --mail-user=tizatt@tgen.org # send-to

while getopts r:o:n:e: flag
do
   case "${flag}" in
        r) ref=${OPTARG};;
        o) dir=${OPTARG};;
        n) name=${OPTARG};;
	e) report=${OPTARG};;
   esac
done
module load SAMtools

t2t_name="${dir}/t2t-${name}"
telogator_ref="${dir}/${name}.ref.fa"

# Step 1
source ~/.bash_profile
mkdir ${dir}
echo "ref: ${ref}"
echo "copying to: ${dir}"
cp ${ref} ${dir}
ref_base=`basename ${ref}`
gunzip ${dir}/${ref_base}
new_ref=${dir}/${ref_base/.gz/}
rename_ref=${new_ref/.fa/.rename.fa}
echo "new ref = ${new_ref}"
echo "rename ref = ${rename_ref}"

# Step 2
conda init
conda activate telogator2
python fasta_renamer.py -r ${report} -i ${new_ref} -o ${rename_ref}

# Step 3
singularity exec -B /scratch -B /home -B /tgen_labs /home/tgenref/containers/samtools-1.16.1_bryce.sif samtools faidx ${rename_ref}

# Step 4
./make_telogator_ref.sh -r ${rename_ref} -n ${name} -o ${telogator_ref}

