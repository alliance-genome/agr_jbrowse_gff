#Note that for the upload command to work, the AWS access key and the AWS
# secret key must supplied as environment variables call AWS_ACCESS_KEY and
# AWS_SECRET_KEY
#
# Example invocation:

#     docker build --no-cache -f Dockerfile -t test-gff . 
#     docker run --rm -e "AWS_ACCESS_KEY=<AWSACCESS>" -e "AWS_SECRET_KEY=<AWSSECRET>" test-gff

# The script "parallel.sh" is also allows specifying what S3 bucket to use
# via an environment variable called AWS_S3_BUCKET but the default is agrjbrowse, the
# Alliance bucket for jbrowse data.  It also assumes the path is SOMETHING
# which is what the trackList.json (JBrowse's track config file) assumes as well. 
# So, if you want to use a different bucket or path, it needs to be changed both in the
# parallel.sh script as well as in /jbrowse/data/*/trackList.json file (basically,
# all of the urlTemplate entries for NCList tracks).

# Also note that this image only processes GFF files into NCList json and does
# not deal with processing FASTA data (since it changes relatively infrequently,
# that is the sort of thing that ought to be done "by hand").  It also doesn't deal
# with any other file times like BigWig or VCF.

FROM gmod/jbrowse-gff-base:latest 

LABEL maintainer="scott@scottcain.net"

RUN git clone --single-branch --branch main https://github.com/alliance-genome/agr_jbrowse_gff.git
RUN git clone --single-branch --branch master https://github.com/alliance-genome/agr_jbrowse_config.git

RUN cp /agr_jbrowse_gff/parallel.sh / && \
    mkdir -p /jbrowse/data/seq 



VOLUME /data
CMD ["/bin/bash", "/parallel.sh"]
