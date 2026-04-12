#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void win() {
    printf("You win!\n");
    exit(0);
}

void vuln() {
    char buf[64];
    read(0, buf, 200);   /* intentional overflow */
}

int main() {
    vuln();
    return 0;
}
