#!/usr/bin/perl -w

use strict;
use OPC;

my $num_leds = 150;
my $max_brightness = 150;
my $client = new OPC('localhost:7890');
$client->can_connect();

my $pixels = [];
push @$pixels, [0, 0, 0] while scalar(@$pixels) < $num_leds;
$client->put_pixels(0, $pixels);
sleep 1;

print "Done\n";
