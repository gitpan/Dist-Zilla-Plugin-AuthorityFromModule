use strict;
use warnings;
package Dist::Zilla::Plugin::AuthorityFromModule;
# git description: 0a6433e
$Dist::Zilla::Plugin::AuthorityFromModule::VERSION = '0.001';
# ABSTRACT: Add metadata to your distribution indicating what module to copy PAUSE permissions from
# KEYWORDS: distribution metadata authority permissions PAUSE users
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::MetaProvider';
use Moose::Util::TypeConstraints 'role_type';
use List::Util 'first';
use Module::Metadata;
use namespace::autoclean;

has module => (
    is => 'ro', isa => 'Str',
);

has _module_name => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $file;
        if (my $module = $self->module)
        {
            $file = first { $self->_package_from_file($_) eq $module } @{ $self->zilla->files };
        }
        else
        {
            $self->log_debug('no module provided; defaulting to the main module');
            $file = $self->zilla->main_module;
        }

        $self->log_debug('extracting the package name from ' . $file->name);
        $self->_package_from_file($file);
    },
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        module => $self->_module_name,
    };

    return $config;
};

sub metadata
{
    my $self = shift;

    my $module = $self->_module_name;

    +{
        # TODO: figure out which field is preferred
        x_authority_from_module => $module,
        x_permissions_from_module => $module,
    };
}

sub _package_from_file
{
    my ($self, $file) = @_;

    # TODO: use Dist::Zilla::Role::ModuleMetadata
    my $fh;
    ($file->can('encoding')
        ? open $fh, sprintf('<encoding(%s)', $file->encoding), \$file->encoded_content
        : open $fh, '<', \$file->content)
            or $self->log_fatal('cannot open handle to ' . $file->name . ' content: ' . $!);

    my $mmd = Module::Metadata->new_from_handle($fh, $file->name);
    ($mmd->packages_inside)[0];
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AuthorityFromModule - Add metadata to your distribution indicating what module to copy PAUSE permissions from

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In your F<dist.ini>:

    [AuthorityFromModule]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that adds the C<x_authority_from_module> and
C<x_permissions_from_module> keys to your distribution metadata, indicating
from which module to copy PAUSE permissions when a module in your distribution
enters the PAUSE index that has not ever previously been indexed.

Note that these fields aren't actually supported yet by PAUSE - that's still
to come (as is figuring out which field name everyone prefers, and ditching
the other one).

=head1 CONFIGURATION OPTIONS

=head2 C<module>

The module name to copy permissions from. It must exist in the distribution,
and exist in the PAUSE permissions table (see
L<peek at PAUSE permissions|https://pause.perl.org/pause/authenquery?ACTION=peek_perms>).

This config is optional; it defaults to the L<main module|Dist::Zilla/main module> in the distribution.

=for Pod::Coverage metadata

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-AuthorityFromModule>
(or L<bug-Dist-Zilla-Plugin-AuthorityFromModule@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-AuthorityFromModule@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::Authority>

=item *

L<peek at PAUSE permissions|https://pause.perl.org/pause/authenquery?ACTION=peek_perms>

=item *

L<What is x_authority?|http://jawnsy.wordpress.com/2011/02/20/what-is-x_authority>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
