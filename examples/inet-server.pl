#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::SIPC;

my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::INET' );

$sipc->connect(
   LocalAddr  => 'localhost',
   LocalPort  => 50010,
   Proto      => 'tcp',
   Listen     => 10,
   Reuse      => 1,
) or die $sipc->errstr($@);

warn "server initialized\n";

$sipc->sock->timeout(10);

while ( 1 ) {
   while (my $client = $sipc->accept()) {
      print "connect from client: ", $client->sock->peerhost, "\n";
      my $request = $client->read(1) or die $client->errstr($!);
      next unless $request;
      chomp($request);
      warn "client says: $request\n";
      $client->send({ foo => 'is foo', bar => 'is bar', baz => 'is baz'}) or die $client->errstr($!);
      $client->disconnect or die $client->errstr($!);
   }
   warn "server runs on a timeout, re-listen on socket\n";
}

$sipc->disconnect or die $sipc->errstr($!);
