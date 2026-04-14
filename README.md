# Prep Telogator: 
```bash
Generating a species-specific Telogator2 reference file
Make 500 kb fastq from reference
```

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
assembly = "An Assembly ID"
```

### Basic Command

```bash
python process_ref_from_samplesheet.py -s <sample_sheet.tsv> -d <output_directory>
```

