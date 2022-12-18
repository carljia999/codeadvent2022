#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all);
use Data::Dumper;

my (@screen, @program);
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

    my $pos = ($tick - 1) % 40;

    # overlap
    push @screen, $pos >= $register - 1 && $pos <= $register + 1 ? '#' : '.';
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

# print screen

while (@screen) {
    say join('', splice @screen, 0, 40);
}

