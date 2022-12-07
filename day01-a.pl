#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(sum0);

my ($max, $total) = (0, 0);
my @all;

while (<>) {
    if (/\d/) {
        $total += $_;
    } else {
        push @all, $total;
        $total = 0;
    }
}

@all = sort {$b <=> $a} @all;

say sum0 @all[0..2];
