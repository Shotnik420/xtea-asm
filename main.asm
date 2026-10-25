section .data
    msg db "XTEA Encryptor Start", 10  ;Zapis tekstu i dodanie \n na końcu.
    msg_len equ $ - msg                ;Obliczenie dlugosci tekstu.

section .text
    global main                        ;Mówimy kompilatorowi gcc gdzie ma zacząć wykonywać kod.

main:
    mov rax, 1                         ;Wybieramy poleceni sys_write
    mov rdi, 1                         ;Wybor ekranu do wypisania
    mov rsi, msg                       ;Wczytanie do ramu tekstu
    mov rdx, msg_len                   ;Wczytanie długości tekstu
    syscall                            ;Wykonanie

    mov rax, 60                        ;Wybieramy polecenie 
    xor rdi, rdi                       ;Kod bledu - 0
    syscall                            ;Wykonanie
