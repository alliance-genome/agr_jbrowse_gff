# agr_jbrowse_gff

Tools for processing Alliance GFF into JBrowse NCList

# What this Docker file does

The container defined by the Docker file in this repo does several things:

- Fetches the _latest_ GFF files for each assembly from the FMS (see note/warning
  below).
- Creates BED and MCScanX-style anchor files for the orthology/synteny tracks.
- Processes the GFF in to JBrowse NCList tracks and does search indexing.
- Uploads all of this to the agrjbrowse S3 bucket.
