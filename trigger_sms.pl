# Copyright (c) 2012 Tim Heckman <timothy.heckman@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
####
# About
# This script was designed to use my Twilio Notifier Python script.  This irssi
# script handles incoming hilights/messages
#
####
# User editable options
#
# Set the location of Python, and where the Twilio Notifier script live
our $PYTHON_PATH = '/usr/bin/env python';
our $SMS_PATH = $ENV{HOME} . '/twilio-sms/twsms.py';
#
# This regex exists to remove the nickname portion from channel hilights
# you may ened to alter this depending on your theme.  However, this was
# build to work on the default theme
our $PUBMSG_REGEX_PRENICK = '^.*?';
our $PUBMSG_REGEX_POSTNICK = '.*?\s';
#
# End user editable options
# Do not edit beyond this point
####

use strict;
use Irssi;
use File::Basename;

our $VERSION = '0.1';
our %IRSSI = (
	authors => 'Tim Heckman',
	contact => 'timothy.heckman@gmail.com',
	url => 'FIXME',
	name => 'trigger_sms',
	description => 
		"Interfaces with twilio-notifier Python script to send you " .
		"SMS messages while marked as away." .
		"Requires the twilio-notifier Python script on your system.",
	license => 'MIT',
);
our $user_away = 0;
our $sms_reset = 0;

sub call_notifier {
	my ($reset, $force, $message) = @_;
	my $args = '';
	my ($filename, $directory) = fileparse($SMS_PATH);
	$args = $args . ' --reset' if ($reset != 0);
	$args = $args . ' --force' if ($force != 0);
	$args = $args . ' --message ' . qq/$message/ if (length($message) > 0);
	chdir $directory;

	system($PYTHON_PATH . ' ' . $SMS_PATH . $args)
}

sub check_user_away {
	foreach my $server (Irssi::servers()) {
		if ($server->{usermode_away}) {
			if (!$user_away && !$sms_reset) {
				call_notifier(1, 0, '');
				$user_away = 1;
				$sms_reset = 1;
			}
		}
		else {
			$user_away = 0 if ($user_away);
		}
	}
	$sms_reset = 0;
}

sub privmsg_handler {
	my ($server, $message, $nick, $address) = @_;
	if ($server->{usermode_away}) {
		my $body = '[' . $server->{chatnet} . '/' . $nick . '] ' . $message;
		call_notifier(0, 0, $body);
	}
}

sub pubmsg_handler {
	my ($dest, $text, $stripped) = @_;
	if ($user_away && ($dest->{level} & MSGLEVEL_HILIGHT) && ($dest->{level} & MSGLEVEL_PUBLIC)) {
		my $chatnet = $dest->{server}->{chatnet};
		my $target = $dest->{target};
		my $nick = Irssi::parse_special('$;');
		my $message = $stripped;
		$message =~ s/($PUBMSG_REGEX_PRENICK)($nick)($PUBMSG_REGEX_POSTNICK)//;
		my $body = '[' . $chatnet . '/' . $target . '/' . $nick . '] ' . $message;
		call_notifier(0, 0, $body);
    }
}

Irssi::timeout_add(5*1000, 'check_user_away', '');
Irssi::signal_add_last("message private", "privmsg_handler");
Irssi::signal_add_last("print text", "pubmsg_handler")
