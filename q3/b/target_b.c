#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void win() {
    printf("You have passed!\n");
    exit(0);
}

void vuln() {
    char buf[64];
    read(0, buf, 200);   /* intentional overflow */
}

int main() {
    win();
    return 0;
}
