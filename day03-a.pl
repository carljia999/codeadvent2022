#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);

sub priority {
    my $s = shift;
    if ($s =~ /[a-z]/) {
        return 1 + ord($s) - ord('a');
    } else {
        return 27 + ord($s) - ord('A');
    }
}


say sum0 map {
    chomp;
    return 0 unless $_;
    my @line = split //;
    my @h1 = splice(@line, 0, @line/2);

    my %h1 = map { $_ => 1 } @h1;
    my $s = first { $h1{$_} } @line;

    priority($s);
} <>;
