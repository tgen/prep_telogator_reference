# Prep Telogator: 
Generating a species-specific Telogator2 reference file

## Prerequisites

Before running the scripts, ensure you have the required Python modules installed. 

### Option: Using Conda (Recommended)
```bash
conda env create -f environment.yml
conda activate prep_telogator
```

## Usage

You can run this script from the command line to process your TSV sample sheet. 

Check out the example samplesheet file here: [Example Data](./examples/samplesheet_example.txt).

```bash
reference, (asm_report/assemblyreport), (assembly/Assembly ID)
```
```bash
reference = "Your downloaded species reference file".
assemblyreport = "Path to a downloaded assembly report for this reference"
Assembly ID = "An Assembly ID"
```

### Basic Command

```bash
python process_ref_from_samplesheet.py -s <sample_sheet.tsv> -d <output_directory>
```



#
# Generate 500 kb fastq from reference:

The `generate_500kb_ref.sh` script extracts the first and last 500kb of each chromosome from a reference genome. This is specifically formatted for use as input fastq to be used with Telogator2.

### Prerequisites
- **Samtools**: Ensure `samtools` is installed and available in your PATH.
  ```bash
  conda install -c bioconda samtools
  ```

## Usage

To run this on command line:

### Basic Command


```bash
    ./generate_500kb_ref.sh -r <Path to the original reference FASTA> -o <output directory> -i <sample_id>
```
```
sample_id = "name of the output"
```
