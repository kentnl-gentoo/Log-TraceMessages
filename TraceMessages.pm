package Log::TraceMessages;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
@EXPORT_OK = qw(t trace d dmp);
use vars '$VERSION';
$VERSION = '1.0';

=pod

=head1 NAME

Log::TraceMessages - Perl extension for trace messages used in debugging

=head1 SYNOPSIS

  use Log::TraceMessages qw(t d);
  $Log::TraceMessages::On = 1;
  t 'got to here';
  t 'value of $a is ' . d($a);
  {
      local $Log::TraceMessages::On = 0;
      t 'this message will not be printed';
  }

  # For a CGI program producing HTML
  $Log::TraceMessages::CGI = 1;

  # Or to turn on trace if there's a command-line argument '--trace'
  Log::TraceMessages::check_argv();

=head1 DESCRIPTION

This module is a slightly better way to put trace statements into your
code than just calling print().  It provides an easy way to turn trace
on and off for particular sections of code without having to comment
out bits of source.

=head1 USAGE

=over

=item $Log::TraceMessages::On

Flag controlling whether tracing is on or off.  You can set it as you
wish, and of course it can be C<local>-ized.  The default is off.

=cut
use vars '$On';
$On = 0;

=pod


=item $Log::TraceMessages::CGI

Flag controlling whether the program printing trace messages is a CGI
program (default is no).  This means that trace messages will be
printed as HTML to stdout, so they appear in the output page.

=cut
use vars '$CGI';
$CGI = 0;

=pod


=item t(messages)

Print the given strings, if tracing is enabled.  Unless
$Log::TraceMessages::CGI is true (see below), each message will be
printed to standard error with a newline appended.

=cut
sub t(@) {
    return unless $On;
    my $s;
    foreach $s (@_) {
	if ($CGI) {
	    require HTML::FromText;
	    print "\n<pre>", HTML::FromText::text2html($s), "</pre>\n";
	}
	else {
	    print STDERR "$s\n";
	}
    }
}

=pod


=item trace(messages)

Synonym for C<t(messages)>.

=cut
sub trace(@) { &t }

=pod


=item d(scalar)

Return a string representation of a scalar's value suitable for use in
a trace statement.  This is just a wrapper for Data::Dumper.

C<d()> will exit with '' if trace is not turned on.  This is to
stop your program being slowed down by generating lots of strings for
trace statements that are never printed.

=cut
sub d($) {
    return '' if not $On;
    require Data::Dumper;
    my $s = $_[0];
    my $d = Data::Dumper::Dumper($s);
    $d =~ s/^\$VAR1 =\s*//;
    $d =~ s/;$//;
    chomp $d;
    return $d;
}

=pod


=item dmp(scalar)

Synonym for C<d(scalar)>.

=cut
sub dmp(@) { &d }

=pod


=item check_argv()

Looks at the global C<@ARGV> of command-line parameters to find one
called '--trace'.  If this is found, it will be removed from C<@ARGV>
and tracing will be turned on.  Since tracing is off by default,
calling C<check_argv()> is a way to make your program print trace only
when you ask for it from the command line.

=cut
sub check_argv() {
    my @new_argv = ();
    foreach (@ARGV) {
        if ($_ eq '--trace') {
	    $On = 1;
        } else {
	    push @new_argv, $_;
        }
    }
    @ARGV = @new_argv;
}

=pod

=head1 AUTHOR

Ed Avis, epa98@doc.ic.ac.uk

=head1 SEE ALSO

perl(1), Data::Dumper(3).

=cut

1;
__END__
