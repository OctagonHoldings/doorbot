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
  * You will want to follow these [instructions](https://learn.adafruit.com/adafruit-nfc-rfid-on-raspberry-pi) to get the PN532 to play well with your pi.
* Door strike is an [Aiphone EL-12S](https://www.amazon.com/Aiphone-EL-12S-Electric-Strike-Requirement/dp/B002HM53Q0)
* Computer is connected to a box with a backup battery and power supply/control board for the door strike (http://www.ebay.com/itm/Door-Access-Power-Supply-Control-AC-110-220-DC-12V-5A-/160443264827)
  * Wired to GPIO 9 on the pi, via a transistor
  * This box supplies 12vdc, so we use a cheap step-down converter to get 5vdc for the pi, soldered to a hacked USB cable

