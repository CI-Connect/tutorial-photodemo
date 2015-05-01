#!/bin/bash
module load python/3.4
# Create the virtualenv
virtualenv pillow

# Find and copy into place the virtualenv software
cp $(python -c 'import virtualenv; print virtualenv.__file__' | sed -e 's/pyc/py/') pillow/bin/
cp $(which virtualenv) pillow/bin/

# "activate" the virtualenv
source pillow/bin/activate

# Install PIL. The STATIC_DEPS variable uses static libraries for any compiled dependencies
env STATIC_DEPS=true pip install Pillow

# Now "deactivate" the virtualenv
deactivate

tar cf pillow.tar pillow

