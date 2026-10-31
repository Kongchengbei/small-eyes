#include <stddef.h>

void *memset(void *destination, int value, size_t count)
{
    unsigned char *output = destination;
    unsigned char byte_value = (unsigned char)value;

    for (size_t index = 0; index < count; ++index)
        output[index] = byte_value;
    return destination;
}
