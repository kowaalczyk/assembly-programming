/// prints size of all usual numeric types on the host
/// $ gcc -o limits limits.c
/// $ ./limits

#include <stdio.h>

int main()
{
    printf("float=%d, double=%d, short=%d, int=%d, long=%d, longlong=%d\n",
           sizeof(float), sizeof(double),
           sizeof(short), sizeof(int), sizeof(long), sizeof(long long));
    return 0;
}
