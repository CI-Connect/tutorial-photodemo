#!/bin/bash

# Load Python 2.7 from OASIS
module load python/2.7
# We'll want to load freetype and libjpeg from oasis as well, when
# they are available.

# Create the virtualenv
virtualenv pillow

# Find and copy into place the virtualenv software
# (We don't need this when using OASIS Python, because it includes
# virtualenv. But it's a useful trick otherwise for copying the local
# virtualenv program.)
#cp $(python -c 'import virtualenv; print virtualenv.__file__' | sed -e 's/pyc/py/') pillow/bin/
#cp $(which virtualenv) pillow/bin/

# "activate" the virtualenv
source pillow/bin/activate

# Install PIL.
pip install Pillow

# Now "deactivate" the virtualenv
deactivate

tar cf pillow.tar pillow

