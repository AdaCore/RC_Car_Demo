with System_Configuration;

package Engine_Control with
  SPARK_Mode
is

   pragma Elaborate_Body;

private

   task Controller with
      Storage_Size => 1 * 1024,
      Priority     => System_Configuration.Engine_Control_Priority;

end Engine_Control;
