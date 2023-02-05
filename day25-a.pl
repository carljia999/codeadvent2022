#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all any pairs product min max);

# parse input
my ($map, @path, $width, @xboundary, @yboundary);
$width = 0;

my @places = map {
    state $v;
    $v = $v ? $v * 5 : 1;
} (1..100);

sub to_decimal {
    my $in = shift;

    my @digits = split //, $in;
    my $v = 0;

    for my $p (0..$#digits) {
        my $d = $digits[-1-$p];

        if ($d =~ /[012]/) {
            $v += $d * $places[$p];
        } elsif ($d eq '-') {
            $v -= $places[$p];
        } elsif ($d eq '=') {
            $v -= 2 * $places[$p];
        }
    }
    return $v;
}

sub from_decimal {
    my $in = shift;

    my @digits;
    while ($in) {
        my $d = $in % 5;
        $in = int($in / 5);

        if ($d == 3) {
            $in ++;
            $d = '=';
        } elsif ($d == 4) {
            $in ++;
            $d = '-';
        }
        push @digits, $d;
    }

    return join('', reverse @digits);
}

my $sum = sum0 map {
    chomp;
    to_decimal($_);
} <>;

say from_decimal($sum);
