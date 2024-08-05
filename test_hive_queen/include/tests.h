/*
 * tests.h
 *
 *  Created on: Oct 13, 2014
 *      Author: stepan
 */

#ifndef TESTS_H_
#define TESTS_H_

#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace bige {
namespace test {

class TestException {
protected:
	const char* mReason;
public:
	TestException(const char* reason) : mReason(reason) {}
	const char* getReason() const { return mReason; }
};

class TestBunch {
public:
	typedef void (*TestMethodTy)(FILE *output);
protected:
	TestMethodTy* mTestMethods;
	char** mTestMethodNames;

	unsigned mTestMethodsMaxCount;
	unsigned mTestNameMaxLength;

	unsigned mNextMethodIndex;

	const char *mName;

	FILE *mReportOutput;
	FILE *mTestOutput;

public:
	TestBunch(const char* name,
			  unsigned testMethodsMaxCount,
			  unsigned testNameMaxLength,
			  FILE *reportOutput, FILE *testOutput) {
		mName = name;
		mTestMethods = new TestMethodTy[testMethodsMaxCount];
		mTestMethodsMaxCount = testMethodsMaxCount;
		mNextMethodIndex = 0;

		mTestMethodNames = new char*[testMethodsMaxCount];

		for (unsigned i = 0; i < testMethodsMaxCount; ++i) {
			mTestMethodNames[i] = new char[testNameMaxLength + 1];
			memset(mTestMethodNames[i], 0, testNameMaxLength + 1);
		}

		mTestNameMaxLength = testNameMaxLength;

		mReportOutput = reportOutput;
		mTestOutput = testOutput;
	}

	virtual ~TestBunch() {
		delete [] mTestMethods;
	}

	void dump(FILE *output) {
		fprintf(output, "%s\nNumber of tests %i\n", mName, mNextMethodIndex);
	}

	unsigned registerMethod(TestMethodTy method, const char *name) {
		if (mNextMethodIndex >= mTestMethodsMaxCount)
			throw new TestException("Maximum tests count has been exceeded");

		mTestMethods[mNextMethodIndex] = method;
		strncpy(mTestMethodNames[mNextMethodIndex], name, mTestNameMaxLength);

		++mNextMethodIndex;

		return mNextMethodIndex;
	}

	void runTests() {
		for (unsigned i = 0; i < mNextMethodIndex; ++i) {
			fprintf(mReportOutput, "Running test '%s' ...", mTestMethodNames[i]);
			try {
            try {
				fprintf(mTestOutput, "Output for test '%s':\n", mTestMethodNames[i]);
				mTestMethods[i](mTestOutput);
				fprintf(mTestOutput, "\n");

				fprintf(mReportOutput, "ok\n");
			}
			catch (const TestException &e) {
				fprintf(mReportOutput, "failed\nReason:\n%s\nEnd of reason.\n\n", e.getReason());
			}
			}
			catch (...) {
				fprintf(mReportOutput, "failed. Unknown reason.\n");
			}
		}
	}
};

class TestHiveQueen {

	TestBunch** mTestBunches;

	const static unsigned mTestMaxBunchesCount;
	unsigned mNextTestBunchIndex;

	FILE *mBunchReportOutput;
	FILE *mBunchTestOutput;

public:

	TestHiveQueen(FILE *defaultReportOutput, FILE *defaultTestOutput) {
		mTestBunches = new TestBunch*[mTestMaxBunchesCount];
		mNextTestBunchIndex = 0;
		mBunchReportOutput = defaultReportOutput;
		mBunchTestOutput = defaultTestOutput;
	}

	virtual ~TestHiveQueen() {
		for (unsigned i = 0; i < mNextTestBunchIndex; ++i)
			delete mTestBunches[i];
		delete [] mTestBunches;
	}

	TestBunch* createBunch(const char* name,
						   unsigned testMethodsMaxCount,
						   unsigned testNameMaxLength,
						   FILE *reportOutput, FILE *testOutput) {
		TestBunch *bunch =
				new TestBunch(name,
						testMethodsMaxCount, testNameMaxLength,
						reportOutput, testOutput);
		mTestBunches[mNextTestBunchIndex++] = bunch;
		return bunch;
	}

	TestBunch* createBunch(const char* name,
						   unsigned testMethodsMaxCount,
						   unsigned testNameMaxLength) {
		return createBunch(
				name, testMethodsMaxCount, testNameMaxLength,
				mBunchReportOutput, mBunchTestOutput);
	}

	void runTests() {
		for (unsigned i = 0; i < mNextTestBunchIndex; ++i) {

			TestBunch *bunch = mTestBunches[i];

			fprintf(mBunchReportOutput, "Running bunch:\n");
			bunch->dump(mBunchReportOutput);
			bunch->runTests();
		}
	}

	virtual int main(int argc, char** argv) {
		runTests();
		return 0;
	}

	static TestHiveQueen& getHiveQueen();
};

#define BIGE_TEST_BUNCH_SIZE 32
#define BIGE_TEST_NAME_LENGTH 128

// Define INITIALIZER function for MSVC
#ifdef _MSC_VER

#pragma section(".CRT$XCU",read)
#define INITIALIZER(f) \
   static void __cdecl f(void); \
   __declspec(allocate(".CRT$XCU")) void (__cdecl*f##_)(void) = f; \
   static void __cdecl f(void)

// Define INITIALIZER function for MSVC
#elif defined(__GNUC__)

#define INITIALIZER(f) \
   static void f(void) __attribute__((constructor)); \
   static void f(void)

#endif

#define BIGE_TEST_BUNCH(bunchName) namespace ns ## bunchName {\
	static bige::test::TestBunch* getThisTestBunch() { \
		static bige::test::TestBunch* bunch = bige::test::TestHiveQueen::getHiveQueen() \
			.createBunch(#bunchName, BIGE_TEST_BUNCH_SIZE, \
					                 BIGE_TEST_NAME_LENGTH); \
		return bunch; \
	} \
}; namespace ns ## bunchName \


#define BIGE_TEST_BUNCH_EX(bunchName, reportOutput, testOutput) \
	namespace ns ## bunchName { \
	static bige::test::TestBunch* getThisTestBunch() { \
		static bige::test::TestBunch* bunch = \
			bige::test::TestHiveQueen::getHiveQueen() \
		.createBunch(#bunchName,\
				     BIGE_TEST_BUNCH_SIZE, BIGE_TEST_NAME_LENGTH \
				     (reportOutput), (testOutput)); \
		return bunch; \
	} \
}; namespace ns ## bunchName \


#define BIGE_TEST(testName) \
	void testName(FILE *testOut); \
	INITIALIZER(register ## testName) { \
		getThisTestBunch()->registerMethod(testName, #testName); \
	} \
	void testName(FILE *testOut) \

#define BIGE_TEST_MAIN() \
	int main(int argc, char** argv) { \
		return bige::test::TestHiveQueen::getHiveQueen().main(argc, argv); \
	}

#define BIGE_PRINTF(format, ...) fprintf (testOut, format, ##__VA_ARGS__)

#define BIGE_CHECK_MSG(x, message) \
		if (!(x)) \
			throw bige::test::TestException(message);

#define BIGE_CHECK_TRACE(x, checkName) \
		fprintf(testOut, "CHECK_TRACE: '%s'\n", checkName); \
		if (!(x)) \
			throw bige::test::TestException("Check failed: " checkName); \

#define BIGE_CHECK(x) BIGE_CHECK_MSG(x, #x)


// Example:
//// Put it in the beginning of each test file
//BIGE_TEST_BUNCH(MyBunch1) {
//	// Define your test
//	BIGE_TEST(someTest) {
//		BIGE_CHECK(true, "Check1");
//		BIGE_CHECK_TRACE(true, "Check2");
//		BIGE_PRINTF("Hello world");
//	}
//
//	// Or...
//	BIGE_TEST(someTest2) {
//		BIGE_CHECK_TRACE(false, "Check3");
//	}
//}
//
//// You can put several bunches in single file
//BIGE_TEST_BUNCH(MyBunch2) {
//	BIGE_TEST(someTest) {
//		BIGE_CHECK(true, "Check1");
//		BIGE_CHECK_TRACE(true, "Check2");
//		BIGE_PRINTF("Hello world");
//	}
//}

}
}

#endif /* TESTS_H_ */
