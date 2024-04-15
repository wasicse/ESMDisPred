#! /bin/bash
# Number of parallel run



start=`date +%s%N` 
# Input arguments
input_fasta=$1
output_dir=$2
n=$3
localpythonPath=$4

echo "Input fasta file: $input_fasta"
# echo "Number of parallel run: $n"
# output_dir_path="$(pwd)/Outputs/$output_dir"
# echo "Output directory: $output_dir"

rm -rf temp
mkdir -p temp
mkdir -p ./temp/Parallelinputs

# echo "Splitting the input fasta file"
# echo "$localpythonPath ./split_Data.py $n $input_fasta"
$localpythonPath ./split_Data.py $n	$input_fasta

mkdir -p ./temp/logoutputs
mkdir -p $output_dir 
mkdir -p $output_dir/.cache
mkdir -p $output_dir/.cache/hub
mkdir -p $output_dir/.cache/checkpoints
mkdir -p $output_dir/predictions
mkdir -p $output_dir/features

chmod -R 777 $output_dir
chmod +x $(pwd)/modScripts/DisoCombP.sh

for ((i=1;i<=$n;i++)); 
do 
	echo "Running container No: "$i
	docker run --user $(id -u) -ti --rm \
	-v $(pwd)/temp/Parallelinputs/processedinput_$i.fasta:/opt/Dispredict3.0/example/sample.fasta \
	-v $(pwd)/$output_dir:/opt/Dispredict3.0/$output_dir:rw \
	-v $(pwd)/modScripts/Dispredict3.0.py:/opt/Dispredict3.0/script/Dispredict3.0.py \
	-v $(pwd)/modScripts/DisoCombP.sh:/opt/Dispredict3.0//tools/fldpnn/DisoComb.sh \
	-v $(pwd)/$output_dir/.cache:/opt/Dispredict3.0/.cache:rw \
	-v $(pwd)/$output_dir/.cache/hub:/opt/Dispredict3.0/.cache/hub:rw \
	-e TORCH_HOME='/opt/Dispredict3.0/.cache' \
	-e MPLCONFIGDIR='/opt/Dispredict3.0/.cache' \
	--entrypoint /bin/bash \
	wasicse/dispredict3.0:latest  \
	-c "export PATH=$PATH:/opt/Dispredict3.0/.venv/bin; \
	python /opt/Dispredict3.0/script/Dispredict3.0.py \
	-f /opt/Dispredict3.0/example/sample.fasta \
	-o /opt/Dispredict3.0/${output_dir}/" | tee -a ./temp/logoutputs/output_$i.txt &

done
# echo "Waiting for the output from Containers"
wait


echo "DisPredict3.0 all container runs completed"

# end=`date +%s%N` 

# echo "Total time in ms for :" 
# echo $(( ($end - $start) / 1000000 ))
# echo "Total time in seconds for :" 
# echo $(( ($end - $start) / 1000000000 ))
# echo "Total time in minutes for :" 
# echo $(( ($end - $start) / 60000000000 ))

rm -rf temp