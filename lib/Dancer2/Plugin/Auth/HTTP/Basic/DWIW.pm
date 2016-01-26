use strict;
use warnings;

package Dancer2::Plugin::Auth::HTTP::Basic::DWIW;
# ABSTRACT: HTTP Basic authentication plugin for Dancer2 that does what I want.

use MIME::Base64;
use Dancer2::Plugin;

our $CHECK_LOGIN_HANDLER = undef;

register http_basic_auth => sub {
    my ($dsl, $stuff, $sub, @other_stuff) = @_;

    my $realm = plugin_setting->{'realm'} || 'Please login';
    my $content = plugin_setting->{'content'} || 'Access denied';

    return sub {
        eval {
            my $header = $dsl->app->request->header('Authorization') || die \401;

            my ($auth_method, $auth_string) = split(' ', $header);

            $auth_method ne 'Basic' || $auth_string || die \400;

            my ($username, $password) = split(':', $auth_string);

            $username || $password || die \401;

            if (ref($CHECK_LOGIN_HANDLER) eq 'CODE') {
                my $check_result = eval { $CHECK_LOGIN_HANDLER->($username, $password); };

                if($@) {
                    die \500;
                }

                if(!$check_result) {
                    die \401;
                }
            }
        };

        unless ($@) {
            return $sub->($dsl, @other_stuff);
        }
        else {
            my $error_code = ${$@};

            $dsl->header('WWW-Authenticate' => 'Basic realm="' . $realm . '"');
            $dsl->status($error_code);
            $dsl->app->response->content($content);
            return $error_code;
        }
    };
};

register http_basic_auth_login => sub {
    my ($dsl) = @_;
    my $app = $dsl->app;

    my @auth_header = split(' ', $dsl->app->request->header('Authorization'));
    my $auth_string = $auth_header[1];

    my @auth_parts = split(':', $auth_string);

    return @auth_parts;
    },
    {is_global => 0};

register http_basic_auth_set_check_handler => sub {
    my ($dsl, $handler) = @_;
    $CHECK_LOGIN_HANDLER = $handler;
};

register_plugin for_versions => [2];
1;
__END__

=pod

=head1 SYNOPSIS

    package test;

    use Dancer2;
    use Dancer2::Plugin::Auth::HTTP::Basic::DWIW;

    http_basic_auth_set_check_handler sub {
        my ( $user, $pass ) = @_;

        # you probably want to check the user in a better way
        return $user eq 'test' && $pass eq 'bla';
    };

    get '/' => http_basic_auth required => sub {
        my ( $user, $pass ) = http_basic_auth_login;

        return $user;
    };
    1;

=head1 DESCRIPTION

This plugin gives you the option to use HTTP Basic authentication with Dancer2.

You can set a handler to check the supplied credentials. If you don't set a handler, every username/password combination will work.

=head1 CAUTION

Don't ever use HTTP Basic authentication over clear-text connections! Always use HTTPS!

The only case were using HTTP is ok is while developing an application. Don't use HTTP because you think it is ok in corporate networks or something alike, you can always have bad bad people in your network..

=head1 CONFIGURATION

=over 4

=item realm

The realm presented by browsers in the login dialog.

Defaults to "Please login".

=back

=head1 OTHER

This is my first perl module published on CPAN. Please don't hurt me when it is bad and feel free to make suggestions or to fork it on GitHub.

=head1 AUTHOR

Moritz Grosch (LittleFox), C<< <littlefox at fsfe.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<littlefox at fsfe.org>, or through
the web interface at L<https://github.com/LittleFox94/Dancer2-Plugin-Auth-HTTP-Basic-DWIW/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Auth::HTTP::Basic::DWIW

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Moritz Grosch (LittleFox).

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
