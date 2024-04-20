import os
import pandas as pd
import numpy as np

def applyWindowsing(window_size, data,columnName):
    df=pd.DataFrame(data, columns=[columnName])
    for t in range(window_size, 0,-1):
        df[f'{columnName}-{t}'] = df[columnName].shift(t)
    for t in range(1, window_size+1):
        df[f'{columnName}+{t}'] = df[columnName].shift(-t)
    # replace NAn with 0
    df.fillna(0, inplace=True)
    df.drop([columnName], axis=1, inplace=True)
    return df

def windowing(df_filtered,window_size,columnNames):
    dflist=[]
    for columnName in columnNames:
        df=applyWindowsing(window_size, df_filtered,columnName)
        dflist.append(df)    
    df_window=pd.concat(dflist, axis=1)
    return df_window

def terminal_gen(data):
    print(data.shape)
    # print(data)
    len=data.AminoAcid_2.count()
    # len=data.shape[0]
    print("Length of the sequence: ", len)
    evenly_spaced_numbers = np.linspace(-1, 1, len)    
    return evenly_spaced_numbers


def preProcess_features(features_path,pid,method):
    print("Preprocessing Features...")
    ColumnName_Dispredict3=[f'fldpnn_{i}' for i in range(1, 318)]+[f'FLmodel_{i}' for i in range(1, 5125)]+[ "No_2", "AminoAcid_2", "DispredProba","DispredPred"  ]
    ColumnName_ESM=[f'ESM2650_{i}' for i in range(1, 1281)]
    
    # print(features_path+"/ESM2/"+pid+'_features.csv')
    if os.path.exists(features_path+"/Dispredict3.0/features/"+pid+'_features.csv'):

        df_Dispred=pd.read_csv(features_path+"/Dispredict3.0/features/"+pid+'_features.csv',header=None)          
        df_Dispred.columns=ColumnName_Dispredict3
    else:          
        print(pid, file=open("missing_features_Dispred.txt", "a"))
      
    
    window_size=7
    columnNames=["DispredPred","DispredProba"] 
    df_result=windowing(df_Dispred,window_size,columnNames)  
    mergeData=pd.concat([df_Dispred,df_result], axis=1)  
    
    
    ESM2StatsColumns=["ESM2650_mean", "ESM2650_std", "ESM2650_max", "ESM2650_min", "ESM2650_median", "ESM2650_skew", "ESM2650_kurtosis", "ESM2650_kurt", "ESM2650_var", "ESM2650_sem", "ESM2650_quantile"]
       
    if method in ["ESM2DisPred","ESM2PDBDisPred"]:
        if os.path.exists(features_path+"/ESM2/"+pid+'.csv'):
            df_ESM=pd.read_csv(features_path+"/ESM2/"+pid+'.csv',header=None)
            df_ESM.columns=ColumnName_ESM
        else:  
            print(pid, file=open("missing_features_ESM2.txt", "a")) 
                    
        mergeData=pd.concat([mergeData,df_ESM],axis=1)    
        
        mergeData["ESM2650_mean"]=df_ESM.mean(axis=1)
        mergeData["ESM2650_std"]=df_ESM.std(axis=1)
        mergeData["ESM2650_max"]=df_ESM.max(axis=1)
        mergeData["ESM2650_min"]=df_ESM.min(axis=1)
        mergeData["ESM2650_median"]=df_ESM.median(axis=1)
        mergeData["ESM2650_skew"]=df_ESM.skew(axis=1)
        mergeData["ESM2650_kurtosis"]=df_ESM.kurtosis(axis=1)
        mergeData["ESM2650_kurt"]=df_ESM.kurt(axis=1)
        mergeData["ESM2650_var"]=df_ESM.var(axis=1)
        mergeData["ESM2650_sem"]=df_ESM.sem(axis=1)
        mergeData["ESM2650_quantile"]=df_ESM.quantile(axis=1)
        
        df_result=windowing(mergeData,window_size,ESM2StatsColumns)
        mergeData=pd.concat([mergeData,df_result], axis=1)  
    


    
    # print("Adding Terminal Values")
    evenly_spaced_numbers_merged=terminal_gen(mergeData)
    mergeData["Terminal_posneg"]=evenly_spaced_numbers_merged
 
    ESM2StatsWindowed_columnList=[]
    for columnName in ESM2StatsColumns:
        for t in range(window_size, 0,-1):               
            ESM2StatsWindowed_columnList.append(f'{columnName}-{t}')
        for t in range(1, window_size+1):               
            ESM2StatsWindowed_columnList.append(f'{columnName}+{t}')
    
    window_size=7
    columnNames=["DispredPred","DispredProba"]
    Windowed_columnList=[]
    for columnName in columnNames:
        for t in range(window_size, 0,-1):               
            Windowed_columnList.append(f'{columnName}-{t}')
        for t in range(1, window_size+1):               
            Windowed_columnList.append(f'{columnName}+{t}')
                     
    # print("Selecting features")   
    # SelectedColumns=[f'fldpnn_{i}' for i in range(1, 318)]+[f'FLmodel_{i}' for i in range(1, 5125)]+[  "DispredProba","DispredPred" ,"Terminal_posneg"]+Windowed_columnList+ColumnName_ESM+ESM2StatsColumns+ESM2StatsWindowed_columnList


    SelectedColumns_WithESM2=[f'fldpnn_{i}' for i in range(1, 318)]+[f'FLmodel_{i}' for i in range(1, 5125)]+[  "DispredProba","DispredPred" ,"Terminal_posneg"]+Windowed_columnList+ColumnName_ESM+ESM2StatsColumns+ESM2StatsWindowed_columnList
    SelectedColumns_WithoutESM2=[f'fldpnn_{i}' for i in range(1, 318)]+[f'FLmodel_{i}' for i in range(1, 5125)]+[  "DispredProba","DispredPred" ,"Terminal_posneg"]+Windowed_columnList
    SelectedColumns_EMS2=[  "DispredProba","DispredPred" ,"Terminal_posneg"]+Windowed_columnList+ColumnName_ESM+ESM2StatsColumns+ESM2StatsWindowed_columnList
      
    if method=="ESMDisPred":
        # print("ESMDispred")
        SelectedColumns=SelectedColumns_WithoutESM2
    elif method=="ESM2DisPred":
        # print("ESM2Dispred")
        SelectedColumns=SelectedColumns_WithESM2
    elif method=="ESM2PDBDisPred":
        # print("ESM2PDBDispred")
        SelectedColumns=SelectedColumns_EMS2    
    
    # SelectedColumns=ESMDispred
    X = mergeData.loc[:, SelectedColumns]    
    print("Features Preprocessing Complete...")   

    return X  