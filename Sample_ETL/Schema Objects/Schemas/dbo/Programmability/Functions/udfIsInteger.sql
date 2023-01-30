CREATE FUNCTION [dbo].[udfIsInteger]
(
	@number NVARCHAR(20)
)
RETURNS BIT
AS
BEGIN

   RETURN ISNUMERIC(Replace(Replace(@number,'+','A'),'-','A') + '.0e0')

END