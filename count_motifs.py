import gzip
import sys

def count_motifs(fasta_file):
    count_upper = 0
    count_lower = 0
    
    # Open gzipped or regular files
    open_func = gzip.open if fasta_file.endswith('.gz') else open
    mode = 'rt' if fasta_file.endswith('.gz') else 'r'

    with open_func(fasta_file, mode) as f:
        for line in f:
            # Skip FASTA header lines
            if line.startswith(">"):
                continue
            
            # Count occurrences in the current line
            count_upper += line.count("TTAGGG")
            count_lower += line.count("ttaggg")
            
    return count_upper, count_lower

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python count_motifs.py <fasta_file>")
        sys.exit(1)
        
    file_path = sys.argv[1]
    upper, lower = count_motifs(file_path)
    
    print(f"File: {file_path}")
    print(f"TTAGGG count: {upper}")
    print(f"ttaggg count: {lower}")
    print(f"Total: {upper + lower}")
