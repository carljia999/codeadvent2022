#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all pairs product min max any);

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

# shortest path between non-zero flow valves
my $apsp = $graph->APSP_Floyd_Warshall;

# max points per combination of open valves
# key is the sorted list of open valves
my %max_open;
my @flow_vs = grep { rate($_) } $graph->vertices;

# head, open, time limit, points
my @queue = (["AA", {} , 26, 0]);
while (my $state = shift @queue) {
    my ($hd, $open, $remain, $pts) = @$state;
    next if $remain < 0;

    # update %max_open
    my $key = join(",", sort {$a cmp $b} keys %$open);
    $max_open{$key} = $pts if !$max_open{$key} || $max_open{$key} < $pts;

    next if %$open == @flow_vs || $remain <= 0;

    for my $v (grep {!exists $open->{$_}} @flow_vs) {
        my $distance = $apsp->path_length($hd, $v);

        # open next
        my %noa = (%$open, $v => 1);
        my $nremain = $remain - $distance - 1;
        my $npts = $pts + $nremain * rate($v);
        push @queue, [$v, \%noa, $nremain, $npts];
    }
}

for my $human (keys %max_open) {
    my %open = map { $_ => 1 } split /,/, $human;
    next if scalar %open == @flow_vs;

    for my $elephant (keys %max_open) {
        my @open_e = split /,/, $elephant;
        next if any { exists $open{$_} } @open_e;

        my $max = $max_open{$human} + $max_open{$elephant};
        $max_points = $max if $max > $max_points;
    }
}

say $max_points;
