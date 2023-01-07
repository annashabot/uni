#!/bin/bash

############# READS STATISTICS SHEET #############
#find mapping.txt
mapping_path=$(find -name "mapping.txt")

#extract ids into arrray $sample_ids
sample_ids=($(tail --lines=+2 $mapping_path | grep -o -P "^.*?(?=\t)"))

#count number of samples
sample_count=${#sample_ids[@]}
count=$(( $sample_count +1 ))

#find raw reads file: split_library_log.txt
raw_reads_file=$(find -name "split_library_log.txt")

#raw reads to array $rreadsinsample
for ((i=0; i<$sample_count; i++));
do
	rreadsinsample[i]+=$(grep -o -P "(?<=^${sample_ids[i]}\t).*" $raw_reads_file)
done

#find non-chimeric reads folder: demultiplexed
non_chimeric_path=$(find -name "demultiplexed")

#non-chimeric reads to array $nonchimeric
for ((i=0; i<$sample_count; i++));
do
	nonchimeric[i]+=$(grep -c '^>' $non_chimeric_path/${sample_ids[i]}.fna)
done

#calculate chimeric reads, to array
for ((i=0; i<$sample_count; i++));
do
	chimeric[i]=$(( ${rreadsinsample[i]}-${nonchimeric[i]} ))
done

#find rarefied reads folder: rarefied
rarefied_path=$(find -name "rarefied")

#rarefied reads -> array $rar_reads
for ((i=0; i<$sample_count; i++));
do
	rar_reads[i]+=$(grep -c '^>' $rarefied_path/${sample_ids[i]}.fna)
done

#find reads with OTU file: reads_with_otu_per_sample.txt
otureads_path=$(find -name "reads_with_otu_per_sample.txt")

#reads with otu per sample -> array $otureads
for ((i=0; i<$sample_count; i++));
do
	otureads[i]+=$(grep -o -P "(?<=^ ${sample_ids[i]}: )\d*" $otureads_path)
done

#find OTU per sample file: otu_per_sample.txt
otusample_path=$(find -name "otu_per_sample.txt")

#OTU per sample -> array $otusample
for ((i=0; i<$sample_count; i++));
do
	otusample[i]+=$(grep -o -P "(?<=^ ${sample_ids[i]}: )\d*" $otusample_path)
done

#write to csv file
echo ,,,,rarefied > reads_statistics.xlsx
echo Sample,Raw reads,N of chimeras,Non-chimeric reads,Rarefied reads,Reads with OTU,OTU per sample >> reads_statistics.xlsx
for ((i=0; i<$sample_count; i++));
do
	echo ${sample_ids[i]},${rreadsinsample[i]},${chimeric[i]},${nonchimeric[i]},${rar_reads[i]},${otureads[i]},${otusample[i]} >> reads_statistics.xlsx
done

############# TAXONOMY SHEET #############
#find L7 taxonomy file
L7_path=$(find -name "otu_table_mc2_w_tax_no_pynast_failures_L7.txt" | head -1)

#open L7 taxonomy file and read second row as string
header=$(head -2 $L7_path | tail -1)

#divide header into array by tab delimeter
IFS="	" read -a headarray <<< "$header"

#sort 1 to last elements of array in ascending order, make an array of position numbers
for (( i=0; i<$sample_count; i++)); do
	for ((j=1; j<count; j++)); do
		if [[ ${headarray[j]} == ${sample_ids[i]} ]]; 
			then
				m=$(( $i+1 ))
				sortarray[$m]=$j
			fi
	done
done

#writing header into taxonomy.csv file
for (( i=0; i<count; i++ ));
do
	echo -n ${headarray[${sortarray[i]}]} >> taxonomy.xlsx
 	if (( i==$sample_count )); then
 		echo "" >> taxonomy.xlsx
 	else
 		echo -n "," >> taxonomy.xlsx
 	fi 
done

#read file from 2 to last row line by line
taxa=()
while IFS= read -r line || [[ "$line" ]]; do
  taxa+=("$line")
done < $L7_path

#read taxa by element, split each on tabs, write to taxonomy.csv in right order
for ((j=2; j<${#taxa[@]}; j++)); 
do
	IFS="	" read -a taxaarray <<< "${taxa[j]}"
	for ((i=0; i<count; i++));
	do
		echo -n ${taxaarray[${sortarray[i]}]} >> taxonomy.xlsx
 		if ((i==$sample_count)); then
 			echo "" >> taxonomy.xlsx
 		else
 			echo -n "," >> taxonomy.xlsx
 		fi 
	done
done

############# ALPHA DIVERSITY SHEET #############
indices=$(find -name "indices.txt")
echo -n "Sample_ID" >> tmp
sed 's/\t/,/g' $indices >> tmp

lines=()
while IFS= read -r line || [[ "$line" ]]; do
  lines+=("$line")
done < tmp

echo ${lines[0]} >> alpha_diversity.xlsx

for ((i=1; i<count; i++));
do
	echo ${lines[${sortarray[i]}]} >> alpha_diversity.xlsx
done
rm tmp
