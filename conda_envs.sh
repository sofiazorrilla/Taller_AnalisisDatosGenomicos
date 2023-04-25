## Crear ambientes de conda para el taller

### Demultiplex

conda create -p ./envs/stacks -c bioconda -c conda-forge stacks=2.64
conda activate ./envs/stacks
conda env export > yaml/stacks.yml

### Check quality

conda create -p ./envs/quality -c bioconda fastqc fastq-screen multiqc
conda activate ./envs/quality
conda env export > yaml/quality.yml

### ncbi-datasets

conda create -p ./envs/ncbi_datasets -c conda-forge ncbi-datasets-cli
conda activate ./envs/ncbi_datasets
conda env export > yaml/ncbi_datasets.yml

### Alignment

conda create -p ./envs/mapping -c bioconda bwa samtools
conda activate ./envs/mapping
conda env export > yaml/mapping.yml 

### Picard-tools (el de conda no funciona, no se por que)

sudo snap install picard-tools


######### Install from yaml

conda env create -f environment.yml