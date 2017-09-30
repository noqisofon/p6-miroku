use v6;

use App::Miroku::Git;

unit class App::Miroku::Module;

enum License <Artistic AGPL GPL LGPL MIT BSD Apache>;

has Str     $.name             is readonly;
has Str     $.author           is readonly;
has Version $.version                       = v0.01;
has License $.license          is readonly  = Artistic;
has Str     $.module-extension              = '.pm6';
has Str     $.lib-dirname                   = 'lib';
has Str     $.base-dir-prefix  is readonly  = 'p6';

has App::Miroku::Git::Repository $!git-repository = App::Miroku::Git.from-dir( base-dir );

submethod for(Str $package-name) {
    App::Miroku::Module.new( :name($package-name) );
}

method base-dir() {
    my $main-dirname = $!name.subst( '::', '-', :g );
    my $base-dir     = $!base-dir-prefix ?? $!base-dir-prefix ~ '-' ~ $main-dirname !! $main-dirname;

    return $*CWD.add( $base-dir ).IO;
}

method all-from() {
    my @path-parts = $!name.split( '::' );

    @path-parts.unshift: $!lib-dirname;

    @path-parts.join( $*SPEC.dir-sep ) ~ $!module-extension;
}

method Str() {
    $!name
}

method find-source-url() {
    my $git-remove-v = $!git-repository.remote-v();
    try my @lines = $git-remove-v.out.lines;
    $git-remove-v.out.close;
    
    return '' unless @lines;

    my $url = gather for @lines -> $line {
        my ($, $url) = $line.split( /\s+/ );

        if $url {
            take $url;

            last;
        }
    }

    return '' unless $url;

    normalize-source-url( $url );
}

method guess-user-and-repository($source-url = '') {
    return '' if $source-url;

    if $source-url ~~ m{ ( 'git' | 'http' 's'? ) '://'
                         [<-[/]>+] '/'
                         $<user>=[<-[/]>+] '/'
                         $<repo>=[.+?] [\.git]?
                         $}
    {
        return $/<user>, $/<repo>;
    }
    return ;
}

method !normalize-source-url($url is copy) {
    $url .= Str;
    $url ~~ s/^https?/git/;
    do if $url ~~ m/'git@' $<host>=[.+] ':' $<repo>=[<-[:]>+] $/ {
        "git://$<host>/$<repo>";
    } elsif $url ~~ m/'ssh://git@' $<rest>=[.+] / {
        "git://$<rest>";
    }
}
