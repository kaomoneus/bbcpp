/*
 * tests.cpp
 *
 *  Created on: Oct 13, 2014
 *      Author: stepan
 */

#include "tests.h"

namespace bige {
namespace test {

	const unsigned TestHiveQueen::mTestMaxBunchesCount = 16;

	TestHiveQueen& TestHiveQueen::getHiveQueen() {
		static TestHiveQueen hiveQueen(stdout, stderr);
		return hiveQueen;
	}
}
}

// The ideas is that tests will consist of
//   * tests slave libraries. Such libs define tests and registers them with initializer functions.
//   * tests queen library. This library has main(). But it is still a library.
//
// Each time you want to create bunch of tests, just link your slave libs with that queen library.
// No need to write main yourself.

BIGE_TEST_MAIN()