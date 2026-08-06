#pragma once

#if defined(__x86_64__) || defined(__i386__)
#include <xmmintrin.h>
#include <pmmintrin.h>
#endif

class DenormalHandler {
public:
	DenormalHandler() {
	#if defined(__x86_64__) || defined(__i386__)
		// save daw flag
		original_flags = _mm_getcsr();
		// set ftx and denormal flag
		_mm_setcsr(original_flags | 0x8040);
	#endif
	}
	~DenormalHandler() {
	#if defined(__x86_64__) || defined(__i386__)
		// restore daw flag when out of scope
		_mm_setcsr(original_flags);
	#endif
	}
private:
	#if defined(__x86_64__) || defined(__i386__)
	unsigned int original_flags = 0;
	#endif
};
