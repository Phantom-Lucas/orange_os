#include "syscall.h"
#include "term.h"

#define LINE_SIZE 256
#define IO_SIZE 512
#define HISTORY_SIZE 64

/* 提示符只在 cd 成功后刷新，避免每次命令完成都额外发起一次 FS IPC。 */
static char prompt_cwd[LINE_SIZE] = "/";
/* ANSI remains an optional independent capability; the theme does not depend on it. */
static int style_enabled = 0;

struct shell_editor {
    char line[LINE_SIZE];
    unsigned long length;
    unsigned long cursor;
    char history[HISTORY_SIZE][LINE_SIZE];
    unsigned long history_count;
    long history_view;
    char draft[LINE_SIZE];
    char kill_ring[LINE_SIZE];
    unsigned long previous_render_length;
    int suggestion_index;
    int escape_state;
    char search[LINE_SIZE];
    unsigned long search_length;
    char search_saved[LINE_SIZE];
    int search_active;
    long search_index;
};

static struct shell_editor editor;

static unsigned long text_length(const char* text);

static void write_text(const char* text, unsigned long length) {
    (void)sys_write(1, text, length);
}

static void write_styled(const char* style, const char* text,
                         unsigned long length) {
    if (style_enabled) write_text(style, text_length(style));
    write_text(text, length);
    if (style_enabled) write_text(RESET, text_length(RESET));
}

static void write_styled_text(const char* style, const char* text) {
    write_styled(style, text, text_length(text));
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
    static const char prefix[] = "orange@orange-os:";

    write_styled(CYAN, prefix, sizeof(prefix) - 1);
    write_styled(BLUE, prompt_cwd, text_length(prompt_cwd));
    write_styled(YELLOW, "$ ", 2);
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

static void draw_welcome(void) {
    write_styled_text(YELLOW, "Orange/64 Terminal\n");
    write_styled_text(MUTED, "Type 'help' to list commands.\n\n");
}

static void print_help(void) {
    static const char help[] =
        "Commands:\n"
        "  help              show this help\n"
        "  ls                list directory\n"
        "  cat <file>        print file\n"
        "  echo <text>       print text\n"
        "  mkdir <dir>       create directory\n"
        "  cd <dir>          change directory\n"
        "  pwd               print working directory\n"
        "  ps                list processes\n"
        "  run <program>     start a program\n"
        "  clear             clear terminal\n"
        "\n"
        "Keyboard:\n"
        "  F1-F3             switch console\n"
        "  PgUp/PgDn         scroll history\n"
        "  Ctrl+L            clear screen\n"
        "  Ctrl+C            interrupt foreground process\n"
        "\n";
    write_styled_text(MUTED, help);
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
        /* The left side writes to a pipe, never to a terminal. */
        style_enabled = 0;
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
    int previous_style = style_enabled;
    style_enabled = 0;
    run_command(line);
    style_enabled = previous_style;
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
    int previous_style = style_enabled;
    style_enabled = 0;
    run_command(line);
    style_enabled = previous_style;
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
    else if (text_equal(line, "demo")) command_run("showcase.elf");
    else if (starts_with(line, "exec ")) command_exec(line + 5);
    else if (text_equal(line, "clear")) (void)sys_clear();
    else if (text_equal(line, "about")) {
        (void)sys_clear();
        draw_welcome();
    }
    else if (text_equal(line, "exit")) sys_exit(0);
    else if (*line) command_external(line);
}

static void copy_text(char* destination, const char* source, unsigned long length) {
    if (length >= LINE_SIZE) length = LINE_SIZE - 1;
    for (unsigned long i = 0; i < length; i++) destination[i] = source[i];
    destination[length] = '\0';
}

static int contains_text(const char* text, const char* needle) {
    if (!*needle) return 1;
    for (; *text; text++) {
        const char* a = text;
        const char* b = needle;
        while (*a && *b && *a == *b) { a++; b++; }
        if (!*b) return 1;
    }
    return 0;
}

static int editor_suggestion(void) {
    if (editor.cursor != editor.length || editor.length == 0 || editor.search_active)
        return -1;
    for (long i = (long)editor.history_count - 1; i >= 0; i--) {
        unsigned long j = 0;
        while (j < editor.length && editor.history[i][j] == editor.line[j]) j++;
        if (j == editor.length && editor.history[i][j] != '\0') return (int)i;
    }
    return -1;
}

static void editor_redraw(void) {
    unsigned long visible = editor.length;
    editor.suggestion_index = editor_suggestion();
    if (editor.suggestion_index >= 0) {
        unsigned long suggestion_length = text_length(editor.history[editor.suggestion_index]);
        if (suggestion_length > visible) visible = suggestion_length;
    }
    write_text("\r", 1);
    prompt();
    write_text(editor.line, editor.length);
    if (editor.suggestion_index >= 0) {
        const char* suffix = editor.history[editor.suggestion_index] + editor.length;
        write_styled(MUTED, suffix, text_length(suffix));
    }
    while (visible < editor.previous_render_length) { write_text(" ", 1); visible++; }
    write_text("\r", 1);
    prompt();
    write_text(editor.line, editor.cursor);
    editor.previous_render_length = visible;
}

static void editor_clear(void) {
    editor.length = 0; editor.cursor = 0; editor.line[0] = '\0';
    editor.history_view = -1; editor.previous_render_length = 0;
}

static void editor_insert(const char* text, unsigned long length) {
    if (length > LINE_SIZE - 1 - editor.length) length = LINE_SIZE - 1 - editor.length;
    for (unsigned long i = editor.length; i > editor.cursor; i--)
        editor.line[i + length - 1] = editor.line[i - 1];
    for (unsigned long i = 0; i < length; i++) editor.line[editor.cursor + i] = text[i];
    editor.length += length; editor.cursor += length; editor.line[editor.length] = '\0';
}

static void editor_delete(unsigned long start, unsigned long end) {
    if (start > editor.length) start = editor.length;
    if (end > editor.length) end = editor.length;
    if (end < start) end = start;
    for (unsigned long i = end; i <= editor.length; i++) editor.line[start + i - end] = editor.line[i];
    editor.length -= end - start;
    if (editor.cursor > end) editor.cursor -= end - start;
    else if (editor.cursor > start) editor.cursor = start;
}

static void editor_store_history(void) {
    if (!editor.length || (editor.history_count &&
        text_equal(editor.history[editor.history_count - 1], editor.line))) return;
    if (editor.history_count == HISTORY_SIZE) {
        for (unsigned long i = 1; i < HISTORY_SIZE; i++)
            copy_text(editor.history[i - 1], editor.history[i], text_length(editor.history[i]));
        editor.history_count--;
    }
    copy_text(editor.history[editor.history_count++], editor.line, editor.length);
}

static void editor_history_previous(void) {
    if (!editor.history_count) return;
    if (editor.history_view < 0) {
        copy_text(editor.draft, editor.line, editor.length);
        editor.history_view = (long)editor.history_count - 1;
    } else if (editor.history_view > 0) editor.history_view--;
    copy_text(editor.line, editor.history[editor.history_view],
              text_length(editor.history[editor.history_view]));
    editor.length = text_length(editor.line); editor.cursor = editor.length;
}

static void editor_history_next(void) {
    if (editor.history_view < 0) return;
    if ((unsigned long)(editor.history_view + 1) < editor.history_count) {
        editor.history_view++;
        copy_text(editor.line, editor.history[editor.history_view],
                  text_length(editor.history[editor.history_view]));
    } else {
        editor.history_view = -1;
        copy_text(editor.line, editor.draft, text_length(editor.draft));
    }
    editor.length = text_length(editor.line); editor.cursor = editor.length;
}

static void editor_kill(unsigned long start, unsigned long end) {
    if (end < start) end = start;
    copy_text(editor.kill_ring, editor.line + start, end - start);
    editor_delete(start, end);
}

static void editor_complete(void) {
    static const char* commands[] = {"about", "cat", "cd", "clear", "demo", "echo",
        "exec", "exit", "help", "ls", "mkdir", "ps", "pwd", "rm", "run", "stat", "write"};
    unsigned long prefix = 0, matches = 0, common = 0;
    const char* first = 0;
    while (prefix < editor.length && editor.line[prefix] != ' ') prefix++;
    if (prefix != editor.length) return;
    for (unsigned long i = 0; i < sizeof(commands) / sizeof(commands[0]); i++) {
        unsigned long j = 0;
        while (j < prefix && commands[i][j] == editor.line[j]) j++;
        if (j != prefix) continue;
        if (!matches) { common = text_length(commands[i]); first = commands[i]; }
        else {
            unsigned long k = 0;
            while (k < common && commands[i][k] == first[k]) k++;
            common = k;
        }
        matches++;
    }
    if (!matches) return;
    const char* base = 0;
    for (unsigned long i = 0; i < sizeof(commands) / sizeof(commands[0]); i++) {
        unsigned long j = 0; while (j < prefix && commands[i][j] == editor.line[j]) j++;
        if (j == prefix) { base = commands[i]; break; }
    }
    if (base && common > prefix) editor_insert(base + prefix, common - prefix);
    if (matches == 1) editor_insert(" ", 1);
}

static int editor_search_find(int older) {
    long start = editor.search_index;
    if (start < 0 || !older) start = (long)editor.history_count - 1;
    else start--;
    for (long i = start; i >= 0; i--) {
        if (contains_text(editor.history[i], editor.search)) {
            editor.search_index = i;
            copy_text(editor.line, editor.history[i], text_length(editor.history[i]));
            editor.length = text_length(editor.line); editor.cursor = editor.length;
            return 1;
        }
    }
    return 0;
}

static void editor_search_redraw(void) {
    write_text("\r(reverse-i-search)`", text_length("\r(reverse-i-search)`"));
    write_text(editor.search, editor.search_length);
    write_text("': ", 3);
    write_text(editor.line, editor.length);
}

void _start(void) {
    char input[LINE_SIZE];
    long input_length;
    draw_welcome();
    editor_clear();
    prompt();
    while (1) {
        /*
         * 一次读取尽量多取字符。TTY 没有输入时仍只阻塞一次；输入到达
         * 后会把当前队列中的字符批量交给 Shell，避免“每字符一次
         * read IPC + 每字符一次回显 IPC”在压力输入下形成请求洪泛。
         */
        input_length = sys_read(0, input, sizeof(input));
        if (input_length <= 0) continue;

        for (long input_index = 0; input_index < input_length; input_index++) {
            char ch = input[input_index];
            if (editor.escape_state == 1) {
                editor.escape_state = ch == '[' ? 2 : 0;
                continue;
            }
            if (editor.escape_state == 2) {
                if (ch == '3') { editor.escape_state = 3; continue; }
                editor.escape_state = 0;
                if (ch == 'A') editor_history_previous();
                else if (ch == 'B') editor_history_next();
                else if (ch == 'C') {
                    if (editor.cursor < editor.length) editor.cursor++;
                    else if (editor.suggestion_index >= 0)
                        editor_insert(editor.history[editor.suggestion_index] + editor.length,
                                      text_length(editor.history[editor.suggestion_index]) - editor.length);
                } else if (ch == 'D' && editor.cursor) editor.cursor--;
                else if (ch == 'H') editor.cursor = 0;
                else if (ch == 'F') {
                    if (editor.suggestion_index >= 0)
                        editor_insert(editor.history[editor.suggestion_index] + editor.length,
                                      text_length(editor.history[editor.suggestion_index]) - editor.length);
                    else editor.cursor = editor.length;
                }
                editor_redraw();
                continue;
            }
            if (editor.escape_state == 3) {
                editor.escape_state = 0;
                if (ch == '~') { editor_delete(editor.cursor, editor.cursor + 1); editor_redraw(); }
                continue;
            }
            if (ch == '\033') { editor.escape_state = 1; continue; }

            if (editor.search_active) {
                if (ch == 0x03) {
                    copy_text(editor.line, editor.search_saved, text_length(editor.search_saved));
                    editor.length = text_length(editor.line); editor.cursor = editor.length;
                    editor.search_active = 0; editor_redraw();
                } else if (ch == '\r' || ch == '\n') {
                    editor.search_active = 0; write_text("\n", 1); editor.previous_render_length = 0; prompt(); editor_redraw();
                } else if (ch == 0x12) {
                    (void)editor_search_find(1); editor_search_redraw();
                } else if (ch == '\b' && editor.search_length) {
                    editor.search[--editor.search_length] = '\0'; editor.search_index = -1;
                    (void)editor_search_find(0); editor_search_redraw();
                } else if (ch >= 32 && ch < 127 && editor.search_length + 1 < LINE_SIZE) {
                    editor.search[editor.search_length++] = ch; editor.search[editor.search_length] = '\0';
                    editor.search_index = -1; (void)editor_search_find(0); editor_search_redraw();
                }
                continue;
            }

            if (ch == 0x03) {
                cancel_line("^C\n");
                editor_clear();
                prompt();
            } else if (ch == 0x1C) {
                cancel_line("^\\\n");
                editor_clear();
                prompt();
            } else if (ch == 0x1A) {
                cancel_line("^Z\n");
                editor_clear();
                prompt();
            } else if (ch == 0x0C) {
                (void)sys_clear();
                editor.previous_render_length = 0; editor_redraw();
            } else if (ch == 0x01) { editor.cursor = 0; editor_redraw();
            } else if (ch == 0x05) { editor.cursor = editor.length; editor_redraw();
            } else if (ch == 0x15) { editor_kill(0, editor.cursor); editor_redraw();
            } else if (ch == 0x0B) { editor_kill(editor.cursor, editor.length); editor_redraw();
            } else if (ch == 0x17) {
                unsigned long start = editor.cursor;
                while (start && editor.line[start - 1] == ' ') start--;
                while (start && editor.line[start - 1] != ' ') start--;
                editor_kill(start, editor.cursor); editor_redraw();
            } else if (ch == 0x19) { editor_insert(editor.kill_ring, text_length(editor.kill_ring)); editor_redraw();
            } else if (ch == 0x12) {
                copy_text(editor.search_saved, editor.line, editor.length);
                editor.search_active = 1; editor.search_length = 0; editor.search[0] = '\0'; editor.search_index = -1;
                (void)editor_search_find(0); editor_search_redraw();
            } else if (ch == '\t') { editor_complete(); editor_redraw();
            } else if (ch == 0x04) {
                if (editor.length == 0) sys_exit(0);
            } else if (ch == '\r' || ch == '\n') {
                write_text("\n", 1);
                editor.line[editor.length] = '\0';
                editor_store_history();
                run_command(editor.line);
                {
                    int status = 0;
                    /* 回收后台任务；没有僵尸时 WAIT_NOHANG 立即返回。 */
                    while (sys_wait_nohang(0, &status) > 0) { }
                }
                editor_clear();
                prompt();
            } else if (ch == '\b') {
                if (editor.cursor) { editor_delete(editor.cursor - 1, editor.cursor); editor_redraw(); }
            } else if (ch >= 32 && ch < 127) {
                editor_insert(&ch, 1); editor_redraw();
            }
        }
    }
}
