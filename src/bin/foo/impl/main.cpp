#include "Panic.h"
#include "json/json.h"
#include <iostream>

int main() {
    Json::Value v("Hello");
    std::cout << "Testing json:" << v.toStyledString();

#ifdef TEST_COMPILE_DEFINITION
    std::cout << "Test compile definition works!" << std::endl;
#endif

    bige::panic::Do("This is a happy panic message!");
    return 0;
}