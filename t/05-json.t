# -*- mode: perl6; -*-
use v6;

use JSON::Fast;
use Test;



my @hoge = 1, 2, 3;

my $json = to-json( @hoge );

say $json;

my $piyo    = from-json( $json );

say $piyo;
@hoge = $piyo;
say @hoge;
