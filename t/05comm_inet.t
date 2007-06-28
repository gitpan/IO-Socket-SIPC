use strict;
use warnings;
use Test::More tests => 10;
use IO::Socket::SIPC;

my $addr = '127.0.0.1';
my $port = ();

{  # THE SERVER
   my $socket = IO::Socket::SIPC->new();

   ok($socket, "new object");

   $socket->connect(
      LocalAddr => $addr,
      Proto     => 'tcp',
      Listen    => 1,
      Reuse     => 1,
   ) or do { ok(0, "connect"); die $socket->errstr($!); };

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
   ) or die $socket->errstr($!);

   my %hash = (foo => 'foo', bar => 'bar', baz => 'baz');
   $socket->send(\%hash) or die $socket->errstr;
   $socket->disconnect or die $socket->errstr;
}
