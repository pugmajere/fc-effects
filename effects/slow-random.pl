#!/usr/bin/perl -w

use strict;
use OPC;

my $num_leds = 150;
my $max_brightness = 150;
my $change_percentage = 66;
my $client = new OPC('localhost:7890');
$client->can_connect();

my $pixels = [];
push @$pixels, [0, 0, 0] while scalar(@$pixels) < $num_leds;
$client->put_pixels(0, $pixels);

while(1){
    for (my $i = 0; $i < @$pixels; $i++) {
        if (rand(100) < $change_percentage) {
            $pixels->[$i] = [int(rand($max_brightness)), # red
                             int(rand($max_brightness)), # green
                             int(rand($max_brightness))]; # blue
        }
    }
    
    # Send this row of pixels to the server
    $client->put_pixels(0,$pixels);

    sleep 2;
}

print "Done\n";
