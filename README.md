# ESMDisPred
ESMDisPred: Enhanced Prediction of Disordered Regions Utilizing Representations from a Large Protein Language Model.


# Getting Started
 

These instructions will get you a copy of the project up and running on your local machine  for disorder prediction. 

We have tested ESMDisPred on Ubuntu 20.04. You would need to have Docker in your local or server machine.

 ## Dataset
The dataset can be found in the dataset directory. 

## Run with local OS
### Download the code

- Retrieve the code

```
git clone https://github.com/wasicse/ESMDisPred.git

```

#### Install Dependencies in local OS with SHELL script

You can install all dependencies by running the following script:

```
./install_dependencies.sh
```

### Run ESMDisPred in local OS

Execute the following command to run ESMDisPred from the script directory.

```
run_ESMDisPred.sh
```
- The **outputs** folder should contain the results. The output directory contains the disorder probabilities with labels for each residue in **PROTEINID.caid** file. The directory also have the "timings.csv" file and store execution time for each prediction.


## Run with Docker
- To run the ESMDisPred tool with docker, you can either build the docker image using dockerfile or pull the docker image from the registry.

#### Build Docker image 

```
docker build -t wasicse/esmdispred https://github.com/wasicse/ESMDisPred.git#main    
```
 #### (Alternatively) Pull image from Docker registry.

- Pull the image from the registry.
 ```
docker pull wasicse/esmdispred:latest
```
#### Run ESMDisPred using Docker image
- Create the ESMDisPred container and mount the current (ESMDisPred) directory (downlaoded from GitHub) into the docker container.

```
docker run -ti --name ESMDisPred  wasicse/ESMDisPred:latest
```

- Then, run following python commands inside the docker container to have the disordered prediction.

```
export PATH="/opt/poetry/bin:${PATH}"
source /opt/ESMDisPred/.venv/bin/activate
python /opt/ESMDisPred/script/ESMDisPred.py -f "/opt/ESMDisPred/example/sample.fasta" -o "/opt/ESMDisPred/output/"
```

- Check **output** folder for results. The output should be available only inside the docker container. 

- You can also copy the output to the host computer using the following command:

```
docker cp ESMDisPred:/opt/ESMDisPred/output/ .
```
## Run with Singularity 

- You can also run using Singularity using the following command.

```
singularity pull dispredict3.sif docker://wasicse/ESMDisPred
singularity run --writable-tmpfs dispredict3.sif
```
- Then, run following python commands inside the Singularity container to have the disordered prediction.

```
export PATH="/opt/poetry/bin:${PATH}"
source /opt/ESMDisPred/.venv/bin/activate
python /opt/ESMDisPred/script/ESMDisPred.py -f "/opt/ESMDisPred/example/sample.fasta" -o "/opt/ESMDisPred/output/"
```

- The **output** folder should contain the results. The output directory contains the disorder probabilities with labels for each residue in **sample_disPred.txt** file. The fully disorder prediction for each protein sequence is stored in **sample_fullydisPred.txt** file.

## Authors

Md Wasi Ul Kabir, Md Tamjidul Hoque. For any issue please contact: Md Tamjidul Hoque, thoque@uno.edu 

## References

1. Md Wasi Ul Kabir, and Md Tamjidul Hoque. “ESMDisPred: Prediction of Intrinsically Disordered Regions/Proteins Using Protein Language Model.” Applied Mathematics and Computation, vol. 472, July 2024, p. 128630. ScienceDirect, https://doi.org/10.1016/j.amc.2024.128630.

2. Hu, Gang, Akila Katuwawala, Kui Wang, Zhonghua Wu, Sina Ghadermarzi, Jianzhao Gao, and Lukasz Kurgan. “FlDPnn: Accurate Intrinsic Disorder Prediction with Putative Propensities of Disorder Functions.” Nature Communications 12, no. 1 (December 2021): 4438. https://doi.org/10.1038/s41467-021-24773-7.




