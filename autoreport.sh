#!/bin/bash
metadata_path=$(find -name "sample-metadata-bac1.tsv")
read_stat_path="trunk_10_30_240_220/stats-dada2-bac1/metadata.tsv"
chao1="trunk_10_30_240_220/alpha-metrics/chao1"
faith_pd="trunk_10_30_240_220/alpha-metrics/faith_pd"
observed_features="trunk_10_30_240_220/alpha-metrics/observed_features"
shannon="trunk_10_30_240_220/alpha-metrics/shannon"
simpson="trunk_10_30_240_220/alpha-metrics/simpson"

qiime tools export --input-path $chao1.qza --output-path $chao1
qiime tools export --input-path $faith_pd.qza --output-path $faith_pd
qiime tools export --input-path $observed_features.qza --output-path $observed_features
qiime tools export --input-path $shannon.qza --output-path $shannon
qiime tools export --input-path $simpson.qza --output-path $simpson

head -1 $read_stat_path >> read_stat.xlsx
sed '1,2d' $read_stat_path | sort -n >> read_stat.xlsx

file='alpha-diversity.tsv'
paste $chao1/$file $faith_pd/$file $observed_features/$file $shannon/$file $simpson/$file | cut -f 1,2,4,6,8,10 | sort -n > alpha_diversity.xlsx

declare -a arr=("phyla" "class" "order" "family" "genus" "species")
b=2

for j in "${arr[@]}"
do
awk ' BEGIN {FS="\t"} 
{ for (i=1; i<=NF; i++)  { a[NR,i] = $i } } NF>p { p = NF } END { for(j=1; j<=p; j++) { str=a[1,j]
    	for(i=2; i<=NR; i++){ str=str"\t"a[i,j]; } print str }
}' trunk_10_30_240_220/silva138/bac1/rel-tables/L$b-$j.tsv | cut --complement -f1 | awk 'NR == 1; NR > 1 {print $0 | "sort -n"}' | awk ' BEGIN {FS="\t"}
{ for (i=1; i<=NF; i++)  { a[NR,i] = $i } } NF>p { p = NF } END { for(j=1; j<=p; j++) { str=a[1,j]
    	for(i=2; i<=NR; i++){ str=str"\t"a[i,j]; } print str } }' > $j.xlsx
let "b++"
done
python3 merge.py
rm alpha_diversity.xlsx read_stat.xlsx phyla.xlsx class.xlsx order.xlsx family.xlsx genus.xlsx species.xlsx
