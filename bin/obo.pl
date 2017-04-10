# required: Getopt::Long; PerlIO::gzip; List::MoreUtils; List::Util; Path::Tiny; Graph::Easy
# usage perl bin/obo.pl -infile examples/genes_list.txt

use warnings;
use strict;
use Graph::Easy;
use Getopt::Long;
use Data::Dumper;


# lib will contain all the modules

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

# take input gene name

my $input;
my $namespace;
my ($infile);
my ($indomain);
my $flags = GetOptions ("infile"  => \$infile, "domain"  => \$indomain);
my $file = $ARGV[0];
my $domain = $ARGV[1];
if($infile){
	$input = $file;
}else{
	print "Gene names: ";
	$input = <>;
}
if($indomain){
	$namespace = $domain;
}else{
	print "Domain (eg. biological_process): ";
	$namespace = <>;
}


use parseinput::parseinput 'parseinput';
my $ref_gene = parseinput($input);
my @gene = @{$ref_gene};

# load go-basic obo

use parseobo::refobo 'refobo';
my $obo_file = "res/go-basic.obo"; # go-terms by default
my $ref_obo = refobo($obo_file);
my %obo = %{$ref_obo};

# map input gene inside go-basic obo

use parseobo::geneobo 'geneobo';
my $ref_geneobo = geneobo(\@gene, \%obo, $namespace);
my %geneobo = %{$ref_geneobo};

# retrieve the roots

use graphs::graphobo 'graphobo';
my $graph = graphobo(\%geneobo);
my @roots;
foreach my $node ($graph->predecessorless_nodes()){
	$node->name();
	push @roots, $node->name();
}
print "Number of roots: ",scalar @roots,"\n";

# create the sequences

use graphs::graphseq 'graphseq';
my $ref_seq = graphseq(\@roots,\%geneobo);
my %seq = %{$ref_seq};

foreach my $k (sort { $a <=> $b } keys %seq) {
	my @seq = @{$seq{$k}};
	print join("\t",$k,join(",",@seq)),"\n";
}
