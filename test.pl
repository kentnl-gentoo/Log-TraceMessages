# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Log::TraceMessages qw(t d trace dmp);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;
my $test_str = 'test < > &';

# Test 2 - t() with $On == 1
$Log::TraceMessages::On = 1;
$Log::TraceMessages::CGI = 0;
my $out = grab_output("t('$test_str')");
print 'not ' if $out->[0] ne '' or $out->[1] ne "$test_str\n";
print "ok 2\n";

# Test 3 - t() with $On == 0
$Log::TraceMessages::On = 0;
my $out = grab_output("t('$test_str')");
print 'not ' if $out->[0] ne '' or $out->[1] ne '';
print "ok 3\n";

# Test 4 - t() with $CGI == 1
$Log::TraceMessages::On = 1;
$Log::TraceMessages::CGI = 1;
my $out = grab_output("t('$test_str')");
print 'not ' if $out->[0] ne "\n<pre>test &lt; &gt; &amp;</pre>\n"
             or $out->[1] ne '';
print "ok 4\n";

# Test 5 - quick check that trace() works
$Log::TraceMessages::On = 1;
$Log::TraceMessages::CGI = 0;
my $out = grab_output("trace('$test_str')");
print 'not ' if $out->[0] ne '' or $out->[1] ne "$test_str\n";
print "ok 5\n";

# Test 6 - d().  But this is not a full test suite for Data::Dumper.
$Log::TraceMessages::On = 1;
my $a; eval '$a = ' . d($test_str);
print 'not ' if $a ne $test_str;
print "ok 6\n";

# Test 7 - check that d() does nothing when trace is off
$Log::TraceMessages::On = 0;
print 'not ' if d($test_str) ne '';
print "ok 7\n";

# Test 8 - quick check that dmp() works
$Log::TraceMessages::On = 1;
my $a; eval '$a = ' . dmp($test_str);
print 'not ' if $a ne $test_str;
print "ok 8\n";

# Test 9 - check_argv()
$Log::TraceMessages::On = 0;
my $num_args = @ARGV;
@ARGV = (@ARGV, '--trace');
Log::TraceMessages::check_argv();
print 'not ' if @ARGV != $num_args or not $Log::TraceMessages::On;
print "ok 9\n";


# grab_output()
# 
# Eval some code and return what was printed to stdout and stderr.
# 
# Parameters: string of code to eval
# 
# Returns: listref of [ stdout text, stderr text ]
# 
sub grab_output($) {
    die 'usage: grab_stderr(string to eval)' if @_ != 1;
    my $code = shift;
    require POSIX;
    my $tmp_o = POSIX::tmpnam(); my $tmp_e = POSIX::tmpnam();
    local *OLDOUT, *OLDERR;
    
    # Try to get a message to the outside world if we die
    local $SIG{__DIE__} = sub { print $_[0]; die $_[0] };

    open(OLDOUT, ">&STDOUT") or die "can't dup stdout: $!";
    open(OLDERR, ">&STDERR") or die "can't dup stderr: $!";
    open(STDOUT, ">$tmp_o")  or die "can't open stdout to $tmp_o: $!";
    open(STDERR, ">$tmp_e")  or die "can't open stderr to $tmp_e: $!";
    eval $code;
    close(STDOUT)            or die "cannot close stdout opened to $tmp_o: $!";
    close(STDERR)            or die "will anyone ever see this message?  $!";
    open(STDOUT, ">&OLDOUT") or die "can't dup stdout back again: $!";
    open(STDERR, ">&OLDERR") or die "can't dup stderr back again: $!";

    die $@ if $@;

    local $/ = undef;
    open (TMP_O, $tmp_o) or die "cannot open $tmp_o: $!";
    open (TMP_E, $tmp_e) or die "cannot open $tmp_e: $!";
    my $o = <TMP_O>; my $e = <TMP_E>;
    close TMP_O   or die "cannot close filehandle opened to $tmp_o: $!";
    close TMP_E   or die "cannot close filehandle opened to $tmp_e: $!";
    unlink $tmp_o or die "cannot unlink $tmp_o: $!";
    unlink $tmp_e or die "cannot unlink $tmp_e: $!";

    return [ $o, $e ];
}
