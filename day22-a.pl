#!env perl
use v5.30;
use warnings;
use strict;
use List::Util qw(first sum0 all any pairs product min max);

package Point {
    sub new {
        my ($cls, @xyz) = @_;
        if (@xyz == 1) {
            @xyz = split /,/, $xyz[0];
        }
        bless \@xyz, $cls;
    }
    sub x { $_[0]->[0] = $_[1] if @_> 1; $_[0]->[0] }
    sub y { $_[0]->[1] = $_[1] if @_> 1; $_[0]->[1] }
    sub stringify { join(',', $_[0]->@*) }
}

package Sprite {
    my ($R, $D, $L, $U) = 0..3;

    sub new {
        my ($cls, $x) = @_;
        bless {
            loc     => Point->new($x,0),
            facing  => $R,
        }, $cls;
    }

    sub turn {
        my ($self, $RL) = @_;
        $self->{facing} = ($self->{facing} + ($RL eq 'R' ? 1 : -1)) % 4;
    }

    sub next {
        my ($self) = @_;
        my $facing = $self->{facing};
        my $loc = $self->{loc};
        if ($facing eq $R) {
            return Point->new($loc->x + 1, $loc->y);
        } elsif ($facing eq $L) {
            return Point->new($loc->x - 1, $loc->y);
        } elsif ($facing eq $D) {
            return Point->new($loc->x, $loc->y + 1);
        } elsif ($facing eq $U) {
            return Point->new($loc->x, $loc->y - 1);
        }
    }

    sub score {
        my ($self) = @_;

        my $loc = $self->{loc};
        ($loc->y + 1) * 1000 + ($loc->x + 1) * 4 + $self->{facing}
    }
}

# parse input
my ($map, @path, $width, @xboundary, @yboundary);
$width = 0;
while (my $l = <>) {
    chomp $l;

    next unless $l;
    if ($l =~ /^\d/) {
        @path = $l =~ /(\d+|\w)/g;
    } else {
        my @c = split //, $l;
        $width = @c if @c > $width;
        push @$map, \@c;
        my $left = first { $c[$_] ne ' ' } 0..$#c;
        push @xboundary, {
            left => $left,
            right => $#c,
        };
    }
}

# find y boundary
for my $x (0..$width-1) {
    my ($top, $bottom);
    for my $y (0..$#$map) {
        if ($x >= $xboundary[$y]->{left} && $x <= $xboundary[$y]->{right}) {
            if (!defined $top) {
                $top = $y;
            } else {
                $bottom = $y;
            }
        }
    }

    push @yboundary, {
        top     => $top,
        bottom  => $bottom,
    };
}

my $sprite = Sprite->new($xboundary[0]->{left});

my ($R, $D, $L, $U) = 0..3;

for my $p (@path) {
    if ($p eq 'R' || $p eq 'L') {
        $sprite->turn($p);
        next;
    }
    # move
    my $facing = $sprite->{facing};
    for (1..$p) {
        my $next = $sprite->next;

        # off the board ?
        my $in_map =    $next->y >=0 &&
                        $next->y < @$map &&
                        $next->x >= $xboundary[$next->y]->{left} &&
                        $next->x <= $xboundary[$next->y]->{right};

        # wrap around
        if (!$in_map) {
            if ($facing eq $L or $facing eq $R) { # left or right
                if ($sprite->{loc}->x == $xboundary[$next->y]->{left}) {
                    $next->x($xboundary[$next->y]->{right});
                } else {
                    $next->x($xboundary[$next->y]->{left});
                }
            } else { # up or down
                if ($sprite->{loc}->y == $yboundary[$next->x]->{top}) {
                    $next->y($yboundary[$next->x]->{bottom});
                } else {
                    $next->y($yboundary[$next->x]->{top});
                }
            }
        }

        # is it a wall
        if ( $map->[$next->y][$next->x] eq '#' ) {
            # stop
            last;
        } else {
            # go ahead
            $sprite->{loc} = $next;
        }
    }
}

say $sprite->score;
