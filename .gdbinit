# https://xaizek.github.io/2016-05-26/skipping-standard-library-in-gdb/
define skipstdcxxheaders
python
def skipAllIn(root):
    import os
    for root, dirs, files in os.walk(root, topdown=False):
        for name in files:
            path = os.path.join(root, name)
            gdb.execute('skip file %s' % path, to_string=True)
# do this for C++ only
if 'c++' in gdb.execute('show language', to_string=True):
    skipAllIn('/usr/include/c++')
end
end

define hookpost-run
    skipstdcxxheaders
end
define hookpost-start
    skipstdcxxheaders
end
define hookpost-attach
    skipstdcxxheaders
end

skip file /home/jd/MLOpen/src/include/miopen/errors.hpp
skip file /home/jd/MLOpen/src/include/miopen/object.hpp
skip file /home/jd/MIOpen/src/logger.cpp
