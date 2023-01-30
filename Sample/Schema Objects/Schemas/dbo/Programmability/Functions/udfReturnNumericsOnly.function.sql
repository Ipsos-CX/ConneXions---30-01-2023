CREATE FUNCTION [dbo].[udfReturnNumericsOnly]
(
	@s VARCHAR (1000)
)

/*
	Purpose:	Returns only the numeric characters from the string supplied
	
	Version		Date			Developer			Comment
	1.0			17/01/2014		Chris Ross			Created

*/
RETURNS VARCHAR (1000)
AS
begin
   if @s is null
      return ''
      
   declare @s2 varchar(1000)
   set @s2 = ''
   
   declare @l int
   set @l = len(@s)
   
   declare @p int
   set @p = 1
   
   while @p <= @l 
   begin
      declare @c int
      set @c = ascii(substring(@s, @p, 1))
      if @c between 48 and 57  -- zero to nine
		 set @s2 = @s2 + char(@c)
      
      set @p = @p + 1
   end

   if len(@s2) = 0
      return ''
   return @s2
end