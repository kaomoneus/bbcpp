/*
 * Panic.cpp
 *
 *  Created on: Oct 28, 2014
 *      Author: stepan
 */

#include <cstdio>
#include <cstdlib>
#include <cassert>
#include "Panic.h"

namespace bige {
namespace panic {

    static void defaultPanic(const char *msg) {
        fprintf(stderr, "Panic: %s\n", msg);
        assert(!msg);
    }

    void Do(const char *msg) {
        (*accessPanicFn())(msg);
    }

#ifdef DEBUG
    void Assert(bool statement, const char *msg) {
        if (!statement) Do(msg);
    }
#endif

	panicFnTy& accessPanicFn() {
	    static panicFnTy panicFn = defaultPanic;
	    return panicFn;
	}
}
}


