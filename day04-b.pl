#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);

say scalar grep {
    chomp;
    my ($a1, $a2, $b1, $b2) = /(\d+)/g;
    !(($b2 < $a1) or ($a2 < $b1));
} <>;
