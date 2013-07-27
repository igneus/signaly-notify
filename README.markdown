# signaly-notify #

## Co to umí / Functionality ##

[CZ] signaly-notify.rb je skript, který se přihlásí Tvým uživatelským
jménem a heslem na [signaly.cz](https://signaly.cz) (česká křesťanská sociální síť),
v pravidelném intervalu stránky kontroluje a oznamuje novinky
(toho času pouze příchozí zprávy a ohlášky). Novinky vypisuje jednak
do konzole, jednak posílá grafické upozornění (ve většině správců oken
vypadá jako bublina někde v rohu obrazovky) pomocí knihovny libnotify.

[EN] signaly-notify.rb is a simple script logging in with your user data
to the Czech christian social network [signaly.cz](https://signaly.cz) and notifying you -
by the means of printing to the console as well as sending a visual notification
using libnotify - when something new happens.
(Currently it only detects pending private messages and notifications.)

## Co je potřeba, aby to běželo / Depends on: ##

1. programs
   * ruby 1.9.*
2. Ruby gems:
   * mechanize
   * colorize
   * highline
   * libnotify

## Spouštění / Execution ##

$ ruby signaly-notify.rb

[CZ] Skript spusť za pomoci interpreta Ruby. Volby, které jsou k disposici,
skript vypíše, spustíš-li ho s přepínačem -h .

[EN] Run the script using the Ruby interpreter. Use commandline-option
-h to see all the available options.
