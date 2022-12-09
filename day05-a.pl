#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);
use Data::Dumper;

my $section = 'stack';
my (%stacks, @steps);

# parse input
while (my $line = <>) {
    if ($section eq 'stack') {
        if ($line =~ /\d/) {
            <>;
            $section = 'steps';
            next;
        }
        # parse the crates
        my @g = $line =~ /(^.{3}|.{4})/g;
        for my $i (0..$#g) {
            $stacks{$i+1} //= [];
            my ($crate) = $g[$i] =~ /(\w)/;
            unshift @{$stacks{$i+1}}, $crate if $crate;
        }
    } else {
        # steps
        my %step = $line =~ /(\w+)/g;
        push @steps, \%step;
    }
}

#say Dumper(\%stacks,\@steps);

sub operate {
    for my $s (@steps) {
        my $from = $stacks{$s->{from}};
        my $to = $stacks{$s->{to}};
        my $count = $s->{move};
        for (1..$count) {
            my $crate = pop @$from;
            push @$to, $crate;
        }
    }
}

operate;

my $stacks = %stacks;
say join '', map {
    $stacks{$_}->[-1]
} (1..$stacks);

