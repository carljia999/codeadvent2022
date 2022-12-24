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

package Segment {
    use Moo;
    use Types::Standard qw( Int );
    use namespace::autoclean;

    has x1 => (
        is => 'ro',
        isa => Int,
        required => 1,
    );

    has x2 => (
        is => 'ro',
        isa => Int,
        required => 1,
    );

    sub merge {
        my ($a1, $a2) = @_;
        if ($a1->x1 < $a2->x1 && $a1->x2 >= $a2->x1) {
            return Segment->new(x1 => $a1->x1, x2 => List::Util::max($a2->x2, $a1->x2));
        } elsif ($a2->x1 < $a1->x1 && $a2->x2 >= $a1->x1) {
            return Segment->new(x1 => $a2->x1, x2 => List::Util::max($a2->x2, $a1->x2));
        } else {
            return ($a1, $a2);
        }
    }
}

package main;

my (%row, @sensor, %map);

sub distance {
    my ($c, $d) = @_;

    return abs($c->x - $d->x) + abs($c->z - $d->z);
}

sub get_coverage {
    my ($sensor, $range, $row) = @_;

    my $length = abs($sensor->z - $row);
    if ($length < $range) {
        my $tail = abs($range - $length);
        return Segment->new(x1 => $sensor->x - $tail, x2 => $sensor->x + $tail);
    }
    return;
}

sub build_map {
    while(my $line = <>) {
        my ($sx, $sz, $bx, $bz) = $line =~ /(-?\d+)/g;
        my $sloc = Loc->new(x => $sx, z => $sz);
        my $bloc = Loc->new(x => $bx, z => $bz);

        $map{$sloc->stringify} = 'S';
        $map{$bloc->stringify} = 'B';

        push @sensor, [$sloc, distance($sloc, $bloc)];
    }
}

build_map;

for my $row (0..4000000) {
    my @seg = sort { $a->x1 <=> $b->x1 }
    map {
        get_coverage(@$_, $row)
    } @sensor;

    # merge the segments
    my @merged = shift @seg;
    while (@seg) {
        my $op = pop @merged;
        push @merged, $op->merge(shift @seg);
    }

    my $x = 0;
    while ($x <= 4000000) {
        if ($map{Loc->new(x => $x, z => $row)->stringify}) {
            $x++;
            next;
        }

        my ($found) = grep {$_->x1 <= $x && $_->x2 >= $x} @merged;
        if (!$found) {
            #say "x: $x, y: $row";
            say $x*4000000+$row;
            exit;
        } else {
            $x = $found->x2 + 1;
        }
    }
}
