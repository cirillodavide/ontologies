use strict;

# capture the output of system command
my $output = `ps aux | grep obogenome`;

my @lines = split /\n/, $output;
for my $line (@lines) {
    
    if ($line =~ m/obogenome\.pl/) {
        my @vals = split /\s+/, $line;
        my $mem_used_percent = $vals[3];
        my $pid = $vals[1];
        if ($mem_used_percent > 25) {
            my $now_string = localtime;
            system("kill -9 $pid");
            
            # prepare new list
            open LOG, 'tmp/log.txt' or die $!;
            my @log = <LOG>;
            close LOG;
            my $last = pop(@log);

            my $file = $ARGV[0];
            open FILE, $file or die $!;
            my @array = <FILE>;
            close FILE;

            my( $index )= grep { $array[$_] eq $last } 0..$#array;
            my @newarray = @array[ $index+2 .. $#array ];

            print "Killed obogenome at $array[$index+1] (Used mem % = $mem_used_percent)\n";

            my $n = int(rand(10000));
            open NEW, '>', 'tmp/tmp.'.$n.'.txt' or die $!;
            foreach my $gene(@newarray){
                print NEW $gene,"\n";
            }
            close NEW;

            `mv tmp/tmp.$n.txt $file`;
        }
    }
}
