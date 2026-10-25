section .note.GNU-stack noalloc noexec nowrite progbits ; Wyłącza błąd linkera
section .data

    ;Klucze
    klucz dd 0x01234567, 0x89ABCDEF, 0xFEDCBA98, 0x76543210

    ; Stała XTEA
    DELTA equ 0x9E3779B9

section .text
    global klucz
    global szyfruj_blok
    global deszyfruj_blok

szyfruj_blok:
    
    mov r8d, dword [rdi]
    mov r9d, dword [rdi+4]
    
    xor r10d, r10d
    mov ecx, 32


.enkrypcja:

    ;Wikipedia mówi: 
    ;for (i=0; i < num_rounds; i++) { 
    ;v0 += (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + key[sum & 3])
    ;sum += delta;
    ; v1 += (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + key[(sum>>11) & 3]);
    ;}
    ;v[0]=v0; v[1]=v1;
    
    mov eax, r9d                       ;eax = v1
    shl eax,4                          ;(v1 << 4) - Shift left
    mov ebx, r9d                       ;ebx = v1
    shr ebx, 5                         ;(v1 >> 5) - Shift right
    xor eax, ebx                       ;Sklejamy tutaj te nasze przesuniete slowa w jedną liczbę
    add eax, r9d                       ;dodajemy v1
    
    mov edx, r10d                      ;edx = sum
    and edx, 3                         ;Maskujemy (sum & 3) aby uzyskać indeks klucza 0 lub 1 lub 2 itd.
    mov r11d, dword [klucz + rdx*4]     ;Pobieramy odpowiedni fragment klucza 
    add r11d, r10d

    xor eax, r11d                       ;sklejamy obie polowki
    add r8d, eax                       ;i zapisujemy do v0

    add r10d, DELTA                    ;Dodajemy stałą matematyczną do sum

    mov eax, r8d                       ;eax = v0
    shl eax,4                          ;(v0 << 4) - Shift left
    mov ebx, r8d                       ;ebx = v0
    shr ebx, 5                         ;(v0 >> 5) - Shift right
    xor eax, ebx                       ;Sklejamy tutaj te nasze przesuniete slowa w jedną liczbę
    add eax, r8d                       ;dodajemy v0

    mov edx, r10d                      ;eds = sum
    shr edx, 11                        ;Przesuwamy sumę o 11 bitow
    and edx, 3                         ;Zas wybieramy ktory klucz
    mov r11d, dword [klucz+ rdx*4]      ;Pobieramy odpowiedni fragment klucza
    add r11d, r10d                      ;Dodajemy klucz do sumy

    xor eax, r11d                       ;Sklejamy obie polowki
    add r9d, eax                       ;i zapisujemy do v1

    dec ecx                            ;Zmniejszamy licznik pętli o 1
    jnz .enkrypcja                     ;Skocz jezeli nie-zero
    
    mov dword [rdi], r8d       ; nadpisz w pamięci nowe v0
    mov dword [rdi + 4], r9d   ; nadpisz w pamięci nowe v1
    ret


deszyfruj_blok:
    mov r8d, dword [rdi]               ; v0
    mov r9d, dword [rdi + 4]           ; v1
    mov r10d, 0xC6EF3720               ; sum = DELTA * 32
    mov ecx, 32                        ; 32 rundy

.dekrypcja:
    mov eax, r8d
    shl eax, 4
    mov ebx, r8d
    shr ebx, 5
    xor eax, ebx
    add eax, r8d
    mov edx, r10d
    shr edx, 11
    and edx, 3
    mov r11d, dword [klucz + rdx*4]
    add r11d, r10d
    xor eax, r11d
    sub r9d, eax

    sub r10d, DELTA

    mov eax, r9d
    shl eax, 4
    mov ebx, r9d
    shr ebx, 5
    xor eax, ebx
    add eax, r9d
    mov edx, r10d
    and edx, 3
    mov r11d, dword [klucz + rdx*4]
    add r11d, r10d
    xor eax, r11d
    sub r8d, eax

    dec ecx
    jnz .dekrypcja

    mov dword [rdi], r8d               ; Zapis odszyfrowanych danych
    mov dword [rdi + 4], r9d
    ret