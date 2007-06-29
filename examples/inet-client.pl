#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use IO::Socket::SIPC;

my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::INET' );

$sipc->connect(
   PeerAddr => 'localhost',
   PeerPort => 50010,
   Proto    => 'tcp',
) or die $sipc->errstr($@);

warn "client connected to server\n";

$sipc->send("Hello server, gimme some data :-)\n", 1) or die $sipc->errstr($!);
my $answer = $sipc->read or die $sipc->errstr($!);
warn "server data: \n";
warn Dumper($answer);
$sipc->disconnect or die $sipc->errstr($!);
