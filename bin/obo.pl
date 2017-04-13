# usage: perl bin/obo.pl -infile examples/genes_list.txt -ontology hpo -domain human_phenotype

use warnings;
use strict;
use Graph::Easy;
use Getopt::Long;
use PerlIO::gzip;
use List::MoreUtils qw(uniq);
use Sort::Topological qw(toposort);
use Data::Dumper;


# lib will contain all the modules

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

#=================
# input processing
#=================

my $input;
my $namespace;
my $inobo;
my ($infile);
my ($indomain);
my ($inontology);
my $flags = GetOptions ("infile"  => \$infile, "ontology" => \$inontology, "domain"  => \$indomain,);
my $file = $ARGV[0];
my $ontology = $ARGV[1];
my $domain = $ARGV[2];
if($infile){
	$input = $file;
}else{
	print "Gene names: ";
	$input = <>;
}
if($inontology){
	$inobo = $ontology;
}else{
	print "Ontology (go or hpo): ";
	$inobo = <>;
}
if($indomain){
	$namespace = $domain;
}else{
	print "Domain (eg. biological_process or human_phenotype): ";
	$namespace = <>;
}
chomp($input);
chomp($namespace);
chomp($inobo);

use parseinput 'parseinput';
my $ref_gene = parseinput($input);
my @genes = @{$ref_gene};

#==========
# load obos
#==========

use refobo 'refobo';
my $obo_file;
my $ref_obo;
my %go_obo;
my %hpo_obo;

if($inobo eq "go"){
    $obo_file = "res/go-basic.obo";
    $ref_obo = refobo($obo_file);
    %go_obo = %{$ref_obo};
}

if($inobo eq "hpo"){
    $obo_file = "res/hp.obo";
    $ref_obo = refobo($obo_file);
    %hpo_obo = %{$ref_obo};
}

#=============
# genes to obo
#=============

$/ = "\n";
my %gene_to_go;
my %gene_to_hpo;

if($inobo eq "go"){
    my $file_go = 'res/goa_human.gaf.gz';
    open my $in_go, '<:gzip', $file_go or die $!;
    while(<$in_go>){
        chomp;
        next if $_ =~ /^\!/;
        my ($geneName) = (split/\t/,$_)[2];
        next unless grep{$geneName eq $_}@genes;
        my ($go) = $_ =~ /(GO:\d+)/g; # ignoring colocalizes_with
        my ($ec) = (split/\t/,$_)[6];
        next if !grep{$ec eq $_} qw/EXP IDA IPI IMP IGI IEP/; # only experimental evidence codes
        push @{$gene_to_go{$geneName}}, $go;
        @{$gene_to_go{$geneName}} = uniq @{$gene_to_go{$geneName}};
    }
    close $in_go;
}

if($inobo eq "hpo"){
    my $file_hpo = 'res/OMIM_ALL_FREQUENCIES_diseases_to_genes_to_phenotypes.txt';
    open my $in_hpo, $file_hpo or die $!;
    while(<$in_hpo>){
        chomp;
        next if $. < 2;
        my ($geneName, $hp) = (split/\t/,$_)[1,3];
        next unless grep{$geneName eq $_}@genes;
        push @{$gene_to_hpo{$geneName}}, $hp;
        @{$gene_to_hpo{$geneName}} = uniq @{$gene_to_hpo{$geneName}};
    }
    close $in_hpo;
}

#===================
# GO terms sequences
#===================

if($inobo eq "go"){
	my $tag = $namespace;
	my %out;
	my %go;
	my $cnt = 0;
	foreach my $gene (sort @genes){
		$cnt++;
		foreach my $go (@{$gene_to_go{$gene}}){
			$go{$go} = 1;
		}
	}
	my $ref_sorted = myHoA2seq(\%go, $tag, \%go_obo);
	my %sorted = %$ref_sorted;
	foreach my $k (sort { $a <=> $b } keys %sorted){
		print join("\t",$k,$sorted{$k}),"\n";
	}
}
#====================
# HPO terms sequences
#====================

if($inobo eq "hpo"){
	my $tag = $namespace;
	my %out;
	my %hpo;
	my $cnt = 0;
	foreach my $gene (sort @genes){
		$cnt++;
		foreach my $hpo (@{$gene_to_hpo{$gene}}){
			$hpo{$hpo} = 1;
		}
	}
	my $ref_sorted = myHoA2seq(\%hpo, $tag, \%hpo_obo);
	my %sorted = %$ref_sorted;
	foreach my $k (sort { $a <=> $b } keys %sorted){
		print join("\t",$k,$sorted{$k}),"\n";
	}	
}

##############

sub myHoA2seq{

	use graphobo 'graphobo';
	use graphseq 'graphseq';

	my ( $ref_terms, $tag , $ref_obo ) = @_;
	my %terms = %$ref_terms;
	my @terms = keys %terms;
	my %obo = %$ref_obo;

	my %children;
	my @roots;
	my %out;
	foreach my $elm (@terms){
		next unless defined $obo{$elm}{$tag};
		@{$children{$elm}} = @{$obo{$elm}{$tag}};
		@{$children{$elm}} = uniq(@{$children{$elm}});
		my $graph = graphobo(\%children);
		foreach my $node ($graph->predecessorless_nodes()){
			$node->name();
			push @roots, $node->name() unless grep{$node->name eq $_}@roots;
		}
	}

	my $ref_seq = graphseq(\@roots,\%obo,$tag);
	my %seq = %{$ref_seq};
	foreach my $k (sort { $a <=> $b } keys %seq) {
		my @sorted;
		foreach my $v (@{$seq{$k}}){
			push @sorted, $v if $v;
		}
	$out{$k} = "@sorted";
	}
	print "Numer of roots: ".scalar (keys %seq)." \n";
	return \%out;
}
