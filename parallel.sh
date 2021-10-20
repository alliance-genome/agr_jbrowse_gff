#!/bin/bash

#set -e

RELEASE=4.2.0
while getopts r:s:a:k: option
do
case "${option}"
in
r) 
  RELEASE=${OPTARG}
  ;;
s) 
  SPECIES=${OPTARG}
  ;;
a)
  AWSACCESS=${OPTARG}
  ;;
k)
  AWSSECRET=${OPTARG}
  ;;
esac
done

if [ -z "$RELEASE" ]
then
    RELEASE=${RELEASE}
fi

if [ -z "$AWSACCESS" ]
then
    AWSACCESS=${AWS_ACCESS_KEY}
fi

if [ -z "$AWSSECRET" ]
then
    AWSSECRET=${AWS_SECRET_KEY}
fi

if [ -z "$AWSBUCKET" ]
then
    if [ -z "${AWS_S3_BUCKET}" ]
    then
        AWSBUCKET=agrjbrowse2
    else
        AWSBUCKET=${AWS_S3_BUCKET}
    fi
fi

echo "awsbucket:"
echo $AWSBUCKET
echo "release"
echo $RELEASE

SPECIESLIST=(
'FlyBase/fruitfly'
'MGI/mouse'
'RGD/rat'
'human'
'SGD/yeast'
'WormBase/c_elegans_PRJNA13758'
'zfin/zebrafish-11'
)

PATHPART=(
'FB'
'MGI'
'RGD'
'HUMAN'
'SGD'
'WB'
'ZFIN'
)

WORKDIR=/jbrowse
cd $WORKDIR

parallel -j 2 wget https://fms.alliancegenome.org/download/GFF_{}.gff.gz ::: "${PATHPART[@]}"

parallel -j 2 --link bin/flatfile-to-json.pl --compress --gff GFF_{1}.gz --out data/{2} --type gene,ncRNA_gene,pseudogene,rRNA_gene,snRNA_gene,snoRNA_gene,tRNA_gene,telomerase_RNA_gene,transposable_element_gene --trackLabel "All Genes"  --trackType CanvasFeatures --key "All Genes" --maxLookback 1000000 ::: "${PATHPART[@]}" ::: "${SPECIESLIST[@]}"

parallel -j 2 bin/generate_names.pl --compress --out data/{} ::: "${SPECIESLIST[@]}"

DATADIR=/jbrowse/data


cd $DATADIR

UPLOADTOS3PATH=/agr_jbrowse_config/scripts/upload_to_S3.pl


parallel -j 2 $UPLOADTOS3PATH --bucket $AWSBUCKET --local {} --remote "docker/$RELEASE/"{} --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET ::: "${SPECIESLIST[@]}"
 


