#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all any pairs product min max);

package Monkey {
    sub new {
        my ($cls, $line) = @_;
        $cls = ref $cls if ref $cls;

        my @id = $line =~ /([a-z]{4})/g;

        my $id = shift @id;
        my $self = { id => $id};

        if (@id) {
            $self->{devs} = \@id;
            ($self->{op}) = $line =~ m{([-+*/])};
        } else {
            ($self->{num}) = $line =~ /(\d+)/;
            $self->{is_num} = 1;
        }
        bless $self, $cls;
    }
}

my %monkeys = map {
    my $m = Monkey->new($_);
    $m->{id} => $m
} <>;

# topological sort

my (@working, %sorted);

for (keys %monkeys) {
    if ($monkeys{$_}->{is_num}) {
        $sorted{$_} = 1;
    } else {
        push @working, $_;
    }
}

while (@working) {
    for my $w (@working) {
        my $m = $monkeys{$w};
        if (all { $sorted{$_} } $m->{devs}->@*) {
            $sorted{$w} = 1;
            $m->{is_num} = 1;
            $m->{num} = eval join("", $monkeys{$m->{devs}->[0]}->{num}, $m->{op}, $monkeys{$m->{devs}->[1]}->{num});
        }
    }
    @working = grep { !$monkeys{$_}->{is_num} } @working;
}

say $monkeys{root}->{num};