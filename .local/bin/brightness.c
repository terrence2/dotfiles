#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define BASE "/sys/devices/platform/s3c24xx-pwm.0/pwm-backlight.0/backlight/pwm-backlight.0"
#define BRIGHTNESS_FILE (BASE "/brightness")
#define MAX_BRIGHTNESS_FILE (BASE "/max_brightness")

double max(double a, double b) { return a > b ? a : b; }
double min(double a, double b) { return a < b ? a : b; }

static double
get_brightness_in(const char *filename)
{
    FILE *fp = fopen(filename, "rb");
    if (!fp) {
        fprintf(stderr, "Failed to open: %s -> %s\n", filename,
                strerror(errno));
        return 1.0;
    }
    char data[256];
    memset(data, 0, 256);
    int rv = fread(data, 1, 255, fp);
    fclose(fp);
    if (-1 == rv) {
        fprintf(stderr, "Failed to get max brightness\n");
        return 1.0;
    }
    return strtod(data, NULL);
}

void
set_brightness(int amount)
{
    char data[256];
    int rv = snprintf(data, 255, "%d", amount);
    if (rv < 0) {
        fprintf(stderr, "Failed to serialize: %d\n", amount);
        return;
    }
    FILE *fp = fopen(BRIGHTNESS_FILE, "wb");
    if (!fp) {
        fprintf(stderr, "Failed to open: %s -> %s\n", BRIGHTNESS_FILE,
                strerror(errno));
        return;
    }
    rv = fwrite(data, 1, strlen(data), fp);
    fclose(fp);
    if (-1 == rv) {
        fprintf(stderr, "Failed to write: %s -> %s\n", BRIGHTNESS_FILE,
                strerror(errno));
        return;
    }
}

static double
get_max_brightness()
{
    return get_brightness_in(MAX_BRIGHTNESS_FILE);
}

static double
get_current_brightness()
{
    return get_brightness_in(BRIGHTNESS_FILE);
}

void
update_relative(double fract)
{
    double curb = get_current_brightness();
    double maxb = get_max_brightness();
    double newb = curb + (fract * maxb);
    newb = max(0, newb);
    newb = min(maxb, newb);
    printf("%f -> %f of %f\n", curb, newb, maxb);
    set_brightness((int)newb);
}

void
update_absolute(double fract)
{
    double maxb = get_max_brightness();
    double newb = fract * maxb;
    newb = max(0, newb);
    newb = min(maxb, newb);
    printf("%f of %f\n", newb, maxb);
    set_brightness((int)newb);
}

int
main(int argc, char **argv)
{
    if (argc < 2) {
        printf("brightness <fraction|+|->\n\n");
        printf("\tChange backlight brightness on an ARM chromebook.\n");
        return 1;
    }

    char hostname[256];
    memset(hostname, 0, 256);
    if (gethostname(hostname, 255)) {
        fprintf(stderr, "Failed to get host name\n");
        return 1;
    }

    if (hostname != strstr(hostname, "capuchin")) {
        fprintf(stderr, "Unrecognized host name\n");
        return 1;
    }

    if (argv[1][0] == '+') {
        update_relative(1.0/20.0);
        return 0;
    } else if (argv[1][0] == '-') {
        update_relative(-1.0/20.0);
        return 0;
    }
    double fract = strtod(argv[1], NULL);
    update_absolute(fract / 100.0);
    return 0;
}
