# -*- mode: perl6; -*-
use v6;

use Test;

use App::Miroku::Module;

plan 6;

is 'hoge.txt'           , normalize-path( './hoge.txt' );

is 'lib/Hoge/Piyo.pm6'  , normalize-path( './lib/Hoge/Piyo.pm6' );

is 'Hoge::Piyo'         , to-module( './lib/Hoge/Piyo.pm6' );

is 'Hoge::Piyo'         , to-module( './Hoge/Piyo.pm6' );

is './lib/Hoge/Piyo.pm6', to-file( 'Hoge::Piyo' );

is './lib/Foo/Bar.pm6'  , to-file( 'Foo::Bar' );

done-testing;
