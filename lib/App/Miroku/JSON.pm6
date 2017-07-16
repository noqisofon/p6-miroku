use v6;

need JSON::Pretty;

unit class App::Miroku::JSON;


my class SortedHash does Associative {
    has $.hash;

    method new(%hash) {
        self.bless( hash => %( %hash.kv.map( -> $k, $v { $k => $v ~~ Associative ?? self.new( %($v) ) !! $v } ) ), );
    }

    method map(&block) {
        do for $.hash.keys.sort( { ~$^a cmp ~$^b } ) -> $k {
            block( $k => %.hash{$k} );
        }
    }
}


method encode(::?CLASS:U: %hash) {
    JSON::Pretty::to-json( SortedHash.new( %hash ) );
}

method decode(::?CLASS:U: $text) {
    JSON::Pretty::from-json( $text );
}
