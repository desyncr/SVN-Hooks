use strict;
use warnings;

package SVN::Hooks::CheckLog;
# ABSTRACT: Check log messages in commits.

use Carp;
use Data::Util qw(:check);
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'CHECK_LOG';
our @EXPORT = ($HOOK);

=for Pod::Coverage pre_commit

=head1 SYNOPSIS

This SVN::Hooks plugin allows one to check if the log message in a
'svn commit' conforms to a Regexp.

It's active in the C<pre-commit> hook.

It's configured by the following directive.

=head2 CHECK_LOG(REGEXP[, MESSAGE])

The REGEXP argument must be a qr/quoted regexp/ which must match the
commit log messages. If it doesn't, then the commit is aborted.

The MESSAGE argument is an optional error message that is shown to the
user in case the check fails.

	CHECK_LOG(qr/.../ => "The log message cannot be empty!");
	CHECK_LOG(qr/^\[(prj1|prj2|prj3)\]/
                  => "The log message must start with a project tag.");

=cut

my @checks;

sub CHECK_LOG {
    my ($regexp, $error_message) = @_;

    is_rx($regexp) or croak "$HOOK: first argument must be a qr/Regexp/\n";
    ! defined $error_message || is_string($error_message)
	or croak "$HOOK: second argument must be undefined, or a STRING\n";

    push @checks, {
	regexp => $regexp,
	error  => $error_message || "log message must match $regexp.",
    };

    PRE_COMMIT(\&pre_commit);

    return 1;
}

sub pre_commit {
    my ($svnlook) = @_;

    my $log = $svnlook->log_msg();

    foreach my $check (@checks) {
	$log =~ $check->{regexp}
	    or croak "$HOOK: $check->{error}";
    }

    return;
}

1; # End of SVN::Hooks::CheckLog
