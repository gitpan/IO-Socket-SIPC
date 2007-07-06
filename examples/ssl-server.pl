#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::SIPC;

my $sipc = IO::Socket::SIPC->new(
   favorite      => 'IO::Socket::SSL',
   use_check_sum => 1,
);

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
) or die $sipc->errstr;

$sipc->debug(4);

while ( 1 ) { 
   my $client;
   while ( $client = $sipc->accept(10) ) { 
      print "connect from client: ", $client->sock->peerhost, "\n";
      my $request = $client->read_raw or die $client->errstr;
      next unless $request;
      chomp($request);
      warn "client says: $request\n";
      $client->send({ foo => 'is foo', bar => 'is bar', baz => 'is baz'}) or die $client->errstr;
      $client->disconnect or die $client->errstr;
   }   
   die $sipc->errstr unless defined $client;
   warn "server runs on a timeout, re-listen on socket\n";
}

$sipc->disconnect or die $sipc->errstr;
