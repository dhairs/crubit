#include <cstdio>
#include "lib.h"

int main() {
  int x = lib::add_two_integers(100, 12);
  printf("Hello, World %d time(s)!\n", x);
}
