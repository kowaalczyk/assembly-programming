#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "ppm.h"

void print_usage(const char* executable_name)
{
    fprintf(stderr, "Usage: %s -[rgb] brightness_change filename\n", executable_name);
    fprintf(stderr, " - use r/g/b option to specify color channel to change\n");
    fprintf(stderr, " - brightness_change has to be a valid 8-bit integer\n");
    fprintf(stderr, " - filename must point to a valid PPM file (binary or text)\n\n");
    fprintf(stderr, "Example: %s -r -128 image.ppm\n\n", executable_name);
    exit(2);
}

void exit_error(const char* msg, uint8_t exit_code)
{
    dprintf(2, "%s", msg);
    dprintf(2, "\n");
    exit(exit_code);
}

typedef enum Color { RED, GREEN, BLUE } Color;

char* get_output_path(const char* input_path)
{
    char* output_path;
    // allocate output path
    {
        size_t input_path_len = strlen(input_path);

        output_path = calloc(input_path_len + 2, sizeof(char));
        if (output_path == NULL) exit_error(strerror(errno), 1);

        memset(output_path, 0, input_path_len + 2);
    }

    // copy prefix of input path (until filename) to output path
    {
        char* output_path_cursor = output_path;
        char* last_sep = strchr(input_path, '/');
        if (last_sep == NULL) {
            // path to file in current working directory
            output_path[0] = 'Y'; // update filename

            output_path_cursor += sizeof(char);
            last_sep = (char*)(input_path + sizeof(char));
        } else {
            // output_path points to same directory as input_path
            size_t chars_to_copy = ((last_sep - input_path) / sizeof(char)) + 1;
            strncpy(output_path, input_path, chars_to_copy);

            output_path[chars_to_copy] = 'Y'; // update filename

            output_path_cursor += (chars_to_copy + 1) * sizeof(char);
            last_sep += sizeof(char);
        }
        strcpy(output_path_cursor, last_sep); // copy filename & extension
    }
    return output_path;
}

int main(int argc, char* argv[])
{
    Color color;
    int8_t brightness_change;
    image_t image;

    if (argc != 4) print_usage(argv[0]);

    // first argument
    if (strlen(argv[1]) != 1) exit_error("Expected option: 'r' 'g' or 'b'", 2);
    switch (argv[1][0]) {
        case 'r':
            color = RED;
            break;
        case 'g':
            color = GREEN;
            break;
        case 'b':
            color = BLUE;
            break;
        default:
            print_usage(argv[0]);
    }

    // second argument
    {
        int brightness_change_unchecked = atoi(argv[2]);

        if (brightness_change_unchecked < -128 || brightness_change_unchecked > 127) {
            exit_error("Color change has to be an 8-bit integer in range [-128,127]",
                       2);
        }
        brightness_change = (int8_t)brightness_change_unchecked;
    }

    // third argument
    {
        char* output_file_path;

        // reading input
        {
            FILE* input_file = fopen(argv[3], "r");
            if (input_file == NULL) exit_error(strerror(errno), 2);

            output_file_path = get_output_path(argv[3]);

            int result = ppm_read(input_file, &image);
            if (result < 0) exit_error("Invalid PPM read", 1);

            fclose(input_file); // TODO: error handling
        }

        // TODO: running the program

        // writing output
        {
            FILE* output_file = fopen(output_file_path, "w");
            if (output_file == NULL) exit_error(strerror(errno), 1);

            int result = ppm_write(output_file, &image);
            if (result < 0) exit_error("Invalid PPM write", 1);

            fclose(output_file); // TODO: error handling
        }

        free(output_file_path);
    }
    return 0;
}
