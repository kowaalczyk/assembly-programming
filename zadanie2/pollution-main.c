/// Pollution change simulation driver program.
/// (c) Krzysztof Kowalczyk 2020 kk385830@students.mimuw.edu.pl

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

extern void start(int, int, float*, float);
extern void step(float*);

const int DEBUG=0; // set 1 to enable additional output

const int PADDING_TOP=5;  // 1 for accessing upper neighbours + 4 for easy and safe looping
const int PADDING_BOTTOM=1;  // 1 for accessing lower neighbours
const int PADDING_LEFT=1; // placeholder column for T for easier iteration

void exit_error(const char* msg, short exit_code) {
    dprintf(2, msg);
    dprintf(2, "\n");
    exit(exit_code);
}

int get_real_width(int width) {
    return 2 * width + PADDING_LEFT;
}

int get_real_height(int height) {
    return height + PADDING_TOP + PADDING_BOTTOM;
}

/// translate (row, col) into appropriate index in matrix M
int get_real_index(int row, int col, int real_height) {
    return real_height * (col + PADDING_LEFT) + (row + PADDING_TOP);
}
/**
 * Allocate and read pollution matrix from standard input.
 * The matrix is larger than it's logical representation, as it contains:
 * - 1 additional column on the left side that serves as a placeholder
 *   for incoming values (copied from T)
 * - padding of 5 rows below and 1 row above each row in logical matrix,
 *   to enable highly vectorized computation of pollution deltas
 * - copy of padded matrix that serves as a temporary storage for deltas
 * The matrix can be displayed using print_pollution_matrix function.
 * Elements present in user-facing part of the matrix can be easily accessed
 * via index calculated using get_real_index function.
 */
float* read_pollution_matrix(int width, int height) {
    int real_width = get_real_width(width);
    int real_height = get_real_height(height);

    float* M = aligned_alloc(16, real_width * real_height * sizeof(float));
    if (M == NULL) {
        dprintf(2, "Invalid memory allocation:");
        exit_error(strerror(errno), 1);
    }

    int result;
    for (int row_idx = 0; row_idx < height; row_idx++) {
        for (int col_idx = 0; col_idx < width; col_idx++) {
            int idx = get_real_index(row_idx, col_idx, real_height);
            result = scanf("%f", &M[idx]);
            if (result != 1) {
                exit_error("Expected floating point number", 2);
            }
        }
    }
    return M;
}

void print_pollution_matrix(int width, int height, float* M) {
    int real_height = get_real_height(height);
    for (int row_idx = 0; row_idx < height; row_idx++) {
        for (int col_idx = 0; col_idx < width; col_idx++) {
            int idx = get_real_index(row_idx, col_idx, real_height);
            printf("%12.8f", M[idx]);
            if (col_idx != width - 1) printf(" ");
        }
        printf("\n");
    }
}

// displays entire matrix M (including padding, placeholder column and extra copy)
void debug_print_pollution_matrix(int width, int height, float* M, const char* msg) {
    printf("[DEBUG] '%s':\n", msg);

    // print header
    printf("TP__________ ");
    for (int col_idx = 0; col_idx < width; col_idx++) {
        printf("M%02d_________ ", col_idx);
    }
    for (int col_idx = 0; col_idx < width; col_idx++) {
        printf("D%02d_________ ", col_idx);
    }
    printf("\n");

    // print entire matrix (TP, M and DELTA)
    int real_width = get_real_width(width);
    int real_height = get_real_height(height);
    for (int row_idx = 0; row_idx < real_height; row_idx++) {
        for (int col_idx = 0; col_idx < real_width; col_idx++) {
            printf("%12.8f", M[real_height * col_idx + row_idx]);
            if (col_idx != real_width - 1) printf(" ");
        }
        printf("\n");
    }
    printf("\n");
}

int main() {
    int width, height, result, steps;
    float weight;

    // read simualtion parameters
    result = scanf("%d %d %f\n", &width, &height, &weight);
    if (result != 3) {
        exit_error("Expected 3 integers in the first line", 2);
    }

    // allocate & read matrix for pollution simulation
    float* M = read_pollution_matrix(width, height);

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
    if (DEBUG) debug_print_pollution_matrix(width, height, M, "BEFORE START");
    start(width, height, M, weight);

    for (int step_idx = 0; step_idx < steps; step_idx++) {
        // read incoming pollution values into buffer T
        for (int row_idx = 0; row_idx < height; row_idx++) {
            result = scanf("%f", &T[row_idx]);
            if (result != 1) {
                exit_error("Expected floating point number", 2);
            }
        }

        // perform next step of the simulation
        if (DEBUG) debug_print_pollution_matrix(width, height, M, "BEFORE STEP");
        step(T);

        // print results to standard output
        print_pollution_matrix(width, height, M);
        if (step_idx != steps -1) printf("\n");
    }

    return 0;
}
