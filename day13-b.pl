#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all pairs product);
use Data::Dumper;
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new(utf8 => 1);

my (@objs);

sub compare {
    my ( $l, $r ) = @_;

    if (ref $l && ref $r) {
        my $i = 0;
        while ($i < @$l && $i < @$r) {
            my $v = compare($l->[$i], $r->[$i]);
            return $v if $v != 0;
            $i++;
        }
        return @$r <=> @$l;
    } elsif (!ref $l && !ref $r) {
        return $r <=> $l;
    } elsif (ref $l) {
        return compare($l, [$r]);
    } else {
        return compare([$l], $r);
    }
}

# load program
while(my $line = <>) {
    chomp $line;
    next unless $line;
    push @objs, $json->decode($line);
}

push @objs, [[2]], [[6]];

@objs = sort { compare($b, $a) } @objs;

#say $json->encode($_) for @objs;

my (@index) = map { $_+1 } grep { my $s = $json->encode($objs[$_]); $s eq '[[2]]' or $s eq '[[6]]'} 0..$#objs;

say product @index;


