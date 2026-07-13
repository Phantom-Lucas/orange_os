// kernel/kernel.c

void kernel_main() {
    // 64 位下，显存地址可以直接通过 0xb8000 物理地址寻址
    // 'M' 在 0xb8000, 'L' 在 0xb8002, 'P' 在 0xb8004, '6' 在 0xb8008
    // 我们把 'C' 打印在第 6 个字符位置 (0xb8000 + 10)
    char* video_memory = (char*)0xb800a; 
    
    video_memory[0] = 'C';
    video_memory[1] = 0x1F; // 蓝底白字属性

    while (1) {
        // 内核悬停
    }
}