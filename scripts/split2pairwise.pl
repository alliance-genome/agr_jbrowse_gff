#!/usr/bin/perl
use strict;
use warnings;
use JSON;

my $RELEASE = $ARGV[0];
my $TYPE    = $ARGV[1]; # one of "best", "stringent", "moderate" or "none"

die "no release defined" unless $RELEASE;
die "no filter level defined, should be one of 'stringent', 'moderate' or 'none" unless $TYPE;

system("curl -o combined.json https://fms.alliancegenome.org/api/datafile/by/ORTHO?latest=true") == 0
     or die "fetching orthology info failed: $!";

my $blob;
{
        local $/ = undef;
	open JS, "<combined.json" or die "couldn't open combined.json: $!";
        $blob = <JS>;
	close JS;
}

my $json = JSON->new->decode($blob);

for my $section (@{$json}) {
    next if ($$section{'s3Url'} =~ /1\.0\.1\.7/);
    system("curl -O $$section{'s3Url'}") == 0 or die "failed fetching $$section{'s3Url'}: $!";
}

my @compressed_json = <*.json.gz>;
my @jsons;
for my $file (@compressed_json) {
    system("gzip -d $file") == 0 or die "failed uncompressing $file: $!";
    my $temp ;
    if ($file =~ /(.*)\.gz/) {
        push @jsons, $1;
    } else {
        warn "this shouldn't happen: $file";
	push @jsons, $file;
    }
}

#fetch ID->symbol lookup file
system("curl -O https://s3.amazonaws.com/agrjbrowse/orthology/7.0.0/all.lookup.txt");
my %lookup;
open LOOKUP, "<all.lookup.txt" or die "couldn't open all.lookup.txt: $!";
while (<LOOKUP>) {
    chomp;
    my ($id, $symbol) = split /\t/;
    $lookup{$id} = $symbol;
}
close LOOKUP;


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
	"7955" => "z",
	"8364" => "xt",
	"8355" => "xl",
	"6239" => "w",
	"7227" => "f",
	"10090" => "m",
	"10116" => "r",
	"9606" => "h",
	"4932" => "y",  #"559292" => "y",
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
    next unless $line[3];
    $genes{'9606'}{$line[3]}++;
}
while(<$ratbed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'10116'}{$line[3]}++;
}
while(<$mousebed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'10090'}{$line[3]}++;
}
while(<$fishbed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'7955'}{$line[3]}++;
}
while(<$yeastbed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'4932'}{$line[3]}++;  #$genes{'559292'}{$line[3]}++;
}
while(<$wormbed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'6239'}{$line[3]}++;
}
while(<$flybed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'7227'}{$line[3]}++;
}
while(<$Xlbed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'8355'}{$line[3]}++;
}
while(<$Xtbed>) {
    chomp;
    my @line = split /\t/;
    next unless $line[3];
    $genes{'8364'}{$line[3]}++;
}

my %species_prefix = (
    '9606'   => '',
    '10116'  => '',
    '10090'  => '',
    '7955'   => 'ZFIN:',
    '559292' => 'SGD:',
    '4932'   => 'SGD:',
    '6239'   => 'WB:',
    '7227'   => 'FB:',
    '8355'   => '',
    '8364'   => ''
);

my %seen;
for my $org (@jsons) {

    {
        local $/ = undef;
        open JS, "<$org" or die "couldn't open combined.json: $!";
        $blob = <JS>;
        close JS;
    }

    my $data = JSON->new->decode($blob);

    for my $section (@{$$data{'data'}}) {

	    #need to handle geneID to geneSymbol mappings
        my $species1 = $$section{'gene1Species'};
	my $gene1    = substr($$section{'gene1'},5);
        my $species2 = $$section{'gene2Species'};
	my $gene2    = substr($$section{'gene2'},5);

        if ($species_prefix{$species1}) {
            $gene1 = $species_prefix{$species1}.$gene1;
	}
	if ($species_prefix{$species2}) {
            $gene2 = $species_prefix{$species2}.$gene2;
	}

	if ($species1 == 10116 and $species2 == '559292') {
  	    warn $gene2, $gene1;
        }

        next unless $gene1;
	next unless $gene2;

	$gene1 = $lookup{$gene1};
	$gene2 = $lookup{$gene2};
	
	next unless $gene1;
	next unless $gene2;

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
            my $genetemp    = $gene1;
            my $speciestemp = $species1;
            $gene1    = $gene2;
            $species1 = $species2;
            $gene2    = $genetemp;
            $species2 = $speciestemp;
            next if $seen{$species2}{$gene2}{$species1}{$gene1};
            next if $seen{$species1}{$gene1}{$species2}{$gene2};
            $fh = $$filehandle_map{$$species_map{$species1} . "2" . $$species_map{$species2}};
        }

	if ($TYPE eq 'best') {
            if ( $$section{'isBestRevScore'} eq'Yes' and $$section{'isBestScore'} =~ /Yes/ ) {
                $seen{$species1}{$gene1}{$species2}{$gene2}++;
                print $fh "$gene1\t$gene2\t100\n";
	    }
	}
        if ($TYPE eq 'stringent') {
            if ( $$section{'strictFilter'} ) {
	        $seen{$species1}{$gene1}{$species2}{$gene2}++;
                print $fh "$gene1\t$gene2\t100\n";
            }
        } 
        elsif ($TYPE eq 'moderate') {
            if ( $$section{'moderateFilter'} or $$section{'strictFilter'} ) {
	        $seen{$species1}{$gene1}{$species2}{$gene2}++;
                print $fh "$gene1\t$gene2\t100\n";
   	    }
        }
        elsif ($TYPE eq 'none') {
	    $seen{$species1}{$gene1}{$species2}{$gene2}++;
            print $fh "$gene1\t$gene2\t100\n";
        }
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

unlink glob "*_1.json";
unlink glob "*.anchors";

