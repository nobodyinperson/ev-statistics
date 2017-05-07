#!/usr/bin/env perl
use strict;
use warnings;

my @links;
my @stems;
while(<>) { # read from STDIN
    chomp; # remove trailing newline
    s|^\s+||gi; # remove preceding whitespace
    push @links, $_; # add to linklist
    s|^[a-z]+://+[^/]+||gi; # remove host part
    s|^\W+||gi;s|\W+$||gi; # remove preceding and trailing non-word-characters
    s|\W|-|gi; # replace non-word-characters with dash -> now possible filename
    push @stems, $_; # add to stem list
    }


# set SINGLE_PAGES_STEMS variable
print join " \\\n\t","SINGLE_PAGES_STEMS =",@stems;
print "\n\n";
# set SINGLE_PAGES_LINKS variable
print join " \\\n\t","SINGLE_PAGES_LINKS =",@links;
