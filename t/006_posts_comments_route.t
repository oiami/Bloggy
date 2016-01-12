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

my $comment =  { 
    content  => 'Looks tasty!',
};

my $json_data = to_json($comment);
my $res = $test->request( 
    POST '/posts/A12/comments',
    'Content' => $json_data
);
my $content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$json_data = to_json($comment);
$res = $test->request( 
    POST '/posts/1/comments',
    'Content' => $json_data
);
$content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when type of data is incorrect');

$res = $test->request( 
    POST '/posts/1/comments',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when required data is missing');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when required data is missing');

$comment->{author} = 'Linda';
$json_data = to_json($comment);
$res = $test->request( 
    POST '/posts/1/comments',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when data type is incorrect');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when data type is incorrect');

$comment->{author} = '1';
$json_data = to_json($comment);
$res = $test->request(
    POST '/posts/1/comments',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);
is($res->code, 201, 'get correct successful response code');
$content = from_json($res->content);
is($content->{message}, 'Comment data is valid and created', 'get response message when data is valid' );

$res = $test->request(GET '/posts/A12/comments');
$content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$res = $test->request(GET '/posts/1/comments');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->[0]->{id}, '1', 'get ID of the comment');
is($content->[0]->{content}, 'Looks tasty!', 'get content of the comment');
is($content->[0]->{author}->{id}, '1', 'get ID of the commentator');
is($content->[0]->{author}->{firstname}, 'Linda', 'get firstname of the commentator');
is($content->[0]->{author}->{lastname}, 'Fischer', 'get lastname of the commentator');


$res = $test->request(GET '/posts/xx/comments/yy');
is($res->code, 400, 'get correct response code when post ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$res = $test->request(GET '/posts/1/comments/yy');
is($res->code, 400, 'get correct response code when comment ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find comment ID', 'get error message when comment ID is incorrect');

$res = $test->request(GET '/posts/1/comments/2');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->{id}, '2', 'get ID of the comment');
is($content->{content}, 'Looks tasty!', 'get content of the comment');
is($content->{author}->{id}, '1', 'get ID of the commentator');
is($content->{author}->{firstname}, 'Linda', 'get firstname of the commentator');
is($content->{author}->{lastname}, 'Fischer', 'get lastname of the commentator');

my $new_comment = { 
    content => 'Thanks for sharing',
};

$json_data = to_json($new_comment);

$res = $test->request(PUT '/posts/0/comments/0',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);
is($res->code, 400, 'get correct error response code when post ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$res = $test->request(PUT '/posts/1/comments/0',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
);
is($res->code, 400, 'get correct error response code when comment ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find comment ID', 'get error message when comment ID is incorrect');

$res = $test->request(PUT '/posts/1/comments/2',
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when header data type is incorrect');
$content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when data type is incorrect');

$res = $test->request(PUT '/posts/1/comments/2',
    'Content_Type' => 'application/json', 
    'Content' => $json_data
); 
is($res->code, 200, 'get correct response code when data is successfully updated');
$content = from_json($res->content);
is($content->{message}, 'Comment data is updated', 'get response message when data is successfully updated');

$res = $test->request(DELETE '/posts/0/comments/1');
is($res->code, 400, 'get correct error response code when post ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find post ID', 'get error message when post ID is incorrect');

$res = $test->request(DELETE '/posts/1/comments/1');
is($res->code, 400, 'get correct error response code when ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot find comment ID', 'get error message when comment ID is incorrect');

$res = $test->request(DELETE '/posts/1/comments/2');
is($res->code, 204, 'get correct response code');

done_testing();