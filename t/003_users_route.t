use strict;
use warnings;

use Bloggy;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Data::Dumper;

my $app = Bloggy->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $userdata =  { 
    username  => 'Tom123',
    firstname => 'Thomas',
    lastname  => 'Muller',
    email     => 'tommy12@example.com',
};

$res = $test->request( POST '/users', $userdata );
is($res->code, 400, 'get correct error response code when required data is missing');
my $content = $res->content;
like($content, qr/did not pass type constraint/, 'get error message when required data is missing');

$userdata->{password} = '12345';
$res = $test->request( POST '/users', $userdata );
is($res->code, 400, 'get correct error response code when data type is incorrect');
$content = $res->content;
like($content, qr/did not pass type constraint/, 'get error message when data type is incorrect');

$userdata->{password} = 'PossWort';
$res = $test->request( POST '/users', $userdata );
is($res->code, 200, 'get correct successful response code');
is( $res->content, 'valid!!!!', 'user data is valid' );

done_testing();