with Interfaces;

package AdaFruit.BLE_Msg_Utils is

   type Three_Axes_Data is record
      X, Y, Z : Float;
   end record with
     Alignment => 1;

   type Quaternion_Data is record
      X, Y, Z, W : Float;
   end record with
     Alignment => 1;

   function Yaw (Q : Quaternion_Data) return Float with Inline;
   function Pitch (Q : Quaternion_Data) return Float with Inline;

   type Button_Data is record
      Button_Number : Interfaces.Unsigned_8;
      Value         : Character;
   end record with
     Alignment => 1,
     Object_Size => 16;

   type Color_Data is record
      R, G, B : Interfaces.Unsigned_8;
   end record with
     Alignment => 1,
     Object_Size => 24;

   Gyro_Msg          : constant Character := 'G';
   Quaternion_Msg    : constant Character := 'Q';
   Accelerometer_Msg : constant Character := 'A';
   Magnetometer_Msg  : constant Character := 'M';
   Button_Msg        : constant Character := 'B';
   Color_Picker_Msg  : constant Character := 'C';

   Quaternion_Msg_Length    : constant := 18;
   Accelerometer_Msg_Length : constant := 14;
   Gyro_Msg_Length          : constant := 14;
   Magnetometer_Msg_Length  : constant := 14;
   Button_Msg_Length        : constant := 4;
   Color_Picker_Msg_Length  : constant := 5;

   generic
      type Payload is private;
   procedure Parse_AdaFruit_Controller_Message
     (Input    : String;
      Msg_Kind : Character;
      Result   : out Payload;
      Success  : out Boolean);

end AdaFruit.BLE_Msg_Utils;
