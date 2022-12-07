#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(sum0);

my %games = (
    'A X' => 3+0,
    'A Y' => 1+3,
    'A Z' => 2+6,
    'B X' => 1+0,
    'B Y' => 2+3,
    'B Z' => 3+6,
    'C X' => 2+0,
    'C Y' => 3+3,
    'C Z' => 1+6,
);

say sum0 map {
    chomp;
    return 0 unless $_;
    $games{$_};
} <>;
