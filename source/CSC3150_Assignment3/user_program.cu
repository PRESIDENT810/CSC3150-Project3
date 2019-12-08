#include "virtual_memory.h"
#include <cuda.h>
#include <cuda_runtime.h>
#include "stdio.h"

__device__ void user_program(struct VirtualMemory *vm, uchar *input, uchar *results, int input_size) {
    for (int i = 0; i < input_size; i++) // i: offset
        vm_write(vm, i, input[i]);
	printf("write page fault: %d\n",*(vm->pagefault_num_ptr));
    for (int i = input_size - 1; i >= input_size - 32769; i--) {
        int value = vm_read(vm, i);
    }
	printf("read page fault: %d\n", *(vm->pagefault_num_ptr));

	vm_snapshot(vm, results, 0, input_size);
	printf("snapshot page fault: %d\n", *(vm->pagefault_num_ptr));
}
