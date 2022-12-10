#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all);
use Data::Dumper;

package Loc {
    use Moo;
    use Types::Standard qw( Int );
    use namespace::autoclean;

    has x => (
        is => 'ro',
        isa => Int,
        required => 1,
    );
    has z => (
        is => 'ro',
        isa => Int,
        required => 1,
    );

    sub stringify {
        my ($self) = @_;
        return $self->x. ",". $self->z;
    }

    sub height {
        my ($self, $map) = @_;
        return $map->[$self->x][$self->z];
    }
}

package main;

my @map;
while(my $line = <>) {
    chomp($line);
    my @str = split "", $line;
    push @map, \@str;
}

my $width = scalar @{$map[0]};
my $height = @map;

sub visit {
    my $self = shift;

    my ($distance, $score, $loc);

    #left
    $loc = first {
        $map[$_][$self->z] >= $self->height(\@map)
    } reverse 0..($self->x-1);
    $loc //= 0;
    $distance = $self->x - $loc;
    $score = $distance;

    # right
    $loc = first {
        $map[$_][$self->z] >= $self->height(\@map)
    } ($self->x+1)..($width-1);
    $loc //= $width-1;
    $distance = $loc - $self->x;
    $score *= $distance;

    # up
    $loc = first {
        $map[$self->x][$_] >= $self->height(\@map)
    } reverse 0..($self->z-1);
    $loc //= 0;
    $distance = $self->z - $loc;
    $score *= $distance;

    # down
    $loc = first {
        $map[$self->x][$_] >= $self->height(\@map)
    } ($self->z+1)..($height-1);
    $loc //= $height-1;
    $distance = $loc - $self->z;
    $score *= $distance;

    return $score;
}

my $max_score = 0;
for my $i (1..$height-2) {
    for my $j (1..$width-2) {
        my $me = Loc->new(x => $j, z => $i);
        my $score = visit($me);
        $max_score = $score if $score > $max_score;
    }
}

#say $_->stringify for @visibles;

say $max_score;
