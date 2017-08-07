use v6;

module App::Miroku::Module {

    our sub normalize-path($path) {
        $*DISTRO.is-win ?? $path.subst( '\\', '/', :g ).IO.relative !! $path.IO.relative
    }

    our sub to-module($filename) {
        my $dir-separator = do if $*DISTRO.is-win {
            IO::Spec::Win32.dir-sep
        } else {
            IO::Spec::Unix.dir-sep
        }
        normalize-path( $filename ).Str.subst( 'lib' ~ $dir-separator, '' ).subst( $dir-separator, '::', :g ).subst( /\.pm6?$/, '' )
    }

    our sub to-file($module-name) {
        note $module-name;
        my $path = $module-name.subst( '::', '/', :g ) ~ '.pm6';

        './lib/'.IO.add( $path ).Str
    }

}

sub EXPORT {
    {
        '&normalize-path' => &App::Miroku::Module::normalize-path,
        '&to-module'      => &App::Miroku::Module::to-module,
        '&to-file'        => &App::Miroku::Module::to-file
    }
}
