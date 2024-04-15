# ESMDisPred
ESMDisPred: Improved prediction of disordered regions using representations from a protein large protein language model.


# Getting Started
 

These instructions will get you a copy of the project up and running on your local machine or docker container for disorder prediction. 

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

## Authors

Md Wasi Ul Kabir, Md Tamjidul Hoque. For any issue please contact: Md Tamjidul Hoque, thoque@uno.edu 

## References

1. Md Wasi Ul Kabir, and Md Tamjidul Hoque. “DisPredict3.0: Prediction of Intrinsically Disordered Regions/Proteins Using Protein Language Model.” Applied Mathematics and Computation, vol. 472, July 2024, p. 128630. ScienceDirect, https://doi.org/10.1016/j.amc.2024.128630.

2. Hu, Gang, Akila Katuwawala, Kui Wang, Zhonghua Wu, Sina Ghadermarzi, Jianzhao Gao, and Lukasz Kurgan. “FlDPnn: Accurate Intrinsic Disorder Prediction with Putative Propensities of Disorder Functions.” Nature Communications 12, no. 1 (December 2021): 4438. https://doi.org/10.1038/s41467-021-24773-7.




