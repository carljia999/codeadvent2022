#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all);
use Data::Dumper;
use POSIX ();

package Monkey {
    use Moo;
    use Types::Standard qw( Int Str ArrayRef CodeRef );
    use namespace::autoclean;

    has inspected => (
        is => 'rw',
        isa => Int,
        default => 0,
    );
    has items => (
        is => 'rw',
        isa => ArrayRef[Int],
        required => 1,
    );
    has worry_booster => (
        is => 'ro',
        isa => CodeRef,
        required => 1,
    );
    has throw_to => (
        is => 'ro',
        isa => CodeRef,
        required => 1,
    );

    sub play {
        my ($self) = @_;

        my @throws;
        while (@{$self->items}) {
            my $item = shift @{$self->items};
            $self->{inspected} ++;
            $item = $self->worry_booster->($item);
            my $monkey = $self->throw_to->($item);
            push @throws, [$monkey, $item];
        }
        return @throws;
    }
}

package main;

my (@monkey);

sub build_monkey {
    <>;
    my (@items) = <> =~ /(\d+)/g;
    my ($op) = <> =~ /=(.+)$/;
    my ($divisor) = <> =~ /(\d+)/;
    my ($yes_to) = <> =~ /(\d+)/;
    my ($no_to) = <> =~ /(\d+)/;

    $op =~ s/old/\$level/g;

    return Monkey->new(
        items => \@items,
        worry_booster => sub {
            my ($level) = @_;
            my $new = eval $op;
            POSIX::floor($new/4);
        },
        throw_to => sub {
            my ($level) = @_;
            $level % $divisor == 0 ?
            $yes_to :
            $no_to;
        }
    );
}

# load data
my $more;
do {
    push @monkey, build_monkey;
    $more = <>;
} while $more;

# round 1 to 20
for (1..20) {
    for my $m (@monkey) {
        my @items = $m->play;
        for (@items) {
            my ($to_monkey, $item) = @$_;
            push @{$monkey[$to_monkey]->items}, $item;
        }
    }
}

# monkey business
#say "monkey $_: " . $monkey[$_]->inspected .  " times" for 0..$#monkey;
my ($m1, $m2) = sort { $b <=> $a } map { $_->inspected } @monkey;
say $m1 * $m2;
