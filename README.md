# XTEA GUI (Asembler x86_64)

Prosty program w asemblerze NASM do szyfrowania i deszyfrowania plików za pomocą algorytmu **XTEA** (blok 64-bitowy, klucz 128-bitowy), z prostym interfejsem graficznym (Zenity).

---

## Wymagania

Przed uruchomieniem upewnij się, że masz zainstalowane wymagane pakiety:

```bash
sudo apt update
sudo apt install nasm gcc make zenity
```

---

## Kompilacja

W katalogu z projektem wpisz:

```bash
make
```

Polecenie utworzy plik wykonywalny **`xtea-gui`**.

Aby wyczyścić pliki po kompilacji:
```bash
make clean
```

---

## Instrukcja obsługi

1. Uruchom program w terminalu:
   ```bash
   ./xtea-gui
   ```

2. **Wybór pliku:** W oknie graficznym wskaż plik, który chcesz przetworzyć.
3. **Wybór operacji:** Wybierz przycisk **SZYFROWANIE** lub **DESZYFROWANIE**.
4. **Podanie hasła:** Wpisz własne hasło (klucz) lub zostaw puste / kliknij Anuluj, aby użyć klucza domyślnego.
5. **Wynik:**
   * Po zaszyfrowaniu powstanie plik z końcówką `_enc` (np. `plik_enc`).
   * Po odszyfrowaniu pliku z końcówką `_enc` powstanie plik z końcówką `_dec` (np. `plik_dec`).
   * Zostanie wyświetlone okienko z informacją o zakończeniu operacji.

---

## Struktura projektu

* `main.asm` – obsługa GUI (Zenity), odczyt i zapis plików, padding oraz logika programu.
* `xtea.asm` – implementacja algorytmu szyfrowania i deszyfrowania bloków XTEA w asemblerze.
* `Makefile` – skrypt kompilacji projektu.

