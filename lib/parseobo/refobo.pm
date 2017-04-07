package parseobo::refobo;
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
		my (@id, @is_a, @part_of, @regulates, @negatively_regulates, @positively_regulates, @is_obsolete) = (0);
		$para =~ s/\n/\t/g;
		(@id) = $para =~ /\s+id:\s+(GO:\d+)\s+/g;
		(@is_a) = $para =~ /\s+is_a:\s+(GO:\d+)\s+/g;
		push @{$obo{"@id"}{"is_a"}}, shuffle @is_a; # shuffle same-level "is_a" with reproducible seed 123
		(@part_of) = $para =~ /\s+part_of\s+(GO:\d+)\s+/g;
		push @{$obo{"@id"}{"part_of"}}, @part_of;
		(@regulates) = $para =~ /\s+regulates\s+(GO:\d+)\s+/g;
		push @{$obo{"@id"}{"regulates"}}, @regulates;
		(@negatively_regulates) = $para =~ /\s+negatively_regulates\s+(GO:\d+)\s+/g;
		push @{$obo{"@id"}{"negatively_regulates"}}, @negatively_regulates;
		(@positively_regulates) = $para =~ /\s+positively_regulates\s+(GO:\d+)\s+/g;
		push @{$obo{"@id"}{"positively_regulates"}}, @positively_regulates;
		(@is_obsolete) = $para =~ /\s+is_obsolete:\s+(\S+)\s+/g;
		push @{$obo{"@id"}{"is_obsolete"}}, @is_obsolete;
	}

	return \%obo;
}
