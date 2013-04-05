use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Yancha::Twitter::Bot',
    PREREQ_PM => {
        'AnyEvent::Lingr'           => '0.04',
        'AnyEvent::HTTP::Request'   => '0.301',
        'FindBin'                   => 0,
    },
    MIN_PERL_VERSION => '5.010001',
);
