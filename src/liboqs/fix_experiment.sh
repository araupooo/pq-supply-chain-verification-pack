#!/bin/bash
# Remediation experiment (NOT a clean rebuild): recompile ONLY src/common/common.c
# in each existing build tree, adding -ffile-prefix-map=<that tree's absolute
# source dir>=/liboqs, then compare the two resulting objects.
# All other 2633 archive members were already byte-identical, so if these two
# objects match, a re-archive with the fixed member must match too (verified
# separately in the investigation step).
set -eu
ROOT=~/workspace/goals/postfiat-task-node-connection/hidden_files/task-c0496161/targets/liboqs
for N in 1 2; do
  B="$ROOT/build$N/liboqs"
  D="$B/build/src/common/CMakeFiles/common.dir"
  I="$B/build/src/common/CMakeFiles/internal.dir"
  # flags from flags.make (same C_DEFINES/C_FLAGS in both trees; -I differs but
  # include paths are not embedded in a -O3 -DNDEBUG object without -g)
  /usr/bin/cc -DOQS_HAVE_ALIGNED_ALLOC -DOQS_HAVE_EXPLICIT_BZERO -DOQS_HAVE_MEMALIGN -DOQS_HAVE_POSIX_MEMALIGN \
    -I"$B/build/include" -O3 -DNDEBUG -std=gnu11 -fPIC -fvisibility=hidden \
    -Wa,--noexecstack -fomit-frame-pointer -fdata-sections -ffunction-sections \
    -Wl,--gc-sections -Wbad-function-cast \
    -ffile-prefix-map="$B/src"=/liboqs \
    -o /tmp/fixed_common_$N.o -c "$B/src/common/common.c"
  echo "build$N fixed common.c.o:"; sha256sum /tmp/fixed_common_$N.o
  strings /tmp/fixed_common_$N.o | grep -i "common.c" || echo "(no common.c string)"
done
cmp /tmp/fixed_common_1.o /tmp/fixed_common_2.o && echo "FIXED OBJECTS IDENTICAL"
