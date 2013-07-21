#include <errno.h>
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

char *
filter_path(char *cwd)
{
    char *home = getenv("HOME");
    if (home && strlen(home) > 0 && strncmp(cwd, home, strlen(home)) == 0) {
        char *before = cwd + strlen(home) - 1;
        *before = '~';
        return strdup(before);
    }
    return cwd;
}

char *
filter_battery(char *battery)
{
    char *useless = strstr(battery, ", discharging at zero rate - will never fully discharge.");
    if (useless)
        *useless = '\0';
    useless = strstr(battery, " until charged");
    if (useless)
        *useless = '\0';
    useless = strstr(battery, "\n");
    if (useless)
        *useless = '\0';
    char *discharging = strstr(battery, "Discharging, ");
    if (discharging) {
        discharging += strlen("Discharging, ") - 3;
        /* 0xE2 0x86 0x93 */
        discharging[0] = 0xE2;
        discharging[1] = 0x86;
        discharging[2] = 0x93;
        return strdup(discharging);
    }
    char *charging = strstr(battery, "Charging, ");
    if (charging) {
        charging += strlen("Charging, ") - 3;
        /* 0xE2 0x86 0x91 */
        charging[0] = 0xE2;
        charging[1] = 0x86;
        charging[2] = 0x91;
        return strdup(charging);
    }
    char *full = strstr(battery, "Full, ");
    if (full)
        return "";
    return battery;
}

char *
filter_qtop(char *qtop)
{
    if (strstr(qtop, "no patches applied"))
        return "∅";
    char *useless = strstr(qtop, "\n");
    if (useless)
        *useless = '\0';
    return qtop;
}

const static long int Minutes = 60;
const static long int Hours = 60 * 60;
const static long int Days = 24 * 60 * 60;

char *
filter_time(char *time)
{
    /* If the time is "0", as we get from bash, return Epsilon. */
    if (strlen(time) == 1 && *time == '0')
        return "ε";

    char *end;
    long int sec = strtol(time, &end, 10);

    /* If it is not fully numeric, then it is already formatted. */
    if (*end != '\0')
        return time;

    long int days = 0;
    if (sec >= Days) {
        days = sec / Days;
        sec -= days * Days;
    }

    long int hours = 0;
    if (sec >= Hours) {
        hours = sec / Hours;
        sec -= hours * Hours;
    }

    long int min = 0;
    if (sec >= Minutes) {
        min = sec / Minutes;
        sec -= min * Minutes;
    }

    char buffer[256];
    if (days > 0) {
    } else if (hours > 0) {
    } else if (min > 0) {
    } else {
        snprintf(buffer, sizeof(buffer), "%lds", days);
    }
    return strdup(buffer);
}

void
color(int code, int mod)
{
    printf("\x1b[%d;%dm", code, mod);
}

void red() { color(31, 2); }
void bright_red() { color(31, 1); }
void green() { color(32, 1); }
void blue() { color(34, 2); }
void bright_blue() { color(34, 1); }
void magenta() { color(35, 2); }
void bright_magenta() { color(35, 1); }
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
    printf("%s", (s));               \
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
/------------------------------------------------. time
| $path /  \ qtop /  \ battery /       user@host \------
\->
*/
void
print_line0(int status, int width, char *cwd, char *qtop, char *battery,
            char *commandTime)
{
    size_t offset = 0;

    /* Path */
    clr(status);
    PUT("╭─", 2);
    PUTn("─", utf8_strlen(cwd));
    PUT("─┬──", 4);

    /* QTop */
    if (*qtop) {
        PUT("┬─", 2);
        PUTn("─", utf8_strlen(qtop));
        PUT("─┬", 2);
        PUT("──", 2);
    }

    /* Battery */
    if (*battery) {
        PUT("┬─", 2);
        PUTn("─", utf8_strlen(battery));
        PUT("─┬", 2);
    }

    /* ---- */
    size_t lenTime = utf8_strlen(commandTime);
    if (offset + lenTime + 4 > width) {
        printf("\n");
        return;
    }
    PUTn("─", width - offset - lenTime - 3);

    /* Time */
    clr(status);
    PUT("╮ ", 2);
    magenta();
    PUT(commandTime, lenTime);

    printf("\n");
}

void
print_line1(int status, int width, char *cwd, char *qtop, char *battery,
            char *user, char *hostname, char *commandTime)
{
    size_t offset = 0;

    clr(status);
    PUT("├ ", 2);
    bright_white();
    PUT(cwd, utf8_strlen(cwd));
    clr(status);
    PUT(" ╯  ", 4);

    if (*qtop) {
        clr(status);
        PUT("╰ ", 2);
        magenta();
        PUT(qtop, utf8_strlen(qtop));
        PUT(" ╯  ", 4);
    }

    if (*battery) {
        clr(status);
        PUT("╰ ", 2);
        bright_red();
        PUT(battery, utf8_strlen(battery));
        clr(status);
        PUT(" ╯  ", 4);
    }

    size_t lenUser = utf8_strlen(user);
    size_t lenHost = utf8_strlen(hostname);
    size_t lenTime = utf8_strlen(commandTime);
    size_t lenRight = lenUser + lenHost + lenTime + 5;
    if (offset + lenRight > width) {
        printf("\n");
        return;
    }
    PUTn(" ", width - offset - lenRight);
    green();
    PUT(user, lenUser);
    bright_white();
    PUT("@", 1);
    bright_blue();
    PUT(hostname, lenHost);
    clr(status);
    PUT(" ╰", 2);
    PUTn("─", lenTime + 2);

    printf("\n");
}

/* \->  */
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
     * Assume that we will be called correctly and spawn our long-running
     * commands immediately so that they can process in the background while
     * we work here.
     */
    char *acpiArgs[] = {"acpi", "-b", NULL};
    ChildInfo acpi = spawn("acpi", acpiArgs);
    if (acpi.pid == 0) {
        fprintf(stderr, "Failed to spawn acpi\n");
        return 1;
    }

    char *qtopArgs[] = {"hg", "qtop", NULL};
    ChildInfo qtopCmd = spawn("hg", qtopArgs);
    if (qtopCmd.pid == 0) {
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

    char *user = getenv("USER");
    if (!user)
        user = "";

    char hostname[256];
    memset(hostname, 0, sizeof(hostname));
    gethostname(hostname, sizeof(hostname));

    char *commandTime = (argc >= 4) ? strdup(argv[3]) : "ε";
    commandTime = filter_time(commandTime);

    /* Read the processes we spawned. */
    char *acpiOut = readChild(acpi);
    if (!acpiOut) {
        fprintf(stderr, "Failed to read ACPI command.\n");
        return 1;
    }
    char *battery = filter_battery(acpiOut);

    char *qtopOut = readChild(qtopCmd);
    if (!qtopOut) {
        fprintf(stderr, "Failed to read hg qtop command.\n");
        return 1;
    }
    char *qtop = filter_qtop(qtopOut);

    /* Get the current directory. */
    char *cwd = getcwd(NULL, 0);
    cwd = filter_path(cwd);

    print_line0(status, width, cwd, qtop, battery, commandTime);
    print_line1(status, width, cwd, qtop, battery,
                user, hostname, commandTime);
    print_line2(status);

    return 0;
}

