doorbot
=======

This repo will eventually be the door robot that controls physical access to our home.

# guardian.py
This will become the code for controlling door access

# report_tag.c
This returns the ID of the tags scanned by the door, and is run as a subprocess of guardian.py

# determine_tag_type.c
This returns the type of tag being scanned.  We only support ISO14443-A tags in our current code, but could in theory support others.  If a new NFC tag comes up, this program will be able to determine whether or not it's a type we support in our code.  If it comes up as type 1, we should already support it.  If it comes up as another type, we don't currently support it, but could in theory.  If it doesn't come up, we might be able to support it, but aren't currently able to scan it well enough to know.
