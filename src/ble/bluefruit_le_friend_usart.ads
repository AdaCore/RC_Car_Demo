with Serial_IO.Interrupt_Driven;  use Serial_IO.Interrupt_Driven;

with AdaFruit.Bluefruit_LE_Friend;

package BlueFruit_LE_Friend_USART is new AdaFruit.Bluefruit_LE_Friend
  (Transport_Media => Serial_Port,
   Read            => Get,
   Write           => Put);
