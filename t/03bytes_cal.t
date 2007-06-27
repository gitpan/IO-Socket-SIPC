use strict;
use warnings;
use Test::More tests => 15;
use IO::Socket::SIPC;

my $socket = IO::Socket::SIPC->new();

$socket->read_max_bytes('3 KB');
ok($socket->{read_max_bytes} == 3072, "convert KB");
$socket->read_max_bytes('3 K');
ok($socket->{read_max_bytes} == 3072, "convert K");
$socket->read_max_bytes('3 kb');
ok($socket->{read_max_bytes} == 3072, "convert kb");
$socket->read_max_bytes('3 k');
ok($socket->{read_max_bytes} == 3072, "convert k");

$socket->read_max_bytes('3 MB');
ok($socket->{read_max_bytes} == 3145728, "convert MB");
$socket->read_max_bytes('3 M');
ok($socket->{read_max_bytes} == 3145728, "convert M");
$socket->read_max_bytes('3 mb');
ok($socket->{read_max_bytes} == 3145728, "convert mb");
$socket->read_max_bytes('3 m');
ok($socket->{read_max_bytes} == 3145728, "convert m");

$socket->read_max_bytes('3 GB');
ok($socket->{read_max_bytes} == 3221225472, "convert GB");
$socket->read_max_bytes('3 G');
ok($socket->{read_max_bytes} == 3221225472, "convert G");
$socket->read_max_bytes('3 gb');
ok($socket->{read_max_bytes} == 3221225472, "convert gb");
$socket->read_max_bytes('3 g');
ok($socket->{read_max_bytes} == 3221225472, "convert g");

$socket->read_max_bytes(0);
ok($socket->{read_max_bytes} == 0, "convert 0");
$socket->read_max_bytes('UnLiMiTeD');
ok($socket->{read_max_bytes} == 0, "convert unlimited");
$socket->read_max_bytes(1);
ok($socket->{read_max_bytes} == 1, "convert 1 byte");
