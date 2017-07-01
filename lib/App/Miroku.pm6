use v6;

use App::Miroku::Template;

unit class App::Miroku;

has $!auther = qx{git config --global user.name}.chomp;
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


multi method perform('new', Str $module-name is copy, Str :$prefix = Nil, Str :$to = '.', Str :$type = 'lib') {
    my $main-dirname = $module-name.subst( '::', '-', :g );
    $main-dirname = $prefix ~ $main-dirname if $prefix;

    my $main-dir = $to.IO.resolve.add( $main-dirname );

    die "Already exists $main-dir" if $main-dir.IO ~~ :d;
    
    $main-dir.mkdir;
    chdir( $main-dir );
    {
        my $module-filepath = to-file( $module-name );
        my $module-dir      = $module-filepath.IO.dirname.Str;

        my @child-dirs;
        given $type {
            when 'app' { @child-dirs = ( $module-dir, 't', 'bin' ) }
            when 'lib' { @child-dirs = ( $module-dir, 't' ) }
            default    { @child-dirs = ( $module-dir ) }
        }

        mkdir( $_ ) for @child-dirs;

        my %contents = template-on(
            :module($module-name),
            :$!author, $!email, :$!year,
            dist => $module.subst( '::', '-', :g )
        );
    }
}

multi method perform('build') {
}

multi method perform('test', @file, Bool :$verbose , Int :$jobs) {
}
