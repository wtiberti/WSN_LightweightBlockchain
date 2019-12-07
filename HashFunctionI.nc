#include <stdlib.h>

interface HashFunctionI {
	command int getDigest(void *result, void *data, size_t size);
	command uint8_t getHashLength();
}
