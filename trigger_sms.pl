# Copyright (c) 2012-2013 Tim Heckman <tim@timheckman.net>
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
# the twilio-sms config file you want to use.
our @SYSCALL = qw(/usr/bin/env python);
push @SYSCALL, $ENV{HOME} . '/twilio-sms/twsms.py';
our $TWSMS_CONFIG = 'twilio-sms.json';
#
# End user editable options
# Do not edit beyond this point
####

use warnings;
use strict;
use Irssi;

our $VERSION = '0.5';
our %IRSSI = (
    authors => 'Tim Heckman',
    contact => 'tim@timheckman.net',
    url => 'https://github.com/theckman/trigger-sms',
    name => 'trigger_sms',
    description =>
        "Interfaces with twilio-notifier Python script to send you " .
        "SMS messages while marked as away." .
        "Requires the twilio-notifier Python script on your system.",
    license => 'MIT',
);
my $sms_reset = 0;
my %message_data = ();
my $levels = MSGLEVEL_HILIGHT|MSGLEVEL_MSGS;

sub call_notifier {
    my ($reset, $force, $message) = @_;
    my @sysArray = @SYSCALL;
    push @sysArray, qw(--reset) if ($reset != 0);
    push @sysArray, qw(--force) if ($force != 0);
    push @sysArray, qw(--config);
    push @sysArray, $TWSMS_CONFIG;
    if (length($message) > 0) {
        $message =~ s/`/'/g; # backticks show up as '?'
        push @sysArray, qw(--message);
        push @sysArray, "$message";
    }

    system(@sysArray);
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

sub message_private {
    my ($server, $message, $nick, $address) = @_;
    if ($server->{usermode_away}) {
        $message_data{chatnet} = $server->{chatnet} if (defined $server->{chatnet} && length $server->{chatnet});
        $message_data{privmsg} = 1;
        $message_data{nick} = $nick;
        $message_data{message} = $message;
    }
}

sub message_public {
    my ($server, $message, $nick, $address, $target) = @_;
    if ($server->{usermode_away}) {
        $message_data{chatnet} = $server->{chatnet} if (defined $server->{chatnet} && length $server->{chatnet});
        $message_data{target} = $target;
        $message_data{nick} = $nick;
        $message_data{message} = $message;
    }
}

sub message_irc_action {
    my ($server, $message, $nick, $address, $target) = @_;
    if ($server->{usermode_away}) {
        $message_data{chatnet} = $server->{chatnet} if (defined $server->{chatnet} && length $server->{chatnet});
        $message_data{privmsg} = 1 if ($server->{nick} eq $target);
        $message_data{action} = 1;
        $message_data{target} = $target;
        $message_data{nick} = $nick;
        $message_data{message} = $message;
    }
}

sub print_text {
    my ($dest, $text, $stripped) = @_;
    if (scalar keys %message_data > 0) {
        if ($dest->{level} & $levels) {
            my $body = '[';
            $body .= "$message_data{chatnet}" if (exists $message_data{chatnet});
            if (!exists $message_data{privmsg}) {
                $body .= "/" if (length $body > 1);
                $body .= "$message_data{target}";
            }
            else {
                $body .= "/" if (length $body > 1);
                $body .= "PM";
            }
            if (exists $message_data{action}) {
                $body .= "]*$message_data{nick} $message_data{message}";
            }
            else {
                $body .= "/" if (length $body > 1);
                $body .= "$message_data{nick}]$message_data{message}";
            }
            %message_data = ();
            call_notifier(0, 0, $body);
        }
    }
}

Irssi::timeout_add(5*1000, 'check_user_away', '');
Irssi::signal_add_last("message private", "message_private");
Irssi::signal_add_last("message public", "message_public");
Irssi::signal_add_last("message irc action", "message_irc_action");
Irssi::signal_add_last("print text", "print_text");
