# Line-Following and Parking Robot – AVR Assembly Project

## Project Overview

This project implements an autonomous line-following and parking robot using an Arduino Uno with an ATmega328P microcontroller. The robot uses three TCRT5000 IR sensors to follow a black line and detect perpendicular cross-line markers. A VS1838 / 1838 IR receiver is used to detect the parking bay signal during the slow parking-detection mode.

The control logic is implemented using AVR Assembly and follows a finite state machine design. The robot operates in normal line-following mode, slow parking-detection mode, parking execution mode, and stop mode when the line is lost for a preset timeout period.

## Hardware Components

| Component | Quantity | Purpose |
| Arduino Uno with ATmega328P | 1 | Main microcontroller board |
| TCRT5000 IR sensors | 3 | Line detection |
| VS1838 / 1838 IR receiver | 1 | Parking bay signal detection |
| TB6612 motor driver | 1 | Controls left and right motors |
| N20 DC geared motors, 6V | 2 | Robot movement |
| Rechargeable batteries, 3.7V, 5000mAh | 2 | Power supply |
| Dot board | 1 | Circuit mounting |
| Switch | 1 | Power ON/OFF control |
| Jumper wires | As required | Circuit connections |

## Main Operating Modes

### 1. Normal Line-Following Mode

This is the default mode of the robot. The three IR sensors continuously detect the position of the black line. Based on the detected sensor pattern, the robot moves straight, corrects left, corrects right, or performs a sharp turn.

In this mode, the IR receiver is ignored to prevent accidental parking outside the parking area.

### 2. Slow Parking-Detection Mode

This mode starts when the robot detects the first confirmed perpendicular cross-line marker. The robot reduces its speed and continues following the line slowly.

The IR receiver becomes active only in this mode. If a valid IR signal is received, the robot enters parking execution mode. If no IR signal is received and the final exit cross-line is detected, the robot returns to normal line-following mode.

### 3. Parking Execution Mode

Parking execution mode starts only after a valid IR signal is detected during slow parking-detection mode. In this state, the robot stops normal line following and performs a fixed timing-based parking sequence.

The parking sequence is:

1. Move forward slightly.
2. Stop briefly.
3. Pivot left.
4. Stop briefly.
5. Reverse into the parking bay.
6. Stop the motors.
7. Remain stopped permanently.

This method is timing-based because the N20 motors used in the robot do not include encoders.

### 4. Stop / Line-Lost Timeout Mode

If all three line sensors detect no line continuously for a preset time, the robot assumes that the line is lost and stops. This prevents the robot from moving uncontrollably outside the track.

## Sensor Pattern Testing

| Sensor Pattern | Expected Movement                  | Observed Movement                        |
| -------------- | ---------------------------------- | ---------------------------------------- |
| `010`          | Move straight                      | Robot moved forward                      |
| `110`          | Soft left                          | Robot corrected left                     |
| `100`          | Hard left                          | Robot turned left sharply                |
| `011`          | Soft right                         | Robot corrected right                    |
| `001`          | Hard right                         | Robot turned right sharply               |
| `101`          | Move forward through center gap    | Robot continued forward                  |
| `000`          | Search slowly / stop after timeout | Robot searched and stopped after timeout |

## Finite State Machine Design

The robot was designed as a finite state machine because its behavior changes depending on the current condition and sensor input. This design makes the robot logic organized, predictable, and easier to test and debug.

The main states are:

- Normal Line-Following Mode
- Slow Parking-Detection Mode
- Parking Execution Mode
- Stop / Line-Lost Timeout Mode

The robot begins in normal line-following mode. When the first confirmed cross-line is detected, it enters slow parking-detection mode. If an IR parking signal is received, it performs the parking sequence. If no IR signal is received and the exit cross-line is detected, it returns to normal mode. If the line is lost for the preset timeout period, the robot stops.

## Assembly Toolchain Setup

To build and upload the AVR Assembly program, the following tools are required:

- AVR Assembler / AVR Binutils
- AVR-GCC toolchain
- AVRDUDE
- Arduino IDE, mainly for board driver and serial port checking

## Installation Instructions

### Windows

Install one of the following AVR development environments:

- Microchip Studio
- WinAVR / AVR-GCC toolchain
- Arduino IDE

Also install AVRDUDE if it is not already included. After installation, make sure the AVR tools are added to the system PATH.

### macOS

Install the AVR tools using Homebrew:

```bash
brew install avr-gcc
brew install avrdude
```

Install the Arduino IDE to ensure the Arduino Uno board drivers are available.

### Linux / Ubuntu

Install the required AVR tools using:

```bash
sudo apt update
sudo apt install gcc-avr avr-libc avrdude
```

## Building the Project

The AVR Assembly source file can be assembled and converted into a HEX file using the following commands:

```bash
avr-as -mmcu=atmega328p main.asm -o main.o
avr-objcopy -O ihex main.o main.hex
```

The generated `main.hex` file is the machine-code file that can be uploaded to the Arduino Uno.

## Uploading the Program to Arduino Uno

Connect the Arduino Uno to the computer using a USB cable.

Check the correct serial port:

- Windows: `COM3`, `COM4`, etc.
- macOS / Linux: `/dev/tty.usbmodem...` or `/dev/ttyUSB0`

Upload the HEX file using AVRDUDE.

Example for Windows:

```bash
avrdude -c arduino -p m328p -P COM3 -b 115200 -U flash:w:main.hex:i
```

Example for macOS / Linux:

```bash
avrdude -c arduino -p m328p -P /dev/tty.usbmodem1101 -b 115200 -U flash:w:main.hex:i
```

Replace the port name with the correct port used by your computer.

## Source File Description

| File Name   | Description                                                                                                                                                                                                   |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `main.asm`  | Main AVR Assembly source file. Contains initialization, sensor reading, motor control, line-following logic, cross-line detection, parking-detection logic, parking sequence, and line-lost timeout handling. |
| `README.md` | Documentation file that explains the project overview, hardware, toolchain setup, build instructions, upload instructions, source file descriptions, and testing summary.                                     |
| `main.hex`  | Generated HEX file uploaded to the Arduino Uno. This file is created after assembling and converting the source code.                                                                                         |
| `main.o`    | Intermediate object file created during the assembly process.                                                                                                                                                 |

## Main Sections in `main.asm`

### Initialization

Configures the required input and output pins for the IR sensors, IR receiver, motor driver, and PWM signals.

### Sensor Reading

Reads the three TCRT5000 IR sensors and forms sensor patterns such as `010`, `110`, `100`, `011`, `001`, `101`, and `000`.

### Motor Control

Controls the TB6612 motor driver to move the robot forward, turn left, turn right, pivot, reverse, and stop.

### Normal Line-Following Logic

Uses the detected sensor pattern to keep the robot aligned with the black line.

### Cross-Line Detection

Detects confirmed perpendicular cross-line markers and uses them to enter or exit the slow parking-detection mode.

### IR Parking Detection

Enables the IR receiver only during slow parking-detection mode. If a valid IR signal is detected, the robot starts the parking sequence.

### Parking Sequence

Runs a fixed timing-based maneuver to park the robot inside the parking bay.

### Line-Lost Timeout

Stops the robot if the line is not detected for the preset timeout period.

## Notes

- The robot uses an Arduino Uno based on the ATmega328P microcontroller.
- The program is written in AVR Assembly.
- Three TCRT5000 IR sensors are used for line tracking.
- The IR receiver is only active in slow parking-detection mode.
- Parking is performed only after receiving a valid IR signal in the parking detection area.
- The parking maneuver is timing-based because the motors do not have encoders.
- The finite state machine design makes the robot logic easier to understand, test, and debug.

## Author

Name: Elisha Perera ,MohomadNasif
Module: Embedded Systems / AVR Assembly Project
