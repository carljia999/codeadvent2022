#!/usr/bin/perl

use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0);
use Data::Dumper;
use Tree;

my $root = Tree->new( '/'); 
$root->meta({type => 'd'});

#open(my $fh, "<", \$input)
#    or die "Can't open memory file: $!";

my $node = $root;
while(<>) {
    my ($name, $size);
    if (($name) = /\$ cd (\S+)/) {
        if ($name eq '/') {
            $node = $root;
        } elsif ($name eq '..') {
            $node = $node->parent;
        } else {
            $node = first {$_->value eq $name} $node->children;
        }
    } elsif (/\$ ls/) {
    } elsif (($name) = /^dir (\S+)/) {
        my $c = Tree->new($name);
        $c->meta({type => 'd'});
        $node->add_child($c);
    } elsif (($size, $name) = /^(\d+) (\S+)/) {
        my $c = Tree->new($name);
        $c->meta({type => 'f', size => $size});
        $node->add_child($c);
    } else {
        die "unknow line";
    }
}

#print map("$_\n", @{$root -> tree2string});

my @dir;
for my $n ($root->traverse(Tree->POST_ORDER)) {
    if ($n->meta->{type} eq 'd') {
        $n->meta->{size} = sum0 map {$_->meta->{size}} $n->children;
        push @dir, $n if $n->meta->{size} <= 100000;
    }
}

#say $_->format_node({}, $_) for @dir;

say sum0 map {$_->meta->{size}} @dir;
