use strict;
use warnings;

use Bloggy;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Headers;
use Data::Dumper;
use JSON;

my $app = Bloggy->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $userdata =  { 
    username  => 'Tom123',
    firstname => 'Thomas',
    lastname  => 'Muller',
    email     => 'tommy12@example.com',
};

my $json_data = to_json($userdata);
my $res = $test->request( 
    POST '/users',
    'Content' => $json_data
);
my $content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when type of data is incorrect');

$res = $test->request( 
    POST '/users',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when required data is missing');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when required data is missing');

$userdata->{password} = '12345';
$json_data = to_json($userdata);
$res = $test->request( 
    POST '/users',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when data type is incorrect');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when data type is incorrect');

$userdata->{password} = 'PossWort';
$json_data = to_json($userdata);
$res = $test->request(
    POST '/users',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is( $content->{message}, 'Data is valid', 'get response message when data is valid' );

done_testing();