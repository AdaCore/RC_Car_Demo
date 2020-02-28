with Ada.Interrupts;      use Ada.Interrupts;

package Serial_IO.Interrupt_Driven is
   pragma Elaborate_Body;

   type Serial_Port (IRQ : Interrupt_ID) is new Serial_IO.Device with private;
   --  A serial port that uses interrupts for I/O. Extends the serial port
   --  abstraction that is itself a wrapper for the USARTs hardware.

   overriding
   procedure Put (This : in out Serial_Port;  Data : Character) with Inline;
   --  Non-blocking, ie the caller returns while the character is going out.
   --  Will not interfere with any other I/O on the same device.

   overriding
   procedure Get (This : in out Serial_Port;  Data : out Character) with Inline;
   --  Blocks the caller until a character is available!
   --  Will not interfere with any other I/O on the same device.

private

   --  The protected type defining the interrupt-based I/O for sending and
   --  receiving via the USART attached to the serial port designated by
   --  Port. Each serial port object of the type defined by this package has
   --  a component of this protected type.
   protected type IO_Manager
     (IRQ  : Interrupt_ID;
      Port : access Serial_Port)
   is
      pragma Interrupt_Priority;

      entry Put (Datum : Character);

      entry Get (Datum : out Character);

   private

      Outgoing : Character;
      Incoming : Character;

      Incoming_Data_Available : Boolean := False;
      Transmission_Pending    : Boolean := False;

      procedure Handle_Transmission with Inline;
      procedure Handle_Reception with Inline;

      procedure IRQ_Handler with Attach_Handler => IRQ;
      --  The one interrupt handler for both sending and receiving. Calls the
      --  respective Handle_* routines above for each incoming or outgoing
      --  character interrupt on the USART.

   end IO_Manager;

   type Serial_Port (IRQ : Interrupt_ID) is new Serial_IO.Device with record
      Controller : IO_Manager (IRQ, Serial_Port'Access);
      --  Note that the access discriminant on the protected type provides the
      --  Controller with a view to the Serial_IO.Device components inherited
      --  by this type extension (as well as components introduced by the
      --  extension itself, if any).
   end record;

end Serial_IO.Interrupt_Driven;
