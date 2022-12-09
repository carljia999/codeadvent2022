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

    while ($i+4 < $len) {
        my $quad = substr $str, $i, 4;
        my %s = map {$_ => 1} split //, $quad;
        if (%s == 4) {
            return $i+4;
        }
        $i ++;
    }
    return $len;
}

say packet_marker(<>);