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

TRACKID=(
'Drosophila_melanogaster_all_genes'
'Mus_musculus_all_genes'
'Rattus_norvegicus_all_genes'
'Homo_sapiens_all_genes'
'Saccharomyces_cerevisiae_all_genes'
'Caenorhabditis_elegans_all_genes'
'Danio_rerio_all_genes'
'Xenopus_laevis_all_genes'
'Xenopus_tropicalis_all_genes'
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

parallel "jbrowse sort-gff GFF_{}.gff | bgzip > GFF_{}.sorted.gff.gz && tabix -p gff GFF_{}.sorted.gff.gz" ::: "${PATHPART[@]}"

echo "starting text-index"

parallel --link "jbrowse text-index --fileId {1} --file GFF_{2}.sorted.gff.gz --out data/{3}" ::: "${TRACKID[@]}" ::: "${PATHPART[@]}" ::: "${SPECIESLIST[@]}"

echo "starting upload to S3"

parallel --link "AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET aws s3 cp --acl public-read GFF_{1}.sorted.gff.gz s3://$AWSBUCKET/docker/$RELEASE/{2}/ && AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET aws s3 cp --acl public-read GFF_{1}.sorted.gff.gz.tbi s3://$AWSBUCKET/docker/$RELEASE/{2}/ && AWS_ACCESS_KEY_ID=$AWSACCESS AWS_SECRET_ACCESS_KEY=$AWSSECRET aws s3 cp --acl public-read --recursive data/{2}/trix s3://$AWSBUCKET/docker/$RELEASE/{2}/trix/" ::: "${PATHPART[@]}" ::: "${SPECIESLIST[@]}"
 


