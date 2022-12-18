#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all);
use Data::Dumper;

my (@values, @program);
my $register = 1;

# load program
while(my $line = <>) {
    chomp $line;
    next unless $line;
    if (my ($op, $arg) = split / /, $line) {
        push @program, [$op, $arg];
    }
}

sub tick {
    my $tick = shift;

    my $remain = $tick % 40;
    if ($remain == 20) {
        push @values, $register * $tick;
    }
}

sub run {
    my $tick = 1;
    for (@program) {
        my ($op, $arg) = @$_;

        if ($op eq 'addx') {
            # before run
            tick($tick ++) for (0..1);
            $register += $arg;
        } else {
            # before run
            tick($tick ++);
        }
    }
}

run;

say sum0 @values;
