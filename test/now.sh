#!/bin/bash
set -e
cd $(dirname $0)
echo -n "Testing $(basename -s .sh $0) ... "
t=$(pwd)/tmp/$(basename -s .sh $0)
mkdir -p $t

cat <<EOF | clang -c -fPIC -o $t/a.o -xc -
#include <stdio.h>

void foo() {
  printf("Hello world\n");
}
EOF

clang -fuse-ld=`pwd`/../mold -shared -o $t/b.so $t/a.o -Wl,-z,now
readelf --dynamic $t/b.so | grep -q 'Flags: NOW'

clang -fuse-ld=`pwd`/../mold -shared -o $t/b.so $t/a.o -Wl,-z,now,-z,lazy
readelf --dynamic $t/b.so > $t/log
! grep -q 'Flags: NOW' $t/log || false

echo OK
