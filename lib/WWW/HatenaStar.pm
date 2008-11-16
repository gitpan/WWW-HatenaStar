package WWW::HatenaStar;

use strict;
use 5.8.1;
our $VERSION = '0.01';

use WWW::HatenaLogin;
use URI;
use JSON::Syck 'Load';
use Carp qw(croak);
use Scalar::Util qw(blessed);

sub new {
    my ($class, $args) = @_;
    my $self = bless {
        %$args,
    }, $class;

    $self;
}

sub _login {
    my $self = shift;

    my $session = WWW::HatenaLogin->new({
        username => $self->{config}->{username},
        password => $self->{config}->{password},
        mech_opt => {
            timeout => $self->{config}->{timeout} || 30,
        },
    });

    $self->{session} = $session;
}

sub stars {
    my ($self, $data) = @_;

    if (blessed($data) && $data->isa('URI')) {
        $data = { uri => $data->as_string };
    } elsif (ref($data) ne 'HASH') {
        $data = { uri => $data };
    }

    my $count = exists($data->{count}) ? $data->{count} : 1;

    $self->_entries_json($data->{uri});
    while ($count--) {
        $self->_star_add_json($data);
    }
}

sub _entries_json {
    my ($self, $url) = @_;
    $self->_login unless $self->{_logged_in}++;

    my $uri = URI->new("http://s.hatena.ne.jp/entries.json");
    $uri->query_form(
        uri => $url,
    );
    $self->{session}->mech->get($uri->as_string);
    $self->{$url}->{rks} = Load($self->{session}->mech->content)->{rks};
    croak "cannot get rks for $url" unless $self->{$url}->{rks};

    $self;
}

sub _star_add_json {
    my ($self, $data) = @_;
    $self->_login unless $self->{_logged_in}++;

    my $url = $data->{uri};
    my $uri = URI->new("http://s.hatena.ne.jp/star.add.json");
    my %form;

    for my $key (qw(uri title quote location)) {
        $form{$key} = defined($data->{$key}) ? $data->{$key} : "";
    }
    $form{location} ||= $data->{uri};
    $form{rks} = $self->{$url}->{rks};
    $uri->query_form(\%form);

    $self->{session}->mech->get($uri->as_string);

    my $res = Load($self->{session}->mech->content);
    croak $res->{errors} if defined($res->{errors});
    $self->{$url}->{res} = $res;

    $self;
}

1;
__END__

=head1 NAME

WWW::HatenaStar - perl interface to Hatena::Star

=head1 SYNOPSIS

  use WWW::HatenaStar;

  my $conf = { username => "woremacx", password => "vagina" };
  my $star = WWW::HatenaStar->new({ config => $conf });

  my $uri = "http://blog.woremacx.com/2008/01/shut-the-fuck-up-and-just-be-chaos.html";
  # you will have 5 stars
  $star->stars({ uri => $uri, count => 5 });

=head1 DESCRIPTION

WWW::HatenaStar is perl interface to Hatena::Star.

=head1 AUTHOR

woremacx E<lt>woremacx at cpan dot orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * Hatena::Star (Japanese)

L<http://s.hatena.ne.jp/>

=item * L<WWW::HatenaLogin>

=cut
