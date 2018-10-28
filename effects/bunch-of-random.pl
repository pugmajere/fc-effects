#!/usr/bin/perl -w

use strict;
use OPC;
use List::Util qw(min);
use Time::HiRes qw(gettimeofday usleep sleep);

my $debug = 0;

my $num_leds = 150;
my $gamma = 5;
my $change_percentage = 33;
my $color_scale = 2/3;
my $client = new OPC('localhost:7890');
$client->can_connect();

my $pixels = [];
push @$pixels, [0, 0, 0] while scalar(@$pixels) < $num_leds;
$client->put_pixels(0, $pixels);

my $rotate_time = 1000;
my $iterations = 0;


sub scale {
    my ($ar) = @_;
    my $ret = [0, 0, 0];
    for (my $i = 0; $i < @$ar; $i++) {
        $ret->[$i] = $ar->[$i] * $color_scale;
    }
    return $ret;
}

my @lcols = ([195, 144, 212],
             [75, 71, 179],
             [18, 10, 245],
             [191, 2, 166],
             [12, 232, 140],
             [250, 102, 176],
    );

sub pick_leslie_colors {
    my ($change_percentage) = @_;
    for (my $i = 0; $i < @$pixels; $i++) {
        if (rand(100) < $change_percentage) {
            $pixels->[$i] = scale($lcols[int(rand(@lcols))]);
        }
    }

    return 1.0
}

sub pick_random_colors {
    my ($change_percentage) = @_;
    for (my $i = 0; $i < @$pixels; $i++) {
        if (rand(100) < $change_percentage) {
            $pixels->[$i] = scale([int(rand(255)), # red
                                   int(rand(255)), # green
                                   int(rand(255))] # bleu
                );
        }
    }

    return 1.0
}

my @fcols = (
    [255,  0,  0],
    [128,  0,  0],
    [255, 160,  0],
    [255, 80,  0],
    [255, 40,  0],
    [196,  100,  0],
    );


sub pick_fire_colors {
    my ($change_percentage) = @_;
    $change_percentage /= 5;
    for (my $i = 0; $i < @$pixels; $i++) {
        my $pick = rand(100);
        if ($pick < $change_percentage) {
            $pixels->[$i] = scale($fcols[int(rand(@fcols))]);
        }
    }
    # Fire wants a fast flickering, over a smaller percentage of leds.
    return 0.1;
}

my @greencols = (
    [0, 255, 0],
    [0, 128, 0],
    [0, 0, 0],
    );

sub pick_stpaddy_colors {
    my ($change_percentage) = @_;
    for (my $i = 0; $i < @$pixels; $i++) {
        my $pick = rand(100);
        if ($pick < $change_percentage) {
            $pixels->[$i] = scale($greencols[int(rand(@greencols))]);
        }
    }
    return 1.0;
}

my @orangecols = (
    [255, 165, 0],
    [255, 140, 0],
    [255, 69, 0],
    [0, 0, 0],
    );

sub pick_halloween_colors {
    my ($change_percentage) = @_;
    for (my $i = 0; $i < @$pixels; $i++) {
        my $pick = rand(100);
        if ($pick < $change_percentage) {
            $pixels->[$i] = scale($orangecols[int(rand(@orangecols))]);
        }
    }
    return 1.0;
}

sub Wheel {
    my ($wheel_pos) = @_;
    # Input a value 0 to 768 to get a color value.
    # The colours are a transition r - g -b - back to r
    my $r = 0;
    my $g = 0;
    my $b = 0;
    my $case = int($wheel_pos / 256);
    # printf("case = %s, wheel_pos = %s\n", $case, $wheel_pos);
    if ($case == 0) {
        $r = 255 - ($wheel_pos % 256);   #Red down
        $g = $wheel_pos % 256;      # Green up
        $b = 0;                  #blue off
    } elsif ($case == 1) {
        $g = 255 - ($wheel_pos % 256);  #green down
        $b = $wheel_pos % 256;      #blue up
        $r = 0;                  #red off
    } elsif ($case == 2) {
        $b = 255 - ($wheel_pos % 256);  #blue down
        $r = $wheel_pos % 256;      #red up
        $g = 0;                  #green off
    } else {
	die "case $case unexpected.";
    }

    return ($r, $g, $b);
}


my $rainbow_wheel_counter = 0;
sub set_rainbow_oneshot {
    my ($change_percentage) = @_;

    for (my $i = 0; $i < @$pixels; $i++) {
        my $pick = rand(100);
        if (1 || $pick < $change_percentage) {
	    my $pixel_idx = $i; # % 50;
            my ($r, $g, $b) = Wheel(
                (($pixel_idx * 768 / scalar @$pixels) + $rainbow_wheel_counter) % 768);
	    # printf("LED %i: (%d, %d, %d).\n", $i, $r, $g, $b);
            $pixels->[$i] = scale([$r, $g, $b])
        }
    }
    $rainbow_wheel_counter = ($rainbow_wheel_counter + 1) % 768;
    return 0.03;
}

my @rainbow_colors = (
    [117, 7, 135],
    [148, 0, 211], ##
    [75, 0, 130], ##
    [0, 0, 255],  ##
    [0, 77, 255],
    [0, 255, 0],  ##
    [0, 128, 38],
    [255, 255, 0], ##
    [255, 237, 0],
    [255, 127, 0], ##
    [255, 140, 0],
  [255, 0, 0],
); 

my $static_rainbow_idx = 0;
sub static_rainbow {
    my ($change_percentage) = @_;

    $static_rainbow_idx += 1;

    for (my $i = 0; $i < @$pixels; $i++) {
      my $col = ($static_rainbow_idx + $i) % scalar @rainbow_colors;
      $pixels->[$i] = scale($rainbow_colors[$col]);
    }
    return 5.0;
}

sub nothing {
    my ($change_percentage) = @_;
    for (my $i = 0; $i < @$pixels; $i++) {
        $pixels->[$i] = [0, 0, 0];
    }
    return 60.0;
}


my @patterns = (\&pick_leslie_colors, \&pick_random_colors, 
                \&pick_fire_colors);

my $stpaddy = scalar @patterns;
push @patterns, \&pick_stpaddy_colors;

my $halloween = scalar @patterns;
push @patterns, \&pick_halloween_colors;

my $rainbow = scalar @patterns;
my $rainbow_count = 2;
push @patterns,  \&set_rainbow_oneshot, \&static_rainbow;

my $last_change = 0;
my $algo = -1;
my $chosen_algo;

$client->set_color_correction(0, $gamma, 1.0, 1.0, 1.0);
while(1) {
    my ($seconds, $micros) = gettimeofday();
    if ($seconds - $last_change > $rotate_time || $algo == -1) {
        my @t = localtime();
        if ($t[4] == 2 && $t[3] <= 19 && $t[3] > 14) {
            $algo = $stpaddy;
        } elsif ($t[4] == 5) {
	    $algo = (($algo + 1) % $rainbow_count) + $rainbow;
        } elsif ($t[4] == 9 && $t[3] >= 25) {
            $algo = $halloween;
        } else {
            $algo = ($algo + 1) % scalar @patterns;
        }
        $last_change = $seconds;
        if ($t[2] > 6 && $t[2] < 18) {
            $chosen_algo = \&nothing;
        } else {
            $chosen_algo = $patterns[$algo];
        }
    }
    my $rough_ratio = (($seconds + $micros / 1000 / 1000)  - $last_change) / $rotate_time;
    my $ratio = min($rough_ratio / 0.05, 1.0);

    printf("algo = %2.2f, rough = %2.2f, ratio = %2.2f\n",
           $algo, $rough_ratio, $ratio)
        if $debug;
    
    my $delay = $chosen_algo->($change_percentage * $ratio);
    
    # Send this row of pixels to the server
    $client->put_pixels(0,$pixels);

    Time::HiRes::sleep($delay);
    $iterations++;
}

print "Done\n";
