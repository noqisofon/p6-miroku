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

submethod for(Str $package-name) {
    App::Miroku::Module.new( :name($package-name) );
}

method base-dir(IO::Path $cwd = $*CWD) {
    my $main-dirname = $!name.subst( '::', '-', :g );
    my $base-dir     = $!base-dir-prefix ?? $!base-dir-prefix ~ '-' ~ $main-dirname !! $main-dirname;

    $cwd.add( $base-dir ).IO;
}

method all-from() {
    my @path-parts = $!name.split( '::' );

    @path-parts.unshift: $!lib-dirname;

    @path-parts.join( $*SPEC.dir-sep ) ~ $!module-extension;
}

method Str() {
    $!name
}

method find-source-url(App::Miroku::Git::Repository $git-repository) {
    my $git-remove-v = $git-repository.remote-v();
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

    self!normalize-source-url( $url );
}

method guess-from-module-name($module-name) {
    my $path = $module-name.subst( '::', $*SPEC.dir-sep, :g ) ~ $!module-extension;
    
    $.lib-dirname.IO.add( $path );
}

method guess-user-and-repository($source-url = '') {
    return '' if $source-url;

    if $source-url ~~ m{ ( 'git' | 'http' 's'? ) '://'
                         [<-[/]>+] '/'
                         $<user>=[<-[/]>+] '/'
                         $<repository-name>=[.+?] [\.git]?
                         $}
    {
        return $/<user>, $/<repository-name>;
    }
    return ;
}

method !normalize-source-url($url is copy) {
    $url .= Str;
    $url ~~ s/^https?/git/;
    do if $url ~~ m/'git@' $<host>=[.+] ':' $<repository-name>=[<-[:]>+] $/ {
        "git://$<host>/$<repository-name>";
    } elsif $url ~~ m/'ssh://git@' $<rest>=[.+] / {
        "git://$<rest>";
    }
}
