# signaly-notify

## Co to umí / Functionality

[CZ] signaly-notify.rb je skript, který se přihlásí Tvým uživatelským
jménem a heslem na [signaly.cz](https://signaly.cz) (česká křesťanská sociální síť),
v pravidelném intervalu stránky kontroluje a oznamuje novinky
(příchozí zprávy, ohlášky, výzvy). Novinky vypisuje jednak
do konzole, jednak posílá grafické upozornění (ve většině správců oken
vypadá jako bublina někde v rohu obrazovky) pomocí knihovny libnotify.

[EN] signaly-notify.rb is a simple script logging in with your user data
to the Czech christian social network [signaly.cz](https://signaly.cz) and notifying you -
by the means of printing to the console as well as sending a visual notification
using libnotify - when something new happens.
(Currently it only detects pending private messages and notifications.)

## Co je potřeba, aby to běželo / Depends on:

* ruby >= 1.9
* libnotify (volitelné / optional) `gem install libnotify`

## Instalace / Installation

`$ gem install signaly-notify`

## Spouštění / Execution

`$ signaly-notify.rb`

## Konfigurace

[CZ] Kromě přepínačů na příkazové řádce je možné časté volby uložit
do konfiguračního souboru.
Ten se standardně hledá v ~/.config/signaly-notify/config.yaml
Jinou cestu lze zvolit při spouštění přepínačem `-c`
Níže nabízím jako příklad svůj konfigurační soubor.
Všechny dostupné volby je možné najít na začátku hlavního skriptu -
stačí hledat slovo "defaults".
Můj vlastní konfigurační soubor je na ukázku níže.

[EN] Common options can be saved to a config file.
Default location is ~/.config/signaly-notify/config.yaml
and can be changed by command-line option `-c`.
All available options can easily be found in the main script -
at it's beginning search for word "defaults".
My own config is listed below.

```yaml
login: dromedar
sleep_seconds: 300
remind_after: 600
```
