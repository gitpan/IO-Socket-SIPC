use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'IO::Socket::SIPC',
    dist_author        => 'Jonny Schulz',
    dist_abstract      => undef,
    requires => {
        'UNIVERSAL'          => 0,
        'UNIVERSAL::require' => 0,
        'IO::Socket'         => 0,
        'IO::Socket::SSL'    => 0,
        'Storable'           => 0,
        'Safe'               => 0,
        'Test::More'         => 0,
        'Carp'               => 0,
    },
    recommends         => {},
    sign               => 0,
);
$build->create_build_script;
