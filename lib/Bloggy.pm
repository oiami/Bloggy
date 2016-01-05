package Bloggy;
use strict;
use warnings;

use Dancer2;
use JSON::Schema::AsType;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

post '/users' => sub {
    my $userdata = params;

    # my $userdata = {
    #     username  => 'Tom123',
    #     firstname => 'Thomas',
    #     lastname  => 'Muller',
    #     email     => 'tommy12@example.com',
    #     password  => 'PassWort'
    # };

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
        return 'valid!!!!';
    } else {
        my $explain = $schema->validate($userdata);
        status '400';
        return $explain;
    }

};

true;