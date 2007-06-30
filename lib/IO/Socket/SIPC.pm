=head1 NAME

IO::Socket::SIPC - Serialize perl structures for inter process communication.

=head1 SYNOPSIS

    use IO::Socket::SIPC;

=head1 DESCRIPTION

This module makes it possible to transport perl structures between processes over sockets.
It wrappes your favorite IO::Socket module and controls the amount of data over the socket.
The default serializer is Storable with nfreeze() and thaw() but you can choose each other
serializer you wish to use. You have just follow some restrictions and need only some lines
of code to adjust it for yourself. In addition it's possible to use a checksum to check the
integrity of the transported data. Take a look to the method section.

=head1 METHODS

=head2 new()

Call C<new()> to create a new IO::Socket::SIPC object.

    read_max_bytes  Set the maximum allowed bytes to read from the socket.
    send_max_bytes  Set the maximum allowed bytes to send over the socket.
    favorite        Set your favorite module, IO::Socket::INET or IO::Socket::SSL or something else.
    deflate         Pass your own sub reference for serializion.
    inflate         Pass your own sub reference for deserializion.
    timeout         Set up a timeout one time on accept(). This option is only useful if your favorite
                    socket creator provides a timeout() method. Otherwise is occurs an error.
    use_check_sum   Check each transport with a MD5 sum.
    gen_check_sum   Set up your own checksum generator.

Defaults

    read_max_bytes  unlimited
    send_max_bytes  unlimited
    favorite        IO::Socket::INET
    deflate         nfreeze() of Storable
    inflate         thaw() of Storable (in a Safe compartment)
    timeout         not used until you set it
    gen_check_sum   md5() of Digest::MD5
    use_check_sum   enabled (disable it with 0)

You can set your favorite socket handler. Example:

    use IO::Socket::SIPC;

    my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::SSL' );

NOTE that the only mandatory thing is that your favorite must provide an C<accept()> method to wait
for connections because the C<accept()> method of IP::Socket::SIPC used it. If your favorite doesn't
provide an C<accept()> method it or it's another name then please request this feature by send me
a email. I will try to wrap it or disable checking the existence of C<accept()>!

Also you can set your own serializer if you like. Example:

    use IO::Socket::SIPC;
    use Convert::Bencode_XS;

    my $sipc = IO::Socket::SIPC->new(
        deflate => sub { Convert::Bencode_XS::bencode($_[0]) },
        inflate => sub { Convert::Bencode_XS::bdecode($_[0]) },
    );

    # or maybe

    use IO::Socket::SIPC;
    use JSON::PC;

    my $sipc = IO::Socket::SIPC->new(
        deflate => sub { JSON::PC::convert($_[0]) },
        inflate => sub { JSON::PC::parse($_[0])   },
    );

NOTE that the code that you handoff with deflate and inflate is embed in an eval block and if
it an error occurs you can get the error string by calling C<errstr()>. If you use the default
deserializer of Storable then the data is deserialized in a Safe compartment. If you use another
deserializer you have to build your own Safe compartment within your code ref!

It's just as well possible to use your own checksum generator if you like (dummy example):

    my $sipc = IO::Socket::SIPC->new(
       gen_check_sum => sub { Your::Fav::gen_sum($_[0]) }
    );

But I think Digest::MD5 is very well and it does it's job.

=head2 read_max_bytes() and send_max_bytes()

Call both methods to increase or decrease the maximum bytes that the server or client
is allowed to C<read()> or C<send()>. Possible sizes are KB, MB and GB or just a number
for bytes. It's not case sensitiv and you can use C<KB> or C<kb> or just C<k>. If you want
set the readable or sendable size to unlimited then you can call both methods with 0 or
C<unlimited>. The default max send and read size is unlimited.

Here some notations examples

    $sipc->read_max_bytes(1048576);
    $sipc->read_max_bytes('1024k');
    $sipc->read_max_bytes('1MB');

    # unlimited
    $sipc->read_max_bytes('unlimited');
    $sipc->read_max_bytes(0);

NOTE that the readable and sendable size is computed by the serialized and deserialized data
or on the raw data if you use C<read_raw()> or C<send_raw()>.

=head2 connect()

Call C<connect()> to connect to the socket. C<connect()> just call C<new()> of your favorite
socket creator and handoff all params to it. Example:

    my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::INET' );

    $sipc->connect(
       PeerAddr => 'localhost',
       PeerPort => '50010',
       Proto    => 'tcp',
    );

    # would call intern

    IO::Socket::INET->new(@_);

=head2 accept()

If a Listen socket is defined then you can wait for connections with C<accept()>.
C<accept()> is just a wrapper to the original C<accept()> method of your favorite
socket creator.

If a connection is accepted then a new object is created related to the peer. The new object will
be returned.

In addition you can set a timeout value in seconds if your favorite module provides a C<timeout()>
method.

    while ( my $c = $sipc->accept(10) ) { ... }

=head2 disconnect()

Call C<disconnect()> to disconnect the current connection. C<disconnect()> calls C<close()> on
the socket that is referenced by the object.

=head2 sock()

Call C<sock()> to access the object of your favorite module.

IO::Socket::INET examples:

    $sipc->sock->timeout(10);
    # or
    $sipc->sock->peerhost;
    # or
    $sipc->sock->peerport;
    # or
    my $sock = $sipc->sock;
    $sock->peerhost;

NOTE that if you use

    while ( my $c = $sipc->sock->accept ) { ... }

that $c is the unwrapped IO::Socket::INET object and not a IO::Socket::SIPC object.

=head2 send()

Call C<send()> to send data over the socket to the peer. The data will be serialized
and packed before it sends to the peer. If you use the default serializer then you
must handoff a reference, otherwise an error occure because C<nfreeze()> of Storable
just works with references.

    $sipc->send("Hello World!");  # this would fail
    $sipc->send(\"Hello World!"); # this not

If you use your own serializer then consult the documentation for what the serializer expect.

C<send()> returns undef on errors or if send_max_bytes is overtaken.

=head2 read()

Call C<read()> to read data from the socket. The data will be unpacked and deserialized
before it is returned. If the maximum read bytes is overtaken or an error occured then
C<read()> returns undef and aborts to read from the socket.

=head2 read_raw() and send_raw()

If you want to read or send a raw string and disable the serializer for a single transport then
you can call C<read_raw()> or C<send_raw()>.

=head2 errstr()

Call C<errstr()> to get the current error message if a method returns undef. C<errstr()> is not
useable with C<new()> because new fails by wrong settings.

NOTE that C<errstr()> do not contain the error message of your favorite module, because it's to
confused to find the right place for the error message. As example the error message from IO::Socket::INET
is provided in C<$@> and from IO::Socket::SSL in C<IO::Socket::SSL->errstr()>. Maybe the error message
of your favorite is placed somewhere else. C<errstr()> contains only a short message of what happends
in IO::Socket::SIPC. If you want to know the right message of your favorite try something like...

    # IO::Socket::INET
    $sipc->connect(%options) or die $sipc->errstr($@);

    # IO::Socket::SSL
    $sipc->connect(%options) or die $sipc->errstr($sipc->sock->errstr);

    # Your::Favorite
    $sipc->connect(%options) or die $sipc->errstr($YourFavoriteERRSTR);

    # or just
    $sipc->connect(%options) or die $sipc->errstr($!);

=head1 EXAMPLES

Take a look to the examples directory.

=head2 Server example

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
       while ( my $client = $sipc->accept() ) {
          print "connect from client: ", $client->sock->peerhost, "\n";
          my $request = $client->read(1) or die $client->errstr($!);
          next unless $request;
          chomp($request);
          warn "client says: $request\n";
          $client->send({ foo => 'is foo', bar => 'is bar', baz => 'is baz'})
             or die $client->errstr($!);
          $client->disconnect or die $client->errstr($!);
       }   
       warn "server runs on a timeout, re-listen on socket\n";
    }

    $sipc->disconnect or die $sipc->errstr($!);

=head2 Client example

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

=head1 PREREQUISITES

    UNIVERSAL           -  to check for routines with can()
    UNIVERSAL::require  -  to post load favorite modules
    IO::Socket::INET    -  to create sockets
    Digest::MD5         -  to check the data before and after transports
    Storable            -  the default serializer and deserializer
    Safe                -  deserialize (Storable::thaw) in a safe compartment

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 QUESTIONS

Do you have any questions or ideas?

MAIL: <jschulz.cpan(at)bloonix.de>

IRC: irc.perl.org#perlde

=head1 TODO AND IDEAS

    * do you have any ideas?
    * maybe another implementations of check sum generators
    * do you need another wrapper as accept() or timeout()? Tell me!
    * auto authentification

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package IO::Socket::SIPC;
our $VERSION = '0.02';

use strict;
use warnings;
use UNIVERSAL;
use UNIVERSAL::require;
use Carp qw/croak/;

# the default send + read bytes is unlimited
use constant DEFAULT_IO_SOCKET => 'IO::Socket::INET';
use constant DEFAULT_MAX_BYTES => 0;
use constant USE_CHECK_SUM     => 1;

# globals
$IO::Socket::SIPC::ERRSTR = defined;
$IO::Socket::SIPC::MAXBUF = 16384;

sub new {
   my $class = shift;
   my $self  = $class->_new(@_);

   $self->read_max_bytes($self->{read_max_bytes});
   $self->send_max_bytes($self->{send_max_bytes});
   $self->_load_digest($self->{use_check_sum}) unless $self->{gen_check_sum};
   $self->_load_favorite;

   if (!$self->{deflate} && !$self->{inflate}) {
      $self->_load_serializer;
   } elsif (ref($self->{deflate}) ne 'CODE' || ref($self->{inflate}) ne 'CODE') {
      croak "$class: options deflate/inflate expects a code ref";
   }

   if ($self->{gen_check_sum} && ref($self->{gen_check_sum}) ne 'CODE') {
      croak "$class: option gen_check_sum expect a code ref";
   }

   if ($self->{timeout} && $self->{timeout} !~ /^\d+\z/) {
      croak "$class: invalid value for param timeout";
   }

   return $self;
}

# -------------------------------------------------------------------------
# Yet unsupported and just an idea. This should makes it possible to create
# own wrapper over favorites socket creators... I hope I never need it :-)
# sub wrapper {
#    my ($self, $name, $code) = @_;
#    { no strict 'refs'; *{$name} = $code; }
# }
# -------------------------------------------------------------------------

sub read_max_bytes {
   my ($self, $bytes) = @_; 
   my $class = ref($self);
   $self->{read_max_bytes} = $class->_bytes_calculator($bytes);
   return 1;
}

sub send_max_bytes {
   my ($self, $bytes) = @_; 
   my $class = ref($self);
   $self->{send_max_bytes} = $class->_bytes_calculator($bytes);
   return 1;
}

sub connect {
   my $self = shift;
   my $favorite = $self->{favorite};
   $self->{sock} = $favorite->new(@_)
      or return $self->_raise_error("unable to create socket");
   $self->{sock}->timeout($self->{timeout}) if $self->{timeout};
   return 1;
}

sub accept {
   my ($self, $timeout) = @_;
   my $class = ref($self);
   croak "$class: invalid value for param timeout" if $timeout && $timeout !~ /^\d+\z/;
   my $sock = $self->{sock} or return undef;
   my %options = %{$self};
   $sock->timeout($timeout) if defined $timeout;
   my $new = $class->_new(%{$self});
   $new->{sock} = $sock->accept or return $self->_raise_error("accept fails");
   return $new;
}

sub disconnect {
   my $self = shift;
   close($self->{sock}) or return $self->_raise_error("unable to close socket");
   undef $self->{sock};
   return 1;
}

sub send_raw { return $_[0]->send($_[1], 1) }

sub read_raw { return $_[0]->read(1) }

sub send {
   my ($self, $data, $no_deflate) = (shift, shift, shift);
   my $maxbyt = $self->{send_max_bytes};
   my $sock   = $self->{sock};

   # --------------------------------------------------------
   # at first we serializing data and reuse $data all time
   # because we don't like to blow away memory
   # --------------------------------------------------------

   unless ($no_deflate) {
      $data = $self->_deflate($data)
         or return undef;
   }

   # -------------------------------------------------------
   # the length is first use to check if the serialized data
   # exceeds send_max_bytes, because read_max_bytes checks
   # the serialized length as well
   # -------------------------------------------------------

   my $length = length($data);

   return $self->_raise_error("the data length ($length bytes) exceeds send_max_bytes")
      if $maxbyt && $length > $maxbyt;

   # ------------------------------------------------------------
   # send a checksum of data to the peer if use_check_sum is true
   # ------------------------------------------------------------

   if ($self->{use_check_sum}) {
      my $checksum = $self->_gen_check_sum($data) or return undef;
      $checksum    = pack("n/a*", $checksum); # 2 bytes
      $self->_send(\$checksum) or return undef;
   }

   # ----------------------------------------------------------
   # pack the data. 4 bytes should be really enough to identify
   # the data length. if not, then we got a problem here ;-)
   # ----------------------------------------------------------

   $data = pack("N/a*", $data);
   $self->_send(\$data) or return undef;

   return 1;
}

sub read {
   my ($self, $no_inflate) = @_;
   my $sock    = $self->{sock};
   my $maxbyt  = $self->{read_max_bytes};
   my $recvsum = ();

   # -------------------------------------------------------------
   # At first we read the checksum if option use_check_sum is true
   # -------------------------------------------------------------

   if ($self->{use_check_sum}) {
      my $packet = $self->_read(2) or return undef;
      my $sumlen = unpack("n", $packet);
      $recvsum   = $self->_read($sumlen) or return undef;
   }

   # -----------------------------------------------------------
   # then we read 4 bytes from the buffer. This 4 bytes contains
   # the length of the rest of the data in the buffer
   # -----------------------------------------------------------

   my $buffer = $self->_read(4) or return undef;
   my $length = unpack("N", $buffer)
      or return $self->_raise_error("no data in buffer");

   # ----------------------------------------------
   # $maxbyt is the absolute allowed maximum length
   # ----------------------------------------------

   return $self->_raise_error("the buffer length ($length bytes) exceeds read_max_bytes")
      if $maxbyt && $length > $maxbyt;

   # ---------------------------------
   # now read the rest from the socket
   # ---------------------------------

   my $rdsz  = $length < $IO::Socket::SIPC::MAXBUF ? $length : $IO::Socket::SIPC::MAXBUF;
   my $rest  = $length; # to calculate the rest
   my $bytes = 0;       # total bytes
   $buffer   = '';      # reuse $buffer

   # ----------------------------------
   # we need to read the data in a loop
   # to avoid an buffer overflow
   # ----------------------------------

   while (my $byt = CORE::read($sock, my $buf, $rdsz)) {
      return $self->_raise_error("read only $byt/$rdsz bytes from buffer") unless $byt == $rdsz;
      $bytes  += $byt;     # to compare later how much we read and what we expect to read
      $buffer .= $buf;     # concat the data pieces
      $rest   -= $byt;     # this is the rest we have to read
      $rdsz    = $rest     # otherwise CORE::read() hangs if we wants to read to much
         if $rest < $IO::Socket::SIPC::MAXBUF;
      last unless $rest;   # jump out if we read all data
   }

   return $self->_raise_error("read only $bytes/$length bytes from socket")
      unless $bytes == $length;

   # ---------------------------------------------
   # checking the md5sum if option use_check_sum is true
   # ----------------------------------------------

   if ($self->{use_check_sum}) {
      my $gensum = $self->_gen_check_sum($buffer) or return undef;
      return $self->_raise_error("the checksums are not identical")
         unless $recvsum eq $gensum; # careful... $recvsum is a scalar reference
   }

   # ------------------------------------------
   # deserializing data if $no_inflate is false
   # ------------------------------------------

   return $no_inflate ? $buffer : $self->_inflate($buffer);
}

sub sock {
   # return object || class
   return $_[0]->{sock} || $_[0]->{favorite}
}

sub errstr {
   my ($self, $msg) = @_;
   my $class = ref($self);
   return "$class: " . $IO::Socket::SIPC::ERRSTR . " " . $msg if $msg;
   return "$class: " . $IO::Socket::SIPC::ERRSTR;
}

# -------------
# private stuff
# -------------

sub _new {
   my $class = shift;
   my $args  = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
   return bless $args, $class;
}

sub _send {
   my ($self, $packet) = @_;
   my $sock = $self->{sock};
   my $length = length($$packet);
   my $written = syswrite($sock, $$packet, $length);
   return $self->_raise_error("send only $written/$length bytes over socket")
       unless $written == $length;
   return 1;
}

sub _read {
   my ($self, $length) = @_;
   my $sock = $self->{sock};
   my $read = CORE::read($sock, my $packet, $length);
   return $self->_raise_error("read only $read/$length bytes from socket")
      unless $read == $length;
   return $packet;
}

sub _deflate {
   my ($self, $data) = @_;
   my $deflated = ();
   eval { $deflated = $self->{deflate}($data) };
   return $@ ? $self->_raise_error("an deflate error occurs: ".$@) : $deflated;
}

sub _inflate {
   my ($self, $data) = @_;
   my $inflated = ();
   eval { $inflated = $self->{inflate}($data) };
   return $@ ? $self->_raise_error("an inflate error occurs: ".$@) : $inflated;
}

sub _gen_check_sum {
   my ($self, $data) = @_;
   my $checksum = ();
   eval { $checksum = $self->{gen_check_sum}($data) };
   return $@ ? $self->_raise_error("an gen_check_sum error occurs: ".$@) : $checksum;
}

sub _load_serializer {
   my $self = shift;

   'Storable'->require;
   'Safe'->require;

   my $safe = Safe->new;
   $safe->permit(qw/:default require/);

   {  # no warnings 'once' block
       no warnings 'once';
       $Storable::Deparse = 1;
       $Storable::Eval = sub { $safe->reval($_[0]) };
   }

   $self->{deflate} = sub { Storable::nfreeze($_[0]) };
   $self->{inflate} = sub { Storable::thaw($_[0]) };
}

sub _load_favorite {
   my $self = shift;
   $self->{favorite} ||= DEFAULT_IO_SOCKET;
   my $class = ref($self);
   $self->{favorite}->require
      or croak "$class: unable to require $self->{favorite}";
   UNIVERSAL::can($self->{favorite}, "accept")
      or croak "$class: your favorite $self->{favorite} don't provide an accept() method";
}

sub _bytes_calculator {
   my ($class, $bytes) = @_;

   return
      !$bytes || $bytes =~ /^unlimited\z/i
         ? DEFAULT_MAX_BYTES
         : $bytes =~ /^\d+\z/
            ? $bytes
            : $bytes =~ /^(\d+)\s*kb{0,1}\z/i
               ? $1 * 1024
               : $bytes =~ /^(\d+)\s*mb{0,1}\z/i
                  ? $1 * 1048576
                  : $bytes =~ /^(\d+)\s*gb{0,1}\z/i
                     ? $1 * 1073741824
                     : croak "$class: invalid bytes specification for " . (caller(0))[3];
}

sub _load_digest {
   my ($self, $check_sum) = @_;
   my $class = ref($self);
   $check_sum = USE_CHECK_SUM unless defined $check_sum;
   croak "$class: invalid value for param use_check_sum"
      unless $check_sum =~ /^[10]\z/;
   if ($check_sum) {
      'Digest::MD5'->require;
      $self->{gen_check_sum} = \&Digest::MD5::md5;
   }
   $self->{use_check_sum} = 1;
}

sub _raise_error {
   $IO::Socket::SIPC::ERRSTR = $_[1];
   return undef;
}

1;
