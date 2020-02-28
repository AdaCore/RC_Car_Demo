with STM32.Board; use STM32.Board;

package body Collision_Detection
  with SPARK_Mode
is

   function Moving_Forward
     (Current_Direction : Remote_Control.Travel_Directions;
      Current_Speed     : Float)
   return Boolean
     with Inline;

   function Exclusion_Zone_Violated (Sonar_Reading : Centimeters) return Boolean
     with Inline;

   -----------
   -- Check --
   -----------

   procedure Check
     (Current_Direction  : Remote_Control.Travel_Directions;
      Current_Speed      : Float;
      Collision_Imminent : out Boolean)
   is
      Reading       : Centimeters;
      IO_Successful : Boolean;
   begin
      Orange_LED.Clear;
      Collision_Imminent := False;  -- default
      if Moving_Forward (Current_Direction, Current_Speed) then
         Vehicle.Sonar.Get_Distance (Reading, IO_Successful);
         if not IO_Successful then
            Orange_LED.Set;
            return;
         else
            Collision_Imminent := Exclusion_Zone_Violated (Reading);
         end if;
      end if;
   end Check;

   --------------------
   -- Moving_Forward --
   --------------------

   function Moving_Forward
     (Current_Direction : Remote_Control.Travel_Directions;
      Current_Speed     : Float)
   return Boolean
   is
      use Remote_Control;
   begin
      return Current_Direction = Forward and Current_Speed > 0.0;
   end Moving_Forward;

   -----------------------------
   -- Exclusion_Zone_Violated --
   -----------------------------

   function Exclusion_Zone_Violated (Sonar_Reading : Centimeters) return Boolean is
      Min_Distance : constant Centimeters := 27 + Vehicle.Sonar_Offset_From_Front;
      --  The minimum value read from the sonar sensor indicating an obstacle
      --  ahead that will require us to stop to avoid a collision. Empirically
      --  determined, and approximate. Meant to be sufficient when the vehicle
      --  is traveling at high speed (ie, to give time to stop). Note that too
      --  large a number will cause the vehicle to stop more often than expected
      --  by drivers.
   begin
      if Sonar_Reading = NXT.Ultrasonic_Sensors.Nothing_Detected then
         return False;
      else
         return Sonar_Reading <= Min_Distance;
      end if;
   end Exclusion_Zone_Violated;

end Collision_Detection;
