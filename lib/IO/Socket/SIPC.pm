=head1 NAME

IO::Socket::SIPC - Serialize perl structures for inter process communication.

=head1 SYNOPSIS

    use IO::Socket::SIPC;

=head1 DESCRIPTION

This module makes it possible to transport perl structures between processes over sockets.
It wrappes your favorite IO::Socket module and controls the amount of data over the socket.
The default serializer is Storable with C<nfreeze()> and C<thaw()> but you can choose each
other serializer you wish to use. You have just follow some restrictions and need only some
lines of code to adjust it for yourself. In addition it's possible to use a checksum to check
the integrity of the transported data. Take a look to the method section.

=head1 METHODS

=head2 new()

Call C<new()> to create a new IO::Socket::SIPC object.

    favorite        Set your favorite module - IO::Socket::(INET|UNIX|SSL).
    deflate         Pass your own sub reference for serializion.
    inflate         Pass your own sub reference for deserializion.
    read_max_bytes  Set the maximum allowed bytes to read from the socket.
    send_max_bytes  Set the maximum allowed bytes to send over the socket.
    use_check_sum   Check each transport with a MD5 sum.
    gen_check_sum   Set up your own checksum generator.

Defaults

    favorite        IO::Socket::INET
    deflate         nfreeze() of Storable
    inflate         thaw() of Storable (in a Safe compartment)
    read_max_bytes  unlimited
    send_max_bytes  unlimited
    gen_check_sum   md5() of Digest::MD5
    use_check_sum   enabled (disable it with 0)

Set your favorite socket handler:

    use IO::Socket::SIPC;

    my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::SSL' );

Set your own serializer:

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

Use your own checksum generator (dummy example):

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
and handoff all params to it. Example:

    my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::INET' );

    $sipc->connect(
       PeerAddr => 'localhost',
       PeerPort => '50010',
       Proto    => 'tcp',
    );

    # would call intern

    IO::Socket::INET->new(@_);

=head2 accept()

If a Listen socket is defined then you can wait for connections with C<accept()>. C<accept()> is
just a wrapper to the original C<accept()> method of your favorite. If a connection is accepted
then a new object is created related to the peer. The new object will be returned on success,
undef on error and 0 on a timeout.

You can set a timeout value in seconds.

    my $c = $sipc->accept(10)
    warn "accept: timeout" if defined $c;

=head2 disconnect()

Call C<disconnect()> to disconnect the current connection. C<disconnect()> calls C<close()> on
the socket that is referenced by the object.

=head2 sock()

Call C<sock()> to access the raw object of your favorite module.

IO::Socket::INET examples:

    $sipc->sock->timeout(10);
    # or
    $peerhost = $sipc->sock->peerhost;
    # or
    $peerport = $sipc->sock->peerport;
    # or
    $sock = $sipc->sock;
    $peerhost = $sock->peerhost;

NOTE that if you use

    while ( my $c = $sipc->sock->accept ) { ... }

that $c is the unwrapped IO::Socket::* object and not a IO::Socket::SIPC object.

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
useable with C<new()> because C<new()> croaks by wrong settings.

NOTE that C<errstr()> returns the current error message that contain C<$!> if necessary. If you use
IO::Socket::SSL then the message from IO::Socket::SSL->errstr is appended as well.

=head2 debug()

You can turn on a little debugger if you like

    $sipc->debug(1);

The debugger will set IO::Socket::SSL::DEBUG as well if you use it.

=head1 EXAMPLES

Take a look to the examples directory.

=head2 Server example


=head2 Client example


=head1 PREREQUISITES

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
    * do you like to have another wrapper as accept()? Tell me!
    * auto authentification

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package IO::Socket::SIPC;
our $VERSION = '0.04';

use strict;
use warnings;
use UNIVERSAL::require;
use Carp qw/croak/;

# the default send + read bytes is unlimited
use constant DEFAULT_IO_SOCKET => 'IO::Socket::INET';
use constant DEFAULT_MAX_BYTES => 0;
use constant USE_CHECK_SUM     => 1;

# globals
use vars qw/$ERRSTR $MAXBUF $DEBUG/;
$ERRSTR = defined;
$MAXBUF = 16384;

sub new {
   my $class = shift;
   my $self  = $class->_new(@_);

   $self->read_max_bytes($self->{read_max_bytes});
   $self->send_max_bytes($self->{send_max_bytes});
   $self->_load_favorite;

   if (!$self->{deflate} && !$self->{inflate}) {
      $self->_load_serializer;
   } elsif (ref($self->{deflate}) ne 'CODE' || ref($self->{inflate}) ne 'CODE') {
      croak "$class: options deflate and inflate expects a code ref";
   }

   if (defined $self->{use_check_sum}) {
      croak "$class: invalid value for option use_check_sum" unless $self->{use_check_sum} =~ /^[10]\z/;
      if ($self->{gen_check_sum} && ref($self->{gen_check_sum}) ne 'CODE') {
         croak "$class: option gen_check_sum expect a code ref";
      } else {
         $self->_load_digest;
      }
   }

   return $self;
}

sub read_max_bytes {
   my ($self, $bytes) = @_; 
   my $class = ref($self);
   warn "set read_max_bytes to $bytes" if defined $bytes && $DEBUG;
   $self->{read_max_bytes} = $class->_bytes_calculator($bytes);
   return 1;
}

sub send_max_bytes {
   my ($self, $bytes) = @_; 
   my $class = ref($self);
   warn "set send_max_bytes to $bytes" if defined $bytes && $DEBUG;
   $self->{send_max_bytes} = $class->_bytes_calculator($bytes);
   return 1;
}

sub connect {
   my $self = shift;
   my $favorite = $self->{favorite};
   warn "create a new $self->{favorite} object" if $DEBUG;
   $self->{sock} = $favorite->new(@_)
      or return $self->_raise_sock_error("unable to create socket");
   return 1;
}

sub accept {
   my ($self, $timeout) = @_;
   my $class = ref($self);
   my $sock = $self->{sock} or return $self->_raise_error("there is no socket defined");
   my %options = %{$self};

   if (defined $timeout) {
      croak "$class: timeout isn't numeric" unless $timeout =~ /^\d+\z/;
      warn "set timeout to '$timeout'" if $DEBUG;
      $sock->timeout($timeout);
   }

   warn "waiting for connection" if $DEBUG;

   my $new_sock = $sock->accept or do {
      if ($@ =~ /timeout/i) {
         warn $@ if $DEBUG;
         $ERRSTR = $@; $@ = ''; return 0;
      } else {
         return $self->_raise_sock_error("error on accept()");
      }
   };

   warn "incoming request" if $DEBUG;

   # create and return a new object
   my $new = $class->_new(%{$self});
   $new->{sock} = $new_sock;
   return $new;
}

sub disconnect {
   my $self = shift;
   my $sock = $self->{sock} || return 1;
   warn "disconnecting" if $DEBUG;
   close($sock) or return $self->_raise_error("unable to close socket: $!");
   undef $self->{sock};
   return 1;
}

sub send_raw {
   warn "send raw data" if $DEBUG;
   return $_[0]->send($_[1], 1)
}

sub read_raw {
   warn "read raw data" if $DEBUG;
   return $_[0]->read(1)
}

sub send {
   my ($self, $data, $no_deflate) = @_;
   my $maxbyt = $self->{send_max_bytes};
   my $sock   = $self->{sock};

   warn "send data" if !$no_deflate && $DEBUG;

   # --------------------------------------------------------
   # at first we serializing data and reuse $data all time
   # because we don't like to blow away memory
   # --------------------------------------------------------

   unless ($no_deflate) {
      $data = $self->_deflate($data)
         or return undef;
   }

   # -------------------------------------------------------
   # the length is used to check if the serialized data
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
   return $self->_send(\$data);
}

sub read {
   my ($self, $no_inflate) = @_;
   my $maxbyt  = $self->{read_max_bytes};
   my $sock    = $self->{sock};
   my $recvsum = ();

   warn "read data" if !$no_inflate && $DEBUG;

   # -------------------------------------------------------------
   # At first we read the checksum if option use_check_sum is true
   # -------------------------------------------------------------

   if ($self->{use_check_sum}) {
      warn "read checksum" if $DEBUG;
      my $packet = $self->_read(2) or return undef;
      my $sumlen = unpack("n", $$packet);
      $recvsum   = $self->_read($sumlen) or return undef;
   }

   # -----------------------------------------------------------
   # then we read 4 bytes from the buffer. This 4 bytes contains
   # the length of the rest of the data in the buffer
   # -----------------------------------------------------------

   my $buffer = $self->_read(4) or return undef;
   my $length = unpack("N", $$buffer)
      or return $self->_raise_error("no data in buffer");

   # ----------------------------------------------
   # $maxbyt is the absolute allowed maximum length
   # ----------------------------------------------

   return $self->_raise_error("the buffer length ($length bytes) exceeds read_max_bytes")
      if $maxbyt && $length > $maxbyt;

   # ---------------------------------
   # now read the rest from the socket
   # ---------------------------------

   my $packet = $self->_read($length);

   # ---------------------------------------------
   # checking the md5sum if option use_check_sum is true
   # ----------------------------------------------

   if ($self->{use_check_sum}) {
      my $checksum = $self->_gen_check_sum($$packet) or return undef;
      warn "compare checksums" if $DEBUG;
      return $self->_raise_error("the checksums are not identical")
         unless $$recvsum eq $checksum;
   }

   # ------------------------------------------
   # deserializing data if $no_inflate is false
   # ------------------------------------------

   return $no_inflate ? $$packet : $self->_inflate($$packet);
}

sub sock {
   # return object || class
   warn "access sock object" if $DEBUG;
   return $_[0]->{sock} || $_[0]->{favorite};
}

sub errstr { return $ERRSTR }

sub debug {
   my $self;
   ($self, $DEBUG) = @_;
   if ($self->{favorite} eq 'IO::Socket::SSL') {
      $IO::Socket::SSL::DEBUG = $DEBUG;
   }
}

# -------------
# private stuff
# -------------

sub _new {
   my $class = shift;
   my $args  = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
   warn "creating new IO::Socket::SIPC object" if $DEBUG;
   return bless $args, $class;
}

sub _send {
   my ($self, $packet) = @_;
   my $sock = $self->{sock};
   my $length = length($$packet);
   my $rest   = $length;
   my ($offset, $written) = (0, undef);

   while ( $rest ) {
      $written = syswrite $sock, $$packet, $rest, $offset;
      return $self->_raise_error("system write error: $!")
         unless defined $written;
      $rest   -= $written;
      $offset += $written;
      warn "send $offset/$length bytes" if $DEBUG;
   }

   return 1;
}

sub _read {
   my ($self, $length) = @_;
   my $sock = $self->{sock};
   my $rest = $length;
   my $rdsz = $length < $MAXBUF ? $length : $MAXBUF;
   my ($packet, $rlen);

   while ( my $len = sysread $sock, my $buf, $rdsz ) {
      if (!defined $len) {
         next if $! =~ /^Interrupted/;
         return $self->_raise_error("system read error: $!");
      }
      $packet .= $buf;  # concat the data pieces
      $rest   -= $len;  # this is the rest we have to read
      $rlen   += $len;  # to compare later how much we read and what we expected to read
      warn "read $rlen/$length bytes" if $DEBUG;
      $rest   || last;  # jump out if we read all data
      $rdsz    = $rest  # otherwise sysread() hangs if we wants to read to much
         if $rest < $MAXBUF;
   }

   return $self->_raise_error("read only $rlen/$length bytes from socket")
      if $rest;

   return \$packet;
}

sub _deflate {
   my ($self, $data) = @_;
   warn "deflate data" if $DEBUG;
   eval { $data = $self->{deflate}($data) };
   return $@ ? $self->_raise_error("unable to deflate data: ".$@) : $data;
}

sub _inflate {
   my ($self, $data) = @_;
   warn "inflate data" if $DEBUG;
   eval { $data = $self->{inflate}($data) };
   return $@ ? $self->_raise_error("unable to inflate data: ".$@) : $data;
}

sub _gen_check_sum {
   my ($self, $data) = @_;
   warn "generate checksum" if $DEBUG;
   eval { $data = $self->{gen_check_sum}($data) };
   return $@ ? $self->_raise_error("unable to generate checksum: ".$@) : $data;
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
   $self->{favorite} =~ /^IO::Socket::(?:INET|UNIX|SSL)\z/
      or croak "$class: invalid favorite '$self->{favorite}'";
   $self->{favorite}->require
      or croak "$class: unable to require $self->{favorite}";
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
   my $self = shift;
   'Digest::MD5'->require;
   $self->{gen_check_sum} = \&Digest::MD5::md5;
   $self->{use_check_sum} = 1;
}

sub _raise_error {
   $ERRSTR = $_[1];
   warn $ERRSTR if $DEBUG;
   return undef;
}

sub _raise_sock_error {
   my $self = $_[0];
   $ERRSTR = $_[1];

   $ERRSTR .= " - $!" if $!;

   if ($self->{favorite} eq 'IO::Socket::SSL') {
      my $sslerr = $self->{sock} ? $self->{sock}->errstr : IO::Socket::SSL->errstr;
      $ERRSTR .= " - $sslerr" if $sslerr;
   }

   warn $ERRSTR if $DEBUG;
   return undef;
}

1;
