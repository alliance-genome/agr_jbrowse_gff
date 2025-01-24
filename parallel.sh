#!/bin/bash

set -e

RELEASE=8.0.0

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

#https://fms.alliancegenome.org/api/datafile/by/7.3.0/GFF/ZFIN?latest=true
#parallel wget -q https://fms.alliancegenome.org/download/GFF_{}.gff.gz ::: "${PATHPART[@]}"

#parallel wget -q https://fms.alliancegenome.org/api/datafile/by/$RELEASE/GFF/{}?latest=true :::"${PATHPART[@]}"
#curl https://fms.alliancegenome.org/api/datafile/by/GFF?latest=true | python3 /get_gff_urls.py | parallel

#parallel (curl https://fms.alliancegenome.org/api/datafile/by/$RELEASE/GFF/{}?latest=true | python3 /get_gff_urls.py) ::: "${PATHPART[@]}"
for mod in "${PATHPART[@]}"
do
    curl https://fms.alliancegenome.org/api/datafile/by/$RELEASE/GFF/$mod?latest=true | python3 /get_gff_urls.py
done

#sloppy way to match the number in the file name 
parallel gzip -d GFF_{}*.gff.gz ::: "${PATHPART[@]}"
parallel mv GFF_{}*.gff GFF_{}.gff ::: "${PATHPART[@]}"

#create bed files for orthology tracks
#parallel /agr_jbrowse_gff/scripts/gff2bedgenes.pl {} ::: "${PATHPART[@]}"
#parallel AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET aws s3 cp --acl public-read {}.bed s3://agrjbrowse/orthology/$RELEASE/ ::: "${PATHPART[@]}"

#cat *lookup.txt > all.lookup.txt
#AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET aws s3 cp --acl public-read all.lookup.txt s3://agrjbrowse/orthology/$RELEASE/

# fetch orthology file and split to anchors files and upload
#/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE stringent
#/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE moderate
#/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE none
#/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE best

#will want to add sorting, bgzipping and tabix indexing of GFF files here 

echo "starting flatfile_to_json"

for i in {0..8}
do
    echo "$i"
    #jbrowse sort-gff GFF_${PATHPART[$i]}.gff > GFF_${PATHPART[$i]}.gff.sorted


    bin/flatfile-to-json.pl --compress --gff GFF_${PATHPART[$i]}.gff --out data/${SPECIESLIST[$i]} --type gene,ncRNA_gene,pseudogene,rRNA_gene,snRNA_gene,snoRNA_gene,tRNA_gene,telomerase_RNA_gene,transposable_element_gene --trackLabel "All_Genes"  --trackType CanvasFeatures --key "All_Genes" 

    echo "$i"
done

echo "starting generate_names"
parallel -j 1 bin/generate-names.pl --compress --out data/{} ::: "${SPECIESLIST[@]}"

DATADIR=/jbrowse/data


cd $DATADIR

UPLOADTOS3PATH=/agr_jbrowse_config/scripts/upload_to_S3.pl


parallel -j 1 $UPLOADTOS3PATH --skipseq --bucket $AWSBUCKET --local {} --remote "docker/$RELEASE/"{} --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET ::: "${SPECIESLIST[@]}"
 


