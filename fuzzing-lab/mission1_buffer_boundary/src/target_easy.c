#include "common.h"

int main(int argc, char **argv) {
    size_t length = 0;
    int result = load_input(argc, argv, &length);
    if (result) return result;
    return copy_message(input_bytes, length);
}
