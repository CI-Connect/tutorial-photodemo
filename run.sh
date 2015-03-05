#!/bin/bash

# This is a simple job wrapper to unpack the python virtual environment
# and run the 'luminance2' program, saving output into a results file.

# Unpack the pillow.tar virtualenv which was bundled with the job
tar xf pillow.tar

# Update it to run on this worker
python pillow/bin/virtualenv.py pillow

# Activate the virtualenv to get access to its local modules
source pillow/bin/activate

# N.B. It's important to run "python scriptname" here so that we get the
# python interpreter packaged by the virtualenv instead of the one installed
# on the target system.
#
# Use "$@" to pass whatever arguments came into this script.
python luminance2 "$@"
