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
# Set the location of Python, where the Twilio Notifier script lives,
# the twilio-sms config file you want to use, and the location of your
# irssi configuration file
our $PYTHON_PATH = '/usr/bin/env python';
our $SMS_PATH = $ENV{HOME} . '/twilio-sms/twsms.py';
our $TWSMS_CONFIG = 'twilio-sms.json';
our $IRSSI_CONFIG = $ENV{HOME} . '/.irssi/config';
#
# End user editable options
# Do not edit beyond this point
####

use strict;
use Irssi;
use File::Basename;
use Config::Irssi::Parser;

my $cfp = new Config::Irssi::Parser;

open(my $cfh, '<', $IRSSI_CONFIG) or die("Unable to locate irssi config file ($IRSSI_CONFIG), or something.  What'd you break?");

our $cfhash = $cfp->parse($cfh);

our $VERSION = '0.3';
our %IRSSI = (
	authors => 'Tim Heckman',
	contact => 'timothy.heckman@gmail.com',
	url => 'https://github.com/theckman/trigger-sms',
	name => 'trigger_sms',
	description => 
		"Interfaces with twilio-notifier Python script to send you " .
		"SMS messages while marked as away." .
		"Requires the twilio-notifier Python script on your system.",
	license => 'MIT',
);
our $sms_reset = 0;

sub call_notifier {
	my ($reset, $force, $message) = @_;
	my $args = '';
	my ($filename, $directory) = fileparse($SMS_PATH);
	$message =~ s/\"/\\\"/g if (length($message) > 0);
	$args .= ' --reset' if ($reset != 0);
	$args .= ' --force' if ($force != 0);
	$args .= ' --config "' . $TWSMS_CONFIG . '"';
	$args .= ' --message "' . $message . '"' if (length($message) > 0);
	chdir $directory;

	system($PYTHON_PATH . ' ' . $SMS_PATH . $args)
}

sub check_user_away {
	foreach my $server (Irssi::servers()) {
		if ($server->{usermode_away} && !$sms_reset) {
			call_notifier(1, 0, '');
			$sms_reset = 1;
			return 0;
		}
		elsif ($server->{usermode_away} && $sms_reset) {
			return 0;
		}
		else {
			$sms_reset = 0;
		}
	}
}

sub message_private_handler {
	my ($server, $message, $nick, $address) = @_;
	if ($server->{usermode_away}) {
		my $body = '[' . $server->{chatnet} . '/' . $nick . '] ' . $message;
		call_notifier(0, 0, $body);
	}
}

sub message_public_handler {
	my ($server, $message, $nick, $address, $target) = @_;
	if ($server->{usermode_away} && is_hilight($message)) {
		my $body = '[' . $server->{chatnet} . '/' . $target . '/' . $nick . ']' . $message;
		call_notifier(0, 0, $body);
	}
}

sub message_irc_action_handler {
	my ($server, $message, $nick, $addres, $target) = @_;
	if ($server->{usermode_away} && is_hilight($message)) {
		my $body = '[' . $server->{chatnet} . '/' . $target . ']' . '* ' . $nick . ' ' . $message;
		call_notifier(0, 0, $body);
	}
}

sub is_hilight{
	my $message = shift;
	foreach my $hilite(@{$cfhash->{'hilights'}}) {
		if ($message =~ m/^$hilite->{'text'}./) {
			return 1;
		}
		elsif ($message =~ m/^.$hilite->{'text'}./) { # yes yes, I know.  IRC is not twitter...
			return 1;
		}
		elsif ($message =~ m/\s$hilite->{'text'}\s/ && ($hilite->{'fullword'} eq "yes" || $hilite->{'fullword'} eq "true")) {
			return 1;
		}
		elsif ($message =~ m/$hilite->{'text'}/ && ($hilite->{'fullword'} eq "no" || $hilite->{'fullword'} eq "false")) {
			return 1;
		}
	}
	return 0;
}

Irssi::timeout_add(5*1000, 'check_user_away', '');
Irssi::signal_add_last("message private", "message_private_handler");
Irssi::signal_add_last("message public", "message_public_handler");
Irssi::signal_add_last("message irc action", "message_irc_action_handler");
