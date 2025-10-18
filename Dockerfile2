# Start from the base image you’re using
FROM wasicse/esmdispred:latest

# Set up environment variables
ENV ESMpath=/opt/ESMDisPred

# Copy your local files into the container
COPY requirements.txt $ESMpath/requirements.txt

# Initialize conda and set up environment
RUN eval "$(/opt/.pyenv/versions/miniconda3-4.7.12/bin/conda shell.bash hook)" && \
    conda create -y -n py39 python=3.9 && \
    conda activate py39 && \
    pip install --no-cache-dir -r $ESMpath/requirements.txt

# Set working directory
WORKDIR $ESMpath

# Default command
CMD ["/bin/bash"]
