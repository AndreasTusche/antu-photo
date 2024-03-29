// realpath.c: display the absolute path to a file or directory.
// Adam Liss, August, 2007
// This program is provided "as-is" to the public domain, without express or
// implied warranty, for any non-profit use, provided this notice is maintained.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>   
#include <limits.h>

static char *sMyName;
//void usage(void);
void usage(void) {
    fprintf(stderr, "usage: %s PATH\n", sMyName);
    exit(1);
}

int main(int argc, char *argv[]) {
    char sPath[PATH_MAX];
    sMyName = strdup(basename(argv[0]));

    if (argc < 2)   usage();

    printf("%s\n", realpath(argv[1], sPath));
    return 0;
}    

