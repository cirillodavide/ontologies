use warnings;
use strict;
use Data::Dumper;
use List::UtilsBy qw(max_by);
use List::MoreUtils qw(uniq);
use Graph::Easy;
srand(123); 
use List::Util 'shuffle';

my $file;
my $in;

# Ontology as a hash

$file = shift;

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
	my (@id, @is_a) = (0);
	$para =~ s/\n/\t/g;
	(@id) = $para =~ /id:\s+(\S+)\s+/g;
	(@is_a) = $para =~ /\s+is_a:\s+(\S+)/g;
	push @{$obo{"@id"}}, shuffle @is_a; # shuffle same-level "is_a" with reproducible seed 123
}

# Build the graph (with Graph::Easy)

my $graph = Graph::Easy->new;

while ( my ($from, $to) = each %obo ) {
    $graph->add_edge($from, $_) for @$to;
}

# Retrieve the roots

my @roots;
foreach my $node ($graph->predecessorless_nodes()){
	$node->name();
	push @roots, $node->name();
}

# Print the graph

my $graphviz = $graph->as_graphviz();
open my $DOT, '|dot -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
print $DOT $graphviz;
close $DOT;

# From general tree to binary tree and then code sequence

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


foreach my $root(@roots){
	my @seq;
	my @arr;
	my $k = $root;
	push @seq, $k;

	my $kL = ${$elms{$k}}[0];
	my $kR = ${$elms{$k}}[1];
	push @seq, $kL, $kR;
	push @arr, $kL, $kR;
	@arr = grep {$_} @arr;

	while(scalar @arr > 0){
		$k = shift @arr;
		if(defined $elms{$k}){
			my $kL = ${$elms{$k}}[0];
			my $kR = ${$elms{$k}}[1];
			push @seq, $kL, $kR;
			push @arr, $kL, $kR;
		}
	}
print @seq,"\n";
}
