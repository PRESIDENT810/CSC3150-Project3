#ifndef VIRTUAL_MEMORY_H
#define VIRTUAL_MEMORY_H

#include <cuda.h>
#include <cuda_runtime.h>
#include <inttypes.h>

typedef unsigned char uchar;
typedef uint32_t u32;

struct Page_node {
	int page_idx;
	struct Page_node *nxt;
};

struct VirtualMemory {
    uchar *buffer;
    uchar *storage;
    int *invert_page_table;
    int *pagefault_num_ptr;
    struct Page_node *LRU_head;
	int current_thread;

    int PAGESIZE;
    int INVERT_PAGE_TABLE_SIZE;
    int PHYSICAL_MEM_SIZE;
    int STORAGE_SIZE;
    int PAGE_ENTRIES;
};

// TODO
__device__ void vm_init(VirtualMemory *vm, uchar *buffer, uchar *storage,
                        int *invert_page_table, int *pagefault_num_ptr,
                        int PAGESIZE, int INVERT_PAGE_TABLE_SIZE,
                        int PHYSICAL_MEM_SIZE, int STORAGE_SIZE,
                        int PAGE_ENTRIES, int current_thread);
__device__ uchar vm_read(VirtualMemory *vm, u32 addr, int thread_id);
__device__ void vm_write(VirtualMemory *vm, u32 addr, uchar value, int thread_id);
__device__ void vm_snapshot(VirtualMemory *vm, uchar *results, int offset,
                            int input_size, int thread_id);

#endif
