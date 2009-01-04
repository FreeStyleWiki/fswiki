package CGI::Session::ID::SHA1;

# $Id: SHA1.pm,v 1.1.1.1 2003/08/02 23:39:35 takezoe Exp $

use strict;
use Digest::SHA1;
use vars qw($VERSION);

($VERSION) = '$Revision: 1.1.1.1 $' =~ m/Revision:\s*(\S+)/;

sub generate_id {
    my $self = shift;

    my $sha1 = new Digest::SHA1();
    $sha1->add($$ , time() , rand(9999) );

    return $sha1->hexdigest();
}


1;

=pod

=head1 NAME

CGI::Session::ID::SHA1 - SHA1 session id generator

=head1 SYNOPSIS

    use CGI::Session;

    $session = new CGI::Session("id:SHA1", undef);

=head1 DESCRIPTION

CGI::Session::ID::SHA1 is to generate SHA1 encoded hexidecimal random ids
using Digest::SHA1. The method does not require any arguments. 

=head1 COPYRIGHT

Copyright (C) 2002 Sherzod Ruzmetov. All rights reserved.

This library is free software. You can modify and distribute it under the same terms as Perl itself.

=head1 AUTHOR

Sherzod Ruzmetov <sherzodr@cpan.org>

Feedbacks, suggestions and patches are welcome.

=head1 SEE ALSO

=over 4

=item *

L<Incr|CGI::Session::ID::Incr> - Auto Incremental ID generator

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual

=item *

L<CGI::Session::CookBook|CGI::Session::CookBook> - practical solutions for real life problems

=item *

B<RFC 2965> - "HTTP State Management Mechanism" found at ftp://ftp.isi.edu/in-notes/rfc2965.txt

=item *

L<CGI|CGI> - standard CGI library

=item *

L<Apache::Session|Apache::Session> - another fine alternative to CGI::Session

=back

=cut
