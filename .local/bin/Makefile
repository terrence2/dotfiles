all:
	gcc -O3 -Werror -Wall -std=gnu11 -o brightness brightness.c
	gcc -O3 -Werror -Wall -std=gnu11 `pkg-config glib-2.0 --cflags --libs` -o prompt prompt.c

setuid:
	chown root:root brightness
	chmod 4755 brightness
