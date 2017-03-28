#!/usr/bin/perl -w

use strict;
use OPC;
use List::Util qw(min);
use Time::HiRes qw(gettimeofday usleep sleep);

my $debug = 0;

my $num_leds = 24;
my $gamma = 5;
my $change_percentage = 33;
my $color_scale = 2/3;
my $client = new OPC('localhost:7890');
$client->can_connect();

my $pixels = [];
push @$pixels, [0, 0, 0] while scalar(@$pixels) < $num_leds;
$client->put_pixels(0, $pixels);

my $rotate_time = 10;#00;
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
    

my @patterns = (\&pick_leslie_colors, \&pick_random_colors, \&pick_fire_colors);

my $last_change = 0;
my $algo = -1;

$client->set_color_correction(0, $gamma, 1.0, 1.0, 1.0);
while(1){
    my ($seconds, $micros) = gettimeofday();
    if ($seconds - $last_change > $rotate_time) {
        $algo = ($algo + 1) % scalar @patterns;
        $last_change = $seconds;
    }
    my $rough_ratio = (($seconds + $micros / 1000 / 1000)  - $last_change) / $rotate_time;
    my $ratio = min($rough_ratio / 0.05, 1.0);

    printf("algo = %2.2f, rough = %2.2f, ratio = %2.2f\n",
           $algo, $rough_ratio, $ratio)
        if $debug;
    
    my $delay = $patterns[$algo]->($change_percentage * $ratio);
    
    # Send this row of pixels to the server
    $client->put_pixels(0,$pixels);

    Time::HiRes::sleep($delay / 5);
    $iterations++;
}

print "Done\n";
