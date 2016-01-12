use strict;
use warnings;

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

my $postdata =  { 
    title  => 'Beef Steak',
};

my $json_data = to_json($postdata);
my $res = $test->request( 
    POST '/blogs/A12/posts',
    'Content' => $json_data
);
my $content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$json_data = to_json($postdata);
$res = $test->request( 
    POST '/blogs/1/posts',
    'Content' => $json_data
);
$content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when type of data is incorrect');

$res = $test->request( 
    POST '/blogs/1/posts',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when required data is missing');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when required data is missing');

$postdata->{content} = '123';
$json_data = to_json($postdata);
$res = $test->request( 
    POST '/blogs/1/posts',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when data type is incorrect');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when data type is incorrect');

$postdata->{content} = 'These are ingredients';
$json_data = to_json($postdata);
$res = $test->request(
    POST '/blogs/1/posts',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);
is($res->code, 201, 'get correct successful response code');
$content = from_json($res->content);
is($content->{message}, 'Post data is valid and created', 'get response message when data is valid' );

$res = $test->request(GET '/blogs/A12/posts');
$content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$res = $test->request(GET '/blogs/1/posts');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->[0]->{id}, '1', 'get ID of the post');
is($content->[0]->{title}, 'Beef Steak', 'get title of the post');
is($content->[0]->{content}, 'These are ingredients', 'get title of the blog');
is($content->[0]->{blog}->{id}, '1', "get ID of the post's blog");
is($content->[0]->{blog}->{title}, 'Easy Cooking Menu', "get title of the post's blog");


$res = $test->request(GET '/blogs/xx/posts/yy');
is($res->code, 400, 'get correct response code when id is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$res = $test->request(GET '/blogs/1/posts/yy');
is($res->code, 400, 'get correct response code when id is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$res = $test->request(GET '/blogs/1/posts/2');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->{id}, '2', 'Get ID of the post');
is($content->{title}, 'Teriyaki Chicken', 'get post title');
is($content->{blog}->{id}, '1', "get ID of the post's blog");
is($content->{blog}->{title}, 'Easy Cooking Menu', "get title of the post's blog");

my $new_postdata = { 
    title   => 'Japanese Teriyaki Chicken',
    content => 'Soy sauce is one of ingredients',
};

$json_data = to_json($new_postdata);

$res = $test->request(PUT '/blogs/0/posts/0',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);
is($res->code, 400, 'get correct error response code when ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$res = $test->request(PUT '/blogs/1/posts/0',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);
is($res->code, 400, 'get correct error response code when ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$res = $test->request(PUT '/blogs/1/posts/1',
    'Content' => $json_data
);
is($res->code, 400, 'get correct error response code when header data type is incorrect');
$content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when data type is incorrect');

$res = $test->request(PUT '/blogs/1/posts/2',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
); 
is($res->code, 200, 'get correct response code when data is successfully updated');
$content = from_json($res->content);
is($content->{message}, 'Post data is updated', 'get response message when data is successfully updated');

$res = $test->request(DELETE '/blogs/0/posts/1');
is($res->code, 400, 'get correct error response code when ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find blog ID', 'get error message when blog ID is incorrect');

$res = $test->request(DELETE '/blogs/1/posts/1');
is($res->code, 400, 'get correct error response code when ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$res = $test->request(DELETE '/blogs/1/posts/2');
is($res->code, 204, 'get correct response code');

done_testing();