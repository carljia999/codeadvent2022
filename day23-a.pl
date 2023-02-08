#!env perl
use v5.30;
use warnings;
use strict;

package Loc {
    use Moo;
    use Types::Standard qw( Int );
    use List::Util qw(first);
    use Data::Dumper;
    use namespace::autoclean;

    my @all_neighbours = grep { abs($_->[0]) + abs($_->[1]) > 0 }
                map { my $i = $_; map {[$i, $_]} (-1..1) }
                (-1..1);

    my %neighbours = (
        N => [ map {[$_, -1]} (-1..1) ],
        S => [ map {[$_,  1]} (-1..1) ],
        W => [ map {[-1, $_]} (-1..1) ],
        E => [ map {[ 1, $_]} (-1..1) ],
    );

    my %indexes = (
        map {
            my $d = $_;
            my @points = $neighbours{$d}->@*;

            my @index = map {
                my $i = $_;
                my $v = $all_neighbours[$i];

                my $found = first {
                    $v->[0] == $_->[0] && $v->[1] == $_->[1]
                } @points;

                $found ? ($i) : ();
            } (0..$#all_neighbours);

            $d => \@index;
        } keys %neighbours
    );

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
        my ($self, $dir) = @_;
        map {
            ref($self)->new(x => $self->x + $_->[0], z => $self->z + $_->[1])
        } ($dir ? $neighbours{$dir}->@* : @all_neighbours);
    }

    sub indexes {
        my ($self, $dir) = @_;

        return $indexes{$dir}->@*;
    }

    sub loc_move {
        my ($self, $dir) = @_;
        my $new = ref($self)->new(x => $self->x, z => $self->z);
        if ($dir eq 'N') {
            $new->{z}--;
        } elsif ($dir eq 'S') {
            $new->{z}++;
        } elsif ($dir eq 'W') {
            $new->{x}--;
        } elsif ($dir eq 'E') {
            $new->{x}++;
        }
        return $new;
    }
}

package Elf {
    use Moo;
    use Types::Standard qw( ArrayRef Int Str Enum Any );
    use namespace::autoclean;

    has directions => (
        is => 'ro',
        isa => ArrayRef[Str],
        required => 0,
        default => sub { [qw(N S W E)] },
    );

    sub rotate_directions {
        my ($self) = @_;

        my $aref = $self->directions;
        my $dir = shift @$aref;
        push @$aref, $dir;
        return;
    }
}

use List::Util qw(sum0 min max first all);

my %map;

sub build_map {
    my $z = 0;

    while(my $line = <>) {
        chomp($line);
        my @str = split "", $line;
        for my $x (0..$#str) {
            if ($str[$x] eq '#') {
                my $loc = Loc->new(x => $x, z => $z);
                $map{$loc->stringify} = 1;
            }
        }
        $z++;
    }
}

sub move_candidate {
    my ($elf, $loc) = @_;

    my @around = map { exists $map{$_->stringify} } $loc->neighbours;

    return unless grep {$_} @around;

    first {
        my $dir = $_;

        all {
            !$around[$_]
        } $loc->indexes($dir);
    } $elf->directions->@*;
}

sub my_cmp {
    my ($a, $b) = @_;
    my $c = Loc->new($a);
    my $d = Loc->new($b);
    return $c->z <=> $d->z || $c->x <=> $d->x;
}

sub run_step {
    my %proposed;
    state $elf = Elf->new;
    for my $loc (sort { my_cmp($a, $b) } keys %map) {
        $loc = Loc->new($loc);

        my $move = move_candidate($elf, $loc);

        if ($move) {
            $move = $loc->loc_move($move);
            push @{$proposed{$move->stringify}}, $loc;
        }
    }

    for my $loc (keys %proposed) {
        next if @{$proposed{$loc}} > 1;

        my $old_loc = $proposed{$loc}->[0];
        delete $map{$old_loc->stringify};
        $map{$loc} = 1;
    }

    $elf->rotate_directions;
}

sub count_tiles {
    my ($minx, $maxx, $minz, $maxz);

    my @elves = map {Loc->new($_)} keys %map;

    $minx = min map {$_->x} @elves;
    $maxx = max map {$_->x} @elves;
    $minz = min map {$_->z} @elves;
    $maxz = max map {$_->z} @elves;

    ($maxx - $minx + 1) * ($maxz - $minz + 1) - @elves
}

sub dump_map {
    my ($minx, $maxx, $minz, $maxz);

    my @elves = map {Loc->new($_)} keys %map;

    $minx = min map {$_->x} @elves;
    $maxx = max map {$_->x} @elves;
    $minz = min map {$_->z} @elves;
    $maxz = max map {$_->z} @elves;

    for my $z ($minz..$maxz) {
        say join('', map { exists $map{"$_,$z"} ? '#' : '.' } ($minx..$maxx));
    }
}

build_map;
run_step() for (1..10);
#dump_map;

say count_tiles;

