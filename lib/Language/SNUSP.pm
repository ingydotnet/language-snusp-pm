use strict;
package Language::SNUSP;

our $VERSION = '0.0.1';

my $debug = 0;
my $trace = 0;
my $input = '';

sub run {
    my ($class, @args) = @_;
    while (@args) {
        my $arg = shift @args;
        if ($arg =~ /^(-v|--version)$/) {
            print "Language::SNUSP v$VERSION";
            exit 0;
        }
        if ($arg =~ /^(-\?|-h|--help)$/) {
            die usage();
            exit 0;
        }
        if ($arg =~ /^(-d|--debug)$/) {
            $debug = 1;
            next;;
        }
        if ($arg =~ /^(-t|--trace)$/) {
            $trace = 1;
            next;
        }
        if ($arg =~ /^-/) {
            die "Unknown option: '$arg'\n\n" . usage();
        }
        if (not -f $arg) {
            die "Input file '$arg' does not exist.\n";
        }
        $input = $arg;
        last;
    }
    die usage() if @args or not $input;
    open my $fh, '<', $input or die "Can't open '$input' for input.\n";
    my $code = do {local $/; <$fh>};
    close $fh;
    if ($debug) {
        exit $class->debugger($code);
    }
    else {
        exit $class->runner($code);
    }
}

sub runner {
    my ($class, $input) = @_;
    my ($dy, $p, $dir, $run, $code, @data, @stack, $op) =
        (1, 0, 1, 1, '', 0);
    $code .= $_, $dy < 2 + length and $dy = 2 + length
        for $input =~ /^.*\n/gm;
    $code =~ s/^.*/$& . ' ' x ($dy - 2 - length $&) . "\n"/gem;
    my $ip = index $code, '$'; # find first $ or first char
    $ip = 0 if $ip < 0;
    my %ops = (
        # RIGHT
        '>'  => sub { ++$p },
        # LEFT
        '<'  => sub { $run-- if --$p < 0 },
        # INCR
        '+'  => sub { ++$data[$p] },
        # DECR
        '-'  => sub { --$data[$p] },
        # READ
        ','  => sub { $data[$p] = ord shift },
        # WRITE
        '.'  => sub { print chr $data[$p] },
        # RULD
        '/'  => sub { $dir = abs $dir == 1 ? -$dy * $dir : $dir / -$dy},
        # LURD
        '\\' => sub { $dir = abs $dir == 1 ? $dy * $dir : $dir / $dy},
        # SKIP
        '!'  => sub { $ip += $dir },
        # SKIPZ
        '?'  => sub { $ip += $dir unless $data[$p] },
        # ENTER
        '@'  => sub { push @stack, [ $ip + $dir, $dir ] },
        # LEAVE
        '#'  => sub { @stack ? ($ip, $dir) = @{pop @stack} : $run-- },
        # STOP
        "\n" => sub { $run-- },
    );

    if ($trace) {
        while ($run and $ip >= 0 and $ip < length $code) {
            my $ch = substr $code, $ip, 1;
            print "op: $ch (@data)[$p]\n";
            $op = $ops{$ch} and &$op;
            $ip += $dir;
            print "\n" if $ch eq '.';
        }
    }
    else {
        while ($run and $ip >= 0 and $ip < length $code) {
            $op = $ops{substr $code, $ip, 1} and &$op;
            $ip += $dir;
        }
    }
    return $data[$p];
}

sub debugger {
    my ($class, $input) = @_;
    require Curses; Curses->import;
    require Term::ReadKey; Term::ReadKey->import;

    my ($dy, $dir, $p, @data, @stack, $op, $code, $ch) = (1, 1, 0, 0);
    $code .= $_, $dy < length and $dy = length for $input =~ /^.*\n/gm;
    $code =~ s/^.*/$& . ' ' x ($dy - length $&) . "\n"/gem;
    $dy += 2;
    my %lurd = (-1, -$dy, -$dy, -1, 1, $dy, $dy, 1);
    my $ip = $code =~ /\$/ * $-[0]; # find first $ or first char
    my @out = ();
    my %ops = (
        '>'  => sub { $data[++$p] += 0 },
        '<'  => sub { --$p >= 0 or $dir = 0 },
        '+'  => sub { ++$data[$p] },
        '-'  => sub { --$data[$p] },
        ','  => sub { $data[$p] = ord shift },
        '.'  => sub { push @out, chr $data[$p] },
        '/'  => sub { $dir = -$lurd{$dir} },
        '\\' => sub { $dir =  $lurd{$dir} },
        '!'  => sub { $ip += $dir },
        '?'  => sub { $ip += $dir if $data[$p] == 0 },
        '@'  => sub { push @stack, [ $ip + $dir, $dir ] },
        '#'  => sub { @stack ? ($ip, $dir) = @{pop @stack} : ($dir = 0) },
        "\n" => sub { $dir = 0 },
    );

    initscr();
    ReadMode(3);

    my $y = 0;
    addstr($y++, 0, $&) while $code =~ /.+/g;
    addstr(
        ++$y + 2, 0,
        "(space)togglepause (g)oto n (Enter)step (BS)backstep",
    );
    addstr(
        $y + 3, 0,
        "(r)estart (q)uit (+)fast (-)slow",
    );
    my $count = 0;
    my @history;
    my $key;
    my $sleep = 0.1;
    my $pause = 0;
    my $number = 0;

    while(1) {
        if ($ip < 0) {$ip = 0; $dir = 0}
        if ($ip >= length $code) {$ip = length($code) - 1; $dir = 0}
        $pause = 1 if $dir == 0;
        if ($dir and (not $pause or $key eq "\n")) {
            $pause = 1
                if $number and $count == $number - 1 or $key eq "\n";
            $op = $ops{$ch = substr $code, $ip, 1} and &$op;
            $ip += $dir;
            $history[$count++] ||=
                [$ip, $dir, $p, [@data], [@stack], [@ARGV], [@out] ];
        }
        my $n = 0;
        my $brace = join '', map { $n++ == $p ? "[$_]" : " $_ " } @data;
        my $s = "data: $brace   out: @out  t: $count  n: $number";
        addstr($y, 0, $s);
        clrtoeol();
        move( int($ip / $dy), $ip % $dy);
        refresh();
        $key = ReadKey($pause ? 0 : $sleep);
        if ($key eq 'q' or $key eq 'r') {last}
        elsif ($key =~ /^[\+\=]$/) {$sleep -= 0.01 if $sleep > 0.011}
        elsif ($key eq '-'){$sleep += 0.01}
        elsif ($key eq "\e"){$number = 0}
        elsif ($key =~ /\d/){$number = 10 * $number + $key}
        elsif ($key eq ' '){$pause = not $pause}
        elsif ($key eq 'g' || $key eq "\x08" and $number < @history) {
            $count = $key eq 'g' ? $number : $count - 2;
            ($ip, $dir, $p, my $data, my $stack, my $argv, my $out) =
            @{$history[$count++]};
            @data = @$data;
            @stack = @$stack;
            @ARGV = @$argv;
            @out = @$out;
        }
    }
    ReadMode(0);
    endwin();
}

sub usage {
    <<'...';
Usage:
    snusp [options] input_file.snusp

Options:
    -d, --debug     # Run program in the visual debugger
    -t, --trace     # Run with trace on
    -v, --version   # Print version and exit
    -h, --help      # Print help and exit
...
}

1;

=encoding utf8

=head1 NAME

Language::SNUSP - A SNUSP interpreter written in Perl

=head1 SYNOPSIS

    > snusp examples/fizzbuzz.snusp
    > snusp --debug examples/fizzbuzz.snusp

=head1 DESCRIPTION

SNUSP is a two-dimensional programming language described here:

* http://rosettacode.org/wiki/Category:SNUSP
* http://c2.com/cgi/wiki?SnuspLanguage

Here is the well known FizzBuzz algorithm in SNUSP:

            /               'B' @=@@=@@++++#
           // /             'u' @@@@@=@+++++#
          // // /           'z' @=@@@@+@++++#
         // // // /         'i' @@@@@@=+++++#
        // // // // /       'F' @@@=@@+++++#
       // // // // // /      LF  ++++++++++#
      // // // // // // /   100 @@@=@@@=++++#
    $@/>@/>@/>@/>@/>@/>@/\   0
    /                    /
    !                             /======= Fizz <<<.<.<..>>>#
    /                             |      \
    \?!#->+ @\.>?!#->+ @\.>?!#->+@/.>\   |
    /        !          !         !  /   |
    \?!#->+ @\.>?!#->+@\ .>?!#->+@/.>\   |
    /        !         \!===\!    !  /   |
    \?!#->+ @\.>?!#->+ @\.>?!#->+@/.>\   |
    /        !          !   |     !  /   |
    \?!#->+@\ .>?!#->+ @\.>?!#->+@/.>\   |
    /       \!==========!===\!    !  /   |
    \?!#->+ @\.>?!#->+ @\.>?!#->+@/>>@\.>/
             !          |   |         |
             /==========/   \========!\=== Buzz <<<<<<<.>.>..>>>#
             |
             \!/=dup==?\>>@\<!/back?\<<<#
               \<<+>+>-/   |  \>+<- /
                           |
    /======================/
    |
    |       /recurse\    #/?\ zero
    \print=!\@\>?!\@/<@\.!\-/
              |   \=/  \=itoa=@@@+@+++++#
              !     /+ !/+ !/+ !/+   \    mod10
              /<+> -\!?-\!?-\!?-\!?-\!
              \?!\-?!\-?!\-?!\-?!\-?/\    div10
                 #  +/! +/! +/! +/! +/

This module installs a SNUSP interpreter so that you can run this code
yourself. It also installs a visual debugger, to help you follow the flow of
SNUSP programs. It is very cool to watch!

=head1 CREDIT

This code came from http://c2.com/cgi/wiki?SnuspLanguage

I am just packaging it on CPAN and GitHub for easy installation and continued
maintenance.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004. Rick Klement.

Copyright (c) 2013. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
