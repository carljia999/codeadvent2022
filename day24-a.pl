#!env perl
use v5.30;
use warnings;
use strict;

package Point {
    my @neighbours = reverse grep { abs($_->[0]) + abs($_->[1]) == 1 }
                map { my $i = $_; map {[$i, $_]} (-1..1) }
                (-1..1);
    sub new {
        my ($cls, @xyz) = @_;
        if (@xyz == 1) {
            @xyz = split /,/, $xyz[0];
        }
        $cls = ref $cls if ref $cls;
        bless \@xyz, $cls;
    }
    sub x { $_[0]->[0] = $_[1] if @_> 1; $_[0]->[0] }
    sub y { $_[0]->[1] = $_[1] if @_> 1; $_[0]->[1] }
    sub stringify { join(',', $_[0]->@*) }
    sub neighbours {
        my ($self) = @_;
        map {
            $self->new($self->x + $_->[0], $self->y + $_->[1])
        } @neighbours;
    }
}

package Sprite {
    my ($R, $D, $L, $U) = qw(> v < ^);

    sub new {
        my ($cls, $x, $y, $facing) = @_;
        bless {
            loc     => Point->new($x, $y),
            facing  => $facing,
        }, $cls;
    }

    sub next {
        my ($self, $maxx, $maxy) = @_;
        my $facing = $self->{facing};
        my $loc = $self->{loc};
        if ($facing eq $R) {
            if ($loc->x + 1 <= $maxx) {
                $loc->[0] ++;
            } else {
                $loc->[0] = 1;
            }
        } elsif ($facing eq $L) {
            if ($loc->x - 1 >= 1) {
                $loc->[0] --;
            } else {
                $loc->[0] = $maxx;
            }
        } elsif ($facing eq $D) {
            if ($loc->y + 1 <= $maxy) {
                $loc->[1] ++;
            } else {
                $loc->[1] = 1;
            }
        } elsif ($facing eq $U) {
            if ($loc->y - 1 >= 1) {
                $loc->[1] --;
            } else {
                $loc->[1] = $maxy;
            }
        }
    }
}

package State {
    # path (arryref to record the visited points)
    # minute
    # current location

    my ($R, $D, $L, $U) = qw(> v < ^);

    sub new {
        my ($cls, $loc, $min, $path) = @_;
        $cls = ref $cls if ref $cls;
        bless {
            loc => $loc,
            min => $min,
            path => $path,
        }, $cls;
    }

    sub wait {
        my ($self) = @_;
        my @path = (@{$self->{path}}, $self->{loc});
        return $self->new(
            $self->{loc},
            $self->{min}+1,
            \@path,
        );
    }

    sub move_to {
        my ($self, $loc) = @_;
        my @path = (@{$self->{path}}, $self->{loc});
        return $self->new(
            $loc,
            $self->{min}+1,
            \@path,
        );
    }

    sub key {
        my ($self) = @_;
        $self->{min} . "-" . $self->{loc}->stringify;
    }
}
use List::Util qw(sum0 min max first);

my (@map_by_step, @sprites);

my ($minx, $miny, $maxx, $maxy) = (1, 1);

sub build_map {
    my $y = 0;

    my %map;
    while(my $line = <>) {
        chomp($line);
        my @str = split "", $line;
        for my $x (0..$#str) {
            if ($str[$x] =~ /[>v<^]/) {
                my $loc = Point->new($x, $y);
                push @sprites, Sprite->new($x, $y, $str[$x]);
                $map{$loc->stringify} = 1;
            }
        }
        $maxx = $#str - 1;
        $y++;
    }
    $maxy = $y-2;
    push @map_by_step, \%map;
}

build_map;

sub dump_map {
    my ($maxx, $maxy, $map) = @_;

    say join('', '#.', '#' x $maxx);
    for my $z (1..$maxy) {
        say join('', '#', map { exists $map->{"$_,$z"} ? $map->{"$_,$z"}->{facing} : '.' } (1..$maxx)) . '#';
    }
    say join('', '#' x $maxx, '.#');
}

#dump_map($maxx, $maxy, $map_by_step[0]);
my $mcm;
for my $i (max($maxx, $maxy)..$maxx*$maxy) {
    if ($i % $maxx == 0 and $i % $maxy == 0) {
        $mcm = $i;
        last;
    }
}

say "cycle = $mcm";

sub simulate {
    for (1..$mcm-1) {
        for my $s (@sprites) {
            $s->next($maxx, $maxy);
        }

        my %map = map {
            $_->{loc}->stringify => 1
        } @sprites;

        push @map_by_step, \%map;

        #say "Minute $_";
        #dump_map($maxx, $maxy, \%map);
        #say "";
    }
}

simulate;

sub map_for {
    my ($min) = @_;

    $map_by_step[$min % $mcm];
}

sub find_path_dfs {
    my ($min, $min_path) = (($maxx + $maxy) * 20,);

    my $start = Point->new(1,1);
    my $ss = State->new(
        $start,
        1,
        [$start],
    );
    my @queue = ($ss);
    my %seen = ( $ss->key => 1 ); # backtracking is allowed, thus to avoid repetitions

BAILOUT:
    while (my $s = shift @queue) {
        my $loc = $s->{loc};
        my $locstr = $loc->stringify;
        if ($loc->x == $maxx && 
            $loc->y == $maxy) {

            if ($min > $s->{min}) {
                $min = $s->{min};
                $min_path = $s->{path};
            }

            say "found 1, min = $min";
            next;
        }

        # pruning techniques
        {   # Estimate the min minutes by assuming that we can go one step closer.
            # If that estimation is greater or equal than the currently known min minutes, we do not have further investigate that branch.
            my $estimate = $s->{min} + ($maxx - $loc->x) + ($maxy - $loc->y);

            next BAILOUT if $estimate >= $min;
        }

        # one step further
        my @exp_moves;

        # use map of next minute
        my $map = map_for($s->{min}+1);
        my @neighbours = $loc->neighbours;

        for my $n (@neighbours[0,1], 0, @neighbours[2,3]) {
            if ( !$n ) {
                # wait
                push @exp_moves, $s->wait unless exists $map->{$loc->stringify};
                next;
            }

            # make sure still in the map
            next unless ($n->x >= 1 && $n->x <= $maxx && $n->y >= 1 && $n->y <= $maxy);

            my $ns = $n->stringify;
            # avoid blizzard
            next if (exists $map->{$ns});
            # avoid go up and left if we can go to right or down
            #next if $n->x <= $loc->x && $n->y <= $loc->y && $closer;

            push @exp_moves, $s->move_to($n);
        }

        unshift @queue, grep { !exists $seen{$_->key} } @exp_moves;
        $seen{$_->key} = 1 for @exp_moves;
    }
    #say join('->', map {$_->stringify} @$min_path);
    return $min;
}

sub dump_path {
    my ($path) = @_;

    my $min = 1;
    my $map = map_for($min);

    for my $loc (@$path) {
        say "minute $min, loc => " . $loc->stringify;
        say join('', '#.', '#' x $maxx);
        for my $z (1..$maxy) {
            say join('', '#', map {
                exists $map->{"$_,$z"}
                ? 'B'
                : $loc->x == $_ && $loc->y == $z
                ? 'E'
                : '.'
            } (1..$maxx)) . '#';
        }
        say join('', '#' x $maxx, '.#');
        $min ++;
        $map = map_for($min);
        <>;
    }
}

say 1+find_path_dfs;
