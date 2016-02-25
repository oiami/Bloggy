use strict;
use warnings;

BEGIN {
    $ENV{BLOGGY} = 'test';
    $ENV{DANCER_ENVIRONMENT} = $ENV{BLOGGY};
    use lib 't/lib';
    use BloggyTest;
    BloggyTest->init_data();
}

use Bloggy;
use Test::More;
use Plack::Test;
use JSON;
use JSON::WebToken;
use HTTP::Request::Common;
use Secret::Simple;
use Data::Dumper;

my $app = Bloggy->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $user = { username => 'anna456', password => 'soqyovlk' };
my $json = to_json($user);

my $res  = $test->request(
    POST '/login',
    'Content_Type' => 'application/json', 
    'Content' => $json
);

my $content = from_json($res->content);
my $token = $content->{token};

ok( $token, 'get token' );


END {
    BloggyTest->rollback_data();
}

done_testing();