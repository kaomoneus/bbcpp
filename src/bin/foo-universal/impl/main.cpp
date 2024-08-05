#include "Panic.h"
#include <iostream>

int main() {
#ifdef TEST_COMPILE_DEFINITION
    std::cout << "Test compile definition works!" << std::endl;
#endif

    bige::panic::Do("This is a happy panic message!");
    return 0;
}