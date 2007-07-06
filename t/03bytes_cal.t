use strict;
use warnings;
use Test::More tests => 15;
use IO::Socket::SIPC;

my $socket = IO::Socket::SIPC->new();
my $bytes  = ();

$bytes = $socket->_cal_bytes('3 KB');
ok($bytes == 3072, "convert KB");
$bytes = $socket->_cal_bytes('3 K');
ok($bytes == 3072, "convert K");
$bytes = $socket->_cal_bytes('3 kb');
ok($bytes == 3072, "convert kb");
$bytes = $socket->_cal_bytes('3 k');
ok($bytes == 3072, "convert k");

$bytes = $socket->_cal_bytes('3 MB');
ok($bytes == 3145728, "convert MB");
$bytes = $socket->_cal_bytes('3 M');
ok($bytes == 3145728, "convert M");
$bytes = $socket->_cal_bytes('3 mb');
ok($bytes == 3145728, "convert mb");
$bytes = $socket->_cal_bytes('3 m');
ok($bytes == 3145728, "convert m");

$bytes = $socket->_cal_bytes('3 GB');
ok($bytes == 3221225472, "convert GB");
$bytes = $socket->_cal_bytes('3 G');
ok($bytes == 3221225472, "convert G");
$bytes = $socket->_cal_bytes('3 gb');
ok($bytes == 3221225472, "convert gb");
$bytes = $socket->_cal_bytes('3 g');
ok($bytes == 3221225472, "convert g");

$bytes = $socket->_cal_bytes(0);
ok($bytes == 0, "convert 0");
$bytes = $socket->_cal_bytes('UnLiMiTeD');
ok($bytes == 0, "convert unlimited");
$bytes = $socket->_cal_bytes(1);
ok($bytes == 1, "convert 1 byte");
