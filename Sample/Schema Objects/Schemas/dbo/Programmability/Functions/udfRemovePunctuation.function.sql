CREATE  FUNCTION dbo.udfRemovePunctuation
(
  @return NVARCHAR(2000)
)  
RETURNS 
  NVARCHAR(2000) 
AS  
/*
Description
-----------
Returns a unicode string stripped of all punctuation

Version		Date		Aurthor		Why
------------------------------------------------------------------------------------------------------
1.0		15/01/2004	Mark Davidson	Created

*/
BEGIN 

--Declare local variables	
  DECLARE @unicode INT

--Validate parameter
	IF NULLIF(@return, N'') IS NULL
		GOTO rt

  SET @unicode=33
  WHILE @unicode BETWEEN 33 AND 47
    BEGIN
      SET @return = REPLACE(@return, NCHAR(@unicode), N'')
      SET @unicode=@unicode+1
    END

  SET @unicode=58
  WHILE @unicode BETWEEN 58 AND 64
    BEGIN
      SET @return = REPLACE(@return, NCHAR(@unicode), N'')
      SET @unicode=@unicode+1
    END

	SET @unicode = 91
  WHILE @unicode BETWEEN 91 AND 95
    BEGIN
      SET @return = REPLACE(@return, NCHAR(@unicode), N'')
      SET @unicode=@unicode+1
    END

	SET @unicode = 123
  WHILE @unicode BETWEEN 123 AND 126
    BEGIN
      SET @return = REPLACE(@return, NCHAR(@unicode), N'')
      SET @unicode=@unicode+1
    END

	SET @unicode = 163
	SET @return = REPLACE(@return, NCHAR(@unicode), N'')

	SET @unicode = 172
	SET @return = REPLACE(@return, NCHAR(@unicode), N'')


rt:
  RETURN(@return)
END


