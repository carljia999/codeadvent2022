#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(sum0);

my %games = (
    'A X' => 1+3,
    'A Y' => 2+6,
    'A Z' => 3+0,
    'B X' => 1+0,
    'B Y' => 2+3,
    'B Z' => 3+6,
    'C X' => 1+6,
    'C Y' => 2+0,
    'C Z' => 3+3,
);

say sum0 map {
    chomp;
    return 0 unless $_;
    $games{$_};
} <>;
