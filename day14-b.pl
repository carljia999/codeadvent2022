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

package Sand {
    use Moo;
    use Types::Standard qw( Int HashRef);
    use namespace::autoclean;

    extends 'Loc';

    sub move_to {
        my ($self, $to) = @_;
        $self->x($to->x);
        $self->z($to->z);
    }

    sub come_to_rest {
        my ($self, $map) = @_;
        my $steps = 0;

        while(1) {
            my $pos = Loc->new(x => $self->x, z => $self->z+1);

            if (!$map->is_occupied($pos)) {
                $self->move_to($pos);
                $steps ++;
                next;
            } else {
                $pos->x($self->x-1);
                if (!$map->is_occupied($pos)) {
                    $self->move_to($pos);
                    $steps ++;
                    next;
                } else {
                    $pos->x($self->x+1);
                    if (!$map->is_occupied($pos)) {
                        $self->move_to($pos);
                        $steps ++;
                        next;
                    } else {
                        last;
                    }
                }
            }
        }
        return $steps;
    }
}

package Map {
    use Moo;
    use Types::Standard qw(Int HashRef);
    use namespace::autoclean;

    has md => (
        is => 'ro',
        isa => HashRef,
        required => 1,
    );

    has bottom => (
        is => 'ro',
        isa => Int,
        required => 1,
    );

    sub is_occupied {
        my ($self, $pos) = @_;

        return 1 if $pos->z == $self->bottom;
        return exists $self->md->{$pos->stringify};
    }
}

package main;
my (%map, $bottom);

sub build_map {
    while(my $line = <>) {
        my ($px, $pz); # pre loc
        while ($line =~ /(\d+),(\d+)/g) {
            my ($x, $z) = ($1, $2);
            $bottom = defined $bottom ? max($bottom, $z) : $z;

            if (!defined $px) {
                $px = $x;
                $pz = $z;
                next;
            }

            if ($px == $x) {
                $map{$_->stringify} = '#' for map {Loc->new(x=>$x, z=> $_)} min($pz,$z)..max($pz,$z);
                $pz = $z;                
            } else {
                $map{$_->stringify} = '#' for map {Loc->new(x=>$_, z=> $z)} min($px,$x)..max($px,$x);
                $px = $x;
            }
        }
    }
}

build_map;

my $map = Map->new(md => \%map, bottom => $bottom + 2);

my $units=0;

while(1) {
    my $sand = Sand->new(x => 500, z => 0);
    my $steps = $sand->come_to_rest($map);
    #say $sand->stringify, "steps: $steps";
    last unless $steps > 0;
    $map{$sand->stringify} = 'o';
    $units++;
}

say $units+1;

