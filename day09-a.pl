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
        is => 'rw',
        isa => Int,
        required => 1,
    );
    has z => (
        is => 'rw',
        isa => Int,
        required => 1,
    );

    sub move {
        my ($self, $dir) = @_;

        if ($dir eq 'L') {
            $self->{x} --;
        } elsif ($dir eq 'R') {
            $self->{x} ++;
        } elsif ($dir eq 'U') {
            $self->{z} ++;
        } else {
            $self->{z} --;
        }
    }

    sub distance {
        my ($x1, $x2) = @_;
        return 1  if $x1 - $x2 == 2;
        return -1 if $x2 - $x1 == 2;
        return 0;
    }

    sub follow {
        my ($self, $head) = @_;

        if ($self->x == $head->x) {
            $self->{z} += Loc::distance($head->z, $self->z);
        } elsif ($self->z == $head->z) {
            $self->{x} += Loc::distance($head->x, $self->x);
        } elsif (abs($self->x - $head->x) == 1) {
            my $d = Loc::distance($head->z, $self->z);
            if ($d) {
                $self->{x} = $head->x;
                $self->{z} += $d;
            }
        } elsif (abs($self->z - $head->z) == 1) {
            my $d = Loc::distance($head->x, $self->x);
            if ($d) {
                $self->{z} = $head->z;
                $self->{x} += $d;
            }
        }
    }

    sub stringify {
        my ($self) = @_;
        return $self->x. ",". $self->z;
    }
}

package main;

my ($head, $tail) = (Loc->new(x=>0,z=>0),Loc->new(x=>0,z=>0));
my %moves;

while(<>) {
    if (my ($dir, $steps) = /^([LRUD]) (\d+)/) {
        for (1..$steps) {
            $head->move($dir);
            $tail->follow($head);

            $moves{$tail->stringify} ++;
        }
    }
}

say scalar %moves;
