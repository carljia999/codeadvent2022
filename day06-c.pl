#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);
use Data::Dumper;

sub packet_marker {
    my $str = shift;
    my $i = 0;
    my $len = length $str;

    while ($i+14 < $len) {
        my $quad = substr $str, $i, 14;
        my %s = map {$_ => 1} split //, $quad;
        if (%s == 14) {
            return $i+14;
        }
        $i ++;
    }
    return $len;
}

say packet_marker(<>);