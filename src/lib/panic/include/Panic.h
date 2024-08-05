/*
 * Panic.h
 *
 *  Created on: Oct 28, 2014
 *      Author: stepan
 */

#ifndef PANIC_H_
#define PANIC_H_

namespace bige {
namespace panic {

    typedef void (*panicFnTy)(const char*);

    panicFnTy& accessPanicFn();

    void Do(const char *msg);

#ifdef DEBUG
	void Assert(bool statement, const char *msg);
#else
	inline void Assert(bool statement, const char *msg) {}
#endif

}
}



#endif /* PANIC_H_ */
