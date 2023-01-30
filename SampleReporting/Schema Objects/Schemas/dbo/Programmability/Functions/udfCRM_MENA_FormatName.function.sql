CREATE FUNCTION [dbo].[udfCRM_MENA_Format_Name]
(@FirstName NVARCHAR (MAX), @LastName NVARCHAR (MAX))
RETURNS 
    @t TABLE (
        [FirstName] NVARCHAR (40) NULL,
        [LastName] NVARCHAR (40) NULL)
AS
BEGIN 

/*
	Purpose:	This function is used to format and clean the MENA names before being output in the response feed.  We move the last part of the 
				first name into the last name, if last name is blank.  We then truncate both columns so that they are not longer than 40 chars.
		
	Version		Date				Developer			Comment
	1.0			21/02/2017			Chris Ross			Created.  BUG 13567.

*/


			
		-----------------------------------------------------------------------------
		-- Clean incoming name data
		------------------------------------------------------------------------------

		SET @FirstName = REPLACE(LTRIM(RTRIM(ISNULL(@FirstName, ''))), '  ', ' ')
	    SET @LastName = REPLACE(LTRIM(RTRIM(ISNULL(@LastName, ''))), '  ', ' ')
	

		-----------------------------------------------------------------------------
		-- If Last name is not populated then take the last name from the first name
		------------------------------------------------------------------------------

		IF NULLIF(@LastName, '') IS NULL		
		BEGIN 

			-- Working variables
			DECLARE @Position_SpaceAlSpace	INT,
					@Position_AlSpace		INT,
					@Position_SpaceAlHyphen	INT,
					@Position_Space		INT,
					@Position_SecondSpace INT,
					@LastNameSplit varchar(200)
		
			--Get column positions 
			SELECT @Position_SpaceAlSpace	= charindex(' lA ', reverse(@FirstName))
			SELECT @Position_AlSpace		= charindex(' lA', reverse(@FirstName))
			SELECT @Position_SpaceAlHyphen	= charindex('-lA ', reverse(@FirstName))
			SELECT @Position_Space			= charindex(' ', reverse(@FirstName))
			SELECT @Position_SecondSpace = charindex(' ', reverse(LTRIM(@FirstName)), @Position_Space+1)   -- remove the addtional space at beginning before checking
	



			SELECT @LastNameSplit = CASE WHEN @Position_Space > 0 AND @Position_SpaceAlHyphen > 0 AND @Position_Space <> LEN(@FirstName)									--If there is a space in the file but it is before "Al-"
											AND @Position_SpaceAlHyphen <=  (@Position_Space-3) THEN REVERSE(SUBSTRING(reverse(@FirstName),1,  @Position_SpaceAlHyphen+2))    -- then we the starting point of "Al-"
							 
										 WHEN @Position_Space > 0 AND @Position_SpaceAlSpace  >  0 AND @Position_SecondSpace > 0											-- If the first space lines up with the "Al " and there is an additional space 
											AND @Position_SpaceAlSpace  = @Position_Space THEN REVERSE(SUBSTRING(reverse(@FirstName),1, (@Position_SpaceAlSpace + 3 )))		-- we take from the beginning of the "Al "
										
										  WHEN @Position_Space > 0 AND @Position_AlSpace  >  0 AND (@Position_AlSpace+2) = LEN (@FirstName)							-- If the first space lines up with the "Al " and "Al " is at start of string
											AND @Position_AlSpace  = @Position_Space THEN REVERSE(SUBSTRING(reverse(@FirstName),1, (@Position_AlSpace + 3 ))) 		-- we take from the beginning of the "Al "
							
										 WHEN @Position_Space > 0 AND @Position_SpaceAlSpace <> @Position_Space AND @Position_Space <> LEN(@FirstName)		-- If there is a space counter value now, then it is after and not
											THEN REVERSE(SUBSTRING(reverse(@FirstName),1,  @Position_Space-1))											-- connect to either "Al " OR "Al-" so just takes from the space

										 ELSE @FirstName END																							-- otherwise there is only a single First name and we move that to last name

			SET @LastName = @LastNameSplit
			SET @FirstName = SUBSTRING(@FirstName, 1, (LEN(@FirstName) - LEN(@LastNameSplit)) )  

		END


		-----------------------------------------------------------------------------
		-- Truncate both Last Name and First Name to 40 characters
		------------------------------------------------------------------------------

			SET @FirstName = RTRIM(SUBSTRING(LTRIM(@FirstName), 1, 40) )
			SET @LastName = RTRIM(SUBSTRING(LTRIM(@LastName), 1, 40) )


		-----------------------------------------------------------------------------
		-- Return the name values 
		------------------------------------------------------------------------------

		INSERT INTO @t VALUES( @FirstName,  @LastName )

		RETURN


END

