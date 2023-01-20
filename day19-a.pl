#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all any pairs product min max);
use Array::Split qw( split_by );
use Data::Dumper;

package BluePrint {
    use List::Util qw(first sum0 all any pairs product min max);
    sub new {
        my ($cls, @params) = @_;
        $cls = ref $cls if ref $cls;
        bless \@params, $cls;
    }

    sub number { $_[0]->[0] }
    sub robot_cost {
        my ($self, $robot) = @_;

        return {
            ore => $self->[1],
        } if $robot eq 'ore';
        return {
            ore => $self->[2],
        } if $robot eq 'clay';
        return {
            ore => $self->[3],
            clay => $self->[4],
        } if $robot eq 'obsidian';
        return {
            ore => $self->[5],
            obsidian => $self->[6],
        };
    }

    sub robot_limit {
        my ($self, $robot) = @_;
        if ($robot eq 'ore') {
            if ($#$self == 7) {
                return $self->[7];
            } else {
                my $max = max(@$self[1,2,3,5]);
                push @$self, $max;
                return $max;
            }
        }
        return $self->[4] if $robot eq 'clay';
        return $self->[6] if $robot eq 'obsidian';
        return 100;
    }
}

package State {
    my %type_index = (
        ore => 0,
        clay => 1,
        obsidian => 2,
        geode => 3,
    );

    sub new {
        my ($cls, @params) = @_;
        $cls = ref $cls if ref $cls;
        bless \@params, $cls;
    }

    sub mineral {
        my ($self, $type) = @_;
        return $self->[$type_index{$type}];
    }

    sub consume_mineral {
        my ($self, $type, $amt) = @_;
        return $self->[$type_index{$type}] -= $amt;
    }

    sub robot {
        my ($self, $robot) = @_;
        return $self->[$type_index{$robot} + 4];
    }

    sub push_step {
        my ($self, $step) = @_;
        if ($#$self < 9) {
            push @$self, [ $step ];
        } else {
            $self->[9] = [ @{$self->[9]}, $step ];
        }
    }

    sub path {
        my ($self) = @_;
        join('->', $self->[9]->@*);
    }

    sub add_robot {
        my ($self, $robot) = @_;
        $self->push_step($robot);
        return $self->[$type_index{$robot} + 4] ++;
    }

    sub collect {
        # return a clone
        my ($self) = @_;
        my @clone = @$self;

        for (0..3) {
            $clone[$_] += $clone[$_ + 4];
        }
        $clone[8] --;
        return $self->new(@clone);
    }

    sub remaining { $_[0]->[8]}

    sub cache_key {
        my ($self) = @_;
        join(',', @$self[0..2], @$self[4..8])
    }
    sub stringify {
        my ($self) = @_;
        "minerals: " . join(',', @$self[0..3]) . "\trobots: " . join(',', @$self[4..7]) . "\tremaining: " . $self->remaining
    }
}

package main;

# parse the blueprints
my @blueprint = map { BluePrint->new(@$_) } split_by(7, map { /(\d+)/g } <>);

sub simulate_dfs {
    my ($bp) = @_;
    my ($max, $max_path) = 0;
    #my %cache;

    my @queue = (State->new(
        (0) x 4,
        1, (0) x 3,
        24,
    ));

BAILOUT:
    while (my $s = shift @queue) {
        #say $s->stringify;
        # find one full path
        if ($s->remaining <= 0 ) {
            if ($s->mineral('geode') > $max) {
                $max = $s->mineral('geode');
                $max_path = $s;
            }
            next;
        }

        # pruning techniques
        {   # Estimate the maximum amount of geode by assuming that we can build a geode robot at each time step.
            # If that estimation is less or equal than the currently known maximal amount of geode, we do not have further investigate that branch.
            my $estimate = $s->mineral('geode');
            my $robots = $s->robot('geode');
            for (1..$s->remaining) {
                $estimate += $robots++;
            }
            next BAILOUT if $estimate <= $max;
        }

        #if exists $cache{$s->cache_key} {
        #    my $result = $cache{$s->cache_key};
        #    $max = $result if $result > $max;
        #}

        # one step further
        my $n = $s->collect;

        if ($n->remaining == 0) {
            unshift @queue, $n;
            next;
        }

        # build robots
        my $geode_robot;

        my @robot_moves;
        for my $r (qw(geode obsidian clay ore)) {
            # Do not build more robots than needed to build another robot
            # e.g. if the most expensive robot costs 5 ore, do not build more than 5 ore robots.
            if ($s->robot($r) > $bp->robot_limit($r)) {
                next;
            }

            my $cost = $bp->robot_cost($r);
            my $mn = $s->new(@$n);

            # have enough minerals before collect?
            if (all { $s->mineral($_) >= $cost->{$_} } keys %$cost) {
                $mn->consume_mineral($_, $cost->{$_}) for keys %$cost;
                $mn->add_robot($r);
                push @robot_moves, $mn;

                if ($r eq 'geode') {
                    # Always build a geode robot if you can and do not investigate other branches in that case.
                    $geode_robot = 1;
                    last;
                }
            }
        }

        # don't build any robots
        $n->push_step('n');
        push @robot_moves, $n unless $geode_robot;

        unshift @queue, @robot_moves;
    }

    say $max_path->path;
    return $max;
}

my %cache;
sub max_per_state {
    my ($bp, $s) = @_;

    if ($s->remaining == 0 ) {
        return $s->mineral('geode');
    }

    my $n = $s->collect;

    if ($n->remaining == 0) {
        return $n->mineral('geode');
    }

    my $key = $s->cache_key;

    if (exists $cache{$key}) {
        return $s->mineral('geode') + $cache{$key};
    }

    # build robots
    my $geode_robot;

    my @robot_moves;
    for my $r (qw(geode obsidian clay ore)) {
        # Do not build more robots than needed to build another robot
        # e.g. if the most expensive robot costs 5 ore, do not build more than 5 ore robots.
        if ($s->robot($r) > $bp->robot_limit($r)) {
            next;
        }

        my $cost = $bp->robot_cost($r);
        my $mn = $s->new(@$n);

        # have enough minerals before collect?
        if (all { $s->mineral($_) >= $cost->{$_} } keys %$cost) {
            $mn->consume_mineral($_, $cost->{$_}) for keys %$cost;
            $mn->add_robot($r);
            push @robot_moves, $mn;

            if ($r eq 'geode') {
                # Always build a geode robot if you can and do not investigate other branches in that case.
                $geode_robot = 1;
                last;
            }
        }
    }

    my $max = max map { max_per_state($bp, $_) } (@robot_moves, $n);

    $cache{$key} = $max - $s->mineral('geode');
    #say "set $key = " . $cache{$key};
    return $max;
}

sub simulate_recursive {
    my ($bp) = @_;
    my $max = max_per_state($bp, State->new(
        (0) x 4,
        1, (0) x 3,
        24,
    ));

    # clear cache
    %cache = ();

    return $max;
}

sub playback {
    my ($bp, $s, $steps) = @_;

    my $minute = 1;
    while ($s->remaining && @$steps) {
        say "== Minute $minute ==";
        my $n = $s->collect;
        my $r = shift @$steps;
        
        if ($r ne 'n') {
            my $cost = $bp->robot_cost($r);
            $n->consume_mineral($_, $cost->{$_}) for keys %$cost;
            $n->add_robot($r);
            say "build $r";
        }
        $s = $n;
        $minute ++;

        say $s->stringify;
    }
}

=pod

playback(
    $blueprint[0],
    State->new(
        (0) x 4,
        1, (0) x 3,
        21,
    ), [qw(
        n n n ore clay clay clay clay n obsidian clay clay obsidian clay geode n obsidian geode obsidian geode n
    )
]);
exit;

=cut


# simulate
say sum0 map {
    my $bp = $_;
    my $geode = simulate_recursive($bp);
    $bp->number * $geode
} @blueprint;