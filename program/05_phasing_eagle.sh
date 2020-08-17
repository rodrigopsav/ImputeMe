#!/bin/bash

mkdir -p $PHASE 2>&1 > /dev/null
wait

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
wait


if [[ $DOWN_SCALING != 0 ]]; then
   REF_PANEL=$DOWN_SCALED/train/train_"$FileExtension".vcf.gz
fi
wait


if [[ "$GENETIC_MAP" == "1cMperMb" ]]; then
   GENETIC_MAP=$IMPUTEME_DIR/program/genetic_map_1cMperMb.txt
fi
wait


echo
echo "#@################################################"
echo "#@ PHASING LOW DENSITY PANEL: Chromosome $REGION"
echo "#@ NAME OF ANALYSIS: $OUTPUT_NAME"
D1=`date "+%D    %T"`
echo "#@ Date and Time: $D1"
echo
       #################################

START1=$(date +%s)
 
if [[ -z $REF_PANEL ]]; then
   
   cd $PHASE
   $CONDA/bin/eagle \
   --geneticMapFile=$GENETIC_MAP \
   --vcf=$VCF \
   --chrom=$CHR \
   --bpStart=$BPSTART \
   --bpEnd=$BPEND \
   --chromX=$((CHROM_SET +1)) \
   --numThreads=$THREADS \
   --vcfOutFormat=z \
   --outPrefix=phased_"$FileExtension"
    wait
 
   bcftools index -f -t --threads $THREADS $PHASE/phased_"$FileExtension".vcf.gz
   wait

else
   
   cd $PHASE   
   $CONDA/bin/eagle \
   --geneticMapFile=$GENETIC_MAP \
   --vcfRef=$REF_PANEL  \
   --vcfTarget=$VCF \
   --chrom=$CHR \
   --bpStart=$BPSTART \
   --bpEnd=$BPEND \
   --chromX=$((CHROM_SET +1)) \
   --numThreads=$THREADS \
   --vcfOutFormat=z \
   --outPrefix=phased_"$FileExtension"
   
   bcftools index -f -t --threads $THREADS $PHASE/phased_"$FileExtension".vcf.gz
   wait

fi
wait


END1=$(date +%s)
DIFF1=$(( $END1 - $START1 ))

echo
echo "#@ PHASING LOW DENSITY PANEL CHROMOSOME $REGION TOOK $(printf '%dh:%dm:%ds\n' $(($DIFF1/3600)) $(($DIFF1%3600/60)) $(($DIFF1%60)))"
echo "#@##################################################################"
echo






