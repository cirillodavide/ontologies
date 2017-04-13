package parseinput;
use strict;
use warnings;
use Path::Tiny;
use List::MoreUtils 'uniq';

use Exporter 'import';
our @EXPORT_OK = qw/parseinput/;

sub parseinput {

	my @genes;
	
	my $in = $_[0];
	$in =~ s/\s*$//;
	if(path($in) -> is_file){
		open my $fh, path($in) or die "$!";
		while(<$fh>){
			next if /^\s*$/;
			$_ =~ s/^\s+|\s+$//g;
			push @genes, $_;
		}
		close $fh;
		}else{
			push @genes, split/\s+/,$in;
			@genes = uniq @genes;
		}
		return \@genes;
	}
