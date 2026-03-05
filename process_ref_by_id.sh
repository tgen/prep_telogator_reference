#!/bin/bash

# Path to the mapping file you generated (Accession <tab> Combined_Name)
mammals_map="rerun.asm.samples.txt"

# Directories from your original script
fa_dir="/tgen_labs/schork/projects2/Data/VGP/assembly_UCSC.download__VGP.freeze1/primary/"
#fa_dir="/tgen_labs/schork/projects2/Data/VGP/reference.genomes/whales"
#fa_dir="/tgen_labs/schork/projects2/Data/HPRC_intermediate_r2.etc/asm.fasta/"
#assembly_dir="/tgen_labs/schork/projects2/Data/HPRC_intermediate_r2.etc/asm.report/"
assembly_dir="/tgen_labs/schork/projects2/Data/VGP/VGP-asm.report/assembly_report/"
#assembly_dir="/tgen_labs/schork/projects2/Data/VGP/reference.genomes/whales/assembly_report/"
out_dir="/scratch/tizatt/schork/reference/"
#out_dir="/tgen_labs/schork/projects2/Data/TELOMERE/telogator/reference"

# Check if the mapping file exists
if [ ! -f "$mammals_map" ]; then
    echo "Error: Mapping file $mammals_map not found."
    exit 1
fi

# Loop through the mapping file, skipping the header line
# IFS=$'\t' ensures we split by tabs, not spaces
tail -n +2 "$mammals_map" | while IFS=$'\t' read -r accession; do
    
    # 1. Search for the FASTA file in fa_dir containing the accession ID
    # We use 'find' to handle potential subdirectories and 'head -n 1' just in case
    find "${fa_dir}" -name "*${accession}*.fa.gz"
    fa_path=$(find "${fa_dir}" -name "*${accession}*.fa.gz" | head -n 1)
    
    # 2. Search for the assembly report in assembly_dir containing the accession ID
    assembly_report_path=$(find "${assembly_dir}" -name "*${accession}*assembly_report.txt" | head -n 1)

    # 3. Check if both files were found before echoing the command
    if [[ -n "$fa_path" && -n "$assembly_report_path" ]]; then
        out_path="${out_dir}/${accession}"
        # Use the Combined_Name as the -n variable
        sbatch prep_telogator_ref.sh -r ${fa_path} -o ${out_path} -n ${accession} -e ${assembly_report_path}
	sleep 2
    else
        # Optional: Print a warning if files are missing for an accession
        echo "${accession} not found"
    fi
done
