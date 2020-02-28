--  See https://www.adafruit.com/product/2479 for the product and links to the
--  (free) smarphone app provided by AdaFruit.

--  The red Mode LED on the breakout board will be blinking 3 times with a
--  3-second pause when in "CMD" mode, or 2-times when in "UART Data" mode.

--  The blue LED indicates a Bluetooth connection when on.

--  The UART Data mode uses hardware flow control so you must clear the CTS pin
--  to enable the TXO pin. See the discussion on this page:
--
--  https://learn.adafruit.com/introducing-the-adafruit-bluefruit-le-uart-friend/pinouts

with HAL;          use HAL;
with STM32.GPIO;   use STM32.GPIO;

generic

   type Transport_Media (<>) is limited private;
   --  This is the means of communicating between the BLE device and the MCU.
   --  The AdaFruit BLE Friend has two variants based on this medium: one
   --  that uses SPI and one that uses UART to communicate with the MCU. These
   --  generic formal parameters factor out that selection so that this one
   --  driver can be used with either medium (once instantiated).

   with procedure Read
     (This  : in out Transport_Media;
      Value : out Character) is <>;

   with procedure Write
     (This  : in out Transport_Media;
      Value : Character) is <>;

package AdaFruit.Bluefruit_LE_Friend is

   type Bluefruit_LE_Transceiver (Port : not null access Transport_Media) is
     tagged limited private;

   procedure Configure
     (This     : in out Bluefruit_LE_Transceiver;
      Mode_Pin : GPIO_Point);

   type Modes is (Command, Data);

   procedure Set_Mode
     (This : in out Bluefruit_LE_Transceiver;
      Mode : Modes)
     with Post => Current_Mode (This) = Mode;
   --  Note this will override the corresponding on-board switch setting

   function Current_Mode (This : Bluefruit_LE_Transceiver) return Modes;

   procedure Put
     (This : in out Bluefruit_LE_Transceiver;
      Data : Character);

   procedure Put
     (This : in out Bluefruit_LE_Transceiver;
      Data : String);

   procedure Get
     (This : in out Bluefruit_LE_Transceiver;
      Data : out Character);

   procedure Get
     (This : in out Bluefruit_LE_Transceiver;
      Data : out String;
      Last : out Natural;
      EOM  : Character);
   --  Fills the buffer. The value of Last will be the last index used when
   --  filling. Filling stops when either the buffer is full or the EOM char
   --  is detected. The EOM char is not included in the buffer.

   procedure Get
     (This : in out Bluefruit_LE_Transceiver;
      Data : out String);
   --  Fills the entire buffer before returning.

private

   type Bluefruit_LE_Transceiver (Port : not null access Transport_Media) is
   tagged limited record
      Mode_Pin : GPIO_Point;
   end record;

end AdaFruit.Bluefruit_LE_Friend;
