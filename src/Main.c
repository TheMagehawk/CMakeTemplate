#include <stdio.h>

int main(int argc, char* argv[])
{
    printf("CMakeTemplate by Magehawk!\n"
           "Github Repository: https://github.com/TheMagehawk/CMakeTemplate.git\n\n");

#ifdef IS_DEBUG
    printf("Compiled C Example in Debug mode!\n");
#else
    printf("Compiled C Example in Release mode!\n");
#endif

    if (argc > 1) {
        printf("Running Test %s...\n", argv[1]);
    }

    return 0;
}
