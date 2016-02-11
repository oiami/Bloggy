use strict;
use warnings;

use Bloggy;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my $app = Bloggy->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );

my $user_anna = { username => 'anna456', password => 'soqyovlk' };

my $json_data = to_json($user_anna);
$res = $test->request(GET '/auth/token',
    'Content_Type'  => 'application/json', 
    'Content' => $json_data
);

my $content = from_json($res->content);
is($res->code, 200, 'get correct response code if user is authorized');
ok($content->{token}, 'get generated token return if user if valid'); 
ok($content->{secret}, 'get generated secret return if user is valid');

done_testing();