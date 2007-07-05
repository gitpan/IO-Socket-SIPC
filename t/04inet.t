use strict;
use warnings;
use Test::More tests => 12;
use IO::Socket::SIPC;

my $addr = '127.0.0.1';
my $port = ();

{  # THE SERVER
   my $socket = IO::Socket::SIPC->new( read_max_bytes => 100 );

   ok($socket, "new object");

   $socket->connect(
      LocalAddr => $addr,
      Proto     => 'tcp',
      Listen    => 1,
      Reuse     => 1,
   ) or do { ok(0, "connect"); die $socket->errstr; };

   ok(1, "create socket");

   $port = $socket->sock->sockport;
   ok($port, "get sockport");

   if (my $pid = fork) {
      ok(1, "fork server");

      my $client = $socket->accept or die $socket->errstr;
      ok(1, "accept connect");

      my $string = $client->read_raw or die $client->errstr;

      if ($string eq 'foo-bar-baz') {
         ok(1, "read string");
      } else {
         ok(0, "read string");
      }

      my $struct = $client->read or die $client->errstr;
      ok(1, "read struct");

      my $ok = 0;
      $ok = 1 if $struct->{foo} && $struct->{foo} eq 'foo'
              && $struct->{bar} && $struct->{bar} eq 'bar'
              && $struct->{baz} && $struct->{baz} eq 'baz';

      ok($ok, "deserialize struct");

      my $to_much = $client->read;

      if ($client->errstr =~ /the buffer length \(\d+ bytes\) exceeds read_max_bytes/) {
         ok(1, "read_max_bytes");
      } elsif ($to_much) {
         ok(0, "read_max_bytes");
      }

      $client->disconnect or die $client->errstr;
      ok(1, "disconnect client");

      $socket->disconnect or die $socket->errstr;
      ok(1, "disconnect socket");

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
   ) or die $socket->errstr;

   my $string  = ('foo-bar-baz');
   my %struct  = (foo => 'foo', bar => 'bar', baz => 'baz');
   my $to_much = 'x' x 101;
   $socket->send_raw($string) or die $socket->errstr;
   $socket->send(\%struct) or die $socket->errstr;
   $socket->send(\$to_much) or die $socket->errstr;
   $socket->disconnect or die $socket->errstr;
}
