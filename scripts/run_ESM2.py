# %%
# Author : Md Wasi Ul Kabir  

import torch
import esm
import pathlib 
# import joblib
import numpy as np
import warnings
from Bio import SeqIO
# import gdown
# import subprocess
from optparse import OptionParser
import os
import random
from pathlib import Path

warnings.filterwarnings("ignore")
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  
np.set_printoptions(precision=3)

# Set a seed value: 
seed_value= 2515  
os.environ['PYTHONHASHSEED']=str(seed_value) 
random.seed(seed_value) 
np.random.seed(seed_value) 


def extractFeatures(fasta_filepath,output_path):
    
    
    print("\n","#"*40,"Extracting features from ESM-2...","#"*40, "\n")
    # Load ESM-2 model
    # model, alphabet = esm.pretrained.esm2_t36_3B_UR50D()
    model, alphabet = esm.pretrained.esm2_t33_650M_UR50D()
    batch_converter = alphabet.get_batch_converter()
    model.eval()  # disables dropout for deterministic results

    layern= model.embed_tokens.weight.shape[0]
    layern=33
    # print("Layer Number:",layern)

    print("Extracting Features...")

    for record in SeqIO.parse(fasta_filepath, "fasta"):
        print("Protein ID: ", record.id)
        pid=record.id.strip()
        fasta=record.seq
 
        # file exists
        if os.path.exists(output_path+record.id+".csv"):
            # print("File Exists: ",output_path+record.id+".csv")
            print("Features already exists ")
            continue
        else:
            print("File Not Exists: ",output_path+record.id+".csv")
            print("Sequence length: ", len(fasta))
            data = [ (pid, fasta)]

            # Convert data to PyTorch tensors
            batch_labels, batch_strs, batch_tokens = batch_converter(data)
            batch_lens = (batch_tokens != alphabet.padding_idx).sum(1)
            
            # Extract per-residue representations (on CPU)
            with torch.no_grad():
                results = model(batch_tokens, repr_layers=[layern], return_contacts=True)
            token_representations = results["representations"][layern]

            # Generate per-sequence representations via averaging
            # NOTE: token 0 is always a beginning-of-sequence token, so the first residue is token 1.        
            sequence_representation = token_representations[0, 1 : batch_lens - 1].numpy() 
            print("Sequence representation shape:", sequence_representation.shape)

            np.savetxt(output_path+record.id+".csv", sequence_representation, delimiter=",")    

            print("Feature Extraction Complete...\n")       

if __name__ == "__main__":  
    parent_path = str(Path(__file__).resolve().parents[1])
    # print("Parent Dir",parent_path)

    parser = OptionParser()
    parser.add_option("-f", "--fasta_filepath", dest="fasta_filepath", help="Path to input fasta.", default=parent_path+'/example/sample.fasta')
    parser.add_option("-o", "--output_path", dest="output_path", help="Path to output.", default=parent_path+'/output/')

    (options, args) = parser.parse_args()

    # print("Dataset Path:",options.fasta_filepath)
    # print("Output Path:",options.output_path)

    fasta_filepath=options.fasta_filepath
    output_path=options.output_path
 
    workspace=output_path
    pathlib.Path(workspace).mkdir(parents=True, exist_ok=True) 

    extractFeatures(fasta_filepath,output_path)
    




