#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all any pairs product min max);

package Point {
    my @neighbours = grep { abs($_->[0]) + abs($_->[1]) + abs($_->[2]) == 1 }
                map { my $y = $_; map {[@$y, $_]} (-1..1) }
                map { my $x = $_; map {[$x, $_]} (-1..1) }
                (-1..1);

    sub new {
        my ($cls, @xyz) = @_;
        if (@xyz == 1) {
            @xyz = split /,/, $xyz[0];
        }
        $cls = ref $cls if ref $cls;
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

    sub neighbours {
        my ($self) = @_;
        map {
            $self->new($self->x + $_->[0], $self->y + $_->[1], $self->z + $_->[2])
        } @neighbours;
    }
}

package main;

my ($min, $max, %droplet);

# determine the bounds
for my $p (map { chomp; Point->new($_) } <>) {
    $droplet{$p->stringify} = 1;
    if (!$min) {
        $min = Point->new(@$p);
        $max = Point->new(@$p);
        next;
    }

    for (0..2) {
        $min->[$_] = $p->[$_] if $min->[$_] > $p->[$_];
        $max->[$_] = $p->[$_] if $max->[$_] < $p->[$_];
    }
}
$min->[$_]--, $max->[$_]++ for (0..2);

# flood fill, from min
my %seen = ($min->stringify => 1);
my @queue = ($min);

my $count;
while (my $p = shift @queue) {
    for my $n ($p->neighbours) {
        next if any {; $n->[$_] < $min->[$_] || $n->[$_] > $max->[$_] } (0..2); # within boundary
        my $key = $n->stringify;
        next if exists $seen{$key}; # already visited
        if (exists $droplet{$key}) { # in droplet
            $count ++;
            next;
        }
        $seen{$key} = 1;
        push @queue, $n;
    }
}

# count the sides
#my $count = sum0 map {
#    map { exists $droplet{$_->stringify} ? 1 : 0 } Point->new($_)->neighbours
#} keys %seen;

say $count;