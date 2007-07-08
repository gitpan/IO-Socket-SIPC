#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use IO::Socket::SIPC;

my $sipc = IO::Socket::SIPC->new(
   socket_handler => 'IO::Socket::SSL',
   use_check_sum  => 1,
);

$sipc->connect(
   PeerAddr        => 'localhost',
   PeerPort        => 50010,
   Proto           => 'tcp',
   SSL_use_cert    => 1,
   SSL_verify_mode => 0x01,
   SSL_ca_file     => '../certs/ca.pem',
   SSL_cert_file   => '../certs/clientcert.pem',
   SSL_key_file    => '../certs/clientkey.pem',
   SSL_passwd_cb   => sub { return "pyroraptor" }
) or die $sipc->errstr;

warn "client connected to server\n";

$sipc->debug(4);
$sipc->send_raw("Hello server, gimme some data :-)\n") or die $sipc->errstr;
my $answer = $sipc->read or die $sipc->errstr;
warn "server data: \n";
warn Dumper($answer);
$sipc->disconnect or die $sipc->errstr;
