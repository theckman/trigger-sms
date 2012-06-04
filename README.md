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

License
-------
Copyright (c) 2012 Tim Heckman <<timothy.heckman@gmail.com>>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
