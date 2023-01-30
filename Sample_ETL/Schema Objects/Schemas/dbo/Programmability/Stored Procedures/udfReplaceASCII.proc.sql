CREATE FUNCTION [dbo].[udfReplaceASCII](@inputString NVARCHAR(4000))
RETURNS NVARCHAR(4000)
AS
	 --FUNCTION TO STRIP ALL SPECIAL CHARACTERS FROM A STRING 
     BEGIN
         DECLARE @badStrings NVARCHAR(4000);
         DECLARE @increment INT= 1;
         WHILE @increment <= DATALENGTH(@inputString)
             BEGIN
                 IF(ASCII(SUBSTRING(@inputString, @increment, 1)) < 32)
                     BEGIN
                         SET @badStrings = CHAR(ASCII(SUBSTRING(@inputString, @increment, 1)));
                         SET @inputString = REPLACE(@inputString, @badStrings, '');
                 END;
                 SET @increment = @increment + 1;
             END;
		 --REPLACE LEADING AND TRAILING SPACES AT THE END
         RETURN RTRIM(LTRIM(@inputString));
     END;
GO