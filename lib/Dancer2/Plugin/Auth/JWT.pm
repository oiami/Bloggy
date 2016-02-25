package Dancer2::Plugin::Auth::JWT;

use strict;
use warnings;

# ABSTRACT: JSON Web Token authentication plugin for Dancer2

use Dancer2::Plugin;
use JSON::WebToken;
use Data::Dumper;
use DateTime;
use Try::Tiny;

register generate_token => sub {
    my ($dsl, $args) = @_;

    my $dt = DateTime->now()->add( days => 1 );
    $dt = $dt->epoch;
    $args->{exp} = $dt;

    my $token = JSON::WebToken->encode( $args, 'mysecret');

    return $token;
};

register authorize_user => sub {
    my $dsl = shift;
    
    my $authorization = $dsl->request->headers->{'authorization'};
    my ($auth_method, $token) = split(' ', $authorization);
    
    if( $auth_method ne 'Bearer' ){
        $dsl->status('401');
        $dsl->halt({ error => 'Access Denied' });
    }
    
    my $secret = $dsl->request->param('secret');

    try {
        my $claims = JSON::WebToken->decode( $token, $secret );
        my $now = DateTime->now()->add(days => 2)->epoch;
        my $exp = $claims->{exp};

        if($now <= $exp){
            $dsl->status('400');
            $dsl->halt({ error => 'Token Expired' });
            return 0;
        }
        return $claims; 
    } 
    catch {
        $dsl->status(401);
        $dsl->halt({ error => "Access Denied" });
    };    


};

register_plugin;

1;

__END__