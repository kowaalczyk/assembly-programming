#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

extern void start(int, int, float*, float);
extern void step(float*);

const int DEBUG=0; // set 1 to enable additional output

const int PADDING_TOP=8;  // has to be at least 5, but 8 guarantees alignment to 16bits
const int PADDING_BOTTOM=4;  // has to be at least 1, but 4 guarantees alignment to 16bits
const int PADDING_LEFT=1;

void exit_error(const char* msg, short exit_code) {
    dprintf(2, msg);
    exit(exit_code);
}

float* read_pollution_matrix(int width, int height) {
    // TODO: Top padding needs to be variable in order to provide the right alignment for movaps
    int real_height = height + PADDING_TOP + PADDING_BOTTOM;
    int real_width = width + PADDING_LEFT;

    // 2x because we need to store temporary results in the second matrix
    float* M = aligned_alloc(16, 2 * real_width * real_height * sizeof(float));
    // float* M = calloc(2 * real_width * real_height, sizeof(float));
    if (M == NULL) {
        dprintf(2, "Invalid memory allocation:");
        exit_error(strerror(errno), 1);
    }
    // actual matrix begins on row 5, column 1:
    // rows [0,4] and (height) are just padding
    // column 0 is placeholder for vector T
    // return &M[real_height + 5];

    int result;
    for (int row_idx = 0; row_idx < height; row_idx++) {
        for (int col_idx = 0; col_idx < width; col_idx++) {
            int idx = real_height * (col_idx + PADDING_LEFT) + (row_idx + PADDING_TOP);
            result = scanf("%f", &M[idx]);
            if (result != 1) {
                exit_error("Expected floating point number", 2);
            }
        }
    }
    return M;
}

void print_pollution_matrix(int width, int height, float* M) {
    int real_height = (height + PADDING_TOP + PADDING_BOTTOM);
    for (int row_idx = 0; row_idx < height; row_idx++) {
        for (int col_idx = 0; col_idx < width; col_idx++) {
            int translated_col = (col_idx + PADDING_LEFT) * real_height;
            int translated_row = row_idx + PADDING_TOP;
            printf("%12.8f", M[translated_col + translated_row]);
            if (col_idx != width - 1) printf(" ");
        }
        printf("\n");
    }
}

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
    int real_height = height+PADDING_BOTTOM+PADDING_TOP;
    for (int row_idx = 0; row_idx < real_height; row_idx++) {
        for (int col_idx = 0; col_idx < 2*width + PADDING_LEFT; col_idx++) {
            printf("%12.8f", M[real_height * col_idx + row_idx]);
            if (col_idx != 2*width + PADDING_LEFT - 1) printf(" ");
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
    start(width, height, M, weight);
    if (DEBUG) debug_print_pollution_matrix(width, height, M, "AFTER START");

    for (int step_idx = 0; step_idx < steps; step_idx++) {
        // read incoming pollution values into buffer T
        for (int row_idx = 0; row_idx < height; row_idx++) {
            result = scanf("%f", &T[row_idx]);
            if (result != 1) {
                exit_error("Expected floating point number", 2);
            }
        }

        // perform next step of the simulation
        step(T);
        if (DEBUG) debug_print_pollution_matrix(width, height, M, "AFTER STEP");

        // print results to standard output
        print_pollution_matrix(width, height, M);
    }

    return 0;
}
