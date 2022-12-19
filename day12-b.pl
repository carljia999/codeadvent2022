#!env perl
use v5.30;
use warnings;
use strict;

package Loc {
    use Moo;
    use Types::Standard qw( Int );
    use namespace::autoclean;

    my @neighbours = grep { abs($_->[0]) + abs($_->[1]) == 1 }
                map { my $i = $_; map {[$i, $_]} (-1..1) }
                (-1..1);

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

package Map {
    use Moo;
    use Types::Standard qw( ArrayRef Int Str Enum);
    use namespace::autoclean;

    has md => (
        is => 'ro',
        isa => ArrayRef[ArrayRef[Str]],
        required => 1,
    );

    has width => (
        is => 'ro',
        isa => Int,
        required => 0,
        lazy => 1,
        default => sub {
            my ($self) = @_;
            return scalar @{$self->md->[0]};
        },
    );

    has height => (
        is => 'ro',
        isa => Int,
        required => 0,
        lazy => 1,
        default => sub {
            my ($self) = @_;
            return scalar @{$self->md};
        },
    );

    sub level {
        my ($self, $p) = @_;
        my ($x, $z) = ($p->x, $p->z);
        my $v = $self->md->[$z][$x];
        $v = 'a' if $v eq 'S';
        $v = 'z' if $v eq 'E';
        return ord $v;
    }

    sub dump_map {
        my ($self) = @_;
        print @$_,"\n" for @{$self->md};
    }

    sub on_map {
        my ($self, $p) = @_;
        return 
            $p->x >= 0 && $p->x < $self->width
            &&
            $p->z >= 0 && $p->z < $self->height;
    }
}

package Step {
    use Moo;
    use Types::Standard qw( Any Int InstanceOf );
    use namespace::autoclean;

    has heap => (
        is => 'rw',
        isa => Any,
        required => 0,
    ); # required by Heap module

    has path => (
        is => 'ro',
        isa => InstanceOf["Loc"],
        required => 1,
    );
    has cost => (
        is => 'ro',
        isa => Int,
        required => 1,
    );

    sub cmp { $_[0]->{cost} <=> $_[1]->{cost} }
}

package main;

use List::Util qw(sum0 min);
use Heap::Fibonacci;

my ($start, $end);

sub build_map {
    my @map;
    while(my $line = <>) {
        chomp($line);
        my @str = split "", $line;
        push @map, \@str;
        for my $i (0..$#str) {
            if ($str[$i] eq 'S') {
                $start = Loc->new(x =>$i, z => @map - 1);
            } elsif ($str[$i] eq 'E') {
                $end = Loc->new(x =>$i, z => @map - 1);
            }
        }
    }

    return Map->new(md => \@map);
}

my $map = build_map;

sub find_shortest_path_bfs {
    my $steps = Heap::Fibonacci->new;

    $steps->add(Step->new(
        path => $end,
        cost => 0,
    ));

    my %seen;

    while (my $step = $steps->extract_top) {
        my $p = $step->{path};
        my $cost = $step->{cost};

        # prune
        next if $seen{$p->stringify};
        $seen{$p->stringify} = 1;

        # found exit now
        if ($map->level($p) == ord('a')) {
            return $cost;
        }

        # find next steps
        $steps->add(Step->new(
            path => $_,
            cost => $cost + 1,
        )) for grep {
            $map->on_map($_) && ($map->level($_) - $map->level($p) >= -1)
        } $p->neighbours;
    }

    die "did not find anything!";
}

my ($result) = find_shortest_path_bfs;

say $result;

