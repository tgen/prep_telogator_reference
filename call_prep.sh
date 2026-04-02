#!/bin/bash
# Call Telogator reference prep

# --- Help Menu Function ---
usage() {
    echo "Usage: $0 -r <reference_fasta> -n <reference_name>"
    echo ""
    echo "This script prepares a reference genome for Telogator analysis."
    echo ""
    echo "Options:"
    echo "  -r <file>    Path to the reference genome FASTA file (can be gzipped)."
    echo "  -o <outdir>  Path to the output directory (e.g. /labs/reference/humpback-whale ."
    echo "  -a <report>  Path to the assembly report file for this species. "
    echo "  -h           Display this help message and exit."
    echo ""
    exit 1
}
# --------------------------

# --- Option Parsing ---
while getopts r:n:a:o: flag
do
    case "${flag}" in
        r) ref=${OPTARG};;
	o) outdir=${OPTARG};;
	a) report=${OPTARG};;
	n) name=${OPTARG};;
        h) usage;; # Call the usage function if -h is provided
        \?) echo "Invalid option: -${OPTARG}" >&2; usage;; # Handle invalid options
        :) echo "Option -${OPTARG} requires an argument." >&2; usage;; # Handle missing arguments
    esac
done

# --- Input Validation (Recommended) ---
if [ -z "${ref}" ]; then
    echo "Error: -r ref is required." >&2
    usage
elif [ -z "${outdir}" ]; then
    echo "Error: -o outdir is required." >&2
    usage
elif [ -z "${report}" ]; then
    echo "Error: -a report is required." >&2
    usage
fi 
# -------------------------------------


echo "prep_telogator_ref.sh -r ${ref} -o ${outdir} -n ${name} -e ${report}"
sbatch prep_telogator_ref.sh -r ${ref} -o ${outdir} -n ${name} -e ${report}
