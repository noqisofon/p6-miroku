use v6;

use File::Find;

use App::Miroku::Template;

unit class App::Miroku;

has $!author = qx{git config --global user.name}.chomp;
has $!email  = qx{git config --global user.email}.chomp;
has $!year   = Date.today.year;

my &normalize-path = -> $path {
    $*DISTRO.is-win ?? $path.subst( '\\', '/', :g ).IO.relative !! $path.IO.relative
};

my &to-module = -> $filename {
    normalize-path( $filename ).Str.subst( 'lib/', '' ).subst( '/', '::', :g ).subst( /\.pm6?$/, '' )
};

my &to-file = -> $module-name {
    my $path = $module-name.subst( '::', '/', :g ) ~ '.pm6';

    './lib/'.IO.add( $path ).Str
};


multi method perform('new', Str $module-name is copy, Str :$prefix, Str :$to = '.', Str :$type = 'lib') {
    my $main-dirname = $module-name.subst( '::', '-', :g );

    $main-dirname = $prefix ~ $main-dirname if $prefix;

    my $main-dir = $to.IO.resolve.add( $main-dirname );

    die "Already exists $main-dir" if $main-dir.IO ~~ :d;
    
    $main-dir.mkdir;
    chdir( $main-dir );
    my $module-filepath = to-file( $module-name );
    my $module-dir      = $module-filepath.IO.dirname.Str;

    my @child-dirs = get-child-dirs($type, $module-dir);
    
    mkdir( $_ ) for @child-dirs;

    my %contents = App::Miroku::Template::get-template(
        :module($module-name),
        :$!author, :$!email, :$!year,
        dist => $module-name.subst( '::', '-', :g )
    );

    my %key-by-path = get-key-by-path( $type, $module-filepath );

    for %key-by-path.kv -> $key, $path {
        spurt( $path, %contents{$key} );
    }

    self.perform( 'build' );

    git-init;
    git-add;

    note "Successfully created $main-dir";
}

multi method perform('build') {
    my ( $module, $module-file ) = guess-main-module;

    generate-read-me( $module-file );

    self!generate-meta-info( $module, $module-file );
    self.build;
}

multi method perform('test', @file, Bool :$verbose , Int :$jobs) {
}

method build($build-filename = 'Build.pm') {
    return unless $build-filename.IO.e;

    note " ==> Execute $build-filename";

    # my @command = 

    # my $exit-code = $proc.exitcode;

    # die "Failed with exitcode $exit-code" if $exit-code != 0;
}

method !generate-meta-info($module, $module-file) {
    
}

sub get-child-dirs(Str $type, $module-dir) {
    given $type {
        when 'app' {
            ( $module-dir, 't', 'bin' )
        }
        when 'lib' {
            ( $module-dir, 't' )
        }
        default {
            ( $module-dir )
        }
    }
}

sub get-key-by-path(Str $type, $module-filepath) {
    given $type {
        when 'app' {
            (
                module      => $module-filepath,
                test-case   => 't/01-basic.t',
                license     => 'LICENSE',
                'gitignore' => '.gitignore',
                travis      => '.travis.yml'
            )
        }
        when 'lib' {
            (
                module      => $module-filepath,
                test-case   => 't/01-basic.t',
                license     => 'LICENSE',
                'gitignore' => '.gitignore',
                travis      => '.travis.yml'
            )
        }
        default {
            (
                module      => $module-filepath,
                license     => 'LICENSE',
                'gitignore' => '.gitignore',
                travis      => '.travis.yml'
            )
        }
    }
}

sub git-init() {
    my $dev-null = open $*SPEC.devnull, :w;
    {
        run 'git', 'init', '.', :out($dev-null);

        $dev-null.close;
    }
}

sub git-add() {
    run 'git', 'add', '.';
}

sub with-p6-lib(&block) {
    temp %*ENV;

    %*ENV<PERL6LIB> = %*ENV<PERL6LIB>:exists ?? "$*CWD/lib," ~~ %*ENV<PERL6LIB> !! "$*CWD/lib,";

    block;
}

sub generate-read-me($module-file, $document-type = 'Markdown') {
    my @command = $*EXECUTABLE, "--doc={$document-type}", $module-file;
    my $a-proc  = with-p6-lib { run |@command, :out };

    die "Failed: @command[]" if $a-proc.exitcode != 0;

    my $contents = $a-proc.out.slurp-rest;

    my ($user, $repository) = guess-user-and-repository;
    my $header = do if $user and '.travis.yml'.IO.e {
        "[![Build Status](https://travis-ci.org/$user/$repository.svg?branch=master)]"
        ~ "(https://travis-ci.org/$user/$repository)"
        ~ "\n\n";
    } else {
        '';
    }

    spurt 'README.md', $header ~ $contents;
}

sub guess-user-and-repository() {
    my $source-url = find-source-url;

    return if $source-url eq '';

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

sub guess-main-module($lib-dir = 'lib') {
    die 'Must run in the top directory' unless $lib-dir.IO ~~ :d;

    my @module-files       = find( :dir($lib-dir), :name(/ '.pm'  '6'? $ /) ).list;
    my $module-file-amount = @module-files.elems;
    given $module-file-amount {
        when 0 {
            die 'Could not determine main module file';
        }
        when 1 {
            my $first-module-file = @module-files.first;

            return ( to-module( $first-module-file ), $first-module-file )
        }
        default {
            my $base-dir = $*CWD.basename;

            $base-dir ~~ s/^ ('perl6' | 'p6') '-'//;

            my $module-name       = $base-dir.split( '-' ).join( '/' );
            my @found-module-files = @module-files.grep( -> $filepath { $filepath ~~ m:i/$module-name . pm6?$/ } );
            my $a-file = do if @found-module-files.elems == 0 {
                my @sorted-module-files = @module-files.sort: { $^a.chars <=> $^b.chars };

                @sorted-module-files.shift.Str;
            } elsif @found-module-files.elems == 1 {
                @found-module-files.first.Str;
            } else {
                my @sorted-module-files = @module-files.sort: { $^a.chars <=> $^b.chars };

                @sorted-module-files.shift.Str;
            }
            return ( to-module( $a-file ), $a-file );
        }
    }
}
