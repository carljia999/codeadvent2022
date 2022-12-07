#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);

# build a mapping table
my (%priority, $p);

$p = 1;
for ('a'..'z') {
    $priority{$_} = $p;
    $p++;
}

$p = 27;
for ('A'..'Z') {
    $priority{$_} = $p;
    $p++;
}

# calulate priority
sub priority {
    my $s = shift;
    if ($s =~ /[a-z]/) {
        return 1 + ord($s) - ord('a');
    } else {
        return 27 + ord($s) - ord('A');
    }
}

# given a group of 3 lines, return the common letter
sub find_common {
    my $group = shift;

    my %all;
    for (@$group) {
        for (@$_) {
            $all{$_} ++;
        }
    }

    first { 
        $all{$_} == 3
    } keys %all;
}

# used to build 3 line groups
my @tmp;

say sum0 
map {
    $priority{$_}
}
map {
    my $badge;
    push @tmp, $_;
    if (@tmp > 2) {
        $badge = find_common(\@tmp);
        @tmp = ();
    }
    $badge ? ($badge) : ();
}
map {
    chomp;

    # need to remove the duplicate type in both compartments - exercise one
    my @line = split //;
    # one type might apprear more than once
    my %line = map { $_ => 1 } @line;
    my @h1 = splice(@line, 0, @line/2);

    my %h1 = map { $_ => 1 } @h1;
    my $s = first { $h1{$_} } @line;
    [ grep {$_ ne $s} keys %line ]
}
<>;
