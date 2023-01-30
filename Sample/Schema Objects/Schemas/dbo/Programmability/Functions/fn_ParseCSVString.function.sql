CREATE FUNCTION [dbo].[fn_ParseCSVString]
    (
      @CSVString VARCHAR(8000) ,
      @Delimiter VARCHAR(10)
    )
RETURNS @tbl TABLE ( s VARCHAR(1000) )
AS /*
select * from dbo.fn_ParseCSVString ('qwe,c,rew,c,wer', ',')
*/
    BEGIN
        DECLARE @i INT ,
            @j INT;
        SELECT  @i = 1;
        WHILE @i <= LEN(@CSVString)
            BEGIN
                SELECT  @j = CHARINDEX(@Delimiter, @CSVString, @i);
                IF @j = 0
                    BEGIN
                        SELECT  @j = LEN(@CSVString) + 1;
                    END;
                INSERT  @tbl
                        SELECT  SUBSTRING(@CSVString, @i, @j - @i);
                SELECT  @i = @j + LEN(@Delimiter);
            END;
        RETURN;
    END;

GO