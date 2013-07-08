

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'File-Compare',
    VERSION_FROM => 'lib/File/Compare.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
