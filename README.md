# RC_Car_Demo
Demonstrating Robotics with Ada, SPARK, ARM, and Lego Sensors/Effectors

---

IMPORTANT: Please note that this project exists as part of a blog entry,
article, or other similar material by AdaCore. It is provided for
convenient access to the software described therein. As such, it is not
updated regularly and may, over time, become inconsistent with the
latest versions of any tools and libraries it utilizes (for example, the
Ada Drivers Library).

---

This program demonstrates the use of Ada and SPARK in an embedded environment.
Specifically, we have a remote-controlled car using Lego NXT motors and sensors
but without the Lego NXT Brick. All the software is fully in Ada and SPARK.
No Lego drivers are used whatsoever.

The control program and the physical car itself are based on the HiTechnic IR
RC Car, with several significant differences. Not least is the fact that no
LEGO NXT brick is used, requiring a replacement for the Brick and its battery
pack.

Instructions for building their original car are here:
http://www.hitechnic.com/models

A video of their car is available on YouTube:
https://www.youtube.com/watch?v=KltnZBSvLu4

The computer replacing the Lego Brick is a 32-bit ARM Cortex-M4 MCU on the
STM32F4 Discovery card by STMicroelectronics. An FPU is included so we use
floating-point in the program.

https://www.st.com/en/evaluation-tools/stm32f4discovery.html

In addition, we use a third-party hardware card known as the NXT Shield to
interface to the NXT motors and sonar scanner. Specifically, we use "NXT
Shield Version 2" produced by TKJ Electronics.

http://blog.tkjelectronics.dk/2011/10/nxt-shield-ver2/
http://shop.tkjelectronics.dk/product_info.php?products_id=29

We use a battery that provides separate connections for +5 and +9 (or +12)
volts. The 5V is provided via USB connector, which is precisely what the
STM32F4 card requires for power. It isn't light but holds a charge for a
long time. The battery is the "XTPower AE-MP-10000-External-Battery" pack.

https://www.xtpower.com/

Available remote controls:

* Power_Functions_IR_TX_8879
  see https://www.lego.com/en-us/themes/power-functions/products/ir-speed-remote-control-8879

* AdaFruit app on cell phone, using BLE for the connection
  see https://learn.adafruit.com/bluefruit-le-connect/controller

The AdaFruit remote app uses a Bluetooth connection from the iPhone or
Android mobile phone. The other two remotes use IR, so for those we use the
HiTechnic IR receiver. If the AdaFruit BLE is used we must swap out the IR
receiver for the Bluefruit LE UART Friend receiver.

There is one package declaration for the remote control interface. Each
different remote control device above has a corresponding package body
implementing the single shared package spec. To have the selected remote be
used in the RC_Car program you must build the program with the package body
corresponding to the desired controller. This selection is accomplished via
the "Remote_Control" scenario variable.

See the package bodies for how to use the corresponding remote controls.

Videos of our car in action: 

* https://youtu.be/Hngzh5zDM3E

* https://youtu.be/nK9uDJ4909M (in which we can hear the ultrasonic sensor pings)
