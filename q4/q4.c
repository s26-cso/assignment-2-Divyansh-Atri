#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <limits.h>

typedef int (*op_fn)(int, int);

int main() {
	char op[16];
	long long a, b;

	while (scanf("%15s %lld %lld", op, &a, &b) == 3) {
		char libname[32];
		snprintf(libname, sizeof(libname), "./lib%s.so", op);

		void *handle = dlopen(libname, RTLD_LAZY);
		if (!handle) {
			fprintf(stderr, "library load failed: %s\n", dlerror());
			continue;
		}

		dlerror();
		op_fn fn = (op_fn)dlsym(handle, op);
		char *err = dlerror();
		if (err) {
			fprintf(stderr, "symbol load failed: %s\n", err);
			dlclose(handle);
			continue;
		}

		int result = fn((int)a, (int)b);
		printf("%d\n", result);

		dlclose(handle);
	}
	return 0;
}
