use warnings;
use strict;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use PerlIO::gzip;
use List::UtilsBy qw(max_by);
use List::MoreUtils qw(uniq);
use Graph::Easy;
use Graph::Directed;
srand(123); 
use List::Util 'shuffle';

my $file;
my $in;

# Input list of mutated genes

my %genes;
$file = '../cosmic/malignant_melanoma/out.table.txt';
open $in, $file or die $!;
while(<$in>){
	chomp;
	my($gene) = (split/\s+/,$_)[1];
	my($geneName) = $gene =~ /^(.*)(_)?/;
	$genes{$geneName} = 1;
}
close $in;

# Ontology as a hash
print "Load entire obo...";

$file = "go-basic.obo";

$/ = "";
my @para;
open $in, $file or die $!;
while(<$in>){
	chomp;
	push @para, $_;
}
close $in;

my %obo;
foreach my $para(@para){
	my (@id, @is_a, @part_of, @regulates, @negatively_regulates, @positively_regulates, @is_obsolete) = (0);
	$para =~ s/\n/\t/g;
	(@id) = $para =~ /\s+id:\s+(GO:\d+)\s+/g;
	(@is_a) = $para =~ /\s+is_a:\s+(GO:\d+)\s+/g;
	push @{$obo{"@id"}{"is_a"}}, @is_a;
	# (@part_of) = $para =~ /\s+part_of\s+(GO:\d+)\s+/g;
	# push @{$obo{"@id"}{"part_of"}}, @part_of;
	# (@regulates) = $para =~ /\s+regulates\s+(GO:\d+)\s+/g;
	# push @{$obo{"@id"}{"regulates"}}, @regulates;
	# (@negatively_regulates) = $para =~ /\s+negatively_regulates\s+(GO:\d+)\s+/g;
	# push @{$obo{"@id"}{"negatively_regulates"}}, @negatively_regulates;
	# (@positively_regulates) = $para =~ /\s+positively_regulates\s+(GO:\d+)\s+/g;
	# push @{$obo{"@id"}{"positively_regulates"}}, @positively_regulates;
	# (@is_obsolete) = $para =~ /\s+is_obsolete:\s+(\S+)\s+/g;
	# push @{$obo{"@id"}{"is_obsolete"}}, @is_obsolete;
}

print "done!\n";
# Map mutated genes to ontology
print "Map mutated genes to obo...";

$/ = "\n";
my %mut;
my @eec = qw/EXP IDA IPI IMP IGI IEP/;  # experimental evidence codes
$file = 'goa_human.gaf.gz';
open $in, '<:gzip', $file or die $!;
while(<$in>){
	chomp;
	next if $_ =~ /^\!/;
	my ($geneName) = (split/\t/,$_)[2];
	my ($go) = $_ =~ /(GO:\d+)/g; # ignoring colocalizes_with
	next unless defined $genes{$geneName};
	my $ec = (split/\t/,$_)[6];
	next unless grep{$ec eq $_}@eec;
	push @{$mut{$geneName}}, $go;
	@{$mut{$geneName}} = uniq @{$mut{$geneName}};
}
close $in;

# Create melanoma-specific obo

my %mel_obo;
foreach my $geneName(keys %mut){
	next if $geneName ne "IRF6";
	foreach my $go (@{$mut{$geneName}}){
		foreach my $is_a (@{$obo{$go}{"is_a"}}){
			push @{$mel_obo{$go}}, $is_a unless grep{$is_a eq $_}@{$mel_obo{$go}};
		}
	}
}

%obo = %mel_obo;

print "done!\n";

# Build the graph (with Graph::Easy)
print "Build the graph...";

my $graph = Graph::Easy->new;
while ( my ($from, $to) = each %obo ) {
    $graph->add_edge($from, $_) for @$to;
}
my $graphviz = $graph->as_graphviz();
open my $DOT, '|dot -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
print $DOT $graphviz;
close $DOT;

print "done!\n";
# Retrieve the roots
print "Retrieve the roots...";

my @roots;
foreach my $node ($graph->predecessorless_nodes()){
	$node->name();
	push @roots, $node->name();
}

print "done!\n";
# From general tree to binary tree and then code sequence
# Exclude giant trees

my $g = Graph::Directed->new;
while ( my ($from, $to) = each %obo ) {
    $g->add_edge($from, $_) for @$to;
}
my %succ;
for my $v ( $g->vertices ) {
    my @succ = $g->all_successors($v);
    $succ{$v} = \@succ;
}
for my $v ( sort { @{$succ{$b}} <=> @{$succ{$a}} } $g->vertices ) {
    printf "%s %d\n", $v, scalar @{$succ{$v}};
}

print "From general tree to binary tree...";

my %elms;
foreach my $k (keys %obo){
	my $d = scalar @{$obo{$k}};
	push @{$elms{$k}}, ( ${$obo{$k}}[0], 0 );
	if($d>1){
		for(my $i=0; $i<=$d-2; $i++){
			push @{$elms{${$obo{$k}}[$i]}}, ( 0, ${$obo{$k}}[$i+1] );
		}
	}
}

foreach my $k (keys %elms){
	my $n = scalar @{$elms{$k}};
	if($n > 2){
		if(${$elms{$k}}[0] eq 0 and ${$elms{$k}}[3] eq 0 ){
			@{$elms{$k}} = ( ${$elms{$k}}[2], ${$elms{$k}}[1] );
		}
		if(${$elms{$k}}[1] eq 0 and ${$elms{$k}}[2] eq 0 ){
			@{$elms{$k}} = ( ${$elms{$k}}[0], ${$elms{$k}}[3] );
		}
	}
}
print "done!\n";
print "Sequences...\n";

print "Number of roots: ",scalar @roots,"\n";

my $outfile = "melanoma_sequences.txt";
open OUT, '>', $outfile or die $!;
foreach my $root(@roots){
	my @seq;
	my @arr;
	my $k = $root;
	print OUT "$k,";

	my $kL = ${$elms{$k}}[0];
	my $kR = ${$elms{$k}}[1];
	print OUT $kL, $kR;
	push @arr, $kL, $kR;
	@arr = grep {$_} @arr;

	while(scalar @arr > 0){
		$k = shift @arr;
		if(defined $elms{$k}){
			my $kL = ${$elms{$k}}[0];
			my $kR = ${$elms{$k}}[1];
			print OUT "$kL,$kR,";
			push @arr, $kL, $kR;
		}
	}
print OUT "\n";
}
close OUT;
