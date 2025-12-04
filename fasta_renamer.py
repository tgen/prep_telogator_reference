import csv
import argparse
import sys
import re 
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord 

# --- Configuration for Assembly Report Parsing (NCBI Standard Format) ---
# This is the header expected in a standard NCBI assembly_report.txt file.
NCBI_STANDARD_HEADER = [
    'Sequence-Name', 
    'Sequence-Role', 
    'Assigned-Molecule', 
    'Assigned-Molecule-Location/Type', 
    'GenBank-Accn', 
    'Relationship', 
    'RefSeq-Accn', 
    'Assembly-Unit', 
    'Sequence-Length', 
    'UCSC-style-name'
]

# --- Configuration for the New Simple Report Format (Tab-Separated) ---
# The column indices are ZERO-BASED:
# Col 1: GenBank seq accession (GENBANK_INDEX)
# Col 2: RefSeq seq accession (REFSEQ_INDEX)
# Col 3: Chromosome name (MOLECULE_INDEX)
# Col 6: Molecule type (MOLECULE_TYPE_INDEX)
SIMPLE_REPORT_MAPPING = {
    "GENBANK_INDEX": 1, 
    "REFSEQ_INDEX": 2, 
    "MOLECULE_INDEX": 3,  
    "MOLECULE_TYPE_INDEX": 6, 
    "MOLECULE_TYPE_FILTER": "Chromosome",
    "DELIMITER": '\t', 
}

# --- New Function for Natural Sorting ---
def natural_sort_key(s):
    """
    Key for natural sorting of chromosome names (e.g., chr1, chr2, chr10, chrX).
    Splits the string into a list of strings and integers.
    """
    # Regex to find sequences of digits or sequences of non-digits
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split('([0-9]+)', s)]


def generate_chr_map(input_filepath, report_format):
    """
    Reads the assembly report file, determines its format, and builds the 
    CHR_MAP dictionary.
    
    This function uses DUAL-MAPPING (GenBank and RefSeq) and now uses a strict 
    tab delimiter for the 'simple' format, as requested.
    
    It enforces the 'first accession wins' policy on the TARGET chromosome name 
    to prevent duplicate chromosome headers.
    """
    chr_map_dict = {}
    assigned_chr_names = set() 
    
    # --- 1. Determine Parsing Configuration based on Format ---
    if report_format == 'ncbi':
        required_keys = ["RefSeq-Accn", "Assigned-Molecule", "Sequence-Role", "GenBank-Accn"]
        delimiter = '\t'
        try:
            column_indices = {col_name: NCBI_STANDARD_HEADER.index(col_name) for col_name in required_keys}
            role_index = column_indices["Sequence-Role"]
            refseq_index = column_indices["RefSeq-Accn"]
            molecule_index = column_indices["Assigned-Molecule"]
            genbank_index = column_indices["GenBank-Accn"] 
            max_index = max(refseq_index, molecule_index, role_index, genbank_index)
            print(f"Assembly Report: Using NCBI standard format configuration (Tab-separated).")
        except ValueError as e:
            missing_col = e.args[0].split(':')[0].strip()
            print(f"FATAL ERROR: NCBI format required but column '{missing_col}' is missing from the hardcoded header list.")
            sys.exit(1)

    elif report_format == 'simple':
        # Simple format uses fixed indices and strict tab separation
        genbank_index = SIMPLE_REPORT_MAPPING["GENBANK_INDEX"]
        refseq_index = SIMPLE_REPORT_MAPPING["REFSEQ_INDEX"]
        molecule_index = SIMPLE_REPORT_MAPPING["MOLECULE_INDEX"]
        role_index = SIMPLE_REPORT_MAPPING["MOLECULE_TYPE_INDEX"]
        max_index = max(genbank_index, refseq_index, molecule_index, role_index)
        # NOTE: Updated print statement to reflect strict tab usage
        print(f"Assembly Report: Using simple report format configuration (Tab-separated).") 
    
    else:
        print(f"FATAL ERROR: Unknown report format '{report_format}'. Must be 'ncbi' or 'simple'.")
        sys.exit(1)


    # --- 2. Read file and build map ---
    try:
        header_skipped = False
        
        with open(input_filepath, 'r', newline='', encoding='utf-8') as infile:
            
            # Use strict CSV reader for BOTH formats, as requested for 'simple'
            if report_format == 'ncbi' or report_format == 'simple':
                data_iterator = csv.reader(infile, delimiter='\t')
            
            for row in data_iterator:
                if not row or row[0].startswith('#'):
                    continue
                
                # Header skipping logic: Skip the first non-comment/non-empty line that isn't the NCBI header itself
                if not header_skipped and not row[0].startswith('#'):
                    is_ncbi_header = report_format == 'ncbi' and all(h in row for h in NCBI_STANDARD_HEADER)
                    
                    if not is_ncbi_header:
                        header_skipped = True
                        if report_format == 'simple':
                            print(f"Skipping Simple Report header line...")
                            continue 
                        
                # Ensure the row has enough columns
                if len(row) <= max_index:
                    continue

                # --- Filtering and Mapping ---

                # 2a. Filter condition (Role / Molecule Type)
                if report_format == 'ncbi':
                    filter_value = "assembled-molecule"
                    row_role = row[role_index].strip()
                elif report_format == 'simple':
                    filter_value = SIMPLE_REPORT_MAPPING["MOLECULE_TYPE_FILTER"]
                    row_role = row[role_index].strip()
                
                # Only process records marked as the primary molecule type (e.g., 'Chromosome')
                if row_role.lower() != filter_value.lower(): 
                    continue
                
                # 2b. Extract mapping values for DUAL-MAPPING
                assigned_molecule = row[molecule_index].strip()
                # Check column indices are within bounds before accessing
                genbank_accn = row[genbank_index].strip() if len(row) > genbank_index else ''
                refseq_accn = row[refseq_index].strip() if len(row) > refseq_index else ''
                
                # 2c. Determine the target chromosome name (e.g., 'chr5p')
                target_chr_name = None
                if assigned_molecule:
                    # Append 'chr' if not already present
                    if assigned_molecule.lower().startswith('chr'):
                         target_chr_name = assigned_molecule
                    else:
                         target_chr_name = f"chr{assigned_molecule}"

                # --- DUPLICATE CHECK (First chromosome wins) & DUAL-MAPPING ---
                if target_chr_name:
                    # Check if this target chromosome name has already been assigned
                    if target_chr_name not in assigned_chr_names:
                        
                        # Mark this chromosome name as assigned immediately
                        assigned_chr_names.add(target_chr_name)
                        
                        # Map GenBank Accession if valid
                        if genbank_accn and genbank_accn.lower() != 'na':
                            chr_map_dict[genbank_accn] = target_chr_name
                        
                        # Map RefSeq Accession if valid
                        if refseq_accn and refseq_accn.lower() != 'na':
                            # Map RefSeq even if it's the same as GenBank, ensuring both keys are present
                            chr_map_dict[refseq_accn] = target_chr_name
                            
                    # Else: This chromosome name is already assigned, so we skip both accessions for this row.

        # Calculate skipped records based on the number of rows processed vs unique chromosomes found.
        # This count is less precise but sufficient for confirmation.
        print(f"Assembly Report: Generated CHR_MAP with {len(chr_map_dict)} accession entries (GenBank and/or RefSeq).")
        print(f"The map contains accessions for {len(assigned_chr_names)} unique target chromosome names.")
        return chr_map_dict

    except FileNotFoundError:
        print(f"\n❌ Error: Assembly Report file not found at path: **{input_filepath}**")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ An error occurred during map generation: {e}")
        if report_format == 'simple':
            print(f"HINT: The simple report format requires columns up to index {max_index + 1} ({max_index} zero-based). Check that your file has enough columns and is correctly tab-separated.")
        sys.exit(1)


def rename_fasta_headers_by_accession(input_fasta, output_fasta, chr_map):
    """
    Reads a FASTA file, maps NCBI accessions to standard chromosome names,
    DISCARDS unmapped sequences, and then SORTS the resulting sequences
    using natural sort before writing the output.
    """

    kept_records = []
    kept_count = 0
    discarded_count = 0
    
    print(f"\nFASTA Renamer: Reading records from: {input_fasta}")

    try:
        # --- Phase 1: Read, Rename, and Collect Sequences ---
        for record in SeqIO.parse(input_fasta, "fasta"):

            # Use only the accession part (e.g., 'CM123456.1') 
            # before any spaces for lookup in the map.
            accession_key = record.id.split()[0]

            if accession_key in chr_map:
                # 1. Mapped chromosome: Rename and collect
                new_id = chr_map[accession_key]
                record.id = new_id
                # Clear description to keep headers clean (e.g., '>chr1')
                record.description = ""
                record.name = new_id # Also update .name for consistency
                
                kept_records.append(record)
                kept_count += 1
            else:
                # 2. Unmapped sequence: DISCARD
                discarded_count += 1

        # --- Phase 2: Sort Collected Sequences ---
        print(f"Sorting {kept_count} records by chromosome name...")
        # Sort uses the 'id' field which now holds the new chromosome name (e.g., 'chrX')
        kept_records.sort(key=lambda rec: natural_sort_key(rec.id))


        # --- Phase 3: Write Sorted Sequences to Output ---
        with open(output_fasta, "w") as out_handle:
            SeqIO.write(kept_records, out_handle, "fasta")

        print(f"\nFASTA Renamer: Processing complete.")
        print(f"Output saved to: **{output_fasta}**")
        print(f"Total sequences kept (mapped chromosomes, sorted): {kept_count}")
        print(f"Total unmapped sequences (DISCARDED): {discarded_count}")

    except FileNotFoundError:
        print(f"\n❌ Error: Input FASTA file not found at path: **{input_fasta}**")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ An error occurred during FASTA processing: {e}")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="A pipeline to generate a chromosome map from a local assembly report (in NCBI or simple format) and use it to rename and sort headers in a FASTA file."
    )
    
    # Required arguments
    parser.add_argument(
        "-r", "--report", 
        type=str, 
        required=True,
        help="Path to the local assembly report file."
    )
    
    parser.add_argument(
        "-i", "--input", 
        type=str, 
        required=True,
        help="Path to the input FASTA file to be renamed."
    )
    
    parser.add_argument(
        "-o", "--output", 
        type=str, 
        required=True,
        help="Path for the output renamed and sorted FASTA file."
    )

    # New optional argument to specify the report format
    parser.add_argument(
        "-f", "--format",
        type=str,
        default='simple', 
        choices=['ncbi', 'simple'],
        help="Specify the report format. 'ncbi' uses the full assembly_report.txt structure. 'simple' uses the fixed-column, tab-separated structure (GenBank, RefSeq, Chromosome Name, Molecule Type filter)."
    )
    
    args = parser.parse_args()
    
    # --- Step 1: Generate the CHR_MAP from the local report ---
    chromosome_map = generate_chr_map(args.report, args.format)

    # --- Step 2: Rename and Filter the FASTA headers ---
    if chromosome_map or args.format == 'simple':
        rename_fasta_headers_by_accession(args.input, args.output, chromosome_map)

    print("\n✅ Pipeline finished successfully.")
