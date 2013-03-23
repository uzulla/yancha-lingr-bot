use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Yancha::Twitter::Bot',
    PREREQ_PM => {
        'HTTP::Request'             => '6.00',
        'AnyEvent::Lingr' => '0.04',
        'AnyEvent::HTTP::Request'   => '0.301',
        'URI::Escape'               => '3.31',
        'Encode'                    => '2.49',
        'FindBin'                   => 0,
        'Data::Dumper'              => 0,
    },
    MIN_PERL_VERSION => '5.010001',
);
