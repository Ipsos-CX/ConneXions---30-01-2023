CREATE FUNCTION [dbo].[udfSplitColumnIntoTwo]
(@InputColumn NVARCHAR(MAX), @Column1Len INT, @Column2Len INT)
RETURNS @t TABLE (Column1 NVARCHAR(MAX), Column2 NVARCHAR(MAX))
AS

/*
	Purpose:	Splits a supplied column into two columns based on the column length params supplied.  The split is done so, if possible no whole words
				are split into the first string.  Where there are no spaces to determine words then the first string is split on the length 1 param.
				The second string is then simply the remaining text truncated at the length 2 value.
		
	Version		Date				Developer			Comment
	1.0			16/02/2017			Chris Ross			Created.  BUG 13567.

*/

BEGIN 


	DECLARE @Column1		NVARCHAR(MAX),
			@Column2		NVARCHAR(MAX),
			@RemainderTxt	NVARCHAR(MAX)

	select @InputColumn = REPLACE(@InputColumn, '  ', ' ')																									-- Remove any double spaces first

	IF CHARINDEX(' ', @InputColumn) = 0 OR -- If there are no spaces at all
	   CHARINDEX(' ', @InputColumn) > @Column1Len  -- If there is no space until after the first split length then just split on the column length
		SELECT @Column1 = substring(@InputColumn, 1,@Column1Len)																							-- get the first column from the intput string
	ELSE -- split on the last word that will fit 
		SELECT @Column1 = substring(@InputColumn, 1, (@Column1Len+1)-charindex(' ', reverse(substring(@InputColumn, 1, (@Column1Len+1))), 1))				-- get the first column from the intput string

	SELECT @RemainderTxt = LTRIM(replace(@InputColumn, @Column1, ''))																						-- calc the remainder

	-- Truncate the remaining text at column 2 length
	SELECT @Column2 = RTRIM(substring(@RemainderTxt, 1, @Column2Len)	)																					-- get the remainging chars that will fit in column2

	INSERT INTO @t VALUES( @Column1,  @Column2 )

	RETURN
END