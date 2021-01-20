#include <stdio.h>
#include <stdbool.h>

extern bool quad_roots (double a, double b, double c,
                        double *root1, double *root2);

int main () {
  double a, b, c, root1, root2;

  printf("Podaj współczynniki równania (a,b,c): ");
  scanf("%lf %lf %lf", &a, &b, &c);

  if (quad_roots(a, b, c, &root1, &root2))
    printf("Pierwiastek 1 = %lf, pierwiastek 2 = %lf\n", root1, root2);
  else
    printf("Nie ma pierwiastków rzeczywistych\n");

  return 0;
}

/*EOF*/
