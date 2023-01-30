/*
Purpose:	Pass in an input string and return a code denoting if the string could be a house number.
Version		Developer		Date		Comment
1.0		Martin Riverol		24/09/2003	Created
*/
CREATE FUNCTION dbo.udfIsHouseNumber (@InputString nvarchar(50), @CountryID smallint)  
RETURNS bit AS  
BEGIN 
declare @Char nvarchar(2)
declare @ProcessString nvarchar(50)
declare @CharLen smallint
declare @iCounter smallint
/*	A mathematical operator passed into the isnumeric function will return a true value.
	In the context of a house number these should be ignored therefore remove them
	prior to deciding if they are a valid house number		*/
set @ProcessString = replace(@InputString, '.', '')
set @ProcessString = replace(@ProcessString, '-', '')
set @ProcessString = replace(@ProcessString, '/', '')
set @ProcessString = replace(@ProcessString, '*', '')
set @ProcessString = replace(@ProcessString, '+', '')
set @iCounter = 1
set @CharLen = len(@ProcessString)
--inputstring can be converted to a number therefore likely a house number
if isnumeric(@ProcessString) = 1 
	return 1
while @iCounter <= (@CharLen)
	begin	
		set @char = substring(@ProcessString, @iCounter, 1)
		
		--the input string contains a numeric therefore likely a house number
		if isnumeric(@char) = 1
			return 1
	
		set @iCounter = @iCounter + 1
	
	continue
	end
return 0
END
