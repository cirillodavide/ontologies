package graphseq;
use strict;
use warnings;
use Graph::Easy;
use Data::Dumper;

use Exporter 'import';
our @EXPORT_OK = qw/graphseq/;

sub graphseq {

	my %seq;

	my ( $ref_roots, $ref_geneobo, $tag ) = @_;
	my @roots = @$ref_roots;
	my %geneobo = %$ref_geneobo;

	my $id = "GO";
	if($tag eq "human_phenotype"){$id = "HP";}
	
	my %elms;
	foreach my $k (@roots){
		next unless defined $geneobo{$k}{$tag};
		my $d = scalar @{$geneobo{$k}{$tag}};
		push @{$elms{$k}}, ( ${$geneobo{$k}{$tag}}[0], $id.":0000000" );
		if($d>1){
			for(my $i=0; $i<=$d-2; $i++){
				push @{$elms{${$geneobo{$k}{$tag}}[$i]}}, ( $id.":0000000", ${$geneobo{$k}{$tag}}[$i+1] );
			}
		}
	}

	foreach my $k (keys %elms){
		my $n = scalar @{$elms{$k}};
		if($n > 2){
			if(${$elms{$k}}[0] eq $id.":0000000" and ${$elms{$k}}[3] eq $id.":0000000" ){
				@{$elms{$k}} = ( ${$elms{$k}}[2], ${$elms{$k}}[1] );
			}
			if(${$elms{$k}}[1] eq $id.":0000000" and ${$elms{$k}}[2] eq $id.":0000000" ){
				@{$elms{$k}} = ( ${$elms{$k}}[0], ${$elms{$k}}[3] );
			}
		}
	}

	my $cnt = 0;
	foreach my $root(@roots){
		my $len_seq = 1;
		$cnt++;
		my @arr;
		my $k = $root;
		push @{$seq{$cnt}}, $k;

		my $kL = ${$elms{$k}}[0];
		my $kR = ${$elms{$k}}[1];
		push @{$seq{$cnt}}, ( $kL, $kR );
		push @arr, ( $kL, $kR );
		@arr = grep {$_} @arr;

		while(scalar @arr > 0 and $len_seq < 21){ # maximum sequence length 20
			$k = shift @arr;
			$len_seq++;
			if(defined $elms{$k}){
				my $kL = ${$elms{$k}}[0];
				my $kR = ${$elms{$k}}[1];
				push @{$seq{$cnt}}, ( $kL, $kR );
				push @arr, ( $kL, $kR );
				@arr = grep {$_} @arr;
			}else{
				next;
			}
		}
		#print "\t$root len_seq: $len_seq\n";
	}

	return \%seq;
}
