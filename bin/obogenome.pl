# built single-gene trees for the entire human genome
# usage: perl bin/obogenome.pl res/gencode.v25.gene_names.txt

use warnings;
use strict;
use Graph::Easy;
use Getopt::Long;
use Process::MaxSize;
use Data::Dumper;

open OUT, '>>', "tmp/out.txt" or die $!;
open LOG, '>', "tmp/log.txt" or die $!;

# lib will contain all the modules

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

# load go-basic obo

use parseobo::refobo 'refobo';
my $obo_file = "res/go-basic.obo"; # go-terms by default
my $ref_obo = refobo($obo_file);
my %obo = %{$ref_obo};

# load gene names

$/ = "\n";
open FILE, $ARGV[0] or die $!; # res/gencode.v25.gene_names.txt
my @genome = <FILE>;
chomp(@genome);
close FILE;

my $cnt = 0;
my $tot = scalar(@genome);
foreach my $gene(@genome){

	# map every gene inside go-basic obo

	my @gene;
	push @gene, $gene;
	use parseobo::geneobo 'geneobo';
	my $ref_geneobo = geneobo(\@gene, \%obo);
	my %geneobo = %{$ref_geneobo};

	# build the graph and retrieve the roots

	use graphs::graphobo 'graphobo';
	my $graph = graphobo(\%geneobo);
	my @roots;
	foreach my $node ($graph->predecessorless_nodes()){
		$node->name();
		push @roots, $node->name();
	}
	print LOG "$gene\n";

	# create the sequences

	my %seq;
	use graphs::graphseq 'graphseq';
	my $ref_seq = graphseq(\@roots,\%geneobo);
	%seq = %{$ref_seq};
	foreach my $k (%seq) {
		next unless defined $seq{$k};
		my @seq = @{$seq{$k}};
		print OUT join("\t",$gene,join(",",@seq)),"\n";
		}
	}

close LOG;

close OUT;