Irssi SMS
=========

This is an irssi script to interface with the [Twilio SMS](https://github.com/theckman/twilio-sms) script.  This script will cause an SMS to be sent on hilight or PM when you are marked away.  The Twilio SMS script will determine whether the SMS message should be sent or not to avoid excessive Twilio charges.

Installation
------------

Download the script itself to your irssi script folder.  This is usually `~/.irssi/scripts`.  Once that's done, you'll want to open the file in your editor and set the path to the Twilio SMS script:

	####
	# User editable options
	#
	# Set the location of Python, and where the Twilio Notifier script live
	our $PYTHON_PATH = '/usr/bin/env python';
	our $SMS_PATH = $ENV{HOME} . '/twilio-sms/twsms.py';

Load
----

Load the script, and you're good to go: `/script load trigger_sms`.  Once you go away, notifications will be sent to the script you specified.
