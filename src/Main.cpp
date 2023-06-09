#include <iostream>

int main(int argc, char* argv[])
{
    std::cout << "CMakeTemplate by Magehawk!\n"
              << "Github Repository: https://github.com/TheMagehawk/CMakeTemplate.git\n\n";

#ifdef IS_DEBUG
    std::cout << "Compiled C++ Example in Debug mode!\n";
#else
    std::cout << "Compiled C++ Example in Release mode!\n";
#endif

    if (argc > 1) {
        std::cout << "Running Test " << argv[1] << "..." << '\n';
    }

    return 0;
}
