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
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use HTTP::Headers;
use Data::Dumper;
use JSON;
use HTTP::Request;

my $app = Bloggy->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $blogdata =  { 
    username  => 'anna456',
    password  => 'soqyovlk',
    blog => {
        title => 'Easy Cooking Menu'
    }
};

my $json_data = to_json($blogdata);
my $res = $test->request( 
    POST '/blogs',
    'Content' => $json_data,
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password},
);
my $content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when type of data is incorrect');

$res = $test->request( 
    POST '/blogs',
    'Content_Type'  => 'application/json', 
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password},
    'Content'       => $json_data
);

is($res->code, 400, 'get correct error response code when required data is missing');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when required data is missing');

$blogdata->{blog}->{url} = '12331223';
$json_data = to_json($blogdata);
$res = $test->request( 
    POST '/blogs',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password}, 
    'Content'       => $json_data
);

is($res->code, 400, 'get correct error response code when data type is incorrect');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when data type is incorrect');

$blogdata->{blog}->{url} = 'easycookingmenu';
$json_data = to_json($blogdata);
$res = $test->request(
    POST '/blogs',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password}, 
    'Content'       => $json_data
);
is($res->code, 201, 'get correct successful response code');
$content = from_json($res->content);
is($content->{message}, 'Blog data is valid and created', 'get response message when data is valid' );

$res = $test->request(GET '/blogs');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->[0]->{id}, '1', 'get ID of the blog');
is($content->[0]->{title}, 'Cooking World', 'get title of the blog');
is($content->[0]->{url}, 'cooking_world', 'get url of the blog');
is($content->[0]->{author}, '2', "get ID of the blog's author");

$res = $test->request(GET '/blogs/ab');
is($res->code, 400, 'get correct response code when id is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$res = $test->request(GET '/blogs/3');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->{id}, '3', 'Get ID of the blog');
is($content->{title}, 'Easy Cooking Menu', 'get blog title');
is($content->{url}, 'easycookingmenu', 'get url of the blog');
is($content->{author}, '2', "get ID of the blog's author");


my $new_blogdata = { 
    blog => {
        title => 'Super Easy Cooking Menu',
        url   => 'easycookingmenu',
        id    => 3,
    },
    username => 'anna456',
    password => 'soqyovlk'
};

$json_data = to_json($new_blogdata);

$res = $test->request(PUT '/blogs/0',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password},  
    'Content' => $json_data
);
is($res->code, 400, 'get correct error response code when ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$res = $test->request(PUT '/blogs/3',
    'Content' => $json_data,
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password}, 
);
is($res->code, 400, 'get correct error response code when header data type is incorrect');
$content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when data type is incorrect');

$res = $test->request(PUT '/blogs/3',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password}, 
    'Content' => $json_data
); 
is($res->code, 200, 'get correct response code when data is successfully updated');
$content = from_json($res->content);
is($content->{message}, 'Blog data is updated', 'get response message when data is successfully updated');

$res = $test->request(DELETE '/blogs/0',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password}, 
    'Content' => $json_data,
);
is($res->code, 400, 'get correct error response code when ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$res = $test->request(DELETE '/blogs/1',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$blogdata->{username} . $blogdata->{password},
    'Content' => $json_data,
);
is($res->code, 204, 'get correct response code');

END {
    BloggyTest->rollback_data();
}

done_testing();