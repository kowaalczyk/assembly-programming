#include <ctype.h>
#include <errno.h>

#include "ppm.h"

static const uint8_t BUFFER_LEN = 7; // [6*digit,\0] - all PPM values are <= 65536

/**
 * Returns -1 on parsing error or positive int - the result of parsing.
 */
static int parse_next_int(FILE* file, char* buffer)
{
    int raw_char;

    uint8_t buffer_pos = 0;
    for (buffer_pos = 0; buffer_pos < BUFFER_LEN; buffer_pos++) {
        buffer[buffer_pos] = 0;
    }

    buffer_pos = 0;
    while ((raw_char = getc(file)) != EOF && buffer_pos < BUFFER_LEN - 1) {
        if (isspace(raw_char)) {
            if (buffer_pos == 0) continue; // nothing read yet
            break; // first whitespace after int
        };

        if (!(raw_char >= '0' && raw_char <= '9')) {
            return -1; // only accept digits
        }

        // valid digit - save to buffer
        buffer[buffer_pos] = (unsigned char)raw_char;
        buffer_pos += 1;
    }
    if (buffer_pos == (BUFFER_LEN - 1) && (!feof(file) || !isspace(raw_char))) {
        return -1; // number is larger than 6 digits
    }
    if (buffer_pos == 0 && feof(file)) {
        return -1; // unexpected end of file (too early)
    }

    int raw_int = atoi(buffer); // safe to convert it now
    return raw_int;
}

/**
 * Parse pixel and store it in the next position in image.
 * Assumes the image-> pixels already have allocated memory.
 * Returns -1 on error, 0 on success.
 */
static int parse_pixel(FILE* file, char* buffer, uint32_t row, uint32_t col,
                       image_t* image)
{
    pixel_t pixel;

    pixel.r = parse_next_int(file, buffer);
    if (pixel.r < 0 || pixel.r > image->max_value) return -1;

    pixel.g = parse_next_int(file, buffer);
    if (pixel.g < 0 || pixel.g > image->max_value) return -1;

    pixel.b = parse_next_int(file, buffer);
    if (pixel.b < 0 || pixel.b > image->max_value) return -1;

    if (image->pixels == NULL) return -1;

    image->pixels[row * image->width + col] = pixel;

    return 0;
}

int ppm_read(FILE* file, image_t* image)
{
    char buffer[BUFFER_LEN];
    int tmp;

    // header - magic number (P)
    tmp = getc(file);
    if (feof(file) || ferror(file)) return -1;
    if (tmp != 'P') {
        return -1; // incompatible header
    }

    // header - magic number (3 or 6)
    tmp = getc(file);
    if (feof(file) || ferror(file)) return -1;
    if (tmp != '3' && tmp != '6') {
        return -1; // incompatible header
    }

    // header - width
    tmp = parse_next_int(file, buffer);
    if (tmp < 0) return tmp;
    image->width = (uint32_t)tmp;

    // header - height
    tmp = parse_next_int(file, buffer);
    if (tmp < 0) return tmp;
    image->height = (uint32_t)tmp;

    // header - maxval
    tmp = parse_next_int(file, buffer);
    if (tmp < 0) return tmp;
    image->max_value = (uint32_t)tmp;

    // pixels
    tmp = ppm_alloc(image);
    if (tmp < 0) return tmp; // bad alloc
    {
        int row, col;
        for (row = 0; row < image->height; row++) {
            for (col = 0; col < image->width; col++) {
                tmp = parse_pixel(file, buffer, row, col, image);
                if (tmp < 0) return tmp;
            }
        }
    }

    return 0;
}

int ppm_write(FILE* file, image_t* image)
{
    int tmp;
    // header
    tmp =
        fprintf(file, "P3\n%d %d\n%d\n", image->width, image->height, image->max_value);
    if (tmp < 0) return tmp;

    // pixels
    {
        int row, col;
        for (row = 0; row < image->height; row++) {
            for (col = 0; col < image->width; col++) {
                pixel_t p = image->pixels[row * image->width + col];
                if (col == image->width - 1) {
                    tmp = fprintf(file, "%d %d %d\n", p.r, p.g, p.b);
                } else {
                    tmp = fprintf(file, "%d %d %d ", p.r, p.g, p.b);
                }
                if (tmp < 0) return tmp;
            }
        }
    }

    return 0;
}

int ppm_alloc(image_t* image)
{
    pixel_t* pixels = (pixel_t*)calloc(image->height * image->width, sizeof(pixel_t));
    if (pixels == NULL) return -1;

    image->pixels = pixels;
    return 0;
}

int ppm_free(image_t* image)
{
    free(image->pixels);
    return 0;
}
