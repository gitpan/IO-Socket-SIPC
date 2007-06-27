=head1 NAME

IO::Socket::SIPC - Serialized perl structures for inter process communication.

=head1 SYNOPSIS

    use IO::Socket::SIPC;

=head1 DESCRIPTION

This module makes it possible to transport perl structures between processes over sockets.
It wrappes your favorite IO::Socket module and controls the amount of data over the socket.
The default serializer is Storable and the functions nfreeze() and thaw() but you can
choose each serialize you want. You need only some lines of code to adjust it for yourself.
Take a look to the method documentation and it's options.

=head1 METHODS

=head2 new()

Call C<new()> to create a new IO::Socket::SIPC object.

    read_max_bytes  Set the maximum allowed bytes to read from the socket.
    send_max_bytes  Set the maximum allowed bytes to send over the socket.
    favorite        Set your favorite module, IO::Socket::INET or IO::Socket::SSL.
    deflate         Pass your own sub reference for serializion.
    inflate         Pass your own sub reference for deserializion.

Defaults

    read_max_bytes  unlimited
    send_max_bytes  unlimited
    favorite        IO::Socket::SSL
    deflate         nfreeze of Storable
    inflate         thaw of Storable (in a Safe compartment)

You can set your favorite socket handler. Example:

    use IO::Socket::SIPC;

    my $sipc = IO::Socket::SIPC->new( favorite => 'IO::Socket::INET' );

The only mandatory thing is that your favorite must provide an C<accept()> method to wait
for connections because C<accept()> of IP::Socket::SIPC used it.

Also you can set your own serializer if you like. Example:

    use IO::Socket::SIPC;
    use Convert::Bencode_XS;

    my $sipc = IO::Socket::SIPC->new(
        deflate => sub { Convert::Bencode_XS::bencode($_[0]) },
        inflate => sub { Convert::Bencode_XS::bdecode($_[0]) },
    );

    # or

    use IO::Socket::SIPC;
    use JSON::PC;

    my $sipc = IO::Socket::SIPC->new(
        deflate => sub { JSON::PC::convert($_[0]) },
        inflate => sub { JSON::PC::parse($_[0])   },
    );

NOTE that the code that you handoff with deflate and inflate is embed in an eval block and if
it produce an error you can get the error string by calling C<errstr()>. If you use the default
deserializer of Storable the data is deserialized in a Safe compartment. If you use another
deserializer you have to build your own Safe compartment within your code ref!

=head2 read_max_bytes(), send_max_bytes()

Call both methods to increase or decrease the maximum bytes that the server or client
is allowed to C<read()> or C<send()>. Possible sizes are KB, MB and GB or just a number
for bytes. It's not case sensitiv and you can use C<KB> or C<kb> or just C<k>. If you want
set the readable size to unlimited then you can call both methods with 0 or C<unlimited>.
The default max send and read size is unlimited.

Here some notations examples

    $sipc->read_max_bytes(1048576);
    $sipc->read_max_bytes('1024k');
    $sipc->read_max_bytes('1MB');

    # unlimited
    $sipc->read_max_bytes('unlimited');
    $sipc->read_max_bytes(0);

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
socket handler.

If a connection is accepted a new object is created related to the peer. The new object will
be returned.

=head2 disconnect()

Call C<disconnect()> to disconnect the current connection. C<disconnect()> calls
C<close()> on the socket that is referenced by the object.

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

Note that if you use

    while (my $c = $sipc->sock->accept) { }

that $c is the unwrapped IO::Socket::INET object and not a IO::Socket::SIPC object.

=head2 send()

Call C<send()> to send data over the socket to the peer. The data will be serialized
and packed before it sends to the peer. The data that is handoff to C<send()> must be
a reference. If you handoff a string to C<send()> then it's a reference is created
on the string.

C<send()> returns the length of the serialized data or undef on errors or if send_max_bytes
is overtaken.

=head2 read()

Call C<read()> to read data from the socket. The data will be unpacked and deserialized
before it is returned. Note that if you send a string that the string is returned as a
scalar reference.

If the maximum allowed bytes is overtaken or an error occured then C<read()> returns undef and
aborts reading from the socket.

=head2 errstr()

Call C<errstr()> to get the current error message if a method returns undef. C<errstr()> is not
useable with C<new()> because new fails by wrong settings.

Note that C<errstr()> do not contain the error message of your favorite module, because it's to
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

    my $sipc = IO::Socket::SIPC->new();

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
          my $request = $client->read or die $client->errstr($client->sock->errstr);
          next unless $$request;
          chomp($$request);
          warn "client says: $$request\n";
          $client->send({ foo => 'is foo', bar => 'is bar', baz => 'is baz'}) or die $client->errstr($client->sock->errstr);
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

    my $sipc = IO::Socket::SIPC->new();

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
    ) or die $sipc->errstr($sipc->sock->errstr);

    warn "client connected to server\n";

    $sipc->send("Hello server, gimme some data :-)\n") or die $sipc->errstr($sipc->sock->errstr);
    my $answer = $sipc->read or die $sipc->errstr($sipc->sock->errstr);
    warn "server data: \n";
    warn Dumper($answer);
    $sipc->disconnect or die $sipc->errstr($!);

=head1 PREREQUISITES

    UNIVERSAL           -  to check for routines with can()
    UNIVERSAL::require  -  to post load favorite modules
    IO::Socket::SSL     -  for the test suite and examples
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

=head1 COPYRIGHT

Copyright (C) 2007 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package IO::Socket::SIPC;
our $VERSION = '0.01_01';

use strict;
use warnings;
use UNIVERSAL;
use UNIVERSAL::require;
use Carp qw/croak/;

# the default send + read bytes is unlimited
use constant DEFAULT_IO_SOCKET => 'IO::Socket::SSL';
use constant DEFAULT_MAX_BYTES => 0;

# to safe error messages
$IO::Socket::SIPC::ERRSTR = defined;

sub new {
   my $class = shift;
   my $self  = $class->_new(@_);

   $self->read_max_bytes($self->{read_max_bytes});
   $self->send_max_bytes($self->{send_max_bytes});
   $self->_load_favorite;

   if (!$self->{deflate} && !$self->{inflate}) {
      $self->_load_serializer;
   } elsif (ref($self->{deflate}) ne 'CODE' || ref($self->{inflate}) ne 'CODE') {
      croak "$class: options deflate/inflate must be a code ref";
   }

   return $self;
}

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
   my $sock = $self->{sock} or return undef;
   my $class = ref($self);
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

sub send {
   my ($self, $data) = @_;
   my $maxbyt = $self->{send_max_bytes};
   my $sock = $self->{sock};
   $data = $self->_deflate(ref($data) ? $data : \$data) or return undef;
   my $length = length($data);
   return $self->_raise_error("the data length ($length bytes) exceeds send_max_bytes")
      if $maxbyt && $length > $maxbyt;
   my $packet = pack("N/a*", $data);
   print $sock $packet or return $self->_raise_error("unable to send data");
   return $length;
}

sub read {
   my $self   = shift;
   my $sock   = $self->{sock};
   my $maxbyt = $self->{read_max_bytes};

   # ------------------------------------------------------------
   # At first read 4 bytes from the buffer. This 4 bytes contains
   # the length of the rest of the data in the buffer
   # ------------------------------------------------------------

   my $bytes = read($sock, my $buffer, 4);

   return $self->_raise_error("read only $bytes/4 bytes from buffer")
      unless 4 == $bytes;

   my $length = unpack("N", $buffer)
      or return $self->_raise_error("no data in buffer");

   # -----------------------------------------------------
   # $maxbyt is the absolute allowed maximum bytes
   # -----------------------------------------------------

   return $self->_raise_error("the buffer length ($length bytes) exceeds read_max_bytes")
      if $maxbyt && $length > $maxbyt;

   # ----------------------------------------------------------
   # now read the rest from the socket and reset some variables
   # ----------------------------------------------------------

   ($buffer, $bytes) = ('', 0);
   my $rdsz = $length < 16384 ? $length : 16384;
   my $rest = $length;

   while (my $byt = read($sock, my $buf, $rdsz)) {
      return $self->_raise_error("read only $byt/$rdsz bytes from buffer") unless $byt == $rdsz;
      $bytes  += $byt;     # to compare later how much we read and what we expect to read
      $buffer .= $buf;     # concat the data pieces
      $rest   -= $byt;     # what is the rest
      $rdsz    = $rest
         if $rest < 16384; # otherwise read() hangs if we wants to read to much
      last unless $rest;   # jump out if we read all data
   }

   return $self->_raise_error("read only $bytes/$length bytes from socket")
      unless $bytes == $length;

   # ------------------
   # deserializing data
   # ------------------

   return $self->_inflate($buffer);
}

sub sock { return $_[0]->{sock} || $_[0]->{favorite} }

sub errstr {
   my ($self, $msg) = @_;
   my $class = ref($self);
   return "$class: " . $IO::Socket::SIPC::ERRSTR . " " . $msg if $msg;
   return "$class: " . $IO::Socket::SIPC::ERRSTR;
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

# -------------
# private stuff
# -------------

sub _new {
   my $class = shift;
   my $args  = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
   return bless $args, $class;
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
   }  # end no warnings 'once' block

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
         : $bytes =~ /^\d+$/
            ? $bytes
            : $bytes =~ /^(\d+)\s*kb{0,1}\z/i
               ? $1 * 1024
               : $bytes =~ /^(\d+)\s*mb{0,1}\z/i
                  ? $1 * 1048576
                  : $bytes =~ /^(\d+)\s*gb{0,1}\z/i
                     ? $1 * 1073741824
                     : croak "$class: invalid bytes specification for " . (caller(0))[3];
}

sub _raise_error {
   $IO::Socket::SIPC::ERRSTR = $_[1];
   return undef;
}

1;
