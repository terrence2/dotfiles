#include <errno.h>
#include <glib.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

/* FIXME: handle combining chars. */
size_t
utf8_strlen(char *s)
{
   size_t len = 0;
   while (*s) {
     if ((*s++ & 0xc0) != 0x80)
         ++len;
   }
   return len;
}

typedef struct ChildInfo_s {
    pid_t pid;
    int read;
} ChildInfo;

ChildInfo
spawn(char *file, char **argv)
{
    ChildInfo out = {0, 0};

    int fds[2];
    int rv = pipe(fds);
    if (rv == -1)
        return out;
    out.read = fds[0];

    out.pid = fork();
    if (out.pid) { /* parent */
        close(fds[1]);
        return out;
    }

    close(fds[0]);
    close(0);
    close(1);
    close(2);

    /* stdout to our parent. */
    dup2(fds[1], 1);

    /* stderr to /dev/null. */
    int err = open("/dev/null", O_NONBLOCK | O_WRONLY);
    if (err == -1)
        exit(1);
    dup2(err, 2);

    rv = execvp(file, argv);
    if (rv)
        exit(1);

    /* Unreachable. */
    return out;
}

char *
readChild(ChildInfo child)
{
    int status;
    int rv = waitpid(child.pid, &status, 0);
    if (rv == -1)
        return NULL;

    rv = fcntl(child.read, F_SETFL, O_NONBLOCK);
    if (rv == -1)
        return NULL;

    char buffer[4096];
    memset(buffer, 0, sizeof(buffer));
    int retc = read(child.read, buffer, sizeof(buffer) - 1);
    if (retc < 0)
        return NULL;

    return strdup(buffer);
}

void
color(int code, int mod)
{
    printf("\x1b[%d;%dm", code, mod);
}

void red() { color(31, 1); }
void green() { color(32, 1); }
void blue() { color(34, 1); }
void bright_blue() { color(34, 2); }
void bright_white() { color(37, 1); }
void normal() { color(37, 0); }

void
clr(int status) {
    if (status)
        red();
    else
        blue();
}

#define PUT(s, l) do {               \
    if (offset + (l) > width) {      \
        printf("\n");                \
        return;                      \
    }                                \
    printf((s));                     \
    offset += (l); } while(0);

#define PUTn(s, n) do {              \
    size_t tmp = (n);                \
    if (offset + tmp > width) {      \
        printf("\n");                \
        return;                      \
    }                                \
    for (size_t i = 0; i < tmp; ++i) \
        printf((s));                 \
    offset += tmp; } while(0);

/*
/-------===-------===----------===============------
| $path /  \ qtop /  \ battery /             \ time
\->
*/
void
print_line0(int status, int width, char *cwd, char *qtop, char *battery, char *commandTime)
{
    size_t offset = 0;

    // Path
    clr(status);
    PUT("╭─", 2);
    PUTn("─", utf8_strlen(cwd));
    PUT("─┮━━", 4);

    // QTop
    if (*qtop) {
        PUT("┭─", 2);
        PUTn("─", utf8_strlen(qtop));
        PUT("─┮", 2);
    }

    PUT("━━", 2);

    // Battery
    if (*battery) {
        PUT("┭─", 2);
        PUTn("─", utf8_strlen(battery));
        PUT("─┮", 2);
    }

    // ----
    size_t len = strlen(commandTime);
    if (offset + len + 4 > width) {
        printf("\n");
        return;
    }

    // Time
    PUTn("━", width - offset - len - 3);
    PUT("┭", 1);
    PUTn("─", strlen(commandTime) + 2);

    printf("\n");
}

void
print_line1(int status, int width, char *cwd, char *qtop, char *battery, char *commandTime)
{
    clr(status);
    printf("╞ ");

    char *pwd = getcwd(NULL, 0);
    bright_white();
    printf("%s", pwd);
    clr(status);
    printf(" ╯");

    printf("\n");
}

// \-> 
void
print_line2(int status)
{
    clr(status);
    printf("╰> ");
    normal();
}

/*
 * Arg0 - invoked as name
 * Arg1 - success status
 * Arg2 - width of terminal
 * Arg3 - previous command time (optional)
 */
int
main(int argc, char **argv)
{
    /*
     * Assume that we will be called correctly and spawn our long-running commands immediately so
     * that they can process in the background while we work here.
     */
    char *acpiArgs[] = {"acpi", "-a", NULL};
    ChildInfo acpi = spawn("acpi", acpiArgs);
    if (acpi.pid == 0) {
        fprintf(stderr, "Failed to spawn acpi\n");
        return 1;
    }

    char *qtopArgs[] = {"hg", "qtop", NULL};
    ChildInfo qtop = spawn("hg", qtopArgs);
    if (qtop.pid == 0) {
        fprintf(stderr, "Failed to spawn ht qtop\n");
        return 1;
    }

    if (argc < 3) {
        fprintf(stderr, "Requires at least 3 arguments.\n");
        return 1;
    }

    long int status = strtoll(argv[1], NULL, 10);
    if (errno != 0 && status == 0) {
        fprintf(stderr, "Failed to parse status.\n");
        return 1;
    }

    long int width = strtoll(argv[2], NULL, 10);
    if (errno != 0 && width == 0) {
        fprintf(stderr, "Failed to parse width.\n");
        return 1;
    }

    char *commandTime = (argc >= 4) ? strdup(argv[3]) : NULL;

    /* Read the processes we spawned. */
    char *acpiOut = readChild(acpi);
    if (!acpiOut) {
        fprintf(stderr, "Failed to read ACPI command.\n");
        return 1;
    }
    char *qtopOut = readChild(qtop);
    if (!qtopOut) {
        fprintf(stderr, "Failed to read hg qtop command.\n");
        return 1;
    }

    /* Get the current directory. */
    char *cwd = getcwd(NULL, 0);

    /* Store offsets of where we put things on line 1 so that line 0 can adapt. */
    /*
    size_t offPath = 0;
    size_t offStart[16] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    size_t offEnd[16] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    */

    print_line0(status, width, cwd, qtopOut, acpiOut, commandTime);
    print_line1(status, width, cwd, qtopOut, acpiOut, commandTime);
    print_line2(status);


    printf("%ld%ld%s:%s:%s\n", status, width, commandTime, acpiOut, qtopOut);
    return 0;
}

