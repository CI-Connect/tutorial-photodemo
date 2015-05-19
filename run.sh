#!/bin/bash

# This is a simple job wrapper to unpack the python virtual environment
# and run the 'luminance2' program, saving output into a results file.

# If no HTTP_PROXY but FRONTIER_PROXY is set, copy it. At some
# sites (notably Syracuse) this helps ensure HTTP access to the internet.
[ -z "$HTTP_PROXY" -a -n "$FRONTIER_PROXY" ] && export HTTP_PROXY=${FRONTIER_PROXY}

# First load a python 2.7 interpreter from OASIS.
module load python/2.7

# Unpack the pillow.tar virtualenv which was bundled with the job
tar xf pillow.tar

# Update it to run on this worker
#python pillow/bin/virtualenv.py pillow
virtualenv pillow

# Activate the virtualenv to get access to its local modules
source pillow/bin/activate

# N.B. It's important to run "python scriptname" here so that we get the
# python interpreter packaged by the virtualenv instead of the one installed
# on the target system.
#
# Use "$@" to pass whatever arguments came into this script.
python luminance2 "$@"
