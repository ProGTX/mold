#!/bin/bash
export LANG=
set -e
CC="${CC:-cc}"
CXX="${CXX:-c++}"
testname=$(basename -s .sh "$0")
echo -n "Testing $testname ... "
cd "$(dirname "$0")"/../..
mold="$(pwd)/mold"
t=out/test/elf/$testname
mkdir -p $t

cat <<EOF | $CC -c -o $t/a.o -xc -
#include <stdio.h>

void foo();

void bar() {
  foo();
  printf("Hello world\n");
}
EOF

cat <<EOF | $CC -c -o $t/b.o -xc -
void foo() {}
void bar();

int main() {
  bar();
  return 0;
}
EOF

cat <<EOF | $CC -shared -o $t/c.so -xc -
void baz() {}
EOF

$CC -B. -o $t/exe $t/a.o $t/b.o $t/c.so \
  -Wl,-y,foo -Wl,--trace-symbol=baz > $t/log

grep -q 'trace-symbol: .*/a.o: reference to foo' $t/log
grep -q 'trace-symbol: .*/b.o: definition of foo' $t/log
grep -q 'trace-symbol: .*/c.so: definition of baz' $t/log

echo OK
