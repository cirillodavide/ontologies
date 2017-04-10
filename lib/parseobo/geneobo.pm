package parseobo::geneobo;
use strict;
use warnings;
use PerlIO::gzip;
use List::MoreUtils qw(uniq);

use Exporter 'import';
our @EXPORT_OK = qw/geneobo/;

my %gene;
my $file = 'res/goa_human.gaf.gz';
open my $in, '<:gzip', $file or die $!;
while(<$in>){
	chomp;
	next if $_ =~ /^\!/;
	my ($geneName) = (split/\t/,$_)[2];
	my ($go) = $_ =~ /(GO:\d+)/g; # ignoring colocalizes_with
	my ($ec) = (split/\t/,$_)[6];
	next if !grep{$ec eq $_} qw/EXP IDA IPI IMP IGI IEP/; # only experimental evidence codes
	push @{$gene{$geneName}}, $go;
	@{$gene{$geneName}} = uniq @{$gene{$geneName}};
}
close $in;

sub geneobo {
	
	my %geneobo;
	my( $ref_inputgene, $ref_obo, $namespace) = @_;

    chomp($namespace);
	my %obo = %{$ref_obo};
	my @input = @{$ref_inputgene};

	foreach my $inputgene(@input){
		chomp($inputgene);
		if(defined $gene{$inputgene}){
			foreach my $go (@{$gene{$inputgene}}){
			next unless grep{$namespace eq $_}@{$obo{$go}{"namespace"}};
			foreach my $is_a (@{$obo{$go}{"is_a"}}){ #only is_a relationships
				push @{$geneobo{$go}}, $is_a unless grep{$is_a eq $_}@{$geneobo{$go}};
			}
		}
		}else{
			print "$inputgene is not annotated.\n";
		}
	}
	return \%geneobo;
}
