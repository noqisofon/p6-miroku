# -*- mode: perl6; -*-
use v6;
use Test;

use App::Miroku::Git;

sub find-source-url(@lines) {
    return '' unless @lines;
    
    my $url = gather for @lines -> $line {
        my ($origin, $url, $type) = $line.split( /\s+/ );

        if  $url {
            take $url;

            last;
        }
    }

    return '' unless $url;

    normalize-source-url( $url );
}

sub normalize-source-url($url is copy) {
    $url .= Str;
    $url ~~ s/^https?/git/;
    do if $url ~~ m/'git@' $<host>=[.+] ':' $<repo>=[<-[:]>+] $/ {
        "git://$<host>/$<repo>";
    } elsif $url ~~ m/'ssh://git@' $<rest>=[.+] / {
        "git://$<rest>";
    }
}


plan 2;
my $git-repository = App::Miroku::Git.from-dir( $*CWD );
{
    my $git-remote-v = $git-repository.remote-v;
    my $url          = find-source-url( $git-remote-v.out.lines );

    ok $url ~~ /^ 'git:'/           , 'source url begin in "git:"';
    ok $url ~~ / 'p6-miroku.git' $/ , 'source url finished beging "p6-miroku.git"';
}
done-testing;
