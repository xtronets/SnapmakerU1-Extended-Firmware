# Polskie GUI U1 – aktualizacja tłumaczenia po nowym firmware

Narzędzie `i18n.py` porównuje angielskie teksty nowego firmware'u z wersją,
z której zrobiono tłumaczenie, sam przenosi wszystko, co się nie zmieniło,
i zostawia do przetłumaczenia tylko nowe lub zmienione teksty.

## Co gdzie leży

| Plik | Opis |
|---|---|
| `../files/pl.json` | polskie teksty GUI (wgrywane jako `tr-TR.json`) |
| `../files/exception_pl.json` | polskie komunikaty błędów (wgrywane jako `exception_tr-TR.json`) |
| `source/en-GB.json`, `source/exception_en-GB.json` | angielskie teksty, z których zrobiono tłumaczenie |
| `exception_templates.json` | szablony błędów EN → PL; `{N}` = numer głowicy/podajnika, `{A}` = oś X/Y/Z |
| `todo.json` | tworzony przez `update`: lista rzeczy do przetłumaczenia |

Komunikaty błędów są tłumaczone przez szablony, więc nowy kod błędu, który
używa znanego zdania (np. kolejna głowica), tłumaczy się sam.

## Krok po kroku (po syncu forka z paxx12)

Wszystkie polecenia uruchamiaj w katalogu repo, w środowisku `./dev.sh bash`
(potrzebne są narzędzia z `make tools` i `unsquashfs`).

1. **Rozpakuj nowy firmware** i wyciągnij angielskie teksty
   (nowy stock z `make firmware` albo build develop od paxx12):
   ```bash
   I18N=overlays/mods/xtronets/80-gui-polish/i18n/i18n.py
   $I18N extract firmware/U1_<wersja>_upgrade.bin tmp/i18n-stock
   ```
   Sprawdza też, czy etykieta „Türkçe” nadal jest w `/usr/bin/gui` dokładnie raz.

2. **Zobacz, co się zmieniło:**
   ```bash
   $I18N status tmp/i18n-stock
   ```

3. **Scal zmiany:**
   ```bash
   $I18N update tmp/i18n-stock
   ```
   Niezmienione tłumaczenia zostają, usunięte klucze znikają, a do
   `todo.json` trafiają:
   - `ui`: nowe/zmienione teksty GUI (`en` = nowy angielski, `old_en`/`old_pl` = poprzednia wersja),
   - `error_templates`: nowe szablony błędów.

4. **Przetłumacz** – uzupełnij pola `"pl"` w `todo.json`. Zachowaj `%d`, `%s`,
   `{N}`, `{A}`, `\n` i w błędach jeden znak `_` (oddziela tytuł od opisu).
   Możesz to dać Claude'owi: „przetłumacz todo.json w forku U1”.

5. **Zastosuj i sprawdź:**
   ```bash
   $I18N apply      # scala tłumaczenia, odświeża source/, uruchamia check
   $I18N check      # sama walidacja (klucze, placeholdery, separator _)
   ```

6. **Zbuduj** jak zwykle:
   ```bash
   ./dev.sh make build PROFILE=extended-xtronets
   ```
   Skrypt budowania ostrzega (`!! WARNING`), jeśli tłumaczenie nie pasuje do
   tekstów w budowanym firmware. Brakujące teksty GUI pokaże wtedy po angielsku.

## Gdy build się zatrzyma na etykiecie „Türkçe”

Snapmaker zmienił tabelę języków w `/usr/bin/gui`. Trzeba sprawdzić
(`strings -n 3 usr/bin/gui | grep -n -B3 -A3 tr-TR`), czy slot tureckiego
nadal istnieje, i ewentualnie wybrać inny slot w `scripts/01-gui-polish.sh`.
