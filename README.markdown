# signaly-notify #

## Co to umí / Functionality ##

signaly-notify.rb je skript, který se přihlásí Tvým uživatelským
jménem a heslem na signaly.cz (česká křesťanská sociální síť),
v pravidelném intervalu stránky kontroluje a oznamuje novinky
(toho času pouze příchozí zprávy a ohlášky). Novinky vypisuje jednak
do konzole, jednak posílá grafické upozornění (ve většině správců oken
vypadá jako bublina někde v rohu obrazovky) pomocí programu notify-send.

signaly-notify.rb is a simple script logging in with your user data
to the Czech christian social network signaly.cz and notifying you -
by the means of printing to the console as well as sending a visual notification
using notify-send - when something new happens.
(Currently it only detects pending private messages and notifications.)

## Co je potřeba, aby to běželo / Depends on: ##

1. programs
   * ruby 1.9.*
   * notify-send (program usually packed with libnotify1)
2. Ruby gems:
   * mechanize
   * colorize
   * highline
