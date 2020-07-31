theme: Inter
text: #EEEEEE
code: auto(42), Monaco, line-height(1.2)
footnote: #EEEEEE, text-scale(1.4)
footer-style: #EEEEEE, text-scale(3)
build-lists: true

# Much Nerves - A Hello World For The Embedded World
### @mattrudel - github.com/mtrudel - mat@geeky.net

---

# The Plan

* What Is Nerves?
* Hello World
* GPIO Demo (LEDs and Buttons)
* Beyond GPIO 
* Desk Clock Demo

---
# What Is Nerves?
### https://www.nerves-project.org

* Framework for running Elixir in embedded environments
* Handles cross-compilation, firmware packaging, lots of other details
* Runs the BEAM on top of a Buildroot-based Linux distro
* tl;dr: Elixir running on a RPi

---
# Hello World
## Step 1: Install Nerves

* https://hexdocs.pm/nerves/installation.html
* Very well documented (like most of Nerves)
* Beware of OTP mismatches! Just listen to instructions for the most part

---
# Hello World
## Step 2: Create a new project

* `mix nerves.new hello_nerves`
* `cd hello_nerves`
* `MIX_TARGET=rpi0 mix firmware.burn`

---

# So what can you do with it?

* It's Just Elixir!
* `iex` REPL
* Can run Phoenix, make HTTP calls, etc
* Can also interact with the physical world

---

# GPIO Hello World
## Part 1: Blink an LED

* Usual warnings about LEDs needing resistors

---

# GPIO Hello World
## Part 2: Reading Buttons

* https://hexdocs.pm/circuits_gpio/readme.html has a great intro on basic wiring setups

^ Note that it's just like Elixir anywhere else. Any number of processes, each doing their own thing. For anyone who's done any embedded work before, being able to so easily multitask in an embedded environment is just, the best thing. All of the things that make Elixir great in server environments are even more useful in the embedded world. It's good. Walking and chewing gum

---

# But Wait! There's More!
## Phyisical Protocols

* I2C
* SPI
* RS-232
* HAT & pHAT
* https://shop.pimoroni.com, https://buyapi.ca, etc

---

# Desk Clock

github.com/mtrudel/desk_clock

* Provides an NTP synced desktop clock
* Powers an SPI OLED display (SSD1322)
* Standard Elixir App (GenServers, Tasks, etc)
* Uses `circuits_spi` & `circuits_gpio` libraries + some extras

---

# SSD1322 Library

github.com/mtrudel/ssd1322

* SSD1322 datasheet as a library
* Drive it with 4 bit greyscale bitmaps

---

# ex_paint Library

github.com/mtrudel/ex_paint

* Thin wrapper around Erlang's EGD library
* Pluggable rasterizers (incl. 4 bit greyscale bitmap!)
* Not terribly performant
* Would love to build this out more someday

---

# Desk Clock

github.com/mtrudel/desk_clock

* Provides an NTP synced desktop clock
* Powers an SPI OLED display (SSD1322)
* Standard Elixir App (GenServers, Tasks, etc)
* Uses `circuits_spi` & `circuits_gpio` libraries + some extras

---

# Links

https://www.nerves-project.org - Project Page

https://hexdocs.pm/nerves/installation.html - Install Docs

https://hexdocs.pm/circuits_gpio/readme.html - Basic GPIO Circuits

https://shop.pimoroni.com - Shopping!

https://buyapi.ca - Shopping!

Creatron - Local Shopping!

https://github.com/mtrudel/desk_clock - Desk Clock Demo App

https://github.com/mtrudel/talks - This talk


