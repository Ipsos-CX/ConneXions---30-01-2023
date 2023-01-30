CREATE FUNCTION [dbo].[udfCleanText]
(		
		@TextIn		NVARCHAR (255), 
		@Delimiter	VARCHAR (2)='|'
		
)

RETURNS NVARCHAR (255)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @RetVal NVARCHAR(510)='',
			@pos	INT			 =0
	
	
	Set @TextIn = LTRIM(RTRIM(ISNULL(@TextIn,'')))
	
	
	IF  LEN(@TextIn) > 0
	BEGIN
		
		--Remove CrLf's
		SET @TextIn = REPLACE(REPLACE(@TextIn, CHAR(10), ''), CHAR(13), '')
		
		--Search for delimter char, and return all char's before it
		SET  @pos = CHARINDEX(@Delimiter,@TextIn)				
		IF @pos > 0
			SET @TextIn = LEFT(@TextIn,@pos-1)
		
		SET @RetVal = @TextIn
	END

	-- Return the result of the function
	RETURN @RetVal
END
