# _Automated Color Filter Production Line_

## Programmers
- _[Lim Jia Xiang]()_
- _[Liew Ming Heng](https://github.com/MH-Electronic)_

## Code Programs
**8051 Microcontroller**
- _programmed in assembly language for counting objects and display on the LCD module_
  - _2 Servos for detect position of the moving object_
  - _2 Servos for detect whether the moving object is falling inside the boxes_ 
- _receive signals from VisionFive 2 development board for controlling servo actuators to push falling the objects_

**VisionFive 2 Development Board**
- _OpenCV for color filtering to determine the color of objects, then sends signals to the 8051 microcontroller to manage further movements._
- _Using ADC0804 to using input signals from potentiometer and output as PWM Duty Cycle to control the speed of the conveyer belt in percentage_

### Materials Used
**Microcontrollers (MCU)**
- AT89C52

**Single Board Computer (SBC)**
- VisionFive 2 Development Board

**Sensors/Components**
- 4 IR Sensors
- 1 LCD Module
- 1 Webcam
- 2 Servo Motor
- 1 Potentiometer
- 1 ADC0804

