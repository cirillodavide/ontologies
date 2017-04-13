package refobo;
use strict;
use warnings;
use List::Util 'shuffle';

use Exporter 'import';
our @EXPORT_OK = qw/refobo/;

sub refobo {

	srand(123); 

	my $file = shift;

	$/ = "";
	my @para;
	open my $in, $file or die $!;
	while(<$in>){
		chomp;
		push @para, $_;
	}
	close $in;

	my %obo;
	foreach my $para(@para){
		my (@id, @is_a, @namespace, @is_obsolete) = (0);
		$para =~ s/\n/\t/g;
		(@is_obsolete) = $para =~ /\s+is_obsolete:\s+(\S+)/g;
		next if grep{"true" eq $_}@is_obsolete; # remove obsolete terms
		(@id) = $para =~ /\s+id:\s+(\S+:\d+)\s+/g;
		(@is_a) = $para =~ /\s+is_a:\s+(\S+:\d+)\s+/g;
		if($para =~ /namespace/){
			(@namespace) = $para =~ /\s+namespace:\s+(\S+)\s+/g;
		}else{
			(@namespace) = "human_phenotype";
		}
		push @{$obo{"@id"}{"@namespace"}}, shuffle @is_a; # shuffle same-level "is_a" with reproducible seed 123
	}

	return \%obo;
}
