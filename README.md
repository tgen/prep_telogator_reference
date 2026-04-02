## Prep Telogator: 
Generating a species-specific Telogator2 reference file

## Prerequisites

Before running the scripts, ensure you have the required Python modules installed. 

### Option 1: Using Conda (Recommended)
```bash
conda env create -f environment.yml
conda activate prep_telogator
```

## Usage

You can run this script from the command line to process your TSV sample sheet. 

Check out the example samplesheet file here: [Example Data](./examples/samplesheet_example.txt)

### Basic Command

```bash
python process_ref_from_samplesheet.py -s <sample_sheet.tsv> -d <output_directory>
