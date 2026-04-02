#!/usr/bin/env bash
#SBATCH -N 1 # number of nodes
#SBATCH --mem 16G # memory pool for all cores
#SBATCH -t 0-1:00 # time (D-HH:MM)
#SBATCH --job-name="telogator_ref"
#SBATCH --mail-type=NONE,FAIL # notifications for job done & fail

while getopts r:o:n:e: flag
do
   case "${flag}" in
        r) ref=${OPTARG};;
        o) dir=${OPTARG};;
        n) name=${OPTARG};;
	e) report=${OPTARG};;
   esac
done

name2=${name/_/-}
t2t_name="${dir}/t2t-${name2}"
telogator_ref="${dir}/${name}.fa"

# Step 1
source ~/.bash_profile
mkdir ${dir}
echo "ref: ${ref}"
echo "copying to: ${dir}"
ref_base=`basename ${ref}`
cp ${ref} ${dir}/${ref_base}
gunzip ${dir}/${ref_base}
new_ref=${dir}/${ref_base/.fa.gz/.fa}
rename_ref=${new_ref/.fa/.rename.fa}
echo "new ref = ${new_ref}"
echo "rename ref = ${rename_ref}"

# Step 2
python fasta_renamer.py -r ${report} -i ${new_ref} -o ${rename_ref}
echo "RENAME REF=${rename_ref}"

#./generate_qc_500kb_ref.sh ${rename_ref} ${dir}/QC/ ${name}
# Step 3
samtools faidx ${rename_ref}

# Step 4
./make_telogator_ref.sh -r ${rename_ref} -n ${name2} -o ${telogator_ref}
