/**
 * Executable with arguments and output that allow for easier testing.
 *
 * (c) Krzysztof Kowalczyk 2020 kk385830@students.mimuw.edu.pl
 */

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

#define STDIN 0
#define STDOUT 1
#define STDERR 2

#define TRUE 1

extern void start (int, int, char*);  // conway.asm
extern void run (int);  // conway.asm

void exit_error(const char* msg, short exit_code) {
    dprintf(2, msg);
    exit(exit_code);
}

/// machine-readable version more useful for testing
void print_game_state(const int width, const int height, const char* fields) {
    int row, col;

    for (row = 0; row < height; row++) {
        for (col = 0; col < width; col++) {
            if (fields[row*width + col] == (char)1) {
                printf("1");
            } else {
                printf("0");
            }
            if (col != width - 1) {
                printf(" ");
            }
        }
        printf("\n");
    }
}

/**
 * First line of input:
 * width, height, steps to simulate
 *
 * Next `height` lines:
 * each line has `width` space-separated digits (0 or 1)
 * representing initial state
 *
 * Output:
 * final state (after simulating specified number of steps),
 * in the same representation as input state.
 */
int main() {
    int height, width, row, col, result, line_size, steps;

    // load height, width and number of steps
    result = scanf("%d %d %d\n", &width, &height, &steps);
    if (result != 3) {
        exit_error("Invalid read: expected 3 items in the first line", 2);
    }

    // allocate memory for all fields
    char* fields = calloc(height * width, sizeof(char));
    if (fields == NULL) {
        dprintf(2, "Invalid memory allocation:");
        exit_error(strerror(errno), 1);
    }

    // load fields
    for (row = 0; row < height; row++) {
        for (col = 0; col < width; col++) {
            int val;
            scanf("%d", &val);
            switch (val) {
                case 0:
                    break;
                case 1:
                    fields[row*width + col] = (char)1;
                    break;
                default:
                    exit_error("Invalid read: expected 0 or 1", 2);
            }
        }
    }

    // initialize and run the game
    start(width, height, fields);
    run(steps);
    print_game_state(width, height, fields);

    return 0;
}
