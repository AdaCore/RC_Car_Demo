with STM32.Device; use STM32.Device;

package body AdaFruit.Bluefruit_LE_Friend is

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (This     : in out Bluefruit_LE_Transceiver;
      Mode_Pin : GPIO_Point)
   is
      Configuration : GPIO_Port_Configuration;
   begin
      This.Mode_Pin := Mode_Pin;

      Enable_Clock (Mode_Pin);
      Configuration := (Mode_Out,
                        Output_Type => Push_Pull,
                        Speed       => Speed_100MHz,  -- arbitrary
                        Resistors   => Pull_Down);
      Mode_Pin.Configure_IO (Configuration);
   end Configure;

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode
     (This : in out Bluefruit_LE_Transceiver;
      Mode : Modes)
   is
   begin
      if Mode = Command then
         This.Mode_Pin.Set;
      else
         This.Mode_Pin.Clear;
      end if;
   end Set_Mode;

   ------------------
   -- Current_Mode --
   ------------------

   function Current_Mode (This : Bluefruit_LE_Transceiver) return Modes is
   begin
      return (if This.Mode_Pin.Set then Command else Data);
   end Current_Mode;

   ---------
   -- Put --
   ---------

   procedure Put
     (This : in out Bluefruit_LE_Transceiver;
      Data : Character)
   is
   begin
      Write (This.Port.all, Data);
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put
     (This : in out Bluefruit_LE_Transceiver;
      Data : String)
   is
   begin
      for Next_Char of Data loop
         Write (This.Port.all, Next_Char);
      end loop;
   end Put;

   ---------
   -- Get --
   ---------

   procedure Get
     (This : in out Bluefruit_LE_Transceiver;
      Data : out Character)
   is
   begin
      Read (This.Port.all, Data);
   end Get;

   ---------
   -- Get --
   ---------

   procedure Get
     (This : in out Bluefruit_LE_Transceiver;
      Data : out String;
      Last : out Natural;
      EOM  : Character)
   is
      Next_Received : Character;
   begin
      Last := Data'First - 1;
      for Index in Data'Range loop
         Read (This.Port.all, Next_Received);
         exit when Next_Received = EOM;
         Data (Index) := Next_Received;
         Last := Index;
      end loop;
   end Get;

   ---------
   -- Get --
   ---------

   procedure Get
     (This : in out Bluefruit_LE_Transceiver;
      Data : out String)
   is
   begin
      for Index in Data'Range loop
         Read (This.Port.all, Data (Index));
      end loop;
   end Get;

end AdaFruit.Bluefruit_LE_Friend;
