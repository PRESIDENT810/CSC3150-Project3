#include "virtual_memory.h"
#include <cuda.h>
#include <cuda_runtime.h>
#include "stdlib.h"
#include "stdio.h"

// extern int pagefault_num;

__device__ void init_invert_page_table(VirtualMemory *vm) {

    for (int i = 0; i < 1024; i++) {
        vm->invert_page_table[i] = -1; // invalid := MSB is 1
        vm->invert_page_table[i + 1024] = i%4;
    }
}

__device__ void vm_init(VirtualMemory *vm, uchar *buffer, uchar *storage,
             int *invert_page_table, int *pagefault_num_ptr,
             int PAGESIZE, int INVERT_PAGE_TABLE_SIZE,
             int PHYSICAL_MEM_SIZE, int STORAGE_SIZE,
             int PAGE_ENTRIES, int current_thread) {
    // init variables
    vm->buffer = buffer;
    vm->storage = storage;
    vm->invert_page_table = invert_page_table;
    vm->pagefault_num_ptr = pagefault_num_ptr;
	vm->current_thread = current_thread;

    struct Page_node *head;
    struct Page_node *current;
	head = (struct Page_node *) malloc(100);
	head->nxt = NULL;
	//cudaMalloc((void **)head, 100);
	current = head;
    for (int i = 0; i < 1024; i++) {
        struct Page_node *temp;
		//cudaMalloc((void **)temp, 100);
		temp = (struct Page_node *) malloc(100);
        temp->page_idx = i;
        temp->nxt = NULL;
        current->nxt = temp;
        current = temp;
		current->nxt = NULL;
		//free(temp);
    }

    vm->LRU_head = head;

    // init constants
    vm->PAGESIZE = PAGESIZE;
    vm->INVERT_PAGE_TABLE_SIZE = INVERT_PAGE_TABLE_SIZE;
    vm->PHYSICAL_MEM_SIZE = PHYSICAL_MEM_SIZE;
    vm->STORAGE_SIZE = STORAGE_SIZE;
    vm->PAGE_ENTRIES = PAGE_ENTRIES;

    // before first vm_write or vm_read
    init_invert_page_table(vm);
}

__device__ int get_LRUidx(VirtualMemory *vm) { // get the least used index, which is a logical/disk memory address
    return vm->LRU_head->nxt->page_idx;
}


__device__ int search_pageidx(VirtualMemory *vm, int page_num) {
    for (int i = 0; i < 1024; i++) {
        if (vm->invert_page_table[i] == page_num) return i;
    }
    return -1;
}


__device__ void update_stack(VirtualMemory *vm, int idx) {
    struct Page_node *current = vm->LRU_head;

    while (current->nxt->page_idx != idx) current = current->nxt;

    struct Page_node *target = current->nxt;
    current->nxt = target->nxt;

	while (current->nxt != NULL) {
		current = current->nxt;
	}

    current->nxt = target;
    target->nxt = NULL;
}

__device__ void vm_write(VirtualMemory *vm, u32 addr, uchar value, int thread_id) {
    /* Complete vm_write function to write value into data buffer */
    int page_num = addr / 32; // addr is the address of disk/logical memory, and page_num is the corresponding page number

	// printf("address %d\n", addr);
	int search_result = search_pageidx(vm, page_num);
	
	if (search_result == -1 || vm->invert_page_table[search_result+1024] != thread_id) { // not found or not this thread
		printf("write page fault %d with thread %d\n",page_num, thread_id);
		(*(vm->pagefault_num_ptr))++;
		int LRU_idx = get_LRUidx(vm); // LRU index is the index of page table instead of the address of logical memory/disk
        int disk_addr = vm->invert_page_table[LRU_idx];
    
		if (disk_addr != -1) {
            for (int i = 0; i < 32; i++) { // swap out
                vm->storage[disk_addr * 32 + i] = vm->buffer[LRU_idx * 32 + i];
            }
        }

		// update page table
		vm->invert_page_table[LRU_idx] = page_num;
		vm->invert_page_table[LRU_idx + 1024] = thread_id;

        for (int i = 0; i < 32; i++) { // swap in
            vm->buffer[LRU_idx * 32 + i] = vm->storage[page_num * 32 + i];
        }

    }

    vm->buffer[search_pageidx(vm, page_num) * 32 + addr % 32] = value; // write into main memory
    update_stack(vm, search_pageidx(vm, page_num));

	return;
}

__device__ uchar vm_read(VirtualMemory *vm, u32 addr, int thread_id) {
    /* Complate vm_read function to read single element from data buffer */
    /* Complete vm_write function to write value into data buffer */
    int page_num = addr / 32; // addr is the address of disk/logical memory, and page_num is the corresponding page number

	int search_result = search_pageidx(vm, page_num);
	if (search_result == -1 || vm->invert_page_table[search_result + 1024] != thread_id) { // not found or not this thread
		printf("read page fault %d with thread %d\n", page_num, thread_id);
		(*(vm->pagefault_num_ptr))++;
		int LRU_idx = get_LRUidx(vm); // LRU index is the index of page table instead of the address of logical memory/disk
		int disk_addr = vm->invert_page_table[LRU_idx];

		if (disk_addr != -1) {
			for (int i = 0; i < 32; i++) { // swap out
				vm->storage[disk_addr * 32 + i] = vm->buffer[LRU_idx * 32 + i];
			}
		}

		// update page table
		vm->invert_page_table[LRU_idx] = page_num; 
		vm->invert_page_table[LRU_idx + 1024] = thread_id;

		for (int i = 0; i < 32; i++) { // swap in
			vm->buffer[LRU_idx * 32 + i] = vm->storage[page_num * 32 + i];
		}

	}

    uchar content = vm->buffer[search_pageidx(vm, page_num) * 32 + addr % 32]; // read character
    update_stack(vm, search_pageidx(vm, page_num));

    return content;
}

__device__ void vm_snapshot(VirtualMemory *vm, uchar *results, int offset, int input_size, int thread_id) {
    /* Complete snapshot function togther with vm_read to load elements from data to result buffer */
	int temp = 0;
    for (int i=0; i<input_size;i++){
        int value = vm_read(vm,i, thread_id);
        results[i+offset] = value;
    }
}

