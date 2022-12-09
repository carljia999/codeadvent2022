#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);
use Data::Dumper;

sub packet_marker {
    my $str = shift;
    my $i = 1;
    my $len = length $str;
    my (%quad, @quad);
    @quad = split //, substr($str, 0, 14);
    $quad{$_}++ for @quad;

    while ($i+14 < $len) {
        my $nc = substr $str, $i+14-1, 1;
        my $lc = substr $str, $i-1, 1;

        if ($nc eq $lc) {
            $i ++;
            next;
        }

        if ( $quad{$lc} == 1) {
            delete $quad{$lc};
        } else {
            $quad{$lc}--;
        }

        $quad{$nc} ++;

        if (%quad == 14) {
            return $i+14;
        }
        $i ++;
    }
    return $len;
}

say packet_marker(<>);