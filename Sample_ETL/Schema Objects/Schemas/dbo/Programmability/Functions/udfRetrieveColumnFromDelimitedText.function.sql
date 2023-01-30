CREATE FUNCTION dbo.udfRetrieveColumnFromDelimitedText(
 @text      varchar(MAX)
,@column    int
,@separator char(1)
)RETURNS varchar(MAX)

AS

/*
	Description: Returns the specified column from a delimited text value.
	
	Version			Date			Developer			Comment
	1.0				19/01/2017		Chris Ross			Created for BUG 13464.

*/


  BEGIN
       DECLARE @pos_start  int = 1
       DECLARE @pos_end    int = CHARINDEX(@separator, @text, @pos_start)

        WHILE (@column >1 and  @pos_end> 0)
         BEGIN
             SET @pos_start = @pos_end + 1
             SET @pos_end = CHARINDEX(@separator, @text, @pos_start)
             SET @column = @column - 1
         END 

        IF @column > 1  SET @pos_start  = LEN(@text) + 1
       IF @pos_end = 0 SET @pos_end = LEN(@text) + 1 

        RETURN SUBSTRING  (@text,  @pos_start, @pos_end - @pos_start)

END
