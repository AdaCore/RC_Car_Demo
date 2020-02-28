with Remote_Control;
with Vehicle;
with NXT.Ultrasonic_Sensors; use NXT.Ultrasonic_Sensors;

package Collision_Detection
  with SPARK_Mode
is
   pragma Unevaluated_Use_Of_Old (Allow);

   procedure Check
     (Current_Direction  : Remote_Control.Travel_Directions;
      Current_Speed      : Float;
      Collision_Imminent : out Boolean)
   with
     Pre  => Vehicle.Sonar.Configured and then
             Vehicle.Sonar.Enabled and then
             Vehicle.Sonar.Current_Scan_Mode = Continuous,
     Post => Vehicle.Sonar.Configured and then
             Vehicle.Sonar.Enabled and then
             Vehicle.Sonar.Current_Scan_Mode = Vehicle.Sonar.Current_Scan_Mode'Old;

end Collision_Detection;
