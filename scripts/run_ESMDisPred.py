# Author : Md Wasi Ul Kabir  

import torch
import esm
import pathlib 
import joblib
import numpy as np
import warnings
from Bio import SeqIO
# import gdown
import subprocess
from optparse import OptionParser
import os
import random
from pathlib import Path
import pandas as pd
import time
import datetime
import csv
    
from preprocess import preProcess_features, sanitize_sequence
warnings.filterwarnings("ignore")
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  

np.set_printoptions(precision=3)

# Set a seed value: 
seed_value= 2515  
os.environ['PYTHONHASHSEED']=str(seed_value) 
random.seed(seed_value) 
np.random.seed(seed_value) 


# def loadModels():
    # print("Loading models...")
    # output = parent_path+"/models/model.pkl"
    # path = pathlib.Path(output)
    # if not path.is_file():
        
    #     url = "https://www.cs.uno.edu/~mkabir3/ESMDispred/models/model.pkl"
    #     gdown.download(url=url, output=output, quiet=False, fuzzy=True)

def ESMDisPred(fasta_filepath,output_path,feature_path,model):
    output_dir = Path(output_path)
    model_output_dir = output_dir / "disorder" / model
    model_output_dir.mkdir(parents=True, exist_ok=True)
  
    
    # Threshold is not optimized, it is just a default value
    threshold=0.5
    df_time = pd.DataFrame(columns=['sequence', 'milliseconds'])
    seq=[]
    time_milli=[]  
    for record in SeqIO.parse(fasta_filepath, "fasta"):
        start_time = time.time()


        print("Protein ID: ", record.id)
        pid=record.id.strip()
        fasta=sanitize_sequence(str(record.seq))
        protein_sequence = [fasta]   
        protein_sequence= np.array(list(protein_sequence[0]) ).reshape(-1,1).astype(str)
        
        X = preProcess_features(feature_path,pid,model)
        
        saved_model = joblib.load(parent_path+"/models/model_"+model+".pkl")

        proba = saved_model.predict_proba(X)

        # pred = (proba[:,1] >= threshold).astype(int)
        np_index=np.arange(1, len(proba)+1).reshape(-1,1)
    
     
        proba_vals = proba[:,1]
        np_proba = np.array([f'{i:.3f}' for i in proba_vals]).reshape(-1,1)
        np_pred = (proba_vals >= threshold).astype(int).reshape(-1,1).astype(str)
        result=np.hstack((np_index, protein_sequence, np_proba, np_pred))
             
        with open(model_output_dir / f"{pid}.caid", "w") as f:
            f.write((">"+pid+"\n"))
            fmt = '%s', '%s', '%s', '%s'
            np.savetxt(f, result, delimiter='\t',fmt=fmt)

        print("--- Total Time (ms) ---" , int((time.time() - start_time)*1000))
        print("\n")
        seq.append(pid)
        time_milli.append(int((time.time() - start_time)*1000))
        
    df_time['sequence'] = seq
    df_time['milliseconds'] = time_milli

    timenow = datetime.datetime.now().astimezone().strftime("%a %b %d %H:%M:%S %Z %Y")

    def _write_timings(path):
        with open(path, "w") as f:
            print(f"# Running {model}, started {timenow}", file=f)
            print("sequence,milliseconds", file=f)
            for row in df_time.values:
                print(f"{row[0]},{row[1]}", file=f)

    _write_timings(output_dir / f"timings_{model}.csv")
    _write_timings(output_dir / "timings.csv")
    # print(df_time)
    
    print("ESMDisPred prediction end...")

        
            
if __name__ == '__main__':
    
    parent_path = str(Path(__file__).resolve().parents[1])
    
    parser = OptionParser()
    parser.add_option("-f", "--fasta_filepath", dest="fasta_filepath", help="Path to input fasta.", default=parent_path+'/example/sample.fasta')
    parser.add_option("-p", "--features_path", dest="features_path", help="Path to features.", default=parent_path+'/features/')
    parser.add_option("-o", "--output_path", dest="output_path", help="Path to output.", default=parent_path+'/output/')
    parser.add_option("-t", "--model", dest="model", help="Selected model ", default="")

    (options, args) = parser.parse_args()
    print("\n","#"*40,"ESMDisPred prediction started...","#"*40, "\n")
    print("Input Path:",options.fasta_filepath)
    print("Output Path:",options.output_path)
    print("Features Path:",options.features_path)
    print("Selected Model:",options.model)
    print("\n")
    workspace=options.output_path
    pathlib.Path(workspace).mkdir(parents=True, exist_ok=True) 
    pathlib.Path(workspace+"/disorder").mkdir(parents=True, exist_ok=True) 
    pathlib.Path(workspace+"/disorder/"+options.model).mkdir(parents=True, exist_ok=True) 
    workspace=parent_path+"/models"
    pathlib.Path(workspace).mkdir(parents=True, exist_ok=True)

    # loadModels()
    
    ESMDisPred(options.fasta_filepath,options.output_path,options.features_path,options.model)
    
