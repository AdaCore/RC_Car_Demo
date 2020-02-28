--  This package represents the physical plant, ie the RC car itself. As such,
--  it contains the declarations for the two NXT motors and the NXT ultrasonic
--  "sonar" sensor. The motors are used for propulsion and steering, and the
--  sonar is used for collision avoidance. Other physical artifacts are also
--  provided here, such as the mapping of turning directions to motor rotation
--  direction, the wheel size and gear ratio, and so forth. Finally, the package
--  provides runtime information about the car, such as the current speed (in
--  centimeters/sec).
--
--  The physical car is based directly on the HiTechnic IR RC Car, with several
--  significant differences. Not least is the fact that no LEGO NXT brick is
--  used, requiring a "cage" to hold the selected MCU card as well as a place to
--  put the third-party electronics card used to interface to the NXT motors and
--  sonar sensor.
--
--  Instructions for building their original car are here:
--  http://www.hitechnic.com/models

with System_Configuration;
with NXT.Motors;             use NXT.Motors;
with NXT.Ultrasonic_Sensors; use NXT.Ultrasonic_Sensors;
with Remote_Control;         use Remote_Control;

package Vehicle with
  SPARK_Mode,
  Abstract_State => (Internal_State with Synchronous),
  Initializes => (Internal_State)
  --  Initializes => (Engine, Steering_Motor, Sonar, Internal_State),
  --  Initial_Condition => Configured (Sonar) and then Enabled (Sonar) and then Current_Scan_Mode (Sonar) = Continuous
is

   pragma Elaborate_Body;

   procedure Initialize with
     Post => Configured (Sonar) and then Enabled (Sonar) and then Current_Scan_Mode (Sonar) = Continuous;

   Engine         : Basic_Motor;  -- this is NXT_Shield.Motor2, as physically connected
   Steering_Motor : Basic_Motor;  -- this is NXT_Shield.Motor1, as physically connected

   Sonar : Ultrasonic_Sonar_Sensor (Hardware_Device_Address => 1);
   --  this sensor is always on the third port of the NXT_Shield, dedicated to
   --  sensors that require +9V power

   To_The_Right : constant NXT.Motors.Directions := Backward;
   To_The_Left  : constant NXT.Motors.Directions := Forward;
   --  The mapping of steering directions to motor directions. These values
   --  reflect the physical construction of the vehicle.

   function To_Steering_Motor_Direction (Power : Float) return NXT.Motors.Directions
   with Inline;
   --  Map the input power to a motor rotation direction, ie one of the above
   --  constants. The choice of To_The_Right versus To_The_Left reflects the
   --  steering mechanism's physical construction with the steering motor.

   function To_Propulsion_Motor_Direction (Direction : Remote_Control.Travel_Directions)
     return NXT.Motors.Directions
   with Inline,
        Pre => Direction /= Remote_Control.Neither;
   --  Map the input travel direction to a motor rotation direction. The result
   --  reflects the drive mechanism's physical construction with the propulsion
   --  motor.

   function Speed return Float with Inline, Volatile_Function;
   --  in cm/sec

   function Odometer return Float with Inline, Volatile_Function;
   --  in centimeters

   Sonar_Offset_From_Front : constant Centimeters := 8;
   --  The offset of the ultrasonic sensor from the front of the vehicle as
   --  physically built. You need to change this if you move the sonar sensor.

   --  The wheel diameter and gear ratio are used in the package body to
   --  calculate the speed, but might be useful elsewhere within the code.
   --  Therefore we make their declarations visible.
   --
   --  NOTE: if you use different wheels or change the gear ratio you must
   --  change these values! Otherwise the speed and distance traveled
   --  calculations will be wrong.

   Wheel_Diameter : constant := 5.6; -- centimeters
   --  This is the diameter for the Lego NXT 56x26mm wheels.

   Gear_Ratio : constant := 24.0 / 40.0;
   --  This is the gear ratio using the 24-tooth gear on the differential
   --  as the driven output gear and the 40-tooth spur gear as the driver gear
   --  connected to the motor.
   --
   --  LEGO Technic Differential Gear Complete Set 24-16 Teeth (part 6573) and
   --  Bevel Gears 12-Tooth (part 6589)

private

   task Engine_Monitor with
     Part_Of      => Internal_State,
     Storage_Size => 1 * 1024,
     Priority     => System_Configuration.Engine_Monitor_Priority;

end Vehicle;
