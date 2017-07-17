#!/usr/bin/perl
use warnings;
use strict;

my $site2region = "site2region.txt.tmp";
my $adjust_beta = $ARGV[0];

my %region;
my %rgmean;
my %beta;

## read region list file
open(S2R, $site2region) or die "can't open region list file $site2region:$!\n";
while(<S2R>){
	chomp;
	my ($region, $site) = split "\t";
	my @sites = split(",", $site);
	foreach my $probe (@sites){
		$region{$region}{$probe} = 1;
	}
}
close S2R;

## read adjusted beta value file
open(BT, $adjust_beta) or die "can't open adjusted beta value file $adjust_beta:$!\n";
my $head1 = <BT>;
my $theta = <BT>;
chomp $head1;
my @sampleid = split "\t", $head1;
shift @sampleid;
while(<BT>){
	chomp;
	my @line = split "\t";
	my $probe = shift @line;
	foreach my $n (0..$#sampleid){
		$beta{$sampleid[$n]}{$probe}{adjust_value} = $line[$n];
	}
}
close BT;

## for each region, get the sum of beta values and count
foreach my $region (sort keys %region){
	foreach my $probe (keys %{$region{$region}}){
		foreach my $sample (sort keys %beta){
			if(defined $beta{$sample}{$probe}{adjust_value} && $beta{$sample}{$probe}{adjust_value} ne 'NA'){
				$rgmean{$sample}{$region}{sum} += $beta{$sample}{$probe}{adjust_value};
				$rgmean{$sample}{$region}{count} += 1;
			}
		}
	}
}

## calculate mean beta value of each region
foreach my $sample (sort keys %rgmean){
	foreach my $region (keys %{$rgmean{$sample}}){
		if($rgmean{$sample}{$region}{count} != 0){
			$rgmean{$sample}{$region}{mean} = $rgmean{$sample}{$region}{sum} / $rgmean{$sample}{$region}{count};
		}else{
			$rgmean{$sample}{$region}{mean} = "NA";
		}
		#print "$sample\t$region\t$rgmean{$sample}{$region}{mean}\n";
	}
}
#print "@sampleid\n";
#=pod
## output region mean, each column is a region and each line is a sample
open(RES, ">$ARGV[0].regionmean.txt") or die "cannot open result file $ARGV[0].regionmean.txt:$!\n";
print RES "region_id";
foreach my $region (sort keys %{$rgmean{$sampleid[0]}}){
	print RES "\t$region";
}
print RES "\n";
foreach my $sample (sort keys %rgmean){
	print RES "$sample";
	foreach my $region (sort keys %{$rgmean{$sample}}){
		print RES "\t$rgmean{$sample}{$region}{mean}";
	}
	print RES "\n";
}
close RES;
