#!./perl

#BEGIN {
#  chdir 't' if -d 't';
#  @INC = '../lib';
#}

our $TEST = "t/TEST";
our $README = "t/README";

BEGIN {
  our @TEST = stat "t/TEST";
  our @README = stat "t/README";
  unless (@TEST && @README) {
    print "1..0 # Skip: no file TEST or README\n";
    exit 0;
  }
}
use Test::More ( tests => 16 );

use File::Compare qw(compare compare_text);

# Upon success, compare() and compare_text() return a Unix-ish 0
# rather than a Perl-ish 1.  So tests for truth must be inverted.

ok(! compare($README,$README), "compare file to itself");
ok(  compare($TEST,$README), "compare file to different file");
is(  compare($README,"HLAGHLAG"), -1,
    "compare file to nonexistent file returns error value"); 

ok(! compare_text($README,$README), "compare_text file to itself");
ok(  compare_text($TEST,$README), "compare_text file to different file");
is(  compare_text($TEST,"HLAGHLAG"), -1,
    "compare_text file to nonexistent file returns error value");
ok(! compare_text($README,$README,sub {$_[0] ne $_[1]}),
    "compare_text with code ref as third argument, file to itself");

ok(  compare_text($TEST,$README,sub {$_[0] ne $_[1]}),
    "compare_text with code ref as third argument, file to different file");

{
    open my $fh, '<', $README
        or die "Unable to open $README for reading: $!";
    binmode($fh);
    ok(! compare($fh,$README),
        "compare file with filehandle open to same file");
    close $fh;
}

{
    open my $fh, '<', $README
        or die "Unable to open $README for reading: $!";
    binmode($fh);
    ok(compare($fh,$TEST),
        "compare file with filehandle open to different file");
    close $fh;
}

# Different file with contents of known file,
# will use File::Temp to do this, skip rest of
# tests if this does not seem to work

my @donetests;
eval {
  require File::Temp; import File::Temp qw/ tempfile unlink0 /;

  my($tfh,$filename) = tempfile('fcmpXXXX', TMPDIR => 1);
  # NB. The trailing space is intentional (see [perl #37716])
  my $whsp = get_valid_whitespace();
  open my $tfhSP, ">", "$filename$whsp"
      or die "Could not open '$filename$whsp' for writing: $!";
  binmode($tfhSP);
  {
    local $/; #slurp
    my $fh;
    open($fh,$README);
    binmode($fh);
    my $data = <$fh>;
    print $tfh $data;
    close($fh);
    print $tfhSP $data;
    close($tfhSP);
  }
  seek($tfh,0,0);
  $donetests[0] = compare($tfh, $README);
  if ($^O eq 'VMS') {
      unlink0($tfh,$filename);  # queue for later removal
      close $tfh;               # may not be opened shared
  }
  $donetests[1] = compare($filename, $README);
  unlink0($tfh,$filename);
  $donetests[2] = compare($README, "$filename$whsp");
  unlink "$filename$whsp";
};
print "# problem '$@' when testing with a temporary file\n" if $@;

SKIP: {
    my $why = "Likely due to File::Temp";
    my $how_many = 3;
    my $have_some_feature = (@donetests == 3);
    skip $why, $how_many unless $have_some_feature;

    ok(! $donetests[0], "fh/file [$donetests[0]]");
    ok(! $donetests[1], "file/file [$donetests[1]]");
    TODO: {
        my $why = "spaces after filename silently truncated";
        my $how_many = 1;
        my $condition = ($^O eq "cygwin") or ($^O eq "vos");
        todo_skip $why, $how_many if $condition;
        ok(! $donetests[2], "file/fileCR [$donetests[2]]");
    }
}

{
    local $@;
    eval { compare(); 1 };
    like($@, qr/Usage:\s+compare/,
        "detect insufficient arguments to compare()");
}

{
    local $@;
    eval { compare(undef, $README); 1 };
    like($@, qr/from\s+undefined/,
        "compare() fails: first argument undefined");
}

{
    local $@;
    eval { compare($README, undef ); 1 };
    like($@, qr/to\s+undefined/,
        "compare() fails: second argument undefined");
}

sub get_valid_whitespace {
    return ' ' unless $^O eq 'VMS';
    return (exists $ENV{'DECC$EFS_CHARSET'} && $ENV{'DECC$EFS_CHARSET'} =~ /^[ET1]/i) 
           ? ' '
           : '_';  # traditional mode eats spaces in filenames
}
