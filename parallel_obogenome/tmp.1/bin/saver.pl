use strict;
 
# capture the output of system command
my $output = `ps aux | grep obogenome`;

my @lines = split /\n/, $output;
for my $line (@lines) {
    # activate obogenome.pl if not running
    if ($line =~ m/obogenome\.pl/) {
        exit;
    }else{
    	my $file = $ARGV[0];
        `perl bin/obogenome.pl $file`;
    }
}
