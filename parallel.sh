#!/bin/bash

#set -e

RELEASE=6.0.0

while getopts r:s:a:k: option
do
case "${option}"
in
#r) 
#  RELEASE=${OPTARG}
#  ;;
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

#if [ -z "$RELEASE" ]
#then
#    RELEASE=${RELEASE}
#fi

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
        AWSBUCKET=agrjbrowse
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
'XenBase/x_laevis'
'XenBase/x_tropicalis'
)

PATHPART=(
'FB'
'MGI'
'RGD'
'HUMAN'
'SGD'
'WB'
'ZFIN'
'XBXL'
'XBXT'
)

WORKDIR=/jbrowse
cd $WORKDIR

#parallel wget -q https://fms.alliancegenome.org/download/GFF_{}.gff.gz ::: "${PATHPART[@]}"
curl https://fms.alliancegenome.org/api/datafile/by/GFF?latest=true | python3 /get_gff_urls.py | parallel


#sloppy way to match the number in the file name 
parallel gzip -d GFF_{}*.gff.gz ::: "${PATHPART[@]}"
parallel mv GFF_{}*.gff GFF_{}.gff ::: "${PATHPART[@]}"

echo "starting flatfile_to_json"
parallel --link bin/flatfile-to-json.pl --compress --gff GFF_{1}.gff --out data/{2} --type gene,ncRNA_gene,pseudogene,rRNA_gene,snRNA_gene,snoRNA_gene,tRNA_gene,telomerase_RNA_gene,transposable_element_gene --trackLabel "All_Genes"  --trackType CanvasFeatures --key "All_Genes" --maxLookback 1000000 ::: "${PATHPART[@]}" ::: "${SPECIESLIST[@]}"

echo "starting generate_names"
parallel bin/generate-names.pl --compress --out data/{} ::: "${SPECIESLIST[@]}"

DATADIR=/jbrowse/data


cd $DATADIR

UPLOADTOS3PATH=/agr_jbrowse_config/scripts/upload_to_S3.pl


parallel $UPLOADTOS3PATH --skipseq --bucket $AWSBUCKET --local {} --remote "docker/$RELEASE/"{} --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET ::: "${SPECIESLIST[@]}"
 


