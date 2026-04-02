#!/bin/bash
samtools='singularity exec -B /scratch -B /home -B /tgen_labs /home/tgenref/containers/samtools-1.16.1_bryce.sif samtools'
# Path to the mapping file you generated (Accession <tab> Combined_Name)
mammals_map="samples.txt"
combine="no"
# Directories from your original script
fa_dir="/scratch/achan/new.vgp.assembly-12/asm.fasta"
#assembly_dir="/tgen_labs/schork/projects2/Data/HPRC_intermediate_r2.etc/asm.report/"
assembly_dir="/scratch/achan/new.vgp.assembly-12/asm.report"
#assembly_dir="/tgen_labs/schork/projects2/Data/VGP/VGP-asm.report/"
#assembly_dir="/tgen_labs/schork/projects2/Data/VGP/reference.genomes/whales/assembly_report/"
out_dir="/scratch/tizatt/schork/reference/"
#out_dir="/tgen_labs/schork/projects2/Data/TELOMERE/telogator/reference"

# Check if the mapping file exists
if [ ! -f "$mammals_map" ]; then
    echo "Error: Mapping file $mammals_map not found."
    exit 1
fi

job_ids=""
# Loop through the mapping file, skipping the header line
# IFS=$'\t' ensures we split by tabs, not spaces
while IFS=$'\t' read -r accession; do
    
    # 1. Search for the FASTA file in fa_dir containing the accession ID
    # We use 'find' to handle potential subdirectories and 'head -n 1' just in case
    fa_path=$(find "${fa_dir}" -name "*${accession}*.fna" | head -n 1)
    #fa_path=$(find "${fa_dir}" -name "*${accession}*.fa.gz" | head -n 1)
    
    # 2. Search for the assembly report in assembly_dir containing the accession ID
    assembly_report_path=$(find "${assembly_dir}" -name "*${accession}*assembly_report.txt" | head -n 1)

    # 3. Check if both files were found before echoing the command
    if [[ -n "$fa_path" && -n "$assembly_report_path" ]]; then
        out_path="${out_dir}/${accession}"
        # Use the Combined_Name as the -n variable
	job_id=$(sbatch --parsable prep_telogator_ref.sh -r ${fa_path} -o ${out_path} -n ${accession} -e ${assembly_report_path})
	if [ -z "$job_ids" ]; then 
            job_ids="$job_id"
        else 
            job_ids="$job_ids:$job_id"
        fi
        echo ${job_ids}
	sleep 1
    else
        # Optional: Print a warning if files are missing for an accession
        echo "${accession} not found"
    fi
done < <(tail -n +2 "$mammals_map")
echo "job_ids=${job_ids}"
if [ ${combine} == "yes" ]; then
    echo "Scheduling merge job to wait for IDs: $job_ids"
    # We use a glob (subfolder/*.fa) to find the files. 
    # The --wrap command will run after all previous jobs finish successfully.
    sbatch --dependency=afterok:${job_ids} \
           --job-name=merge_telogator \
           --mem=8G \
           --wrap="cat ${out_dir}/*/*.fa > ${out_dir}/combined_telogator_ref.fa && ${samtools} faidx ${out_dir}/combined_telogator_ref.fa"
fi

