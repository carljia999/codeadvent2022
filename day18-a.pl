#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all any pairs product min max);

package Point {
    sub new {
        my ($cls, @xyz) = @_;
        if (@xyz == 1) {
            @xyz = split /,/, $xyz[0];
        }
        bless \@xyz, $cls;
    }
    sub x { $_[0]->[0] }
    sub y { $_[0]->[1] }
    sub z { $_[0]->[2] }
    sub stringify { join(',', $_[0]->@*) }
    sub is_adjacent {
        my ($p1, $p2) = @_;
        my $diff = List::Util::sum0 map { abs($p1->[$_] - $p2->[$_]) } (0..2);
        return $diff == 1;
    }
}

package main;

my @droplet = map { chomp; Point->new($_) } <>;

my $covered;
for my $p (@droplet) {
    for my $pb (@droplet) {
        next if $p == $pb;
        $covered ++ if $p->is_adjacent($pb);
    }
}
say @droplet * 6 - $covered;