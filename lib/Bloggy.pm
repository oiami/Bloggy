package Bloggy;
use strict;
use warnings;

use Dancer2;
use JSON::Schema::AsType;
use Data::Dumper;
set serializer => 'JSON';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
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
        status '201';
        return { message => 'Data is valid and created' };
    } else {
        my $explain = $schema->validate($userdata);
        status '400';
        return { error => $explain };
    }

};

get '/users' => sub {
    my $data =  { 
        id        => '1',
        username  => 'Tom123',
        firstname => 'Thomas',
        lastname  => 'Muller',
        email     => 'tommy12@example.com',
        password  => 'PassWOrt' 
    };
    return [$data];
};

get '/users/:id' => sub {
    my $id = param('id');
    
    unless ($id eq '1'){
        status '400';
        return { error => 'Cannot find user' };
    }

    my $data =  { 
        id        => '1',
        username  => 'Tom123',
        firstname => 'Thomas',
        lastname  => 'Muller',
        email     => 'tommy12@example.com',
        password  => 'PassWOrt'
    };
    return $data;
};

put '/users/:id' => sub {
    my $new_userdata = params;

    my $content_type ||= request->header('Content-Type');

    unless ($content_type eq 'application/json'){
        return { error => 'JSON data type is required' };
    }

    unless (param('id') eq '1'){
        status '400';
        return { error => 'Cannot find user' };
    }

    return { message => 'User data is updated' };
};

del '/users/:id' => sub {
    unless (param('id') eq '1') {
        status '400';
        return { error => 'Cannot find user' };
    }
    status '204';
    return {};
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
        status '201';
        return { message => 'Blog data is valid and created' };
    } else {
        my $explain = $schema->validate($blogdata);
        status '400';
        return { error => $explain };
    }
};

get '/blogs' => sub {
    my $data =  {
        id     => '1',
        title  => 'Easy Cooking Menu',
        url    => 'easycookingmenu',
        author => {
            id    => '1',
            firstname => 'Thomas',
            lastname  => 'Muller',
            email     => 'tommy12@example.com'
        }
    };
    return [$data];
};

get '/blogs/:id' => sub {
    my $id = param('id');

    unless ($id eq '1'){
        status '400';
        return { error => 'Cannot find blog ID' };
    }

    my $data =  {
        id     => '1',
        title  => 'Easy Cooking Menu',
        url    => 'easycookingmenu',
        author => {
            id    => '1',
            firstname => 'Thomas',
            lastname  => 'Muller',
            email     => 'tommy12@example.com'
        }
    };
    return $data;
};

put '/blogs/:id' => sub {
    my $new_userdata = params;

    my $content_type = request->header('Content-Type') || '';

    unless ($content_type eq 'application/json'){
        status '400';
        return { error => 'JSON data type is required' };
    }

    unless (param('id') eq '1'){
        status '400';
        return { error => 'Cannot find blog ID' };
    }

    return { message => 'Blog data is updated' };
};

del '/blogs/:id' => sub {
    unless (param('id') eq '1') {
        status '400';
        return { error => 'Cannot find blog ID' };
    }
    status '204';
    return {};
};


true;