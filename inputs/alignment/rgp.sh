### Make readgroups files

file_suffix="morton_data2"
sample_dir="../data/raw_samples/morton_data/"

## list demultiplexed files and add batch and platform 

ls ${sample_dir}/*fq.gz | \
	cut -d "/" -f 5 | cut -d "." -f 1 | \
	sed -e 's/$/\tMORTON\tILLUMINA/g' > read_groups_keys_${file_suffix}.txt

## Create readgroup strings

while read sample batch platform
do 
[ "$sample" == "SAMPLE" ] && continue; echo "@RG\tID:${batch}\tSM:${sample}\tPU:${batch}_${sample}\tPL:${platform}"
done < ../data/readgroups/read_groups_keys_${file_suffix}.txt > ../data/readgroups/readgroups_${file_suffix}.txt

## Add sample to readgroup string and save file 

awk '{print $1}' ../data/readgroups/read_groups_keys_${file_suffix}.txt > ../data/readgroups/temp
paste -d ' ' ../data/readgroups/temp ../data/readgroups/readgroups_${file_suffix}.txt > ../data/readgroups/sampl_rgp_${file_suffix}
rm ../data/readgroups/temp

## Add '' and double \\ to readgroup string

sed -e "s/@/\'@/g" ../data/readgroups/sampl_rgp_${file_suffix} | sed -e "s/$/\'/g" | sed -r 's/\\/\\\\/g' > ../data/readgroups/sampl_rgp_${file_suffix}.txt
rm ../data/readgroups/sampl_rgp_${file_suffix}
mv ../data/readgroups/sampl_rgp_${file_suffix}.txt ../data/readgroups/sampl_rgp_${file_suffix}
