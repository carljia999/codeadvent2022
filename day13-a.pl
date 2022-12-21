#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all pairs);
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

my (@index);
my $i = 1;
foreach my $pair ( pairs @objs ) {
   my ($l, $r) = @$pair;
   my $v = compare($l, $r);
   push @index, $i if $v > 0;
   $i++;
}

say sum0 @index;
