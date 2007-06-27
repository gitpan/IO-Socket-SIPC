use strict;
use warnings;
use Test::More tests => 11;
use IO::Socket::SIPC;

unless (-d "certs") {
    if (-d "../certs") {
        chdir "..";
    } else {
        ok(0, "Find certs");
        die "Please run this example from the IO::Socket::SIPC distribution directory!\n";
    }
}

ok(1, "find certs");

my $addr = '127.0.0.1';
my $port = ();

{  # THE SERVER
   my $socket = IO::Socket::SIPC->new();

   ok($socket, "new object");

   $socket->connect(
      LocalAddr       => $addr,
      Proto           => 'tcp',
      Listen          => 1,
      Reuse           => 1,
      SSL_verify_mode => 0x01,
      SSL_ca_file     => 'certs/ca.pem',
      SSL_cert_file   => 'certs/servercert.pem',
      SSL_key_file    => 'certs/serverkey.pem',
      SSL_passwd_cb   => sub {return "megaraptor"},
   ) or do { ok(0, "connect"); die $socket->errstr($socket->sock->errstr); };

   ok(1, "create socket");

   $port = $socket->sock->sockport;
   ok($port, "get sockport");

   if (my $pid = fork) {
      ok(1, "fork server");

      my $client = $socket->accept or die $socket->errstr;
      ok(1, "accept connect");

      my $struct = $client->read or die $client->errstr;
      ok(1, "read struct");

      $client->disconnect or die $client->errstr;
      ok(1, "disconnect client");

      $socket->disconnect or die $socket->errstr;
      ok(1, "disconnect socket");

      my $ok = 0;
      $ok = 1 if $struct->{foo} && $struct->{foo} eq 'foo'
              && $struct->{bar} && $struct->{bar} eq 'bar'
              && $struct->{baz} && $struct->{baz} eq 'baz';

      ok($ok, "deserialize struct");

      waitpid($pid, 0);
      ok(!$?, "waitpid");
      exit;
   }
}

sleep 1;

{  # THE CLIENT
   my $socket = IO::Socket::SIPC->new();

   $socket->connect(
      PeerAddr        => $addr,
      PeerPort        => $port,
      Proto           => 'tcp',
      SSL_use_cert    => 1,
      SSL_verify_mode => 0x01,
      SSL_ca_file     => 'certs/ca.pem',
      SSL_cert_file   => 'certs/clientcert.pem',
      SSL_key_file    => 'certs/clientkey.pem',
      SSL_passwd_cb   => sub { return "pyroraptor" }
   ) or die $socket->errstr($socket->sock->errstr);

   my %hash = (foo => 'foo', bar => 'bar', baz => 'baz');
   $socket->send(\%hash) or die $socket->errstr;
   $socket->disconnect or die $socket->errstr;
}
