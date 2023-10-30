#!/usr/bin/perl
use strict;
use warnings;

my $IN = $ARGV[0];
my $OUT = "$IN.bed";
$IN = "GFF_$IN.gff";

open IN,  "<$IN"  or die "Couldn't open $IN: $!";
open OUT, ">$OUT" or die "Couldn't open $OUT: $!";

while (<IN>) {
	next if /^#/;
	my @line = split /\t/;
	next if $line[2] ne 'gene';
	my $name = $1 if ($line[8] =~ /Name=([^;]+);/ || $line[8] =~ /Name=([^;]+)$/);
        next unless $name;
	print OUT join("\t", $line[0], $line[3]-1, $line[4], $name, 0, $line[6]), "\n";
}

close IN;
close OUT;
