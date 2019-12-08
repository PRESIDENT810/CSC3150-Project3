#include "virtual_memory.h"
#include <cuda.h>
#include <cuda_runtime.h>
#include "stdio.h"

__device__ void user_program(VirtualMemory *vm, uchar *input, uchar *results, int input_size) {
//	for (int i = 0; i < input_size; i++) // i: offset
//		vm_write(vm, i, input[i]);
//	printf("write page fault: %d\n", *(vm->pagefault_num_ptr));
//	for (int i = input_size - 1; i >= input_size - 32769; i--) {
//		int value = vm_read(vm, i);
//	}
//	printf("read page fault: %d\n", *(vm->pagefault_num_ptr));
//
//	vm_snapshot(vm, results, 0, input_size);
//	printf("snapshot page fault: %d\n", *(vm->pagefault_num_ptr));
}


__device__ void user_program(VirtualMemory *vm, uchar *input, uchar *results, int input_size, int thread_id) {
//	printf("thread: %d\n", thread_id);
	int order = 0;

	for (int i = 0; i < input_size/4; i++) { // i: offset
		//if (thread_id != vm->current_thread) {
		//	printf("thread id %d, current thread %d, wait\n", thread_id, vm->current_thread);
		//	continue;
		//}

		//if (i % 4 != thread_id) continue;

		int fuck = i + thread_id * (input_size / 4);
		// printf("thread id %d, fuck is %d\n", thread_id, fuck);

		if (thread_id == 0) {
			vm_write(vm, fuck, input[fuck], thread_id);
		}
		__syncthreads();

		if (thread_id == 1) {
			vm_write(vm, fuck, input[fuck], thread_id);
		}
		__syncthreads();

		if (thread_id == 2) {
			vm_write(vm, fuck, input[fuck], thread_id);
		}
		__syncthreads();

		if (thread_id == 3) {
			vm_write(vm, fuck, input[fuck], thread_id);
		}
		__syncthreads();

		// printf("thread id %d, current thread %d, current+1\n", thread_id, vm->current_thread);
		//vm->current_thread = (vm->current_thread+1)%4;

		
//		__syncthreads(); // all four threads have written, synchronize then continue 
	}
	printf("write page fault count: %d\n", *(vm->pagefault_num_ptr));

    for (int i = input_size - 1; i >= input_size - 32769; i--) {
		int fuck = i + thread_id * (input_size / 4);

		if (thread_id == 0) {
			int value = vm_read(vm, fuck, thread_id);
		}
		__syncthreads();

		if (thread_id == 1) {
			int value = vm_read(vm, fuck, thread_id);
		}
		__syncthreads();

		if (thread_id == 2) {
			int value = vm_read(vm, fuck, thread_id);
		}
		__syncthreads();

		if (thread_id == 3) {
			int value = vm_read(vm, fuck, thread_id);
		}
		__syncthreads();

		//vm->current_thread = (vm->current_thread + 1) % 4;
    }
	printf("read page fault count: %d\n", *(vm->pagefault_num_ptr));

	if (thread_id != 0) return;
	vm_snapshot(vm, results, 0, input_size, thread_id);
	printf("snapshot page fault %d\n", *(vm->pagefault_num_ptr));
}
