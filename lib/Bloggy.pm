package Bloggy;
use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::Database;
use JSON::Schema::AsType;
use Data::Dumper;
set serializer => 'JSON';

our $VERSION = '0.1';

# get '/' => sub {
#     template 'index';
# };

post '/users' => sub {
    my $userdata = params;
    my $content_type = request->header('Content-Type');

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }
    
    my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            username  => { type => 'string' },
            firstname => { type => 'string' },
            lastname  => { type => 'string' },
            email     => { type => 'string' },
            password  => { type => 'string' }
        },
        required => ['username', 'firstname', 'lastname', 'email', 'password']
    });

    if ($schema->check($userdata)){
        database->quick_insert('user', $userdata);
        status '201';
        return { message => 'Data is valid and created' };
    } else {
        my $explain = $schema->validate($userdata);
        status '400';
        return { error => $explain };
    }

};

get '/users' => sub {
    
    my @users;
    @users = database->quick_select('user', {});

    return \@users;
};

get '/users/:id' => sub {
    my $id = param('id');

    my $user =  database->quick_select('user', { id => $id });

    unless ($user){
        status '400';
        return { error => 'Cannot find user' };
    }

    return $user;
};

put '/users/:id' => sub {
    my $new_userdata = param('user');

    my $content_type = request->header('Content-Type') || "";

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    my $result = database->quick_update('user', { id => param('id') }, $new_userdata);

    if ( $result == 1 ){
        return { message => 'User data is updated' };
    } else {
        status '400';
        return { error => 'Cannot find user' };
    }


};

del '/users/:id' => sub {

    my $result = database->quick_delete('user', { id => param('id') });

    if ($result == 1){
        status '204';
        return {};
    }
    else {
        status '400';
        return { error => 'Cannot find user' };
    }

};

#=================Blog========================

post '/blogs' => sub {
    my $blogdata = params;
    my $content_type = request->header('Content-Type');

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            title  => { type => 'string' },
            url    => { type => 'string' },
            author => { type => 'integer' },
        },
        required => ['title', 'url', 'author']
    });

    if ($schema->check($blogdata)){
        database->quick_insert('blog', $blogdata);
        status '201';
        return { message => 'Blog data is valid and created' };
    } else {
        my $explain = $schema->validate($blogdata);
        status '400';
        return { error => $explain };
    }
};

get '/blogs' => sub {

    my @blogs;
    @blogs = database->quick_select('blog', {});

    return \@blogs;
};

get '/blogs/:id' => sub {
    my $id = param('id');

    my $data = database->quick_select('blog', { id => $id });
    unless ($data){
        status '400';
        return { error => 'Cannot find blog ID' };
    }

    return $data;
};

put '/blogs/:id' => sub {
    my $new_blogdata = params;

    my $content_type = request->header('Content-Type') || '';

    unless ($content_type eq 'application/json'){
        status '400';
        return { error => 'JSON data type is required' };
    }

    my $result = database->quick_update('blog', { id => param('id') }, $new_blogdata);
   
    if( $result == 1 ){
        return { message => 'Blog data is updated' };
    }
    else {
        status '400';
        return { error => 'Cannot find blog ID' };
    }

};

del '/blogs/:id' => sub {

    my $result = database->quick_delete('blog', { id => param('id') });

    if( $result == 1 ){
        status '204';
        return {};
    }
    else {
        status '400';
        return { error => 'Cannot find blog ID' };
    }

};

#====================Posts=======================================

post '/blogs/:blog/posts' => sub {
    my $postdata = params;

    my $content_type = request->header('Content-Type');

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            title   => { type => 'string' },
            content => { type => 'string' }
        },
        required => ['title', 'content']
    });

    if ($schema->check($postdata)){
        my $res = database->quick_insert('post', $postdata);
        status '201';
        return { message => 'Post data is valid and created' };
    } else {
        my $explain = $schema->validate($postdata);
        status '400';
        return { error => $explain };
    }
};

get '/blogs/:blogid/posts' => sub {
    my $blog_id = param('blogid');

    my @posts;
    @posts = database->quick_select('post', { blog => $blog_id }); 

    return \@posts;
};

get '/blogs/:blog/posts/:id' => sub {
    my $params = params;
    
    my $data = database->quick_select('post', $params);

    return $data;
};

put '/blogs/:blog/posts/:id' => sub {
    my $new_postdata = params;

    my $content_type = request->header('Content-Type') || '';

    unless ($content_type eq 'application/json'){
        status '400';
        return { error => 'JSON data type is required' };
    }

    my $blog_id = param('blog');
    my $post_id = param('id');

    my $result = database->quick_update('post', 
        { id => $post_id, blog => $blog_id },
        $new_postdata) || 0;
    
    if ($result == 1) {
        return { message => 'Post data is updated' };
    }
    else {
        status '400';
        return { error => 'Cannot update data' };
    }
};

del '/blogs/:blog/posts/:id' => sub {
    my $blog_id = param('blog');
    my $id      = param('id');

    my $result = database->quick_delete('post', {id => $id, blog => $blog_id});
   
    if ($result == 1){
        status '204';
        return {};
    }
    else {
        status '400';
        return { error => 'Cannot delete post' };
    }
   
};

#=================Comments=================================

post '/posts/:postid/comments' => sub {
    my $postdata = params;

    my $content_type = request->header('Content-Type');

    unless (param('postid') eq '1'){
        status '400';
        return { error => 'Cannot find post ID' };
    }

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            content => { type => 'string' },
            author  => { type => 'integer' }
        },
        required => ['content', 'author']
    });

    if ($schema->check($postdata)){
        status '201';
        return { message => 'Comment data is valid and created' };
    } else {
        my $explain = $schema->validate($postdata);
        status '400';
        return { error => $explain };
    }
};

get '/posts/:postid/comments' => sub {

    unless (param('postid') eq '1'){
        status '400';
        return { error => 'Cannot find post ID' };
    }

    my $data =  {
        id      => '1',
        content => 'Looks tasty!',
        author  => {
            id  => '1',
            firstname => 'Linda',
            lastname  => 'Fischer'
        }
    };
    return [$data];
};

get '/posts/:postid/comments/:commentid' => sub {

    unless (param('postid') eq '1'){
        status '400';
        return { error => 'Cannot find post ID' };
    }

    unless (param('commentid') eq '2') {
        status '400';
        return { error => 'Cannot find comment ID' };
    }

    my $data =  {
        id      => '2',
        content => 'Looks tasty!',
        author  => {
            id  => '1',
            firstname => 'Linda',
            lastname  => 'Fischer'
        }
    };
    return $data;
};

put '/posts/:postid/comments/:commentid' => sub {
    my $new_comment = params;

    my $content_type = request->header('Content-Type') || '';

    unless ($content_type eq 'application/json'){
        status '400';
        return { error => 'JSON data type is required' };
    }

    unless (param('postid') eq '1'){
        status '400';
        return { error => 'Cannot find post ID' };
    }

    unless (param('commentid') eq '2'){
        status '400';
        return { error => 'Cannot find comment ID' };
    }

    return { message => 'Comment data is updated' };
};

del '/posts/:postid/comments/:commentid' => sub {
    unless (param('postid') eq '1'){
        status '400';
        return { error => 'Cannot find post ID' };
    }

    unless (param('commentid') eq '2'){
        status '400';
        return { error => 'Cannot find comment ID' };
    }

    status '204';
    return {};
};

true;