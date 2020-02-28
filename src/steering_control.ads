with System_Configuration;

package Steering_Control
  with SPARK_Mode
is

   pragma Elaborate_Body;

private

   task Servo with
     Storage_Size => 1 * 1024,
     Priority     => System_Configuration.Steering_Priority;

end Steering_Control;
