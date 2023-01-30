CREATE FUNCTION [Selection].[udfStripCharForNPSMobile]

	(@MobileNumber NVARCHAR(70))

RETURNS NVARCHAR(70)
AS
BEGIN

	DECLARE @retVal nvarchar(70)

	-- THE WEEK NUMBERS START FROM WEEK COMMENCING 25/09/2006

	IF LEFT(@MobileNumber,1)= '0'
		
		SET	@retVal = SUBSTRING(@MobileNumber,2,LEN(@MobileNumber))   
		
	ELSE 
		
		SET	@retVal = @MobileNumber

	RETURN @retVal
END