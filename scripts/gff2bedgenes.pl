#!/usr/bin/perl
use strict;
use warnings;

my $IN = $ARGV[0];
my $OUT = "$IN.bed";
$IN = "GFF_$IN.gff";

my $LOOKUP = "$IN.lookup.txt";

open IN,  "<$IN"  or die "Couldn't open $IN: $!";
open OUT, ">$OUT" or die "Couldn't open $OUT: $!";
open LOOKUP, ">$LOOKUP" or die "Couldn't open $LOOKUP: $!";

while (<IN>) {
	next if /^#/;
	chomp;
	my @line = split /\t/;
	next if $line[2] ne 'gene';
	my $name = $1 if ($line[8] =~ /Name=([^;]+);/  || $line[8] =~ /Name=([^;]+)$/);
        my $curie= $1 if ($line[8] =~ /curie=([^;]+);/ || $line[8] =~ /curie=([^;]+)$/);
        next unless $name;
	print OUT join("\t", $line[0], $line[3]-1, $line[4], $name, 0, $line[6]), "\n";
        if ($curie) {
            print LOOKUP "$curie\t$name\n";
        }
}

close IN;
close OUT;
close LOOKUP;
