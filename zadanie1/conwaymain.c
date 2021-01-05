/**
 * Main executable for running Conway's Game of Life step-by-step
 * (input and output format as requested for this assignment).
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

/// prints human-friendly representation of the board
void print_game_state(const int width, const int height, const char* fields) {
    int row, col;

    printf("/");
    for (col = 0; col < width; col++) {
        printf("-");
    }
    printf("\\\n");

    for (row = 0; row < height; row++) {
        printf("|");
        for (col = 0; col < width; col++) {
            if (fields[row*width + col] == (char)1) {
                printf("X");
            } else {
                printf(" ");
            }
        }
        printf("|\n");
    }

    printf("\\");
    for (col = 0; col < width; col++) {
        printf("-");
    }
    printf("/\n\n");
}

/**
 * First line of input:
 * width, height of the game world
 *
 * Next `height` lines:
 * each line has `width` space-separated digits (0 or 1)
 * representing initial state of the game
 *
 * Output:
 * after each step of the simulation, the number of total steps and the result
 * are printed (X denoting a live cell, blank space a dead one).
 *
 * Use Ctrl+C to quit the game.
 */
int main() {
    int height, width, row, col, result, line_size;

    // load height and width
    result = scanf("%d %d\n", &width, &height);
    if (result != 2) {
        exit_error("Invalid read: expected 2 items in the first line", 2);
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
    int step = 0;
    while (TRUE) {
        run(1);
        sleep(1);

        step++;
        printf("Current step: %d\n", step);
        print_game_state(width, height, fields);
    }

    return 0;
}
