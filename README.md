# agr_jbrowse_gff

Tools for processing Alliance GFF into JBrowse NCList

# What this Docker file does

The container defined by the Docker file in this repo does several things:

- Fetches the _latest_ GFF files for each assembly for a release from the FMS.
- Creates BED and MCScanX-style anchor files for the orthology/synteny tracks.
- Processes the GFF in to JBrowse NCList tracks and does search indexing.
- Uploads all of this to the agrjbrowse S3 bucket.

# Typical workflow

1. When all of the GFF files are in place in the FMS for the coming release,
   update the `RELEASE=` in parallel.sh to the release you're building and commit
   and push the change.

2. Unpause the `JBrowseSoftwareProcessAGR` and `JBrowseProcessAGR` pipelines
   in GoCD, which will allow the Docker containers to build and run.

3. Run the workflow in the VCF processing container (assuming the VCF files
   are in the FMS), https://github.com/alliance-genome/agr_jbrowse_vcf.

4. In the JBrowse 2 repo stage branch
   (https://github.com/alliance-genome/agr_amplify_jbrowse2) update references
   to the previous release to the upcoming release. This can be done with `sed`
   or a `perl` one liner:

   ```
   perl -pi -e 's/7\.2\.0/7.3.0/' config.json
   ```

   Though I often do it in multiple steps while editing in vim to make sure
   there aren't any unintended side effects. Commit and push these changes and
   then check that the stage JBrowse 2 instance is doing what you expect.

5. Update the Apollo container, by updating the fetch_vcf script in agr_jbrowse_config
   and rebuild the apollo container in GoCD.
