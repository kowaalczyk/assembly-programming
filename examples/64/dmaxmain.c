#include <stdio.h>

extern double dmax (double d1, double d2);

int main (int argc, char* args[]) {
  double result = dmax(2.1245, 2.1244);
  printf("Result=%f\n", result);
  return 0;
}
