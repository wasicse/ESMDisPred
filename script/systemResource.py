import os
import psutil
import time 
from optparse import OptionParser

def get_process_memory_usage(pid):
    process = psutil.Process(pid)
    memory_info = process.memory_info()
    return memory_info.rss

def get_subprocess_memory_usage(pid):
    process = psutil.Process(pid)
    subprocess_memory_usage = 0
    for child in process.children():
        subprocess_memory_usage += get_process_memory_usage(child.pid)
    return subprocess_memory_usage

if __name__ == '__main__':   
    print("\n","#"*40,"System Resource Monitoring started...","#"*40, "\n")
    # print("System Resource Monitoring")
    parser = OptionParser()
    parser.add_option("-f", "--pid", dest="pid", help="pid", default=1)
  
    (options, args) = parser.parse_args()

    # print("PID",options.pid)
    pid=int(options.pid)
    # pid=280921
    # Get the memory usage of the current process and its subprocesses
    process = psutil.Process(pid)
    # run it every 5 seconds until the pid exit and save into a csv file
    import pandas as pd
    df=pd.DataFrame(columns=["MemoryUsageGB","TotalMemoryAvailable","TotalMemoryUsed","MemoryUsagePercentage"])
    while process.is_running():    
        # print("Process is running")    
        total_memory_usage = get_process_memory_usage(pid) + get_subprocess_memory_usage(pid)
        # Add  dataframe  without append
        df.loc[len(df)] = [round(total_memory_usage/1024**3,2),round(psutil.virtual_memory().available/1024**3,2),round(psutil.virtual_memory().used/1024**3,2),round(total_memory_usage / psutil.virtual_memory().total * 100,2)]
        time.sleep(1)

    df.to_csv("../outputs/MemoryUsage.csv",index=False)

    # find the max memory usage
    max_memory_usage = df["MemoryUsageGB"].max()
    print("Max Memory Usage:",max_memory_usage)
    #find max TotalMemoryAvailable
    max_TotalMemoryAvailable = df["TotalMemoryAvailable"].max()
    print("Max TotalMemoryAvailable:",max_TotalMemoryAvailable)
    # find min TotalMemoryAvailable
    min_TotalMemoryAvailable = df["TotalMemoryAvailable"].min()
    print("Min TotalMemoryAvailable:",min_TotalMemoryAvailable)
    #find max TotalMemoryUsed
    max_TotalMemoryUsed = df["TotalMemoryUsed"].max()
    print("Max TotalMemoryUsed:",max_TotalMemoryUsed)
    #find max MemoryUsagePercentage
    max_MemoryUsagePercentage = df["MemoryUsagePercentage"].max()
    print("Max MemoryUsagePercentage:",max_MemoryUsagePercentage)
    