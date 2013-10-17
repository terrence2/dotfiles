all:
	gcc -O3 -Werror -Wall -std=gnu1x -o brightness brightness.c
	gcc -O3 -Werror -Wall -std=gnu1x -o prompt prompt.c

setuid:
	chown root:root brightness
	chmod 4755 brightness
