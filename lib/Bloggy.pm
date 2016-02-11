package Bloggy;
use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;
use JSON::Schema::AsType;
use Data::Dumper;
use OAuth::Lite::Token;

set serializer => 'JSON';

our $VERSION = '0.1';

# get '/' => sub {
#     template 'index';
# };

get '/auth/token' => sub {

    my $result = database->quick_select('user', {
        username => param('username'), 
        password => param('password') 
    });

    if( $result ){
       my $token = OAuth::Lite::Token->new_random;
       return { token => $token->token, secret => $token->secret };
    } else {
        return({ error => 'User is unautorized' });
    }
};

http_basic_auth_set_check_handler sub {
    my $username = param('username') || "";
    my $password = param('password') || "";

    my $result = database->quick_select('user', {
        username => $username, 
        password => $password 
    });

    if ( $result ){
        session userid => $result->{id};
        return 1;
    } else {
        status '401';
        halt({ error => 'Access denied'});
    }
};

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

put '/users/:id' => http_basic_auth required => sub {
    my $new_userdata = param('user');
    my $userid = session('userid');

    my $content_type = request->header('Content-Type') || "";

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    #user id from data should match user retrieve from data base
    unless ( param('id') eq $userid ) {
        status '400';
        return { error => 'Cannot find user' };
    }

    my $result = database->quick_update('user', { id => param('id') }, $new_userdata);

    if ( $result == 1 ){
        return { message => 'User data is updated' };
    } else {
        status '400';
        return { error => 'Cannot update user' };
    }
};

del '/users/:id' => http_basic_auth required => sub {

    my $result = database->quick_delete('user', { id => param('id') });
    my $userid = session('userid');
    #user id from data should match user retrieve from data base
    unless ( param('id') eq $userid ) {
        status '400';
        return { error => 'Cannot find user' };
    }

    if ($result == 1){
        status '204';
        return {};
    }
    else {
        status '400';
        return { error => 'Cannot delete user' };
    }

};

#=================Blog========================

post '/blogs' => http_basic_auth required => sub {
    my $blogdata = param('blog');
    my $content_type = request->header('Content-Type');
    my $author = session('userid');

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    $blogdata->{author} = $author;

    my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            title  => { type => 'string' },
            url    => { type => 'string' },
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

put '/blogs/:id' => http_basic_auth required => sub {
    my $new_blogdata = param('blog');

    my $content_type = request->header('Content-Type') || '';

    unless ($content_type eq 'application/json'){
        status '400';
        return { error => 'JSON data type is required' };
    }

    #user should be owner of the blog in order to edit
    my $author = session('userid');

    my $result = database->quick_update('blog', { 
        id     => param('id'), 
        author => $author 
    }, $new_blogdata);
   
    if( $result == 1 ){
        return { message => 'Blog data is updated' };
    }
    else {
        status '400';
        return { error => 'Cannot find blog ID' };
    }

};

del '/blogs/:id' => http_basic_auth required => sub {

    my $author = session('userid');

    my $result = database->quick_delete('blog', 
        { id => param('id'), author => $author }
    );

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

post '/blogs/:blogid/posts' => http_basic_auth required => sub {
    my $postdata = param('post');

    my $content_type = request->header('Content-Type');

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    my $author = session('userid');
    my $blog = database->quick_select('blog', { id => param('blogid'), author => $author });
    $postdata->{blog} = $blog->{id};

    my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            title   => { type => 'string' },
            content => { type => 'string' },
            blog    => { type => 'integer' },
        },
        required => ['title', 'content', 'blog']
    });

    if ($schema->check($postdata)){
        database->quick_insert('post', $postdata);
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

get '/blogs/:blogid/posts/:id' => sub {
    my $params = params;
    
    my $data = database->quick_select('post', { blog => param('blogid'), id => param('id') });

    unless ($data){
        status '400';
        return { error => 'Cannot find post ID' };
    }

    return $data;
};

put '/blogs/:blogid/posts/:id' => http_basic_auth required => sub {
    my $new_postdata = param('post');

    my $content_type = request->header('Content-Type') || '';

    unless ($content_type eq 'application/json'){
        status '400';
        return { error => 'JSON data type is required' };
    }

    my $author = session('userid');
    my $blog = database->quick_select('blog', { id => param('blogid'), author => $author });
    
    my $blog_id = $blog->{id};
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

del '/blogs/:blogid/posts/:id' => http_basic_auth required => sub {
    my $author = session('userid');

    my $blog = database->quick_select('blog', { id => param('blogid'), author => $author });
    my $blog_id = $blog->{id};

    my $result = database->quick_delete('post', { id => param('id'), blog => $blog_id });
   
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

post '/posts/:postid/comments' => http_basic_auth required => sub {
    my $commentdata = param('comment');

    $commentdata->{author} = session('userid');
    $commentdata->{post}   = param('postid');

    my $content_type = request->header('Content-Type');

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            content => { type => 'string' },
            author  => { type => 'integer' },
            post    => { type => 'integer' },
        },
        required => ['content', 'author', 'post']
    });

    if ($schema->check($commentdata)){
        my $result = database->quick_insert('comment', $commentdata);
        if ($result == 1){
            status '201';
            return { message => 'Comment data is valid and created' };
        }
    } else {
        my $explain = $schema->validate($commentdata);
        status '400';
        return { error => $explain };
    }
};

get '/posts/:post/comments' => sub {
    my $post_id = param('post');
    my @posts;
    @posts = database->quick_select('comment', { post => $post_id });
    return \@posts;
};

get '/posts/:post/comments/:id' => sub {
    my $params = params;

    my $data = database->quick_select('comment', $params);

    return $data;
};

put '/posts/:post/comments/:id' => http_basic_auth required => sub {
    my $new_comment = param('comment');

    my $post_id    = param('post');
    my $comment_id = param('id');
    my $author     = session('userid');

    my $content_type = request->header('Content-Type') || "";

    unless ($content_type eq 'application/json'){
        status '400';
        return { error => 'JSON data type is required' };
    }

    my $result = database->quick_update('comment',
        { id => $comment_id, post => $post_id, author => $author },
        $new_comment) || 0;

    if ($result == 1) {
        return { message => 'Comment data is updated' };
    }
    else {
        status '400';
        return { error => 'Cannot update data' };
    }

};

del '/posts/:post/comments/:id' => http_basic_auth required => sub {
    my $post_id = param('post');
    my $id      = param('id');
    my $author  = session('userid');
    my $deleted = 0;

    my $sth = database->prepare(
        'SELECT * FROM blog JOIN post on blog.id=post.blog WHERE blog.author = ? AND post.id = ?'
    );
    $sth->execute($author, $post_id);
    my $result = $sth->fetchrow_hashref;

    if ( $result ){
        $deleted = database->quick_delete('comment',
            {id => $id, post => $post_id }
        );
    } else {
        $deleted = database->quick_delete('comment',
            {id => $id, post => $post_id, author => $author }
        );
    }

    if ($deleted == 1){
        status '204';
        return {};
    }
    else {
        status '400';
        return { error => 'Cannot delete comment' };
    }
   
};

true;