#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all any pairs product min max);

package Element {
    sub new {
        my ($cls, @params) = @_;
        $cls = ref $cls if ref $cls;
        bless \@params, $cls;
    }

    sub number { $_[0]->[0] }

    sub key {
        my ($self) = @_;
        join('.', @$self[0..1]);
    }
}

my @inital = map {chomp; $_} <>;

# initialise
my %numbers;
my @moving = map {
    my $n = $numbers{$_}++;
    Element->new($_, $n);
} @inital;
%numbers=();

@inital = @moving;

my $size = @moving;
my %moving = map { $moving[$_]->key => $_ } 0..$#moving;

# mix up
while (my $e = shift @inital) {
    my $index = $moving{$e->key};

    my $v = $e->number;

    my $ni = $index;
    $ni = ($index + $v) % ($size - 1);
    if ($v > 0) { # move right
        $ni = 0 if $ni == $size -1;
    } elsif ($v < 0) { # move left
        $ni = $size-1 if $ni == 0;
    }

    if ($ni < $index) {
        for my $i (reverse $ni+1..$index) {
            my $m = $moving[$i] = $moving[$i-1];
            $moving{$m->key} = $i;
        }

        $moving[$ni] = $e;
        $moving{$e->key} = $ni;
    } elsif ($ni > $index) {
        for my $i ($index..$ni-1) {
            my $m = $moving[$i] = $moving[$i+1];
            $moving{$m->key} = $i;
        }

        $moving[$ni] = $e;
        $moving{$e->key} = $ni;
    }

    #say "moving $v";
    #say join(", ", map {$_->number} @moving);
}

# find 0
my $zero_i = $moving{'0.0'};

#say $zero_i;

say sum0 map {
    my $i = ( $zero_i + $_ ) % $size;
    #say $moving[$i]->number;
    $moving[$i]->number;
} (1000, 2000, 3000);
