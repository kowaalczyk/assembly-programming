#include <stdio.h>

extern double array_fsum (double arr[], int);

#define SIZE 10

int main () {
  double value[SIZE] = {1,2,3,4,5,6,7,8,9,10};
  
  printf("Suma elementów = %lf\n", array_fsum(value, SIZE));
  return 0;
}

/*EOF*/
