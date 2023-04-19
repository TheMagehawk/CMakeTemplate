#include <stdio.h>

int main(int argc, char* argv[])
{
    printf("CMakeTemplate by Magehawk!\nGithub Repository: https://github.com/TheMagehawk/CMakeTemplate.git\n\n");

    #ifdef IS_DEBUG
    printf("Compiled C Example in Debug mode!\n");
    #else
    printf("Compiled C Example in Release mode!\n");
    #endif

    return 0;
}
