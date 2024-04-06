#!/bin/bash

echo "START"

function align () { local var1="${1%%.*}"; var1="${var1#/home/BCG2022_genomics_exam/}";
if [[ $1 == *father* ]]; 
then
bowtie2 -U $1 -p 8 -x /home/BCG2022_genomics_exam/uni --rg-id 'SF' --rg "SM:father" | samtools view -Sb | samtools sort -o $var1.bam; echo "$1 aligned"; elif
[[ $1 == *mother* ]]; then bowtie2 -U $1 -p 8 -x /home/BCG2022_genomics_exam/uni --rg-id 'SM' --rg "SM:mother" | samtools view -Sb | samtools sort -o $var1.bam; echo "$1 aligned";
else 
bowtie2 -U $1 -p 8 -x /home/BCG2022_genomics_exam/uni --rg-id 'SC' --rg "SM:child" | samtools view -Sb | samtools sort -o $var1.bam; echo "$1 aligned";
fi; }

export -f align

echo "Write the cases you want to analyse like this case###, each  separetd by a space, then press enter:"; read -a names; prova=${names[@]} ; tempo=$(date +%Y-%m-%d--%H:%M:%S ); prov="$prova $tempo"; mkdir "${prov}"
cd "${prov}";
for i in "${names[@]}"; do 
find /home/BCG2022_genomics_exam -type f -name "${i}*" -exec bash -c "align \"{}\"" \;;
done

for file in *.bam; 
do
if [[ $file == *father.bam* ]]; 
then 
bedtools genomecov -ibam $file -bg -trackline -trackopts 'name="father"' -max 100 > "${file%%.*}Cov".bg; echo "Coverage of track of "${file%%.*}" generated"; 
elif [[ $file == *mother.bam* ]];
then
bedtools genomecov -ibam $file -bg -trackline -trackopts 'name="mother"' -max 100 > "${file%%.*}Cov".bg; echo "Coverage of track of "${file%%.*}" generated";
else
bedtools genomecov -ibam $file -bg -trackline -trackopts 'name="child"' -max 100 > "${file%%.*}Cov".bg; echo "Coverage of track of "${file%%.*}" generated";
fi; 
done

mkdir Coverage; mv *.bg Coverage/

for file in *.bam; do samtools index $file; echo ${file} indexed; done

mkdir Indexed; mv *.bai Indexed/

printf '%s\0' *.bam | xargs -0 -n 3 sh -c 'echo "Creating vcf file for "${1%_*}; freebayes -f /home/BCG2022_genomics_exam/universe.fasta -m 20 -C 5 -Q 10 --min-coverage 10 "$3" "$1" "$2" >"${1%_*}.vcf"; echo "Vcf file for "${1%_*} created' sh

echo "Insert cases that are dominant, if none just press enter:"; read -a names; for i in "${names[@]}"; do find . -type f -name "${i}.vcf" -exec sh -c 'x="{}"; mv "${x##*/}" Dominant"${x##*/}"' \; ; done

for file in *.vcf;
do
if [[ $file == *Dominant* ]];
then
awk -F'\t' ' /^#/    { print > ("candilist"FILENAME) } ($10 ~/^0\/0/ || $10 ~/^0\/1/ || $10 ~/^0\/2/) && ($11 ~/^0\/0/ || $11 ~/^0\/1/ || $11 ~/^0\/2/) && ($12 ~/^0\/1/ || $12 ~/^0\/2/){ print >>("candilist"FILENAME) }' "$file"; echo ${file}" filtered" ;
else
awk -F'\t' '/^#/    { print > ("candilistRecessive"FILENAME) } ($10 ~/^0\/1/ || $10 ~/^0\/2/ || $10 ~/^1\/2/ ) && ($11 ~/^0\/1/ || $11 ~/^0\/2/ || $11 ~/^1\/2/ ) && ($12 ~/^1\/1/ || $12 ~/^2\/2/){ print >>("candilistRecessive"FILENAME) }' "$file";    echo ${file} "filtered";
fi;
done

printf '%s\0' *candilist* | xargs -0 -n 1 sh -c 'bedtools intersect -a $1 -b /home/BCG2022_genomics_exam/targetsPad100.bed -u > "TG${1%.*}.vcf"' sh


mkdir FilesforVEP; mv TG* FilesforVEP/
mkdir Notfilteredcandilist; mv cand* Notfilteredcandilist/
mkdir Freebayesout; mv *.vcf Freebayesout/
mkdir Bowtie2out; mv *.bam Bowtie2out/
echo "end"

