#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);

say scalar grep {
    chomp;
    my ($a1, $a2, $b1, $b2) = /(\d+)/g;
    ($a1 >= $b1 && $a2 <= $b2) or ($b1 >= $a1 && $b2 <= $a2);
} <>;
