use v6;

unit class App::Miroku::Git;

class Repository {

    has IO::Path $.pwd is readonly;
    
    method add(:$all, *@files) {
        my @command = 'git', '-C', $!pwd.Str, 'add';

        if $all {
            @command.push: '--all';
        } else {
            @command.push: $_ for @files;
        }
        
        self!perform( |@command );
    }

    method remote-v() {
        my @command = 'git', '-C', $!pwd.Str, 'remote', '-v';

        self!perform( |@command );
    }

    method !perform(*@command) {

        run |@command, :out, :err;
    }
}

submethod init($directory = '.') {
    my $dev-null = open $*SPEC.devnull, :w;
    {
        run 'git', 'init', $directory, :out($dev-null);

        $dev-null.close;
    }
    Repository.new( :pwd($directory.IO.resolve) );
}

multi submethod from-dir(Str $git-directory) {
    Repository.new( :pwd($git-directory.IO.resolve) );
}
multi submethod from-dir(IO::Path $git-directory) {
    Repository.new( :pwd($git-directory) );
}
