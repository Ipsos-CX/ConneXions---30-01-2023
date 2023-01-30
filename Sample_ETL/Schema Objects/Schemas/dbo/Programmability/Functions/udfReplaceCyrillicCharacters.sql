CREATE FUNCTION dbo.udfReplaceCyrillicCharacters (@string NVARCHAR(MAX)) 

RETURNS NVARCHAR(MAX) 

AS

	-- FUNCTION TO REPLACE CYRILLIC CHARACTERS WITH ASCII CHARACHERS
	BEGIN

		DECLARE @i INT = 1
		DECLARE @result NVARCHAR(MAX) = N''

		WHILE (@i <= LEN(@string))
    
			BEGIN
    
				IF UNICODE(SUBSTRING(@string, @i, 1)) = 1040 
					BEGIN
						SET @result = @result + N'A'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1042 
					BEGIN
						SET @result = @result + N'B'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1045 
					BEGIN
						SET @result = @result + N'E'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1050 
					BEGIN
						SET @result = @result + N'K'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1056 
					BEGIN
						SET @result = @result + N'P'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1057 
					BEGIN
						SET @result = @result + N'C'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1072 
					BEGIN
						SET @result = @result + N'a'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1077
					BEGIN
						SET @result = @result + N'e'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1086
					BEGIN
						SET @result = @result + N'o'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1087
					BEGIN
						SET @result = @result + N'n'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1088
					BEGIN
						SET @result = @result + N'p'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1089
					BEGIN
						SET @result = @result + N'c'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1091
					BEGIN
						SET @result = @result + N'y'
					END
				ELSE IF UNICODE(SUBSTRING(@string, @i, 1)) = 1093
					BEGIN
						SET @result = @result + N'x'
					END
				ELSE 
					BEGIN
						SET @result = @result + SUBSTRING(@string, @i, 1)
					END
					
				SET @i = @i + 1
			END
		
		RETURN @result       
	
	END
GO