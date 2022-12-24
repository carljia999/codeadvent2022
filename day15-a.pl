#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all pairs product min max);

package Loc {
    use Moo;
    use Types::Standard qw( Int );
    use namespace::autoclean;

    my @neighbours = grep { abs($_->[0]) + abs($_->[1]) == 1 }
                map { my $i = $_; map {[$i, $_]} (-1..1) }
                (-1..1);

    has x => (
        is => 'rw',
        isa => Int,
        required => 1,
    );
    has z => (
        is => 'rw',
        isa => Int,
        required => 1,
    );

    around BUILDARGS => sub {
        my ( $orig, $class, @args ) = @_;

        if (@args == 1 && !ref $args[0]) {
            my ($x, $z) = split /,/, $args[0], 2;
            return +{ x => $x, z=> $z };
        }

        return $class->$orig(@args);
    };

    sub stringify {
        my ($self) = @_;
        return $self->x. ",". $self->z;
    }

    sub neighbours {
        my ($self) = @_;
        map {
            ref($self)->new(x => $self->x + $_->[0], z => $self->z + $_->[1])
        } @neighbours;
    }
}

package main;

my (%row, @sensor);

my $TARGET = 2000000;

sub distance {
    my ($c, $d) = @_;

    return abs($c->x - $d->x) + abs($c->z - $d->z);
}

sub mark_coverage {
    my ($sensor, $range) = @_;

    my $length = abs($sensor->z - $TARGET);
    if ($length < $range) {
        my $tail = abs($range - $length);
        for ($sensor->x - $tail .. $sensor->x + $tail) {
            $row{$_} = '#' if !exists $row{$_};
        }
    }
}

sub build_map {
    while(my $line = <>) {
        my ($sx, $sz, $bx, $bz) = $line =~ /(-?\d+)/g;
        my $sloc = Loc->new(x => $sx, z => $sz);
        my $bloc = Loc->new(x => $bx, z => $bz);

        $row{$sx} = 'S' if $sz == $TARGET;
        $row{$bx} = 'B' if $bz == $TARGET;

        push @sensor, [$sloc, distance($sloc, $bloc)];
    }
}

build_map;

for my $s (@sensor) {
    mark_coverage(@$s);
}

my $count = grep {$row{$_} eq '#' } keys %row;
say $count;
