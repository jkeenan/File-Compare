package File::Compare;

use 5.006;
use strict;
use warnings;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK, $Too_Big);

require Exporter;

$VERSION = '1.1006';
@ISA = qw(Exporter);
@EXPORT = qw(compare);
@EXPORT_OK = qw(cmp compare_text);

$Too_Big = 1024 * 1024 * 2;

sub croak {
print STDERR "AAA:", "\n";
    require Carp;
    goto &Carp::croak;
}

sub compare {
#    croak("Usage: compare( file1, file2 [, buffersize]) ")
#      unless(@_ == 2 || @_ == 3);
    unless(@_ == 2 || @_ == 3) {
print STDERR "BBB:", "\n";
        croak("Usage: compare( file1, file2 [, buffersize]) ");
    }

    my ($from,$to,$size) = @_;
    my $text_mode = defined($size) && (ref($size) eq 'CODE' || $size < 0);
print STDERR "CCC: $text_mode", "\n";

    my ($fromsize,$closefrom,$closeto);
    local (*FROM, *TO);

#    croak("from undefined") unless (defined $from);
#    croak("to undefined") unless (defined $to);
    unless (defined $from) {
print STDERR "DDD:", "\n";
       croak("from undefined") ;
    }
    unless (defined $to) {
print STDERR "EEE:", "\n";
       croak("to undefined") ;
    }

    if (ref($from) &&
        (UNIVERSAL::isa($from,'GLOB') || UNIVERSAL::isa($from,'IO::Handle'))) {
print STDERR "FFF:", "\n";
        *FROM = *$from;
    }
    elsif (ref(\$from) eq 'GLOB') {
print STDERR "GGG:", "\n";
        *FROM = $from;
    }
    else {
print STDERR "HHH:", "\n";
        open(FROM,"<",$from) or goto fail_open1;
        unless ($text_mode) {
print STDERR "III:", "\n";
            binmode FROM;
            $fromsize = -s FROM;
        }
        $closefrom = 1;
    }

    if (ref($to) &&
        (UNIVERSAL::isa($to,'GLOB') || UNIVERSAL::isa($to,'IO::Handle'))) {
print STDERR "JJJ:", "\n";
        *TO = *$to;
    }
    elsif (ref(\$to) eq 'GLOB') {
print STDERR "KKK:", "\n";
        *TO = $to;
    }
    else {
print STDERR "LLL:", "\n";
        open(TO,"<",$to) or goto fail_open2;
#        binmode TO unless $text_mode;
        unless ($text_mode) {
print STDERR "LLL:", "\n";
           binmode TO ;
       }
        $closeto = 1;
    }

    if (!$text_mode && $closefrom && $closeto) {
print STDERR "MMM:", "\n";
    # If both are opened files we know they differ if their size differ
        goto fail_inner if $fromsize != -s TO;
    }

    if ($text_mode) {
print STDERR "NNN:", "\n";
        local $/ = "\n";
        my ($fline,$tline);
        while (defined($fline = <FROM>)) {
            # goto fail_inner unless defined($tline = <TO>);
            unless (defined($tline = <TO>)) {
print STDERR "OOO:", "\n";
               goto fail_inner ;
            }
            if (ref $size) {
print STDERR "PPP:", "\n";
            # $size contains ref to comparison function
                # goto fail_inner if &$size($fline, $tline);
                if (&$size($fline, $tline)) {
print STDERR "QQQ:", "\n";
                   goto fail_inner ;
                }
            }
            else {
print STDERR "RRR:", "\n";
                # goto fail_inner if $fline ne $tline;
                if ($fline ne $tline) {
print STDERR "SSS:", "\n";
                   goto fail_inner ;
                }
            }
        }
        # goto fail_inner if defined($tline = <TO>);
        if (defined($tline = <TO>)) {
print STDERR "TTT:", "\n";
           goto fail_inner ;
        }
    }
    else {
print STDERR "UUU:", "\n";
        unless (defined($size) && $size > 0) {
print STDERR "VVV:", "\n";
            $size = $fromsize || -s TO || 0;
            $size = 1024 if $size < 512;
    #        $size = $Too_Big if $size > $Too_Big;
            if ($size > $Too_Big) {
print STDERR "WWW:", "\n";
               $size = $Too_Big ;
           }
        }

        my ($fr,$tr,$fbuf,$tbuf);
        $fbuf = $tbuf = '';
        while(defined($fr = read(FROM,$fbuf,$size)) && $fr > 0) {
            unless (defined($tr = read(TO,$tbuf,$fr)) && $tbuf eq $fbuf) {
print STDERR "XXX:", "\n";
                goto fail_inner;
            }
        }
#    goto fail_inner if defined($tr = read(TO,$tbuf,$size)) && $tr > 0;
        if (defined($tr = read(TO,$tbuf,$size)) && $tr > 0) {
print STDERR "YYY:", "\n";
           goto fail_inner ;
        }
    }

    close(TO) || goto fail_open2 if $closeto;
    close(FROM) || goto fail_open1 if $closefrom;

    return 0;

  # All of these contortions try to preserve error messages...
  fail_inner:
    close(TO) || goto fail_open2 if $closeto;
    close(FROM) || goto fail_open1 if $closefrom;

    return 1;

  fail_open2:
    if ($closefrom) {
    my $status = $!;
    $! = 0;
    close FROM;
    $! = $status unless $!;
    }
  fail_open1:
    return -1;
}

sub cmp;
*cmp = \&compare;

sub compare_text {
    my ($from,$to,$cmp) = @_;
    croak("Usage: compare_text( file1, file2 [, cmp-function])")
    unless @_ == 2 || @_ == 3;
    croak("Third arg to compare_text() function must be a code reference")
    if @_ == 3 && ref($cmp) ne 'CODE';

    # Using a negative buffer size puts compare into text_mode too
    $cmp = -1 unless defined $cmp;
    compare($from, $to, $cmp);
}

1;

__END__

=head1 NAME

File::Compare - Compare files or filehandles

=head1 SYNOPSIS

      use File::Compare;

    if (compare("file1","file2") == 0) {
        print "They're equal\n";
    }

=head1 DESCRIPTION

The File::Compare::compare function compares the contents of two
sources, each of which can be a file or a file handle.  It is exported
from File::Compare by default.

File::Compare::cmp is a synonym for File::Compare::compare.  It is
exported from File::Compare only by request.

File::Compare::compare_text does a line by line comparison of the two
files. It stops as soon as a difference is detected. compare_text()
accepts an optional third argument: This must be a CODE reference to
a line comparison function, which returns 0 when both lines are considered
equal. For example:

    compare_text($file1, $file2)

is basically equivalent to

    compare_text($file1, $file2, sub {$_[0] ne $_[1]} )

=head1 RETURN

File::Compare::compare and its sibling functions return 0 if the files
are equal, 1 if the files are unequal, or -1 if an error was encountered.

=head1 AUTHOR

File::Compare was written by Nick Ing-Simmons.
Its original documentation was written by Chip Salzenberg.

=cut

