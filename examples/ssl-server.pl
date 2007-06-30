#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::SIPC;

my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::SSL' );

$sipc->connect(
   LocalAddr       => 'localhost',
   LocalPort       => 50010,
   Proto           => 'tcp',
   Listen          => 10,
   Reuse           => 1,
   SSL_verify_mode => 0x01,
   SSL_ca_file     => '../certs/ca.pem',
   SSL_cert_file   => '../certs/servercert.pem',
   SSL_key_file    => '../certs/serverkey.pem',
   SSL_passwd_cb   => sub {return "megaraptor"},
) or die $sipc->errstr($sipc->sock->errstr);

warn "server initialized\n";

$sipc->sock->timeout(10);

while ( 1 ) {
   while (my $client = $sipc->accept()) {
      print "connect from client: ", $client->sock->peerhost, "\n";
      my $request = $client->read_raw or die $client->errstr($client->sock->errstr);
      next unless $request;
      chomp($request);
      warn "client says: $request\n";
      $client->send({ foo => 'is foo', bar => 'is bar', baz => 'is baz'}) or die $client->errstr($client->sock->errstr);
      $client->disconnect or die $client->errstr($!);
   }
   warn "server runs on a timeout, re-listen on socket\n";
}

$sipc->disconnect or die $sipc->errstr($!);
