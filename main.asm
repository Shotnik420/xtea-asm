section .note.GNU-stack noalloc noexec nowrite progbits ; Wyłącza błąd linkera (zabezpieczenie stosu)

section .data
    cmd_plik db 'zenity --file-selection --title="XTEASM - WYBIERZ PLIK"', 0
    cmd_akcja db 'zenity --question --title="XTEASM" --text="Wybierz operację:" --ok-label="SZYFROWANIE" --cancel-label="DESZYFROWANIE"', 0
    cmd_sukces db 'zenity --info --title="XTEASM" --text="Operacja zakończona sukcesem! Utworzono nowy plik."', 0
    tryb_r db "r", 0
    ; Polecenie Zenity z polem tekstowym (jeśli chcesz ukryć znaki gwiazdkami, dodaj na końcu: --hide-text)
    cmd_klucz db 'zenity --entry --title="XTEASM - KLUCZ" --text="Wprowadź hasło / klucz szyfrowania:"', 0
section .bss
    plik_sciezka resb 256
    plik_wyjscie resb 264
    bufor resb 8                       
    bufor_haslo resb 64        ; Bufor na tekst wpisany w okienku
section .text
    extern popen, fgets, pclose, system
    extern szyfruj_blok, deszyfruj_blok, klucz
    global main

main:
    ; Wyrównanie stosu do 16 bajtów i zachowanie rejestrów chronionych ABI
    push rbp
    mov rbp, rsp
    push r12
    push r13                           
    push r14
    push r15

    ;Wybor pliku
    lea rdi, [cmd_plik] ;Wskaźnik na string z polecenia
    lea rsi, [tryb_r]   ;Tryb r
    xor eax, eax
    call popen
    
    test rax, rax ; Sprawdza czy rax równe zeru (czyli NULL).
    jz .zakoncz   ;Jezeli rax jest NULL, co mówi iż uruchomił się z błędem to kończymy program.
    mov r12, rax  ; Zapisz wskaźnik do strumienia pliku w R12
    
    lea rdi, [plik_sciezka]; Argument 1: adres bufora w RAM dla wyniku
    mov rsi, 256           ;Argument 2: Maksymalna ilość bajtów do odczytu.
    mov rdx, r12           ;Argument 3: Strumień pliku.
    xor eax, eax           ;Zerujemy eax
    call fgets             ;wywołujemy fgets
    
    mov rdi, r12
    xor eax, eax
    call pclose            ;Zamykamy fgets

    lea rdi, [plik_sciezka];Zaladowanie adresu bufora ze sciezka do R12/RDI
.petla_nl:                 ;fgets zostawia nam na końcu znak '\n', musimy go znaleźć i usunąć
    cmp byte [rdi], 0      ;Czy doszliśmy do końca tekstu?
    je .sprawdz_sciezke    ;Jak tak to nie ma '\n', idź dalej.
    cmp byte [rdi], 10     ; sprawdz czy biezacy znak to kod ASCII znaku '\n'
    je .zamien_nl          ;Jak tak to zamien.
    inc rdi                ;Zmniejsz rdi
    jmp .petla_nl          ;Ponów pętlę

.zamien_nl:
    mov byte [rdi], 0      ;nadpisz znak '/n' bajtem zerowym.

.sprawdz_sciezke:
    ; Sprawdzenie: Czy użytkownik kliknął "Anuluj" (ścieżka pusta)?
    cmp byte [plik_sciezka], 0
    je .zakoncz

    lea rdi, [cmd_akcja]   ;Zapytanie Zenity
    xor eax, eax
    call system
    mov r13d, eax          ; 0 = SZYFROWANIE, inne = DESZYFROWANIE

    lea rdi, [cmd_klucz]
    lea rsi, [tryb_r]
    xor eax, eax
    call popen
    test rax, rax
    jz .zakoncz
    mov r12, rax                       ; r12 = potok Zenity

    lea rdi, [bufor_haslo]
    mov rsi, 64
    mov rdx, r12
    xor eax, eax
    call fgets

    mov rdi, r12
    xor eax, eax
    call pclose

    ; Usunięcie '\n' z końca hasła
    lea rdi, [bufor_haslo]
.petla_nl_haslo:
    cmp byte [rdi], 0
    je .sprawdz_haslo
    cmp byte [rdi], 10                 ; kod ASCII '\n'
    je .zamien_nl_haslo
    inc rdi
    jmp .petla_nl_haslo

.zamien_nl_haslo:
    mov byte [rdi], 0

.sprawdz_haslo:
    ; Jeśli użytkownik nic nie wpisał (kliknął Anuluj / puste), zostawiamy domyślny klucz
    cmp byte [bufor_haslo], 0
    je .utworz_nazwe_wyjsciowa

    ; Jeśli wpisał hasło: zerujemy 16 bajtów klucza (2 x qword)
    mov qword [klucz], 0
    mov qword [klucz + 8], 0

    ; Kopiujemy do 16 znaków wpisanego hasła do pamięci 'klucz'
    lea rsi, [bufor_haslo]
    lea rdi, [klucz]
    mov ecx, 16                        ; maksymalnie 16 bajtów (128 bitów)

.kopiuj_haslo:
    mov al, byte [rsi]
    test al, al                        ; czy koniec hasła?
    jz .utworz_nazwe_wyjsciowa
    mov byte [rdi], al
    inc rsi
    inc rdi
    dec ecx
    jnz .kopiuj_haslo

.utworz_nazwe_wyjsciowa:
    lea rsi, [plik_sciezka];Źródło (Source Index)
    lea rdi, [plik_wyjscie];Cel (Dest. Index)
.kopiuj_nazwe:
    mov al, byte [rsi]     ;Pobierz 1 bajt ze źródła rejestru AL
    mov byte [rdi], al     ; zapisz go do bufora
    test al, al            ;Nie jest zerem?
    jz .dodaj_rozszerzenie ;Jak tak to dodaj rozszerzenie
    inc rsi                ;Przesuń wskaźnik zrodla na kolejny bit
    inc rdi                ;Przesuń wskaźnik celu na kolejny bit
    jmp .kopiuj_nazwe      ;Powtorz dla nast. znaku

.dodaj_rozszerzenie:
    ; rdi wskazuje na znak końcowy 0 w plik_wyjscie
    cmp r13d, 0
    jne .rozszerzenie_dec
    ; Szyfrowanie -> dopisujemy ".enc"
    mov byte [rdi], '_'
    mov byte [rdi+1], 'e'
    mov byte [rdi+2], 'n'
    mov byte [rdi+3], 'c'
    mov byte [rdi+4], 0
    jmp .otworz_pliki

.rozszerzenie_dec:
    ; Deszyfrowanie -> dopisujemy ".dec"
    mov byte [rdi], '_'
    mov byte [rdi+1], 'd'
    mov byte [rdi+2], 'e'
    mov byte [rdi+3], 'c'
    mov byte [rdi+4], 0

.otworz_pliki:
    ; Plik wejściowy (O_RDONLY = 0)
    mov rax, 2                         ; sys_open
    lea rdi, [plik_sciezka]
    mov rsi, 0                         ; O_RDONLY
    mov rdx, 0
    syscall
    test rax, rax
    js .zakoncz                        ; Jeśli błąd otwarcia (ujemny deskryptor), wyjdź
    mov r14, rax                       ; r14 = deskryptor wejściowy (fd_in)

    ; Plik wyjściowy (O_WRONLY | O_CREAT | O_TRUNC = 0x241, uprawnienia 0644o)
    mov rax, 2                         ; sys_open
    lea rdi, [plik_wyjscie]
    mov rsi, 0x241                     ; O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0644o                     ; rw-r--r--
    syscall
    test rax, rax
    js .zamknij_we                     ; Jeśli błąd, zamknij plik wejściowy i wyjdź
    mov r15, rax                       ; r15 = deskryptor wyjściowy (fd_out)

    ;Tutaj pobieramy rozmiar pliku wejściowego przez lseek na koniec
    mov rax, 8
    mov rdi, r14
    mov rsi, 0
    mov rdx, 2
    syscall
    mov r12, rax                      ; Mamy rozmiar, leci do r12

    mov rax, 8                        ;przewijamy z powrotem na początek.
    mov rdi, r14
    mov rsi, 0
    mov rdx, 0
    syscall

.petla_glowna:
    mov qword [bufor], 0               ; Czyścimy bufor zerami (padding)

    mov rax, 0                         ; sys_read
    mov rdi, r14                       ; fd_in
    lea rsi, [bufor]
    mov rdx, 8                         ; czytamy 8 bajtów (blok XTEA)
    syscall

    test rax, rax
    jle .koniec_przetwarzania          ; rax <= 0 oznacza koniec pliku (EOF) lub błąd

    sub r12, 8                         ; Odejmujemy 8 bajtów od całkowitego rozmiaru pliku
    lea rdi, [bufor]
    cmp r13d, 0
    je .szyfruj
    call deszyfruj_blok
    mov edx, 8
    cmp r12, 0
    jg .zapisz

.usun_padding:
    cmp edx, 0
    je .zapisz

    cmp byte [bufor + rdx -1], 0
    jne .zapisz

    dec edx
    jmp .usun_padding

.szyfruj:
    call szyfruj_blok
    mov edx, 8

.zapisz:
    mov rax, 1                         ; sys_write
    mov rdi, r15                       ; fd_out
    lea rsi, [bufor]
    syscall

    jmp .petla_glowna

.koniec_przetwarzania:
    ; --- 6. ZAMKNIĘCIE PLIKÓW ---
    mov rax, 3                         ; sys_close (wyjściowy)
    mov rdi, r15
    syscall

.zamknij_we:
    mov rax, 3                         ; sys_close (wejściowy)
    mov rdi, r14
    syscall

    lea rdi, [cmd_sukces]
    xor eax, eax
    call system

.zakoncz:
    ; Sprzątanie rejestrów przed wyjściem
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    
    mov rax, 60                        ; sys_exit
    mov rdi, 0
    syscall