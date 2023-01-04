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

my $paths;
my $max_points = 0;
my $max_path;

my $num_openable = grep { rate($_) } $graph->vertices;

sub node_v {
    my ($n, $open) = @_;
    my $v;

    if (exists $open->{$n}) {
        $v = -$open->{$n};
    } else {
        $v = 1000 + rate($n);
    }

    return $v;
}

my %results; # to cache intermediate result

sub my_key {
    my ($head, $open, $time) = @_;
    my $key = $head . join(".", sort {$a cmp $b} keys %$open) . $time;
    return $key;
}

sub find_path {
    my ($head, $open, $time) = @_;
    my $u = $head;
    #say "head $head, open: " . join(",", keys %$open) . " time $time";

    my $key = my_key(@_);
    return $results{$key} if exists $results{$key};

    # two conditions to quit
    # 1. all nodes are visited
    # 2. 30 mins of time is used
    if (%$open == $num_openable || $time >= 29) {
        return 0;
    }

    # bail out
    return 0 if !%$open && $time > 4;

    $time ++; # move
    my @results;
    for my $v ( $graph->neighbors($u) ) {
        #say "move to $v";
        my $rate = rate($v);
        if ($rate > 0 && !exists $open->{$v}) {
            my %no = (%$open, $v => 1);
            push @results, (30 - $time - 1) * $rate + find_path($v, \%no, $time + 1);
        }

        push @results, find_path($v, $open, $time);
    }

    my $rt = $results{$key} = max @results;
    return $rt;
}

sub get_points {
    my $path = shift;

    my ($total, %seen, $time);
    for my $n (1..$#$path) {
        my $u = $path->[$n];
        $time ++;
        next if $seen{$u};

        $seen{$u} = 1;

        my $rate = rate($u);
        if ($rate > 0) {
            $time ++;
            $total += $rate * (30 - $time);
            die "time more than 30 - $time" if $time >= 30;
        }
    }
    return $total;
}

$max_points = find_path("AA", {}, 0);

say $max_points;
#say join("->", @$max_path);
#say get_points($max_path);