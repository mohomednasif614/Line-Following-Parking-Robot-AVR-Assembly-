### Line-Following-Parking-Robot-AVR-Assembly

### Overview
This repository contains the full hardware design and register-level firmware for an autonomous robot developed for the Embedded Systems Design (IE3064) module at SLIIT. The system is built around the ATmega328P (Arduino Uno) and is programmed entirely in AVR Assembly to achieve high-performance, low-level control without the use of standard Arduino C++ libraries.  
+1

### Key Features

Low-Level Firmware: Implemented using AVR Assembly for direct register-level control of I/O ports, hardware timers, and PWM generation.  

Three-Mode Finite State Machine (FSM):

MODE_NORMAL: High-speed line following.  

MODE_SLOW: Reduced speed triggered by cross-line markers to enable IR signal searching.  

MODE_PARK: Execution of a fixed parking sequence (Forward → Pivot → Reverse).  

Advanced Logic: Includes cross-line confirmation to filter noise, duplicate marker prevention using latch flags, and an IR confirmation counter for reliable parking bay detection.  

Safety Protocols: Features a line-lost timeout function that safely stops the motors if the track is lost for a defined period.  

### Hardware Specifications

Controller: Arduino Uno (ATmega328P).  

Sensors: 3x TCRT5000 IR sensors (Line/Marker detection) and 1x VS1838 IR receiver (Parking signal).  

Actuation: 2x N20 Geared DC Motors driven by a TB6612FNG H-Bridge driver.  

Power: 2x 3.7V Rechargeable batteries with a DC-DC Buck Converter for a stable 5V logic supply.
