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
    RELEASE=${WB_RELEASE}
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

for org in "${PATHPART[@]}'; do

done


DATADIR=/jbrowse/data


cd $DATADIR

UPLOADTOS3PATH=/agr_jbrowse_config/scripts/upload_to_S3.pl


parallel -j "95%" $UPLOADTOS3PATH --bucket $AWSBUCKET --local {} --remote "docker/$RELEASE/"{} --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET ::: "${SPECIESLIST[@]}"
 


