#!/bin/bash

set -e

RELEASE=9.1.0

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
'zfin/zebrafish'
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
parallel gzip -df GFF_{}*.gff.gz ::: "${PATHPART[@]}"
parallel mv GFF_{}*.gff GFF_{}.gff ::: "${PATHPART[@]}"

#create bed files for orthology tracks
parallel /agr_jbrowse_gff/scripts/gff2bedgenes.pl {} ::: "${PATHPART[@]}"
parallel AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET aws s3 cp --acl public-read {}.bed s3://agrjbrowse/orthology/$RELEASE/ ::: "${PATHPART[@]}"

cat *lookup.txt > all.lookup.txt
AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET aws s3 cp --acl public-read all.lookup.txt s3://agrjbrowse/orthology/$RELEASE/

# fetch orthology file and split to anchors files and upload
/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE stringent
/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE moderate
/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE none
/agr_jbrowse_gff/scripts/split2pairwise.pl $RELEASE best

echo "starting sort/bgzip/tabix"

for i in {0..8}
do
    jbrowse sort-gff GFF_${PATHPART[$i]}.gff | bgzip > GFF_${PATHPART[$i]}.sorted.gff.gz
    tabix -p gff GFF_${PATHPART[$i]}.sorted.gff.gz
done

echo "starting text-index"

for i in {0..8}
do
    jbrowse text-index --file GFF_${PATHPART[$i]}.sorted.gff.gz --out data/${SPECIESLIST[$i]}
done

echo "starting upload to S3"

for i in {0..8}
do
    AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET \
        aws s3 cp --acl public-read GFF_${PATHPART[$i]}.sorted.gff.gz \
        s3://$AWSBUCKET/docker/$RELEASE/${SPECIESLIST[$i]}/
    AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET \
        aws s3 cp --acl public-read GFF_${PATHPART[$i]}.sorted.gff.gz.tbi \
        s3://$AWSBUCKET/docker/$RELEASE/${SPECIESLIST[$i]}/
    AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET \
        aws s3 cp --acl public-read --recursive data/${SPECIESLIST[$i]}/trix \
        s3://$AWSBUCKET/docker/$RELEASE/${SPECIESLIST[$i]}/trix/
done
 


