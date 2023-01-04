#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all pairs product min max);

use Graph;

sub build_graph {
    my $g = Graph->new(undirected => 1);
    while (my $line = <>) {
        chomp($line);
        next unless $line;
        my ($v, $rate) = $line =~ /Valve (\w+).+?=(\d+)/;
        my (@vs) = $line =~ /(\w{2})(?:,\s|$)/g;
        $g->add_weighted_vertex($v, $rate);
        $g->add_edge($v, $_) for (@vs);
    }

    return $g;
}

my $graph = build_graph;

sub rate {
    $graph->get_vertex_attribute($_[0], 'weight')
}

my $max_points = 0;

my $num_openable = grep { rate($_) } $graph->vertices;

my %results; # to cache intermediate result

sub my_key {
    my ($ha, $hb, $open, $time) = @_;
    ($ha, $hb) = ($hb, $ha) if $ha gt $hb;
    my $key = "$ha$hb" . join(".", sort {$a cmp $b} keys %$open) . $time;
    return $key;
}

sub find_path {
    my ($ha, $hb, $open, $time) = @_;

    my $key = my_key(@_);
    return $results{$key} if exists $results{$key};

    # two conditions to quit
    # 1. all nodes are visited
    # 2. 26 mins of time is used
    if (%$open == $num_openable || $time >= 25) {
        return 0;
    }

    # bail out
    return 0 if !%$open && $time > 3;

    my @results;

    my $ha_openable;
    my $ratea = rate($ha);
    if ($ratea > 0 && !exists $open->{$ha}) {
        $ha_openable = 1;
        my %noa = (%$open, $ha => 1);
        # open a, move b
        for my $vb ( $graph->neighbors($hb) ) {
            push @results, (26 - $time - 1) * $ratea + find_path($ha, $vb, \%noa, $time+1);
        }
    }

    my $rateb = rate($hb);
    if ($rateb > 0 && !exists $open->{$hb}) {
        my %nob = (%$open, $hb => 1);
        # open b, move a
        for my $va ( $graph->neighbors($ha) ) {
            push @results, (26 - $time - 1) * $rateb + find_path($va, $hb, \%nob, $time+1);
        }

        # open a, open b
        my %noboth = (%$open, $hb => 1, $ha => 1);
        if (%noboth - %$open == 2) {
            push @results, (26 - $time - 1) * ($ratea + $rateb) + find_path($ha, $hb, \%noboth, $time+1);
        }
    }

    # move a, move b
    for my $va ( $graph->neighbors($ha) ) {
        for my $vb ( $graph->neighbors($hb) ) {
            unless ($ha eq $hb && $va eq $vb) { # prevent copy
                push @results, find_path($va, $vb, $open, $time+1);
            }
        }
    }

    return 0 unless @results;

    my $rt = $results{$key} = max @results;
    return $rt;
}

$max_points = find_path("AA", "AA", {}, 0);

say $max_points;
