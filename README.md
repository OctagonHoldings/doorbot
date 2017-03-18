Doorbot is an RFID door opener
===========

# Repo Structure

    frontend/   # the web frontend and the code that locks/unlocks the door (ruby)
    reader/     # interface for the NFC reader, outputs tag IDs

Check each component's README for more.

# Hardware

We have this running in the following configuration:

* Code runs on a Raspberry Pi 2 model B
  * Database is stored locally, but backed up regularly
* Reader is an [Adafruit PN532 breakout](https://www.adafruit.com/product/364)
  * It lives in [this box](https://www.polycase.com/ml-45f-15)
  * It's mounted on [this plate](https://www.polycase.com/ml-45k)
* Computer is connected to a box with a backup battery and power supply/control board for the door strike (link forthcoming)
  * Wired to GPIO 9 on the pi, via a transistor
  * This box supplies 12vdc, so we use a cheap step-down converter to get 5vdc for the pi, soldered to a hacked USB cable

