#!/bin/bash
# generate_500kb_ref.sh

ORIG_REF=$1
OUT_DIR=$2
SAMPLE_ID=$3

# Path setup
SAMTOOLS="singularity exec -B /scratch -B /home -B /tgen_labs /home/tgenref/containers/samtools-1.16.1_bryce.sif samtools"

mkdir -p "${OUT_DIR}"

#RENAMED_REF="${OUT_DIR}/${SAMPLE_ID}.rename.fna"
PRIMARY_REF="${OUT_DIR}/${SAMPLE_ID}.primary.fna.gz"
awk '/^>/ {print $0} /^[^>]/ {print toupper($0)}' ${ORIG_REF} > ${PRIMARY_REF} 
ENDS_LIST="${OUT_DIR}/${SAMPLE_ID}_ends_500kb.txt"
FINAL_FASTA="${OUT_DIR}/${SAMPLE_ID}_500kb_telogator.fasta"

echo "Step 3: Generating 500kb end regions..."
${SAMTOOLS} faidx "${PRIMARY_REF}"
awk '{
    if ($2 > 500000) {
        # Start region: 1 to 500,000
        print $1":1-500000"; 
        # End region: (Length - 499,999) to Length
        print $1":"($2-499999)"-"$2
    }
}' "${PRIMARY_REF}.fai" > "${ENDS_LIST}"

echo "Step 4: Extracting final sequences..."
${SAMTOOLS} faidx "${PRIMARY_REF}" --region-file "${ENDS_LIST}" > "${FINAL_FASTA}"

echo "SUCCESS: Processed reference for ${SAMPLE_ID} is at ${FINAL_FASTA}"
# Output the path so a parent script can capture it in a variable
echo "${FINAL_FASTA}"
