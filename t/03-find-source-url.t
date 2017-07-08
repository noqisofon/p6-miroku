# -*- mode: perl6; -*-
use v6;

use Test;

sub find-source-url() {
    try my @lines = qx{git remote -v 2> /dev/null};

    return '' unless @lines;

    my $url = gather for @lines -> $line {
        my ($, $url) = $line.split( /\s+/ );

        if  $url {
            take $url;

            last;
        }
    }

    return '' unless $url;

    $url .= Str;

    $url ~~ s/^https?/git/;

    if $url ~~ m/'git@' $<host>=[.+] ':' $<repo>=[<-[:]>+] $/ {
        $url = "git://$<host>/$<repo>";
    } elsif $url ~~ m/'ssh://git@' $<rest>=[.+] / {
        $url = "git://$<rest>";
    }
    $url;
}


my $url = find-source-url;

say $url;

ok $url;
