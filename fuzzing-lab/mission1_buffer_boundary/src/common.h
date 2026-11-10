#ifndef FUZZ_LAB_COMMON_H
#define FUZZ_LAB_COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Local classroom targets only. Read at most 256 bytes per test case. */
static unsigned char input_bytes[256];
static volatile unsigned char output_sink;

static int load_input(int argc, char **argv, size_t *length) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s INPUT_FILE\n", argv[0]);
        return 3;
    }
    FILE *file = fopen(argv[1], "rb");
    if (!file) {
        perror("fopen");
        return 3;
    }
    *length = fread(input_bytes, 1, sizeof(input_bytes), file);
    int failed = ferror(file);
    fclose(file);
    return failed ? 3 : 0;
}

/* Intentionally vulnerable: length is not checked in the original build. */
static int copy_message(const unsigned char *data, size_t length) {
#ifdef FIXED
    if (length > 16) return 2;
#endif
    unsigned char *buffer = malloc(16);
    if (!buffer) return 3;
    memset(buffer, 0, 16);
    volatile unsigned char *destination = buffer;
    for (size_t index = 0; index < length; ++index) {
        destination[index] = data[index];
    }
    output_sink = buffer[length ? length - 1 : 0];
    free(buffer);
    return 0;
}

#endif
