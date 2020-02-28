with System;
with Ada.Unchecked_Conversion;
with Ada.Numerics.Generic_Elementary_Functions;

package body AdaFruit.BLE_Msg_Utils is

   Radians_To_Degrees : constant := 180.0 / Ada.Numerics.Pi;

   package Float_Elementary_Functions is new Ada.Numerics.Generic_Elementary_Functions (Float);
   use Float_Elementary_Functions;

   function Copysign (X, Y : Float) return Float with Inline;
   --  returns a value with the magnitude of X and the sign of Y

   ---------
   -- Yaw --
   ---------

   function Yaw (Q : Quaternion_Data) return Float is
      Siny_Cosp : constant Float := +2.0 * (Q.W * Q.Z + Q.X * Q.Y);
      Cosy_Cosp : constant Float := +1.0 - 2.0 * (Q.Y * Q.Y + Q.Z * Q.Z);
      Result    : Float;
   begin
      Result := Arctan (Siny_Cosp, Cosy_Cosp);
      Result := Result * Radians_To_Degrees;
      return Result;
   end Yaw;

   -----------
   -- Pitch --
   -----------

   function Pitch (Q : Quaternion_Data) return Float is
      Sinp   : constant Float := +2.0 * (Q.W * Q.Y - Q.Z * Q.X);
      Result : Float;
   begin
      if abs (Sinp) >= 1.0 then
         Result := Copysign (Ada.Numerics.Pi / 2.0, Sinp);
      else
         Result := Arcsin (Sinp);
      end if;
      Result := Result * Radians_To_Degrees;
      return Result;
   end Pitch;

   --------------
   -- Copysign --
   --------------

   function Copysign (X, Y : Float) return Float is
      Result : Float := X;
   begin
      if Y >= 0.0 then -- positive result
         if Result < 0.0 then
            Result := -Result;
         end if;
      else -- negative result
         if Result >= 0.0 then
            Result := -Result;
         end if;
      end if;
      return Result;
   end Copysign;

   ---------------------------------------
   -- Parse_AdaFruit_Controller_Message --
   ---------------------------------------

   procedure Parse_AdaFruit_Controller_Message
     (Input    : String;
      Msg_Kind : Character;
      Result   : out Payload;
      Success  : out Boolean)
   is
      Payload_Length : constant Integer := Payload'Size / System.Storage_Unit;
      --  Message payloads are always composed of bytes so we know the number
      --  of bits is a integral multiple of a storage units' size, hence the
      --  simple division.

      Start : Integer range Input'First - 1 .. Input'Last := Input'First - 1;

      type Payload_Reference is access all Payload with Storage_Size => 0;

      function As_Payload_Reference is new Ada.Unchecked_Conversion
        (Source => System.Address, Target => Payload_Reference);

   begin
      Success := False;
      --  find header (eg "!G") in Input
      for K in Input'First .. Input'Last - 1 loop
         if Input (K) = '!' and Input (K + 1) = Msg_Kind then
            Start := K;
            exit;
         end if;
      end loop;
      if Start = Input'First - 1 then  -- didn't find requested msg kind's header
         return;
      end if;
      if Start > Input'Last - Payload_Length + 1 then -- not enough data after the header
         return;
      end if;
      Success := True;
      Start := Start + 2; -- skip the 2-byte header
      Result := As_Payload_Reference (Input (Start)'Address).all;
   end Parse_AdaFruit_Controller_Message;

end AdaFruit.BLE_Msg_Utils;
