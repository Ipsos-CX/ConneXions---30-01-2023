﻿
CREATE FUNCTION dbo.udfGENERAL_FormatDateFromText
(
	@Date VARCHAR(100)
) RETURNS DATETIME
AS
BEGIN
	
	DECLARE @ReturnDate DATETIME
	
	IF @Date = '""'
	BEGIN
		SET @ReturnDate = NULL
	END
	ELSE
	BEGIN
		SET @ReturnDate = CONVERT(DATETIME, @Date)
	END
	
	RETURN @ReturnDate
END