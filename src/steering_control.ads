with System_Configuration;
with NXT.Motors;

package Steering_Control
  with SPARK_Mode
is

   pragma Elaborate_Body;

   Encoder_Counts_Per_Degree : constant NXT.Motors.Motor_Encoder_Counts :=
      NXT.Motors.Motor_Encoder_Counts (Float (NXT.Motors.Encoder_Counts_Per_Revolution) / 360.0);
   --  The number of encoder values reported per degree of rotation.

private

   task Servo with
     Storage_Size => 1 * 1024,
     Priority     => System_Configuration.Steering_Priority;

end Steering_Control;
