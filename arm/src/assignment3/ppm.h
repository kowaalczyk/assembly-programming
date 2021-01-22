#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    uint32_t r;
    uint32_t g;
    uint32_t b;
} pixel_t;

typedef struct {
    uint32_t width;
    uint32_t height;
    uint32_t max_value;
    pixel_t* pixels;
} image_t;

/**
 * Reads PPM file into image, overwriting existing values in the structure.
 * Returns 0 on success and -1 on error (for details see errno variable).
 */
int ppm_read(FILE* file, image_t* image);

/**
 * Writes image into file in PPM format.
 * Returns 0 on success and -1 on error (for details see errno variable).
 */
int ppm_write(FILE* file, image_t* image);

/**
 * Allocates memory for pixels in the image based on height and width.
 * Returns 0 on success and -1 on error (for details see errno variable).
 */
int ppm_alloc(image_t* image);

/**
 * Frees memory reserved for pixels contained in the image.
 * Returns 0 on success and -1 on error (for details see errno variable).
 */
int ppm_free(image_t* image);
