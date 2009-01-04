package CGI::Session::Example;

# $Id: Example.pm,v 1.1.1.1 2003/08/02 23:39:34 takezoe Exp $

use strict;
#use diagnostics;
use File::Spec;
use base 'CGI::Application';


# look into CGI::Application for the details of setup() method
sub setup {
  my $self = shift;

  $self->mode_param(\&parsePathInfo);  
  $self->run_modes(
    start => 'default',
    default => 'default',
	'dump-session' => \&dump_session,
	'params'  => \&display_params,
  );

  # setting up default HTTP header. See the details of query() and
  # header_props() methods in CGI::Application manpage
  my $cgi = $self->query();
  my $session = $self->session();
  my $sid_cookie = $cgi->cookie($session->name(), $session->id());
  $self->header_props(-type=>'text/html', -cookie=>$sid_cookie);
}





# this method simply returns CGI::Session object.
sub session {
  my $self = shift;

  if ( defined $self->param("_SESSION") ) {
    return $self->param("_SESSION");
  }
  require CGI::Session;
  my $dsn = $self->param("_SESSION_DSN") || undef;
  my $options = $self->param("_SESSION_OPTIONS") || {Directory=>File::Spec->tmpdir	};
  my $session = CGI::Session->new($dsn, $self->query, $options);  
  unless ( defined $session ) {
    die CGI::Session->error();
  }  
  $self->param(_SESSION => $session);
  return $self->session();
}

# parses PATH_INFO and retrieves a portion which defines a run-mode
# to be executed to display the current page. Refer to CGI::Application
# manpage for details of run-modes and mode_param() method
sub parsePathInfo {
  my $self = shift;

  unless ( defined $ENV{PATH_INFO} ) {
    return;
  }
  my ($cmd) = $ENV{PATH_INFO} =~ m!/cmd/-/([^?]+)!;
  return $cmd;
}


# see CGI::Application manpage
sub teardown {
  my $self = shift;

  my $session = $self->param("_SESSION");
  if ( defined $session ) {
    $session->close();
  }
}





# overriding CGI::Application's load_tmpl() method. It doesn't
# return an HTML object, but the contents of the HTML template
sub load_tmpl {
  my ($self, $filename, $args) = @_;

  # defining a default param set for the templates
  $args ||= {};
  my $cgi     = $self->query();
  my $session = $self->session();
  # making all the %ENV variables available for all the templates
  map { $args->{$_} = $ENV{$_} } keys %ENV;  
  # making session  id available for all the templates
  $args->{ $session->name() } = $session->id;
  # making library's version available for all the templates
  $args->{ VERSION } = $session->version();

  # loading the template
  require HTML::Template;
  my $t = new HTML::Template(filename                    => $filename,
                             associate                   => [$session, $cgi],
                             vanguard_compatibility_mode => 1);
  $t->param(%$args);
  return $t->output();
}



sub urlf {
  my ($self, $cmd) = @_;

  my $sid = $self->session()->id;
  my $name = $self->session()->name;

  return sprintf("$ENV{SCRIPT_NAME}/cmd/-/%s?%s=%s", $cmd, $name, $sid);
}



sub page {
  my ($self, $body) = @_;

  my %params = (
    body        => $body,
    url_default => $self->urlf('default'),
    url_dump    => $self->urlf('dump-session'),
	url_params  => $self->urlf('params'),
  );
  return $self->load_tmpl('page.html', \%params);
}




# Application methods
sub default {
  my $self = shift;

  my $session = $self->session();

  my $body = $self->load_tmpl('welcome.html');
  
  return $self->page($body);
}


sub dump_session {
	my $self = shift;

	my $dmp = $self->session()->dump(undef, 1);
	return $self->page(sprintf "<pre>%s</pre>", $dmp );
}


sub delete_session {
	my $self = shift;

	$self->session()->delete();
	$self->header_type('redirect');
	$self->header_props(-uri=>$ENV{HTTP_REFERER});
}


sub display_params {
	my $self = shift;

	my $session = $self->session();
	my @list = ();
	for my $name ( $session->param() ) {
		$name =~ /^_SESSION_/ and next;
		my $value = $session->param($_);
		push @list, {name => $name, value=>$value};
	}
	my %params = (
		list => \@list,
	);
	my $body = $self->load_tmpl('display-params.html', \%params);
	return $self->page($body);
}
		









1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CGI::Session::Example - Example on using CGI::Session

=head1 DESCRIPTION

STILL NOT COMPLETED. CHECK BACK FOR THE NEXT RELEASE OF CGI::Session.



