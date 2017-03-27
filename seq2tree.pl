use warnings;
use strict;
use Graph::Easy;
use Data::Dumper;

my $seq = "M E 0 B L A C I 0 A 0 H 0 G F D 0 D 0 A C A C A 0 A 0";
my @seq = split(/\s+/, $seq);
my $root = shift(@seq);
my %step;
my $cnt = 0;
while(my ($i,$j) = splice(@seq,0,2)) {
  $cnt++;
  $step{$cnt} = [ $i, $j ];
}

my %HoA;
my $m = length($seq);
my $n = scalar keys %step;
push @{$HoA{$root}}, $step{1}[0] unless $step{1}[0] eq 0;
for(my $c=2;$c<=$n;$c++){
	last if $step{$c}[1] eq 0;
	push @{$HoA{$root}}, $step{$c}[1];
}
my @pos = (0, 1);
for(my $r=1;$r<=$m;$r++){
	next if !defined $step{$r+1}[0];
	for my $p(@pos){
		push @{$HoA{$step{$r}[$p]}}, $step{$r+1}[0] unless $step{$r+1}[0] eq 0;
	}
	for(my $c=$r+2;$c<=$n;$c++){
		last if $step{$c}[1] eq 0;
		for my $p(@pos){
			push @{$HoA{$step{$r}[$p]}}, $step{$c}[1];
		}
	}
}

my %g;
foreach my $k (sort keys %HoA){
	foreach my $v (@{$HoA{$k}}){
		next if $k eq 0 or $k eq $v;
		push @{$g{$k}}, $v unless grep{$v eq $_}@{$g{$k}};
	}
}

my $graph = Graph::Easy->new;
while ( my ($from, $to) = each %g ) {
	$graph->add_edge($from, $_) for @$to;
}
my $graphviz = $graph->as_graphviz();
open my $DOT, '|dot -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
print $DOT $graphviz;
close $DOT;

print Dumper \%g;