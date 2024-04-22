# ESMDisPred
ESMDisPred: Enhanced Prediction of Disordered Regions Utilizing Representations from a Large Protein Language Model.

The repository includes three distinct models, differentiated by the features they employ for prediction:
* 'ESMDisPred' utilizes features from DisPredict3.0 and ESM1.
* 'ESM2DisPred' incorporates features from DisPredict3.0, ESM1, and ESM2.
* 'ESM2PDBDisPred' employs features from DisPredict3.0, ESM1, ESM2, along with structural-related features.

# Getting Started
 
These instructions will help to install and start the ESMDisPred on the local machine for disordered region prediction.

ESMDisPred has been tested on Ubuntu 20.04. You need to have Pyenv installed on your local machine. ESMDisPred can be executed on a local Linux machine or within Docker and Singularity containers.

### Download the code

- Retrieve the code

```
git clone https://github.com/wasicse/ESMDisPred.git

```

## Dataset
The dataset can be found in the dataset directory. 

## Run with local OS


#### Install Dependencies in local OS with SHELL script

- Install all dependencies by running the following script:

```
./install_dependencies.sh
```

### Run ESMDisPred in local OS

- Execute the following command to run ESMDisPred from the script directory. The script takes the input from /home/mkabir3/example/sample.fasta file and produce outputs to the outputs directory.

```
./run_ESMDisPred.sh
```


## Run with Docker
- To run the ESMDisPred tool with docker, you can either build the docker image using dockerfile or pull the docker image from the registry.

#### Build Docker image 

```
docker build -t wasicse/esmdispred2 https://github.com/wasicse/ESMDisPred.git#master    
```
 #### (Alternatively) Pull image from Docker registry.

- Pull the image from the registry.
 ```
docker pull wasicse/esmdispred:latest
```
#### Run ESMDisPred using Docker image
- Create the ESMDisPred container. The script will mount input fasta, features nad outputs directorries form the current (ESMDisPred) directory (downlaoded from GitHub) into the docker container.

```
input_fasta="$(pwd)/example/sample.fasta"
output_dir="outputs"
./run_ESMDisPred_Docker.sh $input_fasta $output_dir
```

## Run with Singularity 


#### Build Singularity image from docker image
- You can also run using Singularity using the following command.

```
singularity pull esmdispred.sif docker://wasicse/esmdispredroot:latest
input_fasta="$(pwd)/example/sample.fasta"
output_dir="outputs"
sudo singularity run --writable-tmpfs \
	-B $input_fasta:/opt/ESMDisPred/example/sample.fasta \
	-B $(pwd)/$output_dir:/opt/ESMDisPred/outputs:rw esmdispred.sif
cd /opt/ESMDisPred  && ./run_ESMDisPred.sh
```
#### Build Singularity image (Not recommended)
```
udo singularity  build ESMDispS.sif ESMDispS.def
input_fasta="$(pwd)/example/sample.fasta"
output_dir="outputs"
sudo singularity run --writable-tmpfs \
	-B $input_fasta:/ESMDisPred/example/sample.fasta \
	-B $(pwd)/$output_dir:/ESMDisPred/outputs:rw ESMDispS.sif
```
## Output format

- The **outputs** folder should contain the results for each of the trained model including Dispredict3.0. 

- The output directory contains the disorder probabilities for each residue in **PROTEINID.caid** file. The directory also have the "timings.csv" file and store execution time for each prediction.


## Authors

Md Wasi Ul Kabir, Md Tamjidul Hoque. For any issue please contact: Md Tamjidul Hoque, thoque@uno.edu 

## References

1. Md Wasi Ul Kabir, and Md Tamjidul Hoque. “ESMDisPred: Prediction of Intrinsically Disordered Regions/Proteins Using Protein Language Model.” Applied Mathematics and Computation, vol. 472, July 2024, p. 128630. ScienceDirect, https://doi.org/10.1016/j.amc.2024.128630.

2. Hu, Gang, Akila Katuwawala, Kui Wang, Zhonghua Wu, Sina Ghadermarzi, Jianzhao Gao, and Lukasz Kurgan. “FlDPnn: Accurate Intrinsic Disorder Prediction with Putative Propensities of Disorder Functions.” Nature Communications 12, no. 1 (December 2021): 4438. https://doi.org/10.1038/s41467-021-24773-7.




