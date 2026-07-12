#Note that for the upload command to work, the AWS access key and the AWS
# secret key must supplied as environment variables call AWS_ACCESS_KEY and
# AWS_SECRET_KEY
#
# Example invocation:

#     docker build --no-cache -f Dockerfile -t test-gff . 
#     docker run --rm -e "AWS_ACCESS_KEY=<AWSACCESS>" -e "AWS_SECRET_KEY=<AWSSECRET>" test-gff

# The script "parallel.sh" is also allows specifying what S3 bucket to use
# via an environment variable called AWS_S3_BUCKET but the default is agrjbrowse, the
# Alliance bucket for jbrowse data. Files are uploaded under docker/$RELEASE/<species_path>/,
# which is the path the JBrowse 2 config's Gff3TabixAdapter track definitions assume as well.
# So, if you want to use a different bucket or path, it needs to be changed both in the
# parallel.sh script as well as in the JBrowse 2 config (agr_amplify_jbrowse2 / agr_jbrowse_config).

# Also note that this image only processes GFF files into sorted, bgzipped,
# tabix-indexed GFF3 (plus a text search index) and does not deal with processing
# FASTA data (since it changes relatively infrequently, that is the sort of thing
# that ought to be done "by hand"). It also doesn't deal with any other file types
# like BigWig or VCF.

FROM gmod/jbrowse-gff-base:latest 

LABEL maintainer="scott@scottcain.net"

RUN git clone --single-branch --branch main https://github.com/alliance-genome/agr_jbrowse_gff.git
RUN git clone --single-branch --branch stage https://github.com/alliance-genome/agr_jbrowse_config.git

RUN cp /agr_jbrowse_gff/parallel.sh / && \
    cp /agr_jbrowse_gff/get_gff_urls.py /


VOLUME /data
CMD ["/bin/bash", "/parallel.sh"]
