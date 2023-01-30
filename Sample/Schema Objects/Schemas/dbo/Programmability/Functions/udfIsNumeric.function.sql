CREATE FUNCTION [dbo].[udfIsNumeric]
(
	@Input NVARCHAR(100)
)

/*
	Purpose:	Does input contain number values 0-9?
	
	Version		Date			Developer			Comment
	1.0			26/11/2013		Martin Riverol		Created

*/
RETURNS BIT

AS

	BEGIN

		DECLARE @Output NVARCHAR(100)
		DECLARE @InputLen SMALLINT
		DECLARE @Result BIT 

		SET @InputLen = LEN(@Input)
		SET @Output = ''

		SELECT @Output = @Output + Value
		FROM
			(
				SELECT TOP 100 PERCENT Number, SUBSTRING(@input, Number, 1) AS Value
				FROM dbo.Numbers (NOLOCK)
				WHERE Number <= @InputLen
				ORDER BY Number
			) AS S
		WHERE Value LIKE '[0-9]'	


		IF @InputLen = LEN(@Output)
			SET @Result = 1
		ELSE
			SET @Result = 0
			
	
		RETURN @Result	
	
	END