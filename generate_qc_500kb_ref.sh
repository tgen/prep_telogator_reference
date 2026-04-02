#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -r <orig_ref> -o <out_dir> -i <sample_id>"
    echo "  -r    Path to the original reference FASTA"
    echo "  -o    Output directory"
    echo "  -i    Sample ID"
    exit 1
}

# Parse command-line arguments
while getopts "r:o:i:" opt; do
    case "$opt" in
        r) ORIG_REF=$OPTARG ;;
        o) OUT_DIR=$OPTARG ;;
        i) SAMPLE_ID=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if required arguments are provided
if [ -z "$ORIG_REF" ] || [ -z "$OUT_DIR" ] || [ -z "$SAMPLE_ID" ]; then
    usage
fi

mkdir -p "${OUT_DIR}"

PRIMARY_REF="${OUT_DIR}/${SAMPLE_ID}.primary.fna"
ENDS_LIST="${OUT_DIR}/${SAMPLE_ID}_ends_500kb.txt"
FINAL_FASTA="${OUT_DIR}/${SAMPLE_ID}_500kb_telogator.fasta"

echo "Step 1: Converting to uppercase..."
awk '/^>/ {print $0} /^[^>]/ {print toupper($0)}' "${ORIG_REF}" > "${PRIMARY_REF}"

echo "Step 2: Generating 500kb end regions..."
samtools faidx "${PRIMARY_REF}"
awk '{
    if ($2 > 500000) {
        # Start region: 1 to 500,000
        print $1":1-500000"; 
        # End region: (Length - 499,999) to Length
        print $1":"($2-499999)"-"$2
    }
}' "${PRIMARY_REF}.fai" > "${ENDS_LIST}"

echo "Step 3: Extracting final sequences..."
samtools faidx "${PRIMARY_REF}" --region-file "${ENDS_LIST}" > "${FINAL_FASTA}"

echo "SUCCESS: Processed reference for ${SAMPLE_ID} is at ${FINAL_FASTA}"
echo "${FINAL_FASTA}"
