


CREATE    FUNCTION Lookup.udfGENERAL_GetCapitalisation
(
	@String NVARCHAR(1000)
)
RETURNS NVARCHAR(1000)
AS

/*
Description
-----------
Title cases the string passed to the function.

Parameters
-----------
@String

Version		Date		Aurthor		Why
------------------------------------------------------------------------------------------------------
1.0		20/01/2004	Mark Davidson	Created
1.1		10/02/2004	Rob Mason	Remove strings containing just '.'
2.0		$(ReleaseDate)		Simon Peacock		Renamed udfGENERAL_GetCapitalisation from uspSTANDARDISE_ProperCaseName
*/

BEGIN
--Declare Local Variables
	DECLARE @DelimLengthID TINYINT
	DECLARE @MaxDelimLengthID TINYINT
	DECLARE @DelimLength TINYINT
	--DECLARE @String NVARCHAR(1000)
	DECLARE @Position TINYINT

--Create table variables
	DECLARE @DelimLengths TABLE 
	(
		DelimLengthID TINYINT IDENTITY(1, 1), 
		DelimLength TINYINT
	)

--Initialise local variables
	SET @String = LTRIM(RTRIM(@String))


	--v1.1 - Replace strings that are just '.' with empty string
	SET @String = ISNULL(NULLIF(@String, '.'), N'')


--If zero length string, exit function here
	IF LEN(@String) < 1
		BEGIN
			RETURN @String
		END

----Lower case string
	SET @String = LOWER(@String)

----Upper case first character
	SET @String = UPPER(LEFT(@String, 1)) + CASE WHEN LEN(@String) < 2 THEN N'' ELSE RIGHT(@String, LEN(@String)-1) END

/*
	Insert distinct lengths of all delimiters
	into table variable
	n.b. use DATALENGTH/2 to keep 'space' characters
*/
	INSERT INTO @DelimLengths (DelimLength)
	SELECT 
		DATALENGTH(pcd.CapitalisationDelimiter)/2
	FROM
		Lookup.CapitalisationDelimiters AS pcd
	WHERE
		DATALENGTH(pcd.CapitalisationDelimiter)/2 <= LEN(@String)
	GROUP BY
		DATALENGTH(pcd.CapitalisationDelimiter)/2

/*
	Initialise variable with max of table variable identity column
*/
	SELECT @MaxDelimLengthID = MAX(DelimLengthID) FROM @DelimLengths

	SET @DelimLengthID = 1

--Loop through delim lengths
	WHILE @DelimLengthID <= @MaxDelimLengthID 
		BEGIN
			SET @Position = 0

--Get current delim length
			SELECT 
				@DelimLength = dl.DelimLength 
			FROM
				@DelimLengths AS dl
			WHERE 
				dl.DelimLengthID = @DelimLengthID

--Loop through each set of @DelimLength characters in @String
		  WHILE @position < LEN(RTRIM(@String))-@DelimLength
			  BEGIN
--Set current position in string
			    SET @position = @position + 1

--Update string where match found with any delimiter
						SELECT
							@String = LEFT(@String, (@position+@DelimLength)-1)
							+	UPPER(SUBSTRING(@String, @position+@DelimLength, 1))
							+	RIGHT(@String, LEN(@String) - (@position+@DelimLength))
						FROM
							Lookup.CapitalisationDelimiters AS pcd
						WHERE
							DATALENGTH(pcd.CapitalisationDelimiter)/2 = @DelimLength
							AND SUBSTRING(@String, @Position, @DelimLength) = pcd.CapitalisationDelimiter
			  END
			SET @DelimLengthID = @DelimLengthID + 1
		END

--Return function result
	RETURN(@String)
END
	



