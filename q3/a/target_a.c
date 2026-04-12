#include <stdio.h>
#include <string.h>

int main() {
    char input[256];
    fgets(input, 256, stdin);
    input[strcspn(input, "\n")] = '\0';
    if (strcmp(input, "D!vy4nsh_4tr1") == 0)
        printf("Access granted!\n");
    else
        printf("Wrong password!\n");
    return 0;
}
