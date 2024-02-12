#!/usr/bin/perl
use strict;
use warnings;
use JSON;

my $RELEASE = $ARGV[0];
my $TYPE    = $ARGV[1]; # one of "stringent", "moderate" or "none"

die "no release defined" unless $RELEASE;
die "no filter level defined, should be one of 'stringent', 'moderate' or 'none" unless $TYPE;

#fetch orthology file
system("curl -o combined.json https://fms.alliancegenome.org/api/datafile/by/ORTHOLOGY-ALLIANCE/COMBINED?latest=true") == 0
     or die "fetching orthology info failed: $!";

my $blob;
{
        local $/ = undef;
	open JS, "<combined.json" or die "couldn't open combined.json: $!";
        $blob = <JS>;
	print $blob;
	close JS;
}

my $json = JSON->new->decode($blob);
print $json;
my $combined_url = $$json[0]{'s3Url'};
system("curl -o ORTHOLOGY-ALLIANCE_COMBINED_5.tsv.gz $combined_url") == 0
    or die "fetching orthology tsv failed: $!";

system("gzip -d ORTHOLOGY-ALLIANCE_COMBINED_5.tsv.gz") == 0
    or die "unzipping orthology tsv failed: $!";

open ORTHOLOGY, "<ORTHOLOGY-ALLIANCE_COMBINED_5.tsv" or die "opening orthology file failed: $!";

open my $h2r, ">", "human2rat.$TYPE.anchors" or die "Can't open human2rat.$TYPE.anchors:$!";
open my $h2m, ">", "human2mouse.$TYPE.anchors" or die "Can't open human2mouse.$TYPE.anchors:$!";
open my $h2z, ">", "human2zebrafish.$TYPE.anchors" or die "Can't open human2zebrafish.$TYPE.anchors:$!";
open my $h2xl, ">", "human2xenopuslaevis.$TYPE.anchors" or die "Can't open human2xenopuslaevis.$TYPE.anchors:$!";
open my $h2xt, ">", "human2xenopustropicalis.$TYPE.anchors" or die "Can't open human2xenopustropicalis.$TYPE.anchors:$!";
open my $h2w, ">", "human2worm.$TYPE.anchors" or die "Can't open human2worm.$TYPE.anchors:$!";
open my $h2f, ">", "human2fly.$TYPE.anchors" or die "Can't open human2fly.$TYPE.anchors:$!";
open my $h2y, ">", "human2yeast.$TYPE.anchors" or die "Can't open human2yeast.$TYPE.anchors:$!";

open my $r2m, ">", "rat2mouse.$TYPE.anchors" or die "Can't open rat2mouse.$TYPE.anchors:$!";
open my $r2z, ">", "rat2zebrafish.$TYPE.anchors" or die "Can't open rat2zebrafish.$TYPE.anchors:$!";
open my $r2xl, ">", "rat2xenopuslaevis.$TYPE.anchors" or die "Can't open rat2xenopuslaevis.$TYPE.anchors:$!";
open my $r2xt, ">", "rat2xenopustropicalis.$TYPE.anchors" or die "Can't open rat2xenopustropicalis.$TYPE.anchors:$!";
open my $r2w, ">", "rat2worm.$TYPE.anchors" or die "Can't open rat2worm.$TYPE.anchors:$!";
open my $r2f, ">", "rat2fly.$TYPE.anchors" or die "Can't open rat2fly.$TYPE.anchors:$!";
open my $r2y, ">", "rat2yeast.$TYPE.anchors" or die "Can't open rat2yeast.$TYPE.anchors:$!";

open my $m2z, ">", "mouse2zebrafish.$TYPE.anchors" or die "Can't open mouse2zebrafish.$TYPE.anchors:$!";
open my $m2xl, ">", "mouse2xenopuslaevis.$TYPE.anchors" or die "Can't open mouse2xenopuslaevis.$TYPE.anchors:$!";
open my $m2xt, ">", "mouse2xenopustropicalis.$TYPE.anchors" or die "Can't open mouse2xenopustropicalis.$TYPE.anchors:$!";
open my $m2w, ">", "mouse2worm.$TYPE.anchors" or die "Can't open mouse2worm.$TYPE.anchors:$!";
open my $m2f, ">", "mouse2fly.$TYPE.anchors" or die "Can't open mouse2fly.$TYPE.anchors:$!";
open my $m2y, ">", "mouse2yeast.$TYPE.anchors" or die "Can't open mouse2yeast.$TYPE.anchors:$!";

open my $z2xl, ">", "zebrafish2xenopuslaevis.$TYPE.anchors" or die "Can't open zebrafish2xenopuslaevis.$TYPE.anchors:$!";
open my $z2xt, ">", "zebrafish2xenopustropicalis.$TYPE.anchors" or die "Can't open zebrafish2xenopustropicalis.$TYPE.anchors:$!";
open my $z2w, ">", "zebrafish2worm.$TYPE.anchors" or die "Can't open zebrafish2worm.$TYPE.anchors:$!";
open my $z2f, ">", "zebrafish2fly.$TYPE.anchors" or die "Can't open zebrafish2fly.$TYPE.anchors:$!";
open my $z2y, ">", "zebrafish2yeast.$TYPE.anchors" or die "Can't open zebrafish2yeast.$TYPE.anchors:$!";

open my $xl2xt, ">", "xenopuslaevis2xenopustropicalis.$TYPE.anchors" or die "Can't open xenopuslaevis2xenopustropicalis.$TYPE.anchors:$!";
open my $xl2w, ">", "xenopuslaevis2worm.$TYPE.anchors" or die "Can't open xenopuslaevis2worm.$TYPE.anchors:$!";
open my $xl2f, ">", "xenopuslaevis2fly.$TYPE.anchors" or die "Can't open xenopuslaevis2fly.$TYPE.anchors:$!";
open my $xl2y, ">", "xenopuslaevis2yeast.$TYPE.anchors" or die "Can't open xenopuslaevis2yeast.$TYPE.anchors:$!";

open my $xt2w, ">", "xenopustropicalis2worm.$TYPE.anchors" or die "Can't open xenopustropicalis2worm.$TYPE.anchors:$!";
open my $xt2f, ">", "xenopustropicalis2fly.$TYPE.anchors" or die "Can't open xenopustropicalis2fly.$TYPE.anchors:$!";
open my $xt2y, ">", "xenopustropicalis2yeast.$TYPE.anchors" or die "Can't open xenopustropicalis2yeast.$TYPE.anchors:$!";

open my $w2f, ">", "worm2fly.$TYPE.anchors" or die "Can't open worm2fly.$TYPE.anchors:$!";
open my $w2y, ">", "worm2yeast.$TYPE.anchors" or die "Can't open worm2yeast.$TYPE.anchors:$!";

open my $f2y, ">", "fly2yeast.$TYPE.anchors" or die "Can't open fly2yeast.$TYPE.anchors:$!";

my $species_map ={ 
	"NCBITaxon:7955" => "z",
	"NCBITaxon:8364" => "xt",
	"NCBITaxon:8355" => "xl",
	"NCBITaxon:6239" => "w",
	"NCBITaxon:7227" => "f",
	"NCBITaxon:10090" => "m",
	"NCBITaxon:10116" => "r",
	"NCBITaxon:9606" => "h",
	"NCBITaxon:559292" => "y",
};

my $filehandle_map = {
	"h2m" => $h2m,
	"h2r" => $h2r,
	"h2z" => $h2z,
	"h2xt" => $h2xt,
	"h2xl" => $h2xl,
	"h2w" => $h2w,
	"h2f" => $h2f,
	"h2y" => $h2y,
	"r2m" => $r2m,
	"r2z" => $r2z,
	"r2xl" => $r2xl,
	"r2xt" => $r2xt,
	"r2w" => $r2w,
	"r2f" => $r2f,
	"r2y" => $r2y,
	"m2z" => $m2z,
	"m2xl" => $m2xl,
	"m2xt" => $m2xt,
	"m2w" => $m2w,
	"m2f" => $m2f,
	"m2y" => $m2y,
	"z2xl" => $z2xl,
	"z2xt" => $z2xt,
	"z2w" => $z2w,
	"z2f" => $z2f,
	"z2y" => $z2y,
	"xl2xt" => $xl2xt,
	"xl2w" => $xl2w,
	"xl2f" => $xl2f,
	"xl2y" => $xl2y,
	"xt2w" => $xt2w,
	"xt2f" => $xt2f,
	"xt2y" => $xt2y,
	"w2f" => $w2f,
	"w2y" => $w2y,
	"f2y" => $f2y,
};

#read in the species bed files to check for gene existance later
open my $humanbed, "<", "HUMAN.bed" or die "Can't open gff/HUMAN.bed:$!";
open my $ratbed  , "<", "RGD.bed"   or die "Can't open gff/RGD.bed:$!";
open my $mousebed, "<", "MGI.bed"   or die "Can't open gff/MGI.bed:$!";
open my $fishbed,  "<", "ZFIN.bed"  or die "Can't open gff/ZFIN.bed:$!";
open my $yeastbed, "<", "SGD.bed"   or die "Can't open gff/SGD.bed:$!";
open my $wormbed,  "<", "WB.bed"    or die "Can't open gff/WB.bed:$!";
open my $flybed,   "<", "FB.bed"    or die "Can't open gff/FB.bed:$!";
open my $Xlbed,    "<", "XBXL.bed"  or die "Can't open gff/XBXL.bed:$!";
open my $Xtbed,    "<", "XBXT.bed"  or die "Can't open gff/XBXT.bed:$!";

my %genes;
while(<$humanbed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:9606'}{$line[3]}++;
}
while(<$ratbed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:10116'}{$line[3]}++;
}
while(<$mousebed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:10090'}{$line[3]}++;
}
while(<$fishbed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:7955'}{$line[3]}++;
}
while(<$yeastbed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:559292'}{$line[3]}++;
}
while(<$wormbed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:6239'}{$line[3]}++;
}
while(<$flybed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:7227'}{$line[3]}++;
}
while(<$Xlbed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:8355'}{$line[3]}++;
}
while(<$Xtbed>) {
    chomp;
    my @line = split /\t/;
    $genes{'NCBITaxon:8364'}{$line[3]}++;
}


my %seen;
while(<ORTHOLOGY>) {
    next if /^#/;
    chomp;
    my $line = $_;
    my @line = split /\t/, $line;

    next if $line[0] eq 'Gene1ID';

    my $gene1 = $line[1];
    my $species1 = $line[2];
    my $gene2 = $line[5];
    my $species2 = $line[6];

    next unless $genes{$species1}{$gene1};
    next unless $genes{$species2}{$gene2};

    # already entered this combo in the opposite direction
    next if $seen{$species2}{$gene2}{$species1}{$gene1};
    next if $seen{$species1}{$gene1}{$species2}{$gene2};

    my $fh = $$filehandle_map{$$species_map{$species1} . "2" . $$species_map{$species2}};

    if (!defined $fh) {
        #print "No filehandle for $line[2] to $line[6]\n";
        #no need to warn about this
        #but swap order and see if that works
        my $genetemp = $gene1;
        my $speciestemp = $species1;
        $gene1    = $gene2;
        $species1 = $species2;
        $gene2    = $genetemp;
        $species2 = $speciestemp;
        next if $seen{$species2}{$gene2}{$species1}{$gene1};
        next if $seen{$species1}{$gene1}{$species2}{$gene2};
        $fh = $$filehandle_map{$$species_map{$species1} . "2" . $$species_map{$species2}};
    }

    #automatically include
    if ($line[8] =~ /ZFIN/ or $line[8] =~ /HGNC/ or $line[8] =~ /Xenbase/) {
        print $fh "$gene1\t$gene2\t100\n";
	$seen{$species1}{$gene1}{$species2}{$gene2}++;
	next;
    }

    my $algcount   = $line[9];
    my $besthit    = $line[11] =~ /Yes/ ? 1 : 0;
    my $revbesthit = $line[12] eq 'Yes' ? 1 : 0;
    if ($TYPE eq 'stringent') {
        if ( (($algcount > 2)  and ($besthit or $revbesthit))
	  or (($algcount == 2) and ($besthit and $revbesthit))) {
	    $seen{$species1}{$gene1}{$species2}{$gene2}++;
            print $fh "$gene1\t$gene2\t100\n";
	}
    } 
    elsif ($TYPE eq 'moderate') {
        if ( ($algcount > 2)
	  or ($algcount == 2 and ($besthit or $revbesthit) ) ) {
	    $seen{$species1}{$gene1}{$species2}{$gene2}++;
            print $fh "$gene1\t$gene2\t100\n";
	}
    }
    elsif ($TYPE eq 'none') {
	$seen{$species1}{$gene1}{$species2}{$gene2}++;
        print $fh "$gene1\t$gene2\t100\n";
    }
    else {
        warn "filter TYPE (one of stringent, moderate or none) not specified on the command line!" and die;
    }

}

for my $keys (keys %{$filehandle_map}) {
    close $$filehandle_map{$keys};
}

#deposit new anchors files in S3
my @anchors = <*$TYPE.anchors>;
for my $file (@anchors) {
    system("AWS_ACCESS_KEY_ID=$ENV{'AWS_ACCESS_KEY'} AWS_SECRET_ACCESS_KEY=$ENV{'AWS_SECRET_KEY'} aws s3 cp --acl public-read $file s3://agrjbrowse/orthology/$RELEASE/") == 0
	or die "failed to copy $file to s3: $!";
}

