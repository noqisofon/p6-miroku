# -*- mode: perl6; -*-
use v6;
use Test;

use App::Miroku::Module;

plan 4;

my $a-module = App::Miroku::Module.for( 'App::Miroku' );

my $module-path = $a-module.guess-from-module-name( 'App::Miroku::Module' );

is 'App::Miroku'                , $a-module.Str                                    , '.Str is App::Miroku';

is 'lib/App/Miroku/Module.pm6'  , $module-path                                     , 'comes back when guess "lib/App/Miroku/Module" in App::Miroku::Module';

is $a-module.all-from           , $a-module.guess-from-module-name( 'App::Miroku' ), 'all-from is guess App::Miroku';

is 'p6-App-Miroku'              , $a-module.base-dir( $*HOME ).basename            , '.base-dir.basename is p6-App-Miroku';

done-testing;
