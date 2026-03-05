
fa_dir="/tgen_labs/schork/projects2/Data/VGP/assembly_UCSC.download__VGP.freeze1/primary/mammals"
assembly_dir="/tgen_labs/schork/projects2/Data/VGP/VGP-asm.report/assembly_report/"
out_dir="/tgen_labs/schork/projects2/Data/TELOMERE/telogator/reference"

for fa_file in `find ${fa_dir} -name *fa.gz`; do
	echo $fa_file
	b_fa_file=`basename ${fa_file}`
	assembly_report=${b_fa_file/.fa.gz/.assembly_report.txt}
	assembly_report_path="${assembly_dir}/${assembly_report}"
        name=${b_fa_file/.fa.gz}
	echo "./prep_telogator_ref.sh -r ${b_fa_file} -o ${out_dir} -n ${name} -e ${assembly_report_path}"
done
