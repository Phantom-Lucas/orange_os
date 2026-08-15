#include "syscall.h"

#define LINE_SIZE 128
#define IO_SIZE 512

/* 提示符只在 cd 成功后刷新，避免每次命令完成都额外发起一次 FS IPC。 */
static char prompt_cwd[LINE_SIZE] = "/";

static void write_text(const char* text, unsigned long length) {
    (void)sys_write(1, text, length);
}

static unsigned long text_length(const char* text) {
    unsigned long length = 0;
    while (text[length]) length++;
    return length;
}

static int text_equal(const char* left, const char* right) {
    while (*left && *left == *right) {
        left++;
        right++;
    }
    return *left == *right;
}

static int starts_with(const char* text, const char* prefix) {
    while (*prefix) {
        if (*text++ != *prefix++) return 0;
    }
    return 1;
}

static void prompt(void) {
    static const char prefix[] = "orange:";

    write_text(prefix, sizeof(prefix) - 1);
    write_text(prompt_cwd, text_length(prompt_cwd));
    write_text("$ ", 2);
}

static void refresh_prompt_cwd(void) {
    char path[LINE_SIZE];
    long length = sys_getcwd(path, sizeof(path));
    if (length < 0 || (unsigned long)length >= sizeof(prompt_cwd)) return;
    for (unsigned long i = 0; i < (unsigned long)length; i++) {
        prompt_cwd[i] = path[i];
    }
    prompt_cwd[length] = '\0';
}

static void erase_line_range(unsigned long count) {
    while (count-- != 0) write_text("\b", 1);
}

static void cancel_line(const char* marker) {
    write_text(marker, text_length(marker));
}

static void print_help(void) {
    static const char help[] =
        "commands: help, ls, echo <text>, write <file> <text>, cat <file>,\n"
        "          mkdir <dir>, cd <dir>, pwd, stat <file>, rm <file>,\n"
        "          run <elf>, exec <elf>, clear, exit\n"
        "keys: PageUp/PageDown scroll history, F1/F2/F3 switch console\n"
        "controls: Ctrl+C quit foreground, Ctrl+L clear, Ctrl+U line,\n"
        "         Ctrl+W word, Ctrl+D exit on empty line\n";
    write_text(help, sizeof(help) - 1);
}

static void command_ls(void) {
    char output[IO_SIZE];
    long count = sys_list(output, sizeof(output));
    if (count > 0) write_text(output, (unsigned long)count);
}

static void command_cat(const char* name) {
    char output[IO_SIZE];
    if (text_equal(name, "-")) {
        long count;
        while ((count = sys_read(0, output, sizeof(output))) > 0)
            write_text(output, (unsigned long)count);
        return;
    }
    long fd = sys_open(name, 0);
    if (fd < 0) {
        write_text("cat: file not found\n", 20);
        return;
    }
    long count = sys_read((int)fd, output, sizeof(output));
    (void)sys_close((int)fd);
    if (count > 0) write_text(output, (unsigned long)count);
    write_text("\n", 1);
}

static void command_write(char* args) {
    char* name = args;
    while (*args && *args != ' ') args++;
    if (*args == '\0') {
        write_text("write: expected file and text\n", 30);
        return;
    }
    *args++ = '\0';
    long fd = sys_open(name, O_CREATE);
    if (fd < 0) {
        write_text("write: cannot open file\n", 24);
        return;
    }
    (void)sys_write((int)fd, args, text_length(args));
    (void)sys_close((int)fd);
}

static void command_run(const char* name) {
    char mutable[LINE_SIZE];
    char* argv[16];
    char path[LINE_SIZE];
    unsigned long length = 0;
    int argc = 0;
    int has_suffix = 0;
    while (name[length] && length + 1 < sizeof(mutable)) {
        mutable[length] = name[length];
        length++;
    }
    mutable[length] = '\0';
    char* cursor = mutable;
    while (*cursor && argc + 1 < (int)(sizeof(argv) / sizeof(argv[0]))) {
        while (*cursor == ' ') cursor++;
        if (*cursor == '\0') break;
        argv[argc++] = cursor;
        while (*cursor && *cursor != ' ') {
            if (argc == 1 && *cursor == '.') has_suffix = 1;
            cursor++;
        }
        if (*cursor) *cursor++ = '\0';
    }
    if (argc == 0) return;
    length = 0;
    while (argv[0][length] && length + 1 < sizeof(path)) {
        path[length] = argv[0][length]; length++;
    }
    if (!has_suffix && length + 4 < sizeof(path)) {
        path[length++] = '.'; path[length++] = 'e'; path[length++] = 'l'; path[length++] = 'f';
    }
    path[length] = '\0';
    argv[0] = path;
    long pid = argc == 1 ? sys_spawn(path) :
               sys_spawnv(path, (const char* const*)argv);
    if (pid < 0) {
        write_text("run: executable not found\n", 26);
        return;
    }
    int status = 0;
    (void)sys_wait((unsigned long)pid, &status);
    if (status >= 128) {
        write_text("run: child terminated by exception\n", 35);
    } else {
        write_text("run: child completed\n", 21);
    }
}

static void command_exec(char* text)
{
    char* argv[16];
    char path[LINE_SIZE];
    int argc = 0;
    int has_suffix = 0;
    char* cursor = text;
    while (*cursor && argc + 1 < (int)(sizeof(argv) / sizeof(argv[0]))) {
        while (*cursor == ' ') cursor++;
        if (*cursor == '\0') break;
        argv[argc++] = cursor;
        while (*cursor && *cursor != ' ') {
            if (argc == 1 && *cursor == '.') has_suffix = 1;
            cursor++;
        }
        if (*cursor) *cursor++ = '\0';
    }
    if (argc == 0) return;
    unsigned long length = 0;
    while (argv[0][length] && length + 1 < sizeof(path)) {
        path[length] = argv[0][length]; length++;
    }
    if (!has_suffix && length + 4 < sizeof(path)) {
        path[length++] = '.'; path[length++] = 'e'; path[length++] = 'l'; path[length++] = 'f';
    }
    path[length] = '\0';
    argv[0] = path;
    long result = argc == 1 ? sys_exec(path) :
                  sys_execv(path, (const char* const*)argv);
    if (result < 0)
        write_text("exec: executable not found\n", 27);
}

static void command_pwd(void) {
    char path[128];
    long length = sys_getcwd(path, sizeof(path));
    if (length >= 0) { write_text(path, (unsigned long)length); write_text("\n", 1); }
}

static void command_stat(const char* name) {
    struct sys_stat stat;
    if (sys_stat(name, &stat) == 0) write_text("stat: OK\n", 9);
    else write_text("stat: not found\n", 16);
}

static void run_command(char* line);

static void command_external(char* line)
{
    char* argv[16];
    char path[LINE_SIZE];
    char* cursor = line;
    int argc = 0;
    int has_suffix = 0;
    long child;

    while (*cursor && argc + 1 < (int)(sizeof(argv) / sizeof(argv[0]))) {
        while (*cursor == ' ') cursor++;
        if (*cursor == '\0') break;
        argv[argc++] = cursor;
        while (*cursor && *cursor != ' ') {
            if (argc == 1 && *cursor == '.') has_suffix = 1;
            cursor++;
        }
        if (*cursor) *cursor++ = '\0';
    }
    argv[argc] = 0;
    if (argc == 0) return;
    unsigned long length = 0;
    while (argv[0][length] && length + 1 < sizeof(path)) {
        path[length] = argv[0][length];
        length++;
    }
    if (!has_suffix && length + 4 < sizeof(path)) {
        path[length++] = '.'; path[length++] = 'e'; path[length++] = 'l'; path[length++] = 'f';
    }
    path[length] = '\0';
    child = sys_fork();
    if (child == 0) {
        if (sys_execv(path, (const char* const*)argv) < 0) {
            write_text("command: not found\n", 19);
            sys_exit(127);
        }
        sys_exit(127);
    }
    if (child < 0) {
        write_text("command: fork failed\n", 22);
        return;
    }
    int status = 0;
    (void)sys_wait((unsigned long)child, &status);
}

static char* skip_spaces(char* text) {
    while (*text == ' ') text++;
    return text;
}

static void trim_trailing_spaces(char* text) {
    unsigned long length = text_length(text);
    while (length != 0 && text[length - 1] == ' ') text[--length] = '\0';
}

/* 最小管道语法：左侧命令的 stdout 接到右侧命令的 stdin。 */
static void run_pipeline(char* line, char* separator) {
    int fds[2];
    long child;
    *separator = '\0';
    char* right = skip_spaces(separator + 1);
    trim_trailing_spaces(line);
    if (*line == '\0' || *right == '\0' || sys_pipe(fds) != 0) {
        write_text("pipe: invalid command\n", 22);
        return;
    }
    child = sys_fork();
    if (child == 0) {
        (void)sys_close(fds[0]);
        if (sys_dup2(fds[1], 1) < 0) sys_exit(127);
        (void)sys_close(fds[1]);
        run_command(line);
        sys_exit(0);
    }
    if (child < 0) {
        (void)sys_close(fds[0]);
        (void)sys_close(fds[1]);
        write_text("pipe: fork failed\n", 19);
        return;
    }
    (void)sys_close(fds[1]);
    if (sys_dup2(fds[0], 0) < 0) {
        (void)sys_close(fds[0]);
        return;
    }
    (void)sys_close(fds[0]);
    run_command(right);
    /* 关闭重定向的 stdin，下一条命令继续回退到 TTY。 */
    (void)sys_close(0);
    int status = 0;
    (void)sys_wait((unsigned long)child, &status);
}

static void run_redirected(char* line, char* separator, int append) {
    *separator = '\0';
    char* target = skip_spaces(separator + (append ? 2 : 1));
    trim_trailing_spaces(line);
    trim_trailing_spaces(target);
    if (*line == '\0' || *target == '\0') {
        write_text("redirect: invalid command\n", 28);
        return;
    }
    long fd = sys_open(target, O_CREATE | (append ? O_APPEND : O_TRUNC));
    if (fd < 0 || sys_dup2((int)fd, 1) < 0) {
        if (fd >= 0) (void)sys_close((int)fd);
        write_text("redirect: open failed\n", 23);
        return;
    }
    (void)sys_close((int)fd);
    run_command(line);
    /* 标准输出为空时由内核回退到 TTY。 */
    (void)sys_close(1);
}

static void run_input_redirected(char* line, char* separator)
{
    *separator = '\0';
    char* target = skip_spaces(separator + 1);
    trim_trailing_spaces(line);
    trim_trailing_spaces(target);
    if (*line == '\0' || *target == '\0') {
        write_text("redirect: invalid input\n", 24);
        return;
    }
    long fd = sys_open(target, 0);
    if (fd < 0 || sys_dup2((int)fd, 0) < 0) {
        if (fd >= 0) (void)sys_close((int)fd);
        write_text("redirect: input open failed\n", 28);
        return;
    }
    (void)sys_close((int)fd);
    run_command(line);
    (void)sys_close(0);
}

static void run_command(char* line) {
    unsigned long line_length = text_length(line);
    if (line_length != 0 && line[line_length - 1] == '&') {
        long child;
        line[--line_length] = '\0';
        trim_trailing_spaces(line);
        child = sys_fork();
        if (child == 0) { run_command(line); sys_exit(0); }
        if (child < 0) write_text("background: fork failed\n", 26);
        return;
    }
    char* pipe = line;
    while (*pipe && *pipe != '|') pipe++;
    if (*pipe == '|') {
        run_pipeline(line, pipe);
        return;
    }
    char* input = line;
    while (*input && *input != '<') input++;
    if (*input == '<') {
        run_input_redirected(line, input);
        return;
    }
    char* redirect = line;
    while (*redirect && *redirect != '>') redirect++;
    if (*redirect == '>') {
        int append = redirect[1] == '>';
        run_redirected(line, redirect, append);
        return;
    }
    if (text_equal(line, "help")) print_help();
    else if (text_equal(line, "ls")) command_ls();
    else if (starts_with(line, "echo ")) {
        write_text(line + 5, text_length(line + 5));
        write_text("\n", 1);
    } else if (starts_with(line, "write ")) command_write(line + 6);
    else if (text_equal(line, "cat")) command_cat("-");
    else if (starts_with(line, "cat ")) command_cat(line + 4);
    else if (starts_with(line, "mkdir ")) {
        if (sys_mkdir(line + 6) != 0) write_text("mkdir: failed\n", 15);
    } else if (starts_with(line, "cd ")) {
        if (sys_chdir(line + 3) != 0) {
            write_text("cd: failed\n", 11);
        } else {
            refresh_prompt_cwd();
        }
    } else if (text_equal(line, "pwd")) command_pwd();
    else if (starts_with(line, "stat ")) command_stat(line + 5);
    else if (starts_with(line, "rm ")) {
        if (sys_unlink(line + 3) != 0) write_text("rm: file not found\n", 19);
    } else if (starts_with(line, "run ")) command_run(line + 4);
    else if (starts_with(line, "exec ")) command_exec(line + 5);
    else if (text_equal(line, "clear")) (void)sys_clear();
    else if (text_equal(line, "exit")) sys_exit(0);
    else if (*line) command_external(line);
}

void _start(void) {
    char line[LINE_SIZE];
    char input[LINE_SIZE];
    char echo[LINE_SIZE];
    unsigned long length = 0;
    long input_length;
    write_text("Orange'S user shell ready. Type 'help'.\n", 40);
    prompt();
    while (1) {
        /*
         * 一次读取尽量多取字符。TTY 没有输入时仍只阻塞一次；输入到达
         * 后会把当前队列中的字符批量交给 Shell，避免“每字符一次
         * read IPC + 每字符一次回显 IPC”在压力输入下形成请求洪泛。
         */
        input_length = sys_read(0, input, sizeof(input));
        if (input_length <= 0) continue;

        unsigned long echo_length = 0;
        for (long input_index = 0; input_index < input_length; input_index++) {
            char ch = input[input_index];

            if (ch == 0x03) {          /* Ctrl+C: cancel an input line. */
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                erase_line_range(length);
                cancel_line("^C\n");
                length = 0;
                prompt();
            } else if (ch == 0x1C) {   /* Ctrl+\\: SIGQUIT-style line cancel. */
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                erase_line_range(length);
                cancel_line("^\\\n");
                length = 0;
                prompt();
            } else if (ch == 0x1A) {   /* Ctrl+Z: no job-control stop state yet. */
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                erase_line_range(length);
                cancel_line("^Z\n");
                length = 0;
                prompt();
            } else if (ch == 0x0C) {   /* Ctrl+L: clear and redraw the input. */
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                (void)sys_clear();
                prompt();
                write_text(line, length);
            } else if (ch == 0x15) {   /* Ctrl+U: erase the whole input line. */
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                erase_line_range(length);
                length = 0;
            } else if (ch == 0x17) {   /* Ctrl+W: erase the previous word. */
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                while (length != 0 && line[length - 1] == ' ') {
                    length--;
                    write_text("\b", 1);
                }
                while (length != 0 && line[length - 1] != ' ') {
                    length--;
                    write_text("\b", 1);
                }
            } else if (ch == 0x04) {   /* Ctrl+D: EOF at an empty Shell prompt. */
                if (length == 0) sys_exit(0);
            } else if (ch == '\r' || ch == '\n') {
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                write_text("\n", 1);
                line[length] = '\0';
                run_command(line);
                {
                    int status = 0;
                    /* 回收后台任务；没有僵尸时 WAIT_NOHANG 立即返回。 */
                    while (sys_wait_nohang(0, &status) > 0) { }
                }
                length = 0;
                prompt();
            } else if (ch == '\b') {
                if (echo_length != 0) {
                    write_text(echo, echo_length);
                    echo_length = 0;
                }
                if (length) {
                    length--;
                    write_text("\b", 1);
                }
            } else if (length + 1 < sizeof(line)) {
                line[length++] = ch;
                if (echo_length < sizeof(echo)) echo[echo_length++] = ch;
            }
        }
        if (echo_length != 0) {
            write_text(echo, echo_length);
        }
    }
}
