/*
 *
 *  Created on: Aug 5, 2024
 *      Author: stepan
 */

#include "tests.h"

namespace bige {
namespace robot {
    BIGE_TEST_BUNCH(PID) {
        BIGE_TEST(PIDMainTest) {
            // All is good
            BIGE_CHECK(true);
            return;
        }

        BIGE_TEST(PIDOsciallator) {
            BIGE_CHECK(false);
        }
    }
}
}



