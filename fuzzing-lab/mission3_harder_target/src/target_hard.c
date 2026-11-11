#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define MAX_INPUT_SIZE 256
#define HEADER_SIZE 5
#define PAYLOAD_BUFFER_SIZE 16

static unsigned char input_bytes[MAX_INPUT_SIZE + 1];
static volatile unsigned char output_sink;

static void convert_abort_to_exit_code(int signal_number) {
    (void)signal_number;
    _exit(86);
}

#ifdef CODECURE_BLIND_FORKSERVER
/*
 * AFL++ 4.09c on WSL2 can stall in its faux forkserver for -n mode.
 * This compatibility forkserver only launches children; it exposes no
 * coverage map, so Blind Mode still receives no path feedback.
 */
static void start_blind_forkserver(void) {
    const int control_fd = 198;
    const int status_fd = 199;
    uint32_t handshake = 0;

    if (write(status_fd, &handshake, sizeof(handshake)) != sizeof(handshake)) {
        return;
    }

    while (1) {
        uint32_t command = 0;
        if (read(control_fd, &command, sizeof(command)) != sizeof(command)) {
            _exit(0);
        }

        pid_t child = fork();
        if (child < 0) _exit(3);
        if (child == 0) {
            close(control_fd);
            close(status_fd);
            return;
        }

        int child_status = 0;
        if (write(status_fd, &child, sizeof(child)) != sizeof(child)) _exit(3);
        if (waitpid(child, &child_status, 0) < 0) _exit(3);
        if (write(status_fd, &child_status, sizeof(child_status)) !=
            sizeof(child_status)) {
            _exit(3);
        }
    }
}
#endif

static int load_input(const char *path, size_t *length) {
    FILE *file = fopen(path, "rb");
    if (file == NULL) {
        perror("fopen");
        return 3;
    }

    *length = fread(input_bytes, 1, sizeof(input_bytes), file);
    int read_failed = ferror(file);
    fclose(file);

    if (read_failed) return 3;
    if (*length > MAX_INPUT_SIZE) return 2;
    return 0;
}

static int process_payload(const unsigned char *payload, size_t length) {
    unsigned char *buffer = malloc(PAYLOAD_BUFFER_SIZE);
    if (buffer == NULL) return 3;

    memset(buffer, 0, PAYLOAD_BUFFER_SIZE);
    volatile unsigned char *destination = buffer;
    for (size_t index = 0; index < length; ++index) {
        destination[index] = payload[index];
    }

    output_sink = buffer[length == 0 ? 0 : (length - 1) % PAYLOAD_BUFFER_SIZE];
    free(buffer);
    return 0;
}

int main(int argc, char **argv) {
    const char *convert_abort = getenv("CODECURE_ASAN_EXITCODE");
    if (convert_abort != NULL && strcmp(convert_abort, "86") == 0) {
        signal(SIGABRT, convert_abort_to_exit_code);
    }

#ifdef CODECURE_BLIND_FORKSERVER
    start_blind_forkserver();
#endif

    if (argc != 2) {
        fprintf(stderr, "usage: %s INPUT_FILE\n", argv[0]);
        return 3;
    }

    size_t length = 0;
    int load_result = load_input(argv[1], &length);
    if (load_result != 0) return load_result;
    if (length < HEADER_SIZE) return 2;

    /* Keep each comparison separate so AFL++ can observe deeper paths. */
    volatile unsigned char *header = input_bytes;
    if (header[0] == 'A') {
        if (header[1] == 'B') {
            if (header[2] == 'C') {
                if (header[3] == 'D') {
                    if (header[4] == ':') {
                        return process_payload(input_bytes + HEADER_SIZE,
                                               length - HEADER_SIZE);
                    }
                }
            }
        }
    }

    return 2;
}
