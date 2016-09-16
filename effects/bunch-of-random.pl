#!/usr/bin/perl -w

use strict;
use OPC;
use List::Util qw(min);

my $debug = 0;

my $num_leds = 150;
my $max_brightness = 150;
my $change_percentage = 33;
my $client = new OPC('localhost:7890');
$client->can_connect();

my $pixels = [];
push @$pixels, [0, 0, 0] while scalar(@$pixels) < $num_leds;
$client->put_pixels(0, $pixels);

my $iterations = 0;
my $rotate_limit = 1000;

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
            $pixels->[$i] = $lcols[int(rand(@lcols))];
        }
    }
}

sub pick_random_colors {
    my ($change_percentage) = @_;
    for (my $i = 0; $i < @$pixels; $i++) {
        if (rand(100) < $change_percentage) {
            $pixels->[$i] = [int(rand($max_brightness)), # red
                             int(rand($max_brightness)), # green
                             int(rand($max_brightness))]; # blue
        }
    }
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
    for (my $i = 0; $i < @$pixels; $i++) {
        my $pick = rand(100);
        if ($pick < $change_percentage) {
            $pixels->[$i] = $fcols[int(rand(@fcols))];
        }
    }

}
    

my @patterns = (\&pick_leslie_colors, \&pick_random_colors, \&pick_fire_colors);

while(1){
    my $algo = ($iterations / $rotate_limit) % @patterns;
    my $rough_algo = $iterations / $rotate_limit;
    my $ratio = min(($rough_algo - int($rough_algo)) / 0.05, 1.0);

    printf("algo = %2.2f, rough = %2.2f, ratio = %2.2f\n",
           $algo, $rough_algo, $ratio)
        if $debug;
    
    $patterns[$algo]->($change_percentage * $ratio);
    
    # Send this row of pixels to the server
    $client->put_pixels(0,$pixels);

    sleep 1;
    $iterations++;
}

print "Done\n";
