#include <stdio.h>
#include <malloc.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

extern void start(int, int, float*, float);
extern void step(float*);

const int DEBUG=1;

void exit_error(const char* msg, short exit_code) {
    dprintf(2, msg);
    exit(exit_code);
}

int main() {
    int width, height, result, steps;
    float weight;

    // read simualtion parameters
    result = scanf("%d %d %f\n", &width, &height, &weight);
    if (result != 3) {
        exit_error("Expected 3 integers in the first line", 2);
    }

    // allocate memory for the main matrix and temporary matrix
    float* M = calloc(2 * width * height, sizeof(float));
    if (M == NULL) {
        dprintf(2, "Invalid memory allocation:");
        exit_error(strerror(errno), 1);
    }

    // read initial state of the main matrix
    for (int row_idx = 0; row_idx < height; row_idx++) {
        for (int col_idx = 0; col_idx < width; col_idx++) {
            result = scanf("%f", &M[height * col_idx + row_idx]);
            if (result != 1) {
                exit_error("Expected floating point number", 2);
            }
        }
    }

    // read number of steps
    result = scanf("%d\n", &steps);
    if (result != 1) {
        exit_error("Expected numbr of steps to simulate", 2);
    }

    // allocate buffer for incoming values (one column)
    float* T = calloc(height, sizeof(float));
    if (T == NULL) {
        dprintf(2, "Invalid memory allocation:");
        exit_error(strerror(errno), 1);
    }

    // initialize state of the simulation
    start(width, height, M, weight);

    for (int step_idx = 0; step_idx < steps; step_idx++) {
        // read incoming pollution values into buffer T
        for (int row_idx = 0; row_idx < height; row_idx++) {
            result = scanf("%f", T + row_idx);
            if (result != 1) {
                exit_error("Expected floating point number", 2);
            }
        }

        // perform next step of the simulation
        step(T);

        // print results to standard output
        if (DEBUG) printf("Step %d - M:\n", step_idx);
        for (int row_idx = 0; row_idx < height; row_idx++) {
            for (int col_idx = 0; col_idx < width; col_idx++) {
                printf("%f", M[height * col_idx + row_idx]);
                if (col_idx != width - 1) {
                    printf(" ");
                }
            }
            printf("\n");
        }
        if (DEBUG) {
            printf("Step %d - MT:\n", step_idx);
            for (int row_idx = 0; row_idx < height; row_idx++) {
                for (int col_idx = 0; col_idx < width; col_idx++) {
                    printf("%f", M[height*width + height * col_idx + row_idx]);
                    if (col_idx != width - 1) {
                        printf(" ");
                    }
                }
                printf("\n");
            }
        }
    }

    return 0;
}
