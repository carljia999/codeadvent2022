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

my @visibles;

sub visit {
    my $self = shift;

    my $found;

    #left
    $found = all {
        $map[$_][$self->z] < $self->height(\@map)
    } 0..($self->x-1);
    return 1 if $found;

    # right
    $found = all {
        $map[$_][$self->z] < $self->height(\@map)
    } ($self->x+1)..($width-1);
    return 1 if $found;

    # up
    $found = all {
        $map[$self->x][$_] < $self->height(\@map)
    } 0..($self->z-1);
    return 1 if $found;

    # down
    $found = all {
        $map[$self->x][$_] < $self->height(\@map)
    } ($self->z+1)..($height-1);

    return $found;
}

for my $i (1..$height-2) {
    for my $j (1..$width-2) {
        my $me = Loc->new(x => $j, z => $i);
        push @visibles, $me if visit($me);
    }
}

#say $_->stringify for @visibles;

say +($height-1+$width-1) * 2 + @visibles;
