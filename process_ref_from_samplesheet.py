import pandas as pd
import subprocess
import os 
import sys
import argparse


def get_column_name(df, possible_names, field_label):
    """
    Helper function to find which column name from a list exists in the DataFrame.
    """
    for name in possible_names:
        if name in df.columns:
            return name
    raise ValueError(f"Could not find a column for '{field_label}'. Tried: {possible_names}")

def process_sample_sheet(file_path, base_output_dir):
    print(f"🔬 Starting processing for sample sheet: {file_path}")
    print(f"📦 Using base output directory: {base_output_dir}")
    
    try:
        # 1. Load the TSV file
        df = pd.read_csv(file_path, sep='\t')
        
        # 2. Identify the correct column names dynamically
        try:
            # PRIORITIES: Checks for UCSC name first
            col_name = get_column_name(df, ['UCSC_common_name-asm', 'common.name', 'organism'], "Common Name")
            
            # Other columns
            col_ref = get_column_name(df, ['reference', 'TGen.location.reference'], "Reference Genome")
            col_report = get_column_name(df, ['asm_report', 'assemblyreport'], "Assembly Report")
            col_assembly = get_column_name(df, ['assembly'], "Assembly ID")
            
            print(f"   Detailed Column Mapping:")
            print(f"   - Reference column found: '{col_ref}'")
            print(f"   - Name column found:      '{col_name}' (Used for Output Dir & -n flag)")
            print(f"   - Report column found:    '{col_report}'")
            
        except ValueError as e:
            print(f"❌ Error: {e}", file=sys.stderr)
            return

        # 3. Drop missing rows based on the columns we just found
        required_cols = [col_ref, col_name, col_report, col_assembly]
        df.dropna(subset=required_cols, inplace=True)
        
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}", file=sys.stderr)
        return
    except pd.errors.ParserError:
        print(f"Error: Could not parse TSV file at {file_path}. Check file format.", file=sys.stderr)
        return

    # ---
    
    ## 🧬 Identify Unique References
    
    # Select only the columns needed
    unique_refs_df = df[required_cols].drop_duplicates()
    
    commands_to_run = []

    for index, row in unique_refs_df.iterrows():
        # Get the values using the dynamic column names
        reference = row[col_ref]
        assembly_report = row[col_report]
        common_name_raw = row[col_name]
        
        # Process the common name
        common_name_clean = str(common_name_raw).replace(' ', '-').replace('(', '-').replace(')', '-')
        common_name_clean = common_name_clean.replace('--', '-').strip('-')
        
        # Define the final output directory path
        output_dir = os.path.join(base_output_dir, common_name_clean)
        
        # Define the final expected reference file path
        expected_ref_file = os.path.join(output_dir, f"{common_name_clean}.ref.fa")
        
        # --- NEW CHECK: Skip if the final reference file already exists ---
        if os.path.isfile(expected_ref_file):
            print(f"⏩ Skipping {common_name_clean}: Expected reference file already exists at {expected_ref_file}")
            continue
        # -------------------------------------------------------------------
        # Construct the command
        command = [
            './call_prep.sh',
            '-r', str(reference),
            '-o', str(output_dir),
            '-a', str(assembly_report),
            '-n', str(common_name_clean) 
        ]
        
        commands_to_run.append(command)
        
    # ---

    ## 🚀 Execute Commands
    
    if not commands_to_run:
        print("\nNo unique references found that require processing.")
        return
        
    print(f"\nFound {len(commands_to_run)} unique reference(s) to process.")
    
    for command in commands_to_run:
        command_str = " ".join(command)
        print(f"\nExecuting: {command_str}")
        
        try:
            result = subprocess.run(
                command, 
                check=True,  
                text=True, 
                capture_output=True
            )
            print(f"  ✅ SUCCESS: \n{result.stdout.strip()}")
            if result.stderr:
                 print(f"  (StdErr captured: {result.stderr.strip()})")

        except subprocess.CalledProcessError as e:
            print(f"  ❌ ERROR: Command failed with exit code {e.returncode}.", file=sys.stderr)
            print(f"  Stderr: {e.stderr.strip()}", file=sys.stderr)
        except FileNotFoundError:
            print(f"  ❌ ERROR: 'call_prep.sh' script not found.", file=sys.stderr)
        except Exception as e:
            print(f"  ❌ An unexpected error occurred: {e}", file=sys.stderr)
            
    print("\nProcessing complete.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a TSV sample sheet to run call_prep.sh.")
    
    parser.add_argument('-s', '--sample-sheet', type=str, required=True, help='Path to input TSV.')
    parser.add_argument('-d', '--outdir', type=str, default=True, help='Reference output directory.')
    
    args = parser.parse_args()
    process_sample_sheet(args.sample_sheet, args.outdir)
