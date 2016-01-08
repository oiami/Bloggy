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
        return { message => 'Data is valid' };
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

get 'users/:id' => sub {
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

true;