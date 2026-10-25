section .data
    msg db "XTEA Szyfrowanie", 10  ;Zapis tekstu i dodanie \n na końcu.
    msg_len equ $ - msg                ;Obliczenie dlugosci tekstu.

    nowa_linia db 10

    ;Zapis 2 bloków danych. Pierwszy to słowo "TEST" a drugi "DATA". Zapisane są od tyłu.
    blok_danych dd 0x54534554, 0x41544144 
    
    ;Klucze
    klucz dd 0x01234567, 0x89ABCDEF, 0xFEDCBA98, 0x76543210

    ; Stała XTEA
    DELTA equ 0x9E3779B9


    plik_we db "Haslo.txt", 0

section .bss
    bufor resb 8

section .text
    global main                        ;Mówimy kompilatorowi gcc gdzie ma zacząć wykonywać kod.

main:
    mov rax, 1                         ;Wybieramy poleceni sys_write
    mov rdi, 1                         ;Wybor ekranu do wypisania
    mov rsi, msg                       ;Wczytanie do ramu tekstu
    mov rdx, msg_len                   ;Wczytanie długości tekstu
    syscall                            ;Wykonanie
    
    ;Otwieramy plik do oczytu
    mov rax, 2
    lea rdi, [plik_we]
    mov rsi, 0
    mov rdx, 0
    syscall

    mov r12, rax                

    ;Czytamy plik
    mov rax, 0                       ;sys_read
    mov rdi, r12                     ;deskryptor podajemy
    lea rsi, [bufor]
    mov rdx, 8
    syscall

    ;Zamykamy plik
    mov rax, 3                       ; sys_close
    mov rdi, r12
    syscall

    mov r8d, dword [bufor]
    mov r9d, dword [bufor+4]
    
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
    mov edi, dword [klucz + rdx*4]     ;Pobieramy odpowiedni fragment klucza 
    add edi, r10d                      ;i go dodajemy do obecnej sumy
    
    xor eax, edi                       ;sklejamy obie polowki
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
    mov edi, dword [klucz+ rdx*4]      ;Pobieramy odpowiedni fragment klucza
    add edi, r10d                      ;Dodajemy klucz do sumy

    xor eax, edi                       ;Sklejamy obie polowki
    add r9d, eax                       ;i zapisujemy do v1

    dec ecx                            ;Zmniejszamy licznik pętli o 1
    jnz .enkrypcja                     ;Skocz jezeli nie-zero
    
    mov dword [blok_danych], r8d       ; nadpisz w pamięci nowe v0
    mov dword [blok_danych + 4], r9d   ; nadpisz w pamięci nowe v1
    
    mov rax, 1                         ;Wybieramy poleceni sys_write
    mov rdi, 1                         ;Wybor ekranu do wypisania
    lea rsi, [blok_danych]             ;Wczytanie do ramu danych
    mov rdx, 8                         ;Rozmiar to 2*4Bajty
    syscall

    mov rax, 1                         ;Wybieramy poleceni sys_write
    mov rdi, 1                         ;Wybor ekranu do wypisania
    mov rsi, nowa_linia                 ;Wczytanie znaku \n
    mov rdx, 1                         ;Rozmiar to 2*4Bajty
    syscall
    
    mov rax, 60                        ; sys_exit
    mov rdi, 0                         ; kod 0 (sukces)
    syscall

