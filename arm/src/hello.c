#include <stdio.h>

int main () {
  long T[10];

  T[5] = 223456;
  printf("Hello %ld,%d.\n", T[5]+2, sizeof(int));
  return 0;
}