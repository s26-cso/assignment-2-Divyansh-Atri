#include <stdio.h>
#include <string.h>

int main() {
    char input[256] = {0};
    fgets(input, 256, stdin);
    input[strcspn(input, "\n")] = '\0';
    if (strcmp(input, "D!vy4nsh_4tr1") == 0) {
        printf("You have passed!\n");
    } else {
        printf("Wrong password!\n");
    }
    return 0;
}
