
CREATE FUNCTION SelectionOutput.udfGeneratePassword( )

/*

Version	Created		Author		Purpose						Called by
2.0		20-Feb-2015	P.Doyle		Change functionality    	Various sp's but mostly [SelectionOutput].[uspRunOutput] 
                                see bug 11224 and
								make it easier to understand  
2.1     09/11/2017  B.King      BUG 14366 - Remove characters from password.
*/

RETURNS CHAR(10)
AS
    BEGIN

        DECLARE @pass_len AS INT
        DECLARE @password varchar(7) 
        DECLARE @ValidChar AS VARCHAR(400) 
        DECLARE @WeekNumber CHAR(3)

		SET @pass_len = 7		
        SET @WeekNumber = DATEDIFF(wk, '25 Sep 2006', GETDATE())        
        SET @ValidChar = 'abcdefghjkmnopqrstuvwxyzABCDEFGHJKMNOPQRSTUVWXYZ023456789' 

        DECLARE @counter INT 
        SET @counter = 0 
        SET @password = '' 
        WHILE @counter < @pass_len
            BEGIN 
                SELECT  @password = @password + SUBSTRING(@ValidChar,
                                                          ( SELECT
                                                              CONVERT(INT, ( LEN(@ValidChar)
                                                              * MyRAND + 1 ))
                                                            FROM
                                                              vwGet_RAND
                                                          ), 1) 
                SET @counter += 1 
            END 
        RETURN @WeekNumber+ @password 
    END 


--old function code

--CREATE FUNCTION [SelectionOutput].[udfGeneratePassword]
--( )
--RETURNS VARCHAR (10)
--AS
--BEGIN
--DECLARE @r VARCHAR(1)
--DECLARE @pw VARCHAR(10)
--SET @pw = ''

--WHILE LEN(@pw) <10
--BEGIN
--	SELECT @pw = COALESCE(@pw, '') + n
--	FROM (
--			SELECT TOP 1
--			CHAR(number) n FROM
--			master..spt_values
--			WHERE type = 'P' AND 
--			(number BETWEEN ASCII(2) AND ASCII(9)
--			OR number BETWEEN ASCII('A') AND ASCII('H')
--			OR number BETWEEN ASCII('J') AND ASCII('N')
--			OR number BETWEEN ASCII('P') AND ASCII('Z'))
--			ORDER BY (SELECT [NewId] FROM dbo.vwGetNewID)
--		) a
--END

--RETURN @pw

--END


