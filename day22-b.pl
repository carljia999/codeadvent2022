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

sub wrap {
    my ($p, $sprite) = @_;
    # folding
    state %rules = (
        # y/50, x/50, dir
        join('', 0, 1, $U) => [3, 0, $R],
        join('', 0, 1, $L) => [2, 0, $R],
        join('', 0, 2, $U) => [3, 0, $U],
        join('', 0, 2, $R) => [2, 1, $L],
        join('', 0, 2, $D) => [1, 1, $L],
        join('', 1, 1, $R) => [0, 2, $U],
        join('', 1, 1, $L) => [2, 0, $D],
        join('', 2, 0, $U) => [1, 1, $R],
        join('', 2, 0, $L) => [0, 1, $R],
        join('', 2, 1, $R) => [0, 2, $L],
        join('', 2, 1, $D) => [3, 0, $L],
        join('', 3, 0, $R) => [2, 1, $U],
        join('', 3, 0, $D) => [0, 2, $D],
        join('', 3, 0, $L) => [0, 1, $D],
    );

    my $key = int($p->y/50) . int($p->x/50) . $sprite->{facing};
    my ($cube_row, $cube_col, $new_dir) = @{$rules{$key}};

    my ($row_idx, $col_idx) = ($p->y % 50, $p->x % 50);

    my $i;
    if ($sprite->{facing} eq $L) {
        $i = 49- $row_idx;
    } elsif ($sprite->{facing} eq $R) {
        $i = $row_idx;
    } elsif ($sprite->{facing} eq $U) {
        $i = $col_idx;
    } elsif ($sprite->{facing} eq $D) {
        $i = 49- $col_idx;
    }

    my ($new_row, $new_col);
    if ($new_dir eq $L) {
        $new_row = 49 - $i;
        $new_col = 49;
    } elsif ($new_dir eq $R) {
        $new_row = $i;
        $new_col = 0;
    } elsif ($new_dir eq $U) {
        $new_row = 49;
        $new_col = $i;
    } elsif ($new_dir eq $D) {
        $new_row = 0;
        $new_col = 49 - $i;
    }

    return ($cube_row*50+$new_row, $cube_col*50+$new_col, $new_dir);
}

sub wrap_demo {
    my ($p, $sprite) = @_;
    # folding
    state %rules = (
        # y/4, x/4, dir
        join('', 0, 2, $U) => [1, 0, $D],
        join('', 0, 2, $L) => [1, 1, $D],
        join('', 0, 2, $R) => [2, 3, $L],
        join('', 1, 0, $L) => [2, 3, $U],
        join('', 1, 0, $U) => [0, 2, $D],
        join('', 1, 0, $D) => [2, 2, $U],
        join('', 1, 1, $U) => [0, 2, $R],
        join('', 1, 1, $D) => [2, 2, $R],
        join('', 1, 2, $R) => [2, 3, $D],
        join('', 2, 2, $L) => [1, 1, $U],
        join('', 2, 2, $D) => [1, 0, $U],
        join('', 2, 3, $U) => [1, 2, $L],
        join('', 2, 3, $D) => [1, 0, $R],
        join('', 2, 3, $R) => [0, 2, $L],
    );

    my $key = int($p->y/4) . int($p->x/4) . $sprite->{facing};
    my ($cube_row, $cube_col, $new_dir) = @{$rules{$key}};

    my ($row_idx, $col_idx) = ($p->y % 4, $p->x % 4);

    my $i;
    if ($sprite->{facing} eq $L) {
        $i = 3- $row_idx;
    } elsif ($sprite->{facing} eq $R) {
        $i = $row_idx;
    } elsif ($sprite->{facing} eq $U) {
        $i = $col_idx;
    } elsif ($sprite->{facing} eq $D) {
        $i = 3- $col_idx;
    }

    my ($new_row, $new_col);
    if ($new_dir eq $L) {
        $new_row = 3 - $i;
        $new_col = 3;
    } elsif ($new_dir eq $R) {
        $new_row = $i;
        $new_col = 0;
    } elsif ($new_dir eq $U) {
        $new_row = 3;
        $new_col = $i;
    } elsif ($new_dir eq $D) {
        $new_row = 0;
        $new_col = 3 - $i;
    }

    return ($cube_row*4+$new_row, $cube_col*4+$new_col, $new_dir);
}

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
        my $on_map =    $next->y >=0 &&
                        $next->y < @$map &&
                        $next->x >= $xboundary[$next->y]->{left} &&
                        $next->x <= $xboundary[$next->y]->{right};

        my ($new_row, $new_col, $new_dir);
        # wrap around
        if (!$on_map) {
            ($new_row, $new_col, $new_dir) = wrap($sprite->{loc}, $sprite);
            $next->x($new_col);
            $next->y($new_row);

            # new loc should be on the map
        }

        # is it a wall
        if ( $map->[$next->y][$next->x] eq '#' ) {
            # stop
            last;
        } else {
            # go ahead
            $sprite->{loc} = $next;
            $sprite->{facing} = $new_dir if defined $new_dir;
        }
    }
}

say $sprite->score;
