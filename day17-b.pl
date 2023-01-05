#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all pairs product min max);

package Loc {
    use Moo;
    use Types::Standard qw( Int );
    use namespace::autoclean;

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

        if (@args == 2) {
            my ($x, $z) = @args;
            return $class->$orig( x => $x, z=> $z );
        }

        return $class->$orig(@args);
    };

    sub stringify {
        my ($self) = @_;
        return $self->x. ",". $self->z;
    }
}

package Rock {
    use Moo;
    use Types::Standard qw( Int InstanceOf ArrayRef Any );
    use List::Util qw(any all min max);
    use namespace::autoclean;

    has width => (
        is => 'ro',
        isa => Int,
    );

    has height => (
        is => 'ro',
        isa => Int,
    );

    has location => (
        is => 'rw',
        isa => InstanceOf["Loc"],
    ); # location of (0, 0) on the map

    has ps => (
        is => 'ro',
        isa => ArrayRef[InstanceOf["Loc"]],
    );

    sub hmove {
        my ($self, $dir, $tower) = @_;

        my $step = 0;
        if ($self->location->z > $tower->height - 1) {
            # no need to check every point
            if ($dir eq '<') { # left
                if ($self->location->x > 0) {
                    $self->location->{x}--;
                    $step = -1;
                }
            } elsif ($dir eq '>') { # right
                if ($self->location->x + $self->width < 7) {
                    $self->location->{x}++;
                    $step = 1;
                }
            }
        } else {
            if ($dir eq '<') { # left
                my $loc = Loc->new(x => $self->location->x -1, z=> $self->location->z);
                if (all {
                    $_->x+$loc->x >=0 &&
                    !$tower->is_rock($_->x+$loc->x, $_->z+$loc->z)
                } @{$self->ps}) {
                    $self->location->{x}--;
                    $step = -1;
                }
            } elsif ($dir eq '>') { # right
                my $loc = Loc->new(x => $self->location->x +1, z=> $self->location->z);
                if (all {
                    $_->x+$loc->x <=6 &&
                    !$tower->is_rock($_->x+$loc->x, $_->z+$loc->z)
                } @{$self->ps}) {
                    $self->location->{x}++;
                    $step = 1;
                }
            }
        }

        return $step; # -1 or 1 or 0
    }

    sub drop {
        my ($self, $tower) = @_;
        my $step = 0;
        my $loc = Loc->new(x => $self->location->x, z=> $self->location->z-1);

        if (all {
            $_->z+$loc->z >=0 &&
            !$tower->is_rock($_->x+$loc->x, $_->z+$loc->z)
        } @{$self->ps}) {
            $self->location->{z}--;
            $step = 1;
        }
        return $step; # or 0
    }
}

package Tower {
    use Moo;
    use Types::Standard qw( Int InstanceOf ArrayRef HashRef Any );
    use namespace::autoclean;

    # the goal of part 2 is to reduce mem usage
    # we can only save most recent content
    has chars => (
        is  => 'rw',
        isa => ArrayRef[Any], # array of array of chars, 7 chars wide, grow to the top
    );

    has archived_height => (
        is  => 'rw',
        isa => Int,
        default => 0,
    );

    sub is_rock {
        my ($self, $x, $z) = @_;

        return 0 if $z >= $self->height;
        die "too optimistic" if $z - $self->archived_height < 0;
        return $self->chars->[$z - $self->archived_height][$x];
    }

    sub height {
        my ($self) = @_;
        return scalar @{$self->chars} + $self->archived_height;
    }

    sub add_rock {
        my ($self, $rock) = @_;
        my $rows = $self->chars;

        for my $pt (@{$rock->ps}) {
            my ($x, $z) = ($pt->x + $rock->location->x, $pt->z + $rock->location->z);

            $z -= $self->archived_height;
            unless ($z < @$rows) {
                push @$rows, [(0)x7];
            }
            $rows->[$z][$x] = 1;
        }
        $self->archive;
    }

    sub archive {
        my ($self) = @_;

        my $rows = $self->chars;
        return unless @$rows > 20000;

        my $to_be_del = 10000;
        splice @$rows, 0, $to_be_del;
        $self->{archived_height} += $to_be_del;
    }
}

package main;
use Data::Dumper;

{
my @order = qw(- + L | 0);
my @width = (4, 3, 3, 1, 2);
my @height = (1, 3, 3, 4, 2);

# coordinates are given based off the left-bottom point as (0,0), x grows to the right, z to the top.
my %shapes = (
    '-' => [
        Loc->new(0,0),
        Loc->new(1,0),
        Loc->new(2,0),
        Loc->new(3,0),
    ],
    '+' => [
        Loc->new(1,0),
        Loc->new(0,1),
        Loc->new(1,1),
        Loc->new(2,1),
        Loc->new(1,2),
    ],
    'L' => [
        Loc->new(0,0),
        Loc->new(1,0),
        Loc->new(2,0),
        Loc->new(2,1),
        Loc->new(2,2),
    ],
    '|' => [
        Loc->new(0,0),
        Loc->new(0,1),
        Loc->new(0,2),
        Loc->new(0,3),
    ],
    '0' => [
        Loc->new(0,0),
        Loc->new(1,0),
        Loc->new(0,1),
        Loc->new(1,1),
    ],
);

sub next_rock {
    my ($height) = @_;
    state $index = 0;
    my $i = $index++ % @order;
    my $type = $order[$i];

    return (Rock->new(
        ps      => $shapes{$type},
        width   => $width[$i],
        height  => $height[$i],
        location => Loc->new(x => 2, z => $height+3),
    ),$i);
}
}

{
my @order = split //, <>;
sub next_move {
    state $index = 0;
    my $i = $index++ % @order;
    my $dir = $order[$i];
    return ($dir, $i);
}
}

my $tower = Tower->new(chars=>[]);

my (%repeat_map, $added_height);

my $ri = 1;

while ($ri <= 1000000000000) {
    my ($s, $rock_i) = next_rock($tower->height);

    my ($success, $m, $move_index) = (1);
    while( $success ) {
        ($m, $move_index) = next_move;
        $s->hmove($m, $tower);
        $success = $s->drop($tower);
    }
    $tower->add_rock($s);

    if (!$added_height) {
        my $key = "$move_index-$rock_i";
        push @{$repeat_map{$key}}, [$ri, $tower->height];

        if (@{$repeat_map{$key}} == 3) {
            # cycle found
            my $delta_rocks  = $ri - $repeat_map{$key}->[1][0];
            my $delta_height = $tower->height - $repeat_map{$key}->[1][1];

            my $repeat = int((1000000000000 - $ri) / $delta_rocks);
            $added_height = $repeat * $delta_height;
            $ri += $repeat * $delta_rocks;
            %repeat_map=();
        }
    }

    $ri++;
}

say $tower->height + $added_height;