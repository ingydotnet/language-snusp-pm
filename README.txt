NAME
    Language::SNUSP - A SNUSP interpreter written in Perl

SYNOPSIS
        > snusp examples/fizzbuzz.snusp
        > snusp --debug examples/fizzbuzz.snusp

DESCRIPTION
    SNUSP is a two-dimensional programming language described here:

    http://rosettacode.org/wiki/Category:SNUSP
    http://c2.com/cgi/wiki?SnuspLanguage

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
    yourself. It also installs a visual debugger, to help you follow the
    flow of SNUSP programs. It is very cool to watch!

CREDIT
    This code came from http://c2.com/cgi/wiki?SnuspLanguage

    I am just packaging it on CPAN and GitHub for easy installation and
    continued maintenance.

AUTHOR
    Ingy döt Net <ingy@cpan.org>

COPYRIGHT AND LICENSE
    Copyright (c) 2004. Rick Klement.

    Copyright (c) 2013. Ingy döt Net.

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

    See http://www.perl.com/perl/misc/Artistic.html

