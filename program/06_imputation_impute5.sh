#!/bin/bash

mkdir -p $IMPUTE 2>&1 > /dev/null
wait

if [[ $PHASING_PROGRAM == "eagle" || $PHASING_PROGRAM == "beagle" || $PHASING_PROGRAM == "shapeit4" || $PHASING_PROGRAM == "glimpse" || $PHASING_PROGRAM == "whatshap" || $PHASING_PROGRAM == "stitch" ]]; then
   VCF=$PHASE/phased_"$FileExtension".vcf.gz
   
else

   if [[ $MAF != 0 || $MISSING != 0 ]]; then
      VCF=$FILTER/filtered_"$FileExtension".vcf.gz
   else

      if [[ $DOWN_SCALING != 0 ]]; then
         VCF=$DOWN_SCALED/test/test_"$FileExtension".vcf.gz
      else
      
         if [[ -f $SWITCH/biallelic_"$FileExtension"_fixref_sorted.vcf.gz ]]; then
            VCF=$SWITCH/biallelic_"$FileExtension"_fixref_sorted.vcf.gz
         else
            VCF=$GENO_PANEL
         fi

      fi
   fi
fi
wait

if [[ $DOWN_SCALING != 0 ]]; then
   REF_PANEL=$DOWN_SCALED/train/train_"$FileExtension".vcf.gz
fi
wait


echo
echo "#@################################################"
echo "#@ IMPUTATION : Chromosome $REGION"
echo "#@ NAME OF ANALYSIS: $OUTPUT_NAME"
D1=`date "+%D    %T"`
echo "#@ Date and Time: $D1"
echo
       #################################

START1=$(date +%s)

CHROM_LENGTH=$(awk -v CHR="$CHR" '$1 == CHR {print $2}' $REF_GENOME.fai)
chunkEnd=0
id=0

while [[ $chunkEnd -lt $CHROM_LENGTH ]]; do
   id=$(( id + 1 ))
   chunkStart=$(( chunkEnd + 1 ))
   chunkEnd=$(( chunkEnd + 5000000 ))

   impute5 \
   --h $REF_PANEL \
   --g $VCF \
   --r "$CHR":"$chunkStart"-"$chunkEnd" \
   --b 300 \
   --o $IMPUTE/imputed_"$FileExtension"_"$id".vcf \
   --out-gp-field --out-ap-field \
   --threads $THREADS
done
wait

### Merging chunks
bcftools view --threads $THREADS -h $IMPUTE/imputed_"$FileExtension"_1.vcf > $IMPUTE/imputed_"$FileExtension".vcf
wait
for i in $(seq 1 1 $id); do
   bcftools view --threads $THREADS -H $IMPUTE/imputed_"$FileExtension"_"$i".vcf >> $IMPUTE/imputed_"$FileExtension".vcf
done
wait

bgzip -@ $THREADS $IMPUTE/imputed_"$FileExtension".vcf
wait
bcftools index -f -t --threads $THREADS $IMPUTE/imputed_"$FileExtension".vcf.gz
wait
rm -r $IMPUTE/imputed_"$FileExtension"_*.vcf 2> /dev/null
wait


END1=$(date +%s)
DIFF1=$(( $END1 - $START1 ))

echo
echo "#@ IMPUTATION CHROMOSOME $REGION TOOK $(printf '%dh:%dm:%ds\n' $(($DIFF1/3600)) $(($DIFF1%3600/60)) $(($DIFF1%60)))"
echo "#@##################################################################"
echo

