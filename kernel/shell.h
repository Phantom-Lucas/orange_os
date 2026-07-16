// kernel/shell.h

#ifndef SHELL_H
#define SHELL_H

// 初始化 shell，打印提示符
void shell_init(void);

// 执行命令的核心逻辑
void execute_command(char* cmd);

// 这个函数专门用来吃掉键盘传来的字符，并处理回车退格逻辑
void shell_take_char(char c);

#endif