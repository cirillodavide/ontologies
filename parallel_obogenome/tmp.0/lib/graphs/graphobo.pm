package graphs::graphobo;
use strict;
use warnings;
use Graph::Easy;

use Exporter 'import';
our @EXPORT_OK = qw/graphobo/;

sub graphobo {

	my ($ref_genoobo) = @_;

	my %genoobo = %{$ref_genoobo};

	my $graph = Graph::Easy->new;
	while ( my ($from, $to) = each %genoobo ) {
    	$graph->add_edge($from, $_) for @$to;
	}

	my $graphviz = $graph->as_graphviz();
	open my $DOT, '|dot -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
	print $DOT $graphviz;
	close $DOT;

	return $graph;

}