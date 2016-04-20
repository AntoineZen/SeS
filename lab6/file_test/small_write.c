#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define BLOCK_SIZE 1024

main(int argc, char *argv[])
{
    void* ptr;
    FILE* f = fopen("generated_file", "w");
    int i;

    for(i=0; i < 4; i++)
    {
        ptr = malloc(BLOCK_SIZE);
        memset(ptr, 0xAA, BLOCK_SIZE);

        fwrite(ptr, BLOCK_SIZE, 1, f);

        free(ptr);
    }

    fclose(f);
}
