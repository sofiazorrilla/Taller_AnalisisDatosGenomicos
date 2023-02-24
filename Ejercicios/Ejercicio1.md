---
title: "Procesamiento bioinformático: demultiplex - llamado de SNPs"
format: html
author: "Sergio y Sofía"
self-contained: true
keep-md: true
---



## Instalar miniconda en su usuario 


## Demultiplex

### process_radtags

STACKS tool process_radtags which:

> ... checks that the barcode and the RAD cutsite are intact, and demultiplexes the data. If there are errors in the barcode or the RAD site within a certain allowance process_radtags can correct them. Second, it slides a window down the length of the read and checks the average quality score within the window. If the score drops below 90% probability of being correct (a raw phred score of 10), the read is discarded. This allows for some seqeuncing errors while elimating reads where the sequence is degrading as it is being sequenced.

- [Manual](https://catchenlab.life.illinois.edu/stacks/comp/process_radtags.php)
- script: `process_radtags.sh`

Parameters:
- `-p` we indicate the directory with the sequence data
- `-i` the type of sequence file
- `-o` the output directory
- `-y` the output format
- `-b` the barcode file to use for demultiplexing
- `-e` the restriction enzyme so it knows what cut site sequence to expect after the barcode
- `--adapter_1` to indicate the adapter sequence to identify and remove contaminants
- `--adapter_mm` the number of mismatches allowed between the read and real adapter sequence
- `-r` to "rescue" (keep) a sequence if there is one error in the barcode
- `-c` to remove reads with uncalled bases (N)
- `-q` to discard reads with low quality scores which are defined by a sliding window if the average score is less than `-s` = 10.

```{.bash}

input_dir=../data/raw_data/batch_01846
barcodes_file=../data/barcodes/barcodes_01846.txt

#mkdir ../data/demultiplexed_raw2/batch_01846

process_radtags -t 18 \ # número de núcleos
                -p $input_dir \
                -i gzfastq \
                -o ../data/demultiplexed_raw2/batch_01846 \
                -b $barcodes_file \
                --renz_1 pstI \ # enzima de restricción
                -r -c \
                --barcode-dist-1 2 \ # numero de discrepancias en el barcode
                -D \
                &>out_demultiplex_01846.log # una forma de guardar lo que se imprime en pantalla 
```


## Revisión de calidad



### FastQ

```{.bash}
files=$(ls -d ../data/raw_data/morton_data/*.gz)

for file in $files
do
fastqc $file -o ../outputs/fastqc/morton_data/
done	

```

### FastQC

```{.bash}
files=$(ls -d ../data/raw_data/morton_data/*.gz)

fastq_screen --threads 10 --aligner bowtie2 --conf fastq_screen.conf $files --outdir ../outputs/fastq_screen/morton_data/

```

### MultiQC - Resumen general

```{.bash}

## Directories

#fastqc="../outputs/fastqc/batch_01846/"
fastqc="../outputs/fastqc/morton_data/"

#fastq_screen="../outputs/fastq_screen/batch_01846/"
fastq_screen="../outputs/fastq_screen/morton_data/"

## Command

multiqc --force --interactive $fastqc $fastq_screen --outdir ../outputs/multiqc/morton_data/ 

```


## Mapeo a un genoma de referencia


After initial quality and contamination assesment. Next step is to performe an aligment to a reference genome (in case there is one available,
otherwise a _de Novo_ aligment and variant callig pipeline has to be used). Further trimming and quality chechs can be evaluated by looking at their
effect on the mapping statistics.

First the reference genome has to be downloaded. See [genome_ncbi_download.md](./genome_ncbi_download.md) for short instructions. The reference
needs to be in a fasta format (.fna is fasta format when sequences are downloaded form NCBI).

-----

#### Instructions for simple genome download from NCBI

In the NCBI website reference genomes are refered as assemblies (representation of genomes). Assemblies is a database in the site where genomes can 
be looked for. 

There are 2 options to download ncbi genomes (both use a FTP connection) through rsync commands or wget/curl commands. There is a short 
[tutorial](https://www.youtube.com/watch?v=-X0H024ST8k&ab_channel=TheNationalLibraryofMedicine) and documentation in the [FTP 
QA](https://www.ncbi.nlm.nih.gov/genome/doc/ftpfaq/)

##### Small number of genomes to be downloaded - rsync

The FTP path can be obtained by first looking up the species of interes in the NCBI Assembly database, click on the record and on the right side 
panel there is an option for FTP directories. Once you get the FTP path it can be inserted in the rsync command. 

Replace the "ftp:" at the beginning of the FTP path with "rsync:". The directory and its contents could be downloaded using the following rsync command:

`rsync --copy-links --recursive --times --verbose rsync://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/001/633/185/GCF_001633185.2_ValleyOak3.2/`

-----

Then the reference genome has to be indexed. This basically means that we can create a system to do queries more efficient. To uderstand more deeply
[Lectures](https://www.youtube.com/watch?v=5G2Db41pSHE&list=PL2mpR0RYFQsADmYpW2YWBrXJZ_6EL_3nu&index=1&ab_channel=BenLangmead).

```{.bash}
# index reference genomes to use fastq_screen

cd ../data/genomes/

paths=$(ls -d $PWD/*)

for i in $paths
do
file=$(ls -d $i/*.fna.gz)
name=$(ls $i/*.fna.gz | cut -d . -f 1-2)
cd $i
bowtie2-build $file $name
done

```
After that we can use one of the bwa algorithms to map short sequences into our reference.

```{.bash}

## Align to reference genome (Q.lobata) using BWA-MEM

######### read group file suffix

#file_suffix="01846"
file_suffix="morton_data2"
#file_suffix="all.90"

######### input data directory

#folder_data="../data/demultiplexed_raw2/all.90bp"
folder_data="../data/raw_data/morton_data/set2/"

######### output directories

out_folder="morton_data2"

mkdir -p ../data/alignment/sam/$out_folder
mkdir -p ../data/alignment/bam/$out_folder

while read sample readgroup
do

echo "bwa mem -M -t 18 -R ${readgroup} ../data/genomes/qlobata/GCA_001633185.5_ValleyOak3.2_genomic.fna ${folder_data}/${sample}.fastq.gz > ../data/alignment/sam/${out_folder}/${sample}.sam" | bash

picard SortSam I=../data/alignment/sam/${out_folder}/${sample}.sam O=../data/alignment/bam/${out_folder}/${sample}.bam SORT_ORDER=coordinate

samtools index ../data/alignment/bam/${out_folder}/${sample}.bam

done < ../data/readgroups/sampl_rgp_${file_suffix}

```

## Llamado de SNPs

