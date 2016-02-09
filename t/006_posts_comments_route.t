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

my %user = ( username => 'claus123', password => 'rh90mcvcsm9s' );
my $comment =  {
    %user,
    comment  => { 
        content => '1233',
    }
};

my $json_data = to_json($comment);
my $res = $test->request( 
    POST '/posts/1/comments',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password},
    'Content' => $json_data
);
my $content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when type of data is incorrect');

$res = $test->request( 
    POST '/posts/1/comments',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password}, 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when required data is missing');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when required data is missing');

$json_data = to_json($comment);
$res = $test->request( 
    POST '/posts/1/comments',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password}, 
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when data type is incorrect');
$content = from_json($res->content);
like($content->{error}, qr/did not pass type constraint/, 'get error message when data type is incorrect');

$comment->{comment}->{content} = 'Looks tasty!';
$json_data = to_json($comment);
$res = $test->request(
    POST '/posts/1/comments',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password}, 
    'Content' => $json_data
);
is($res->code, 201, 'get correct successful response code');
$content = from_json($res->content);
is($content->{message}, 'Comment data is valid and created', 'get response message when data is valid' );

$res = $test->request(GET '/posts/1/comments');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->[0]->{id}, '1', 'get ID of the comment');
is($content->[0]->{content}, 'What a beautiful country.', 'get content of the comment');
is($content->[0]->{author}, '2', 'get ID of the commentator');
is($content->[0]->{post}, '1', "get ID of the post's blog");

$res = $test->request(GET '/posts/1/comments/3');
is($res->code, 200, 'get correct successful response code');
$content = from_json($res->content);
is($content->{id}, '3', 'get ID of the comment');
is($content->{content}, 'Looks tasty!', 'get content of the comment');
is($content->{author}, '1', 'get ID of the commentator');
is($content->{post}, '1', "get ID of the post's comment");

$comment->{comment}->{content} = 'Thanks for sharing';
$json_data = to_json($comment);
$res = $test->request(PUT '/posts/0/comments/0',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password},
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when post ID is incorrect');
$content = from_json($res->content);
is($content->{error}, 'Cannot update data', 'get error message when post ID is incorrect');

$res = $test->request(PUT '/posts/1/comments/0',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password},
    'Content' => $json_data
);

is($res->code, 400, 'get correct error response code when header data type is incorrect');
$content = from_json($res->content);
is($content->{error}, 'JSON data type is required', 'get error message when data type is incorrect');

$res = $test->request(PUT '/posts/1/comments/3',
    'Content_Type'  => 'application/json',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password}, 
    'Content' => $json_data
); 
is($res->code, 200, 'get correct response code when data is successfully updated');
$content = from_json($res->content);
is($content->{message}, 'Comment data is updated', 'get response message when data is successfully updated');

$json_data = to_json(\%user);
$res = $test->request(DELETE '/posts/1/comments/1',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password}, 
    'Content' => $json_data
);
is($res->code, 204, 'get correct code: blog owner should be able to remove comments');

$res = $test->request(DELETE '/posts/1/comments/2',
    'Authorization' => 'Basic '.$comment->{username} . $comment->{password}, 
    'Content' => $json_data
);
is($res->code, 204, 'get correct response code');

my $user_anna = { username => 'anna456', password => 'soqyovlk' };
$json_data = to_json($user_anna);
$res = $test->request(DELETE '/posts/1/comments/3',
    'Authorization' => 'Basic '.$user_anna->{username} . $user_anna->{password}, 
    'Content' => $json_data
);
$content = from_json($res->content);
is($res->code, 400, 'get correct response code: either author or blog user can remove comment');
is($content->{error}, 'Cannot delete comment', 'get error message when comment ID is incorrect');

END {
    BloggyTest->rollback_data();
}

done_testing();