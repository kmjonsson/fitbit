#!/usr/bin/perl 

use strict;
use warnings;

use lib 'lib';
use Fitbit;

use JSON;

sub usage {
	die "Usage: $0 YYYY-MM-DD\n";
}

my $date = shift @ARGV || usage();

usage() unless $date =~ /^\d\d\d\d-\d\d-\d\d$/;

my $fb = Fitbit->new();

if(!-f 'cookies.txt') {
	open(my $pw,"<","password.txt") || die "Failed to open password.txt";
	my($ep) = <$pw>;
	close($pw);
	die "Bad format in password.txt\n" if $ep !~ /^(\S+);(\S+)\s*/;
	my($email,$password) = ($1,$2);
	$fb->login($email,$password) || die "Failed to login..\n";
}

my $result = {
	'steps'              => $fb->steps($date),
	'id_steps'           => $fb->id_steps($date),
	'active_minutes'     => $fb->active_minutes($date),
	'id_active_minutes'  => $fb->id_active_minutes($date),
	'calories_burned'    => $fb->calories_burned($date),
	'id_calories_burned' => $fb->id_calories_burned($date),
	'distance'           => $fb->distance($date),
	'id_distance'        => $fb->id_distance($date),
	'floors'             => $fb->floors($date),
	'id_floors'          => $fb->id_floors($date),
	'sleep'              => $fb->sleep($date,$date),
};

open(my $out,">","out/$date.json") || die "Can't open out/$date.json";
print $out encode_json($result);
close($out);
