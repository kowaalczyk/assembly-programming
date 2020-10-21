#include <stdio.h>

extern int three (void);

int main (int argc, char* args[]) {
  int result = three();
  printf("Result=%d\n", result);
  return result;
}
