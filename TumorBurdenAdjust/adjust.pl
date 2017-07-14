#!/usr/bin/perl
use warnings;
use strict;

my $StableSites = "stable_sites_mean.txt";
my $NormalMode = "normal_mode.txt";
my $BetaValue = $ARGV[0];
system "dos2unix $BetaValue";

my %stable;
my %normalmode;
my %beta;
my %theta;

print "reading $StableSites\n";
open(STB, $StableSites) or die "can't open stable sites file $StableSites:$!\n";
my $head1 = <STB>;
while(<STB>){
	chomp;
	my ($probe, $normal_mean, $cancer_mean) = split "\t";
	$stable{$probe}{normal_mean} = $normal_mean;
	$stable{$probe}{cancer_mean} = $cancer_mean;
}
close STB;

print "reading $NormalMode\n";
open(NMD, $NormalMode) or die "can't open normal mode file $NormalMode:$!\n"; 
my $head2 = <NMD>;
while(<NMD>){
	chomp;
	my ($probe, $mode) = split "\t";
	$normalmode{$probe} = $mode;
}
close NMD;

print "reading $BetaValue\n";
open(BV, $BetaValue) or die "can't open input Beta Value file:$BetaValue:$!\n";
my $head = <BV>;
chomp $head;
my @head = split "\t", $head;
shift @head;
while(<BV>){
	chomp;
	my @line = split "\t";
	my $probe = shift @line;
	if(defined $normalmode{$probe}){
		foreach my $n (0..$#head){
			my $sampleid = $head[$n];
			$beta{$sampleid}{$probe}{raw_value} = $line[$n];
		}
	}
}
close BV;

##estimate tumor burden theta
print "estimate tumor burden theta...\n";
foreach my $sample(keys %beta){
	my $theta = 0;
	my $count = 0;
	foreach my $probe (keys %stable){
		if(defined($beta{$sample}{$probe}) ){
			my $theta_of_the_probe = ($beta{$sample}{$probe}{raw_value} - $stable{$probe}{normal_mean} ) / ( $stable{$probe}{cancer_mean} - $stable{$probe}{normal_mean} );
			$theta += $theta_of_the_probe;
			$count += 1;
			$stable{$probe}{theta_estimate} = $theta_of_the_probe;
		}
	}
	my $theta_estimate = $theta / $count;
	$theta{$sample} = $theta_estimate;
	print "$sample\t$theta{$sample}\n";
}
##adjust beta value
print "adjusting beta value...\n";
foreach my $sample (keys %beta){
	foreach my $probe (keys %{$beta{$sample}}){
		if($beta{$sample}{$probe}{raw_value} =~ /N/){
			$beta{$sample}{$probe}{adjust_value} = 'NA';
		}else{
			$beta{$sample}{$probe}{adjust_value} = ($beta{$sample}{$probe}{raw_value} - (1 - $theta{$sample} ) * $normalmode{$probe} ) / $theta{$sample};
			#print "$probe\t$beta{$sample}{$probe}{raw_value}\t$beta{$sample}{$probe}{adjust_value}\n";
		}
	}
}


#print "tumor_burden estimate: $theta{$sample}\n";
##print adjusted beta value to $ARGV[0]adjust.txt
print "print adjusted beta value to $ARGV[0]_adjust.txt\n";
open(RES, ">$ARGV[0]_adjust.txt") or die "can't open adjust_beta.txt:$!\n";
my @samples = sort keys %theta;
$" = "\t";
print RES "probe\t@samples\n";
print RES "tumor_burden";
foreach my $sample (@samples){
	print RES "\t$theta{$sample}";
}
print RES "\n";

foreach my $probe (sort keys %normalmode){
	my @line;
	$line[0] = $probe;
	foreach my $sample(sort keys %beta){
		if(defined($beta{$sample}{$probe}{adjust_value})){
			push @line,$beta{$sample}{$probe}{adjust_value};
		}
	}
	print RES "@line\n" if($#line >= 1);
}
$" = ' ';
close RES;

