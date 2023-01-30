CREATE FUNCTION [dbo].[udfIsLanguageExcluded]
	(
		@CountryID		INT, 
		@Language		VARCHAR(100)
	)

	RETURNS BIT

/*
	Version			Date			Developer			Comment
	1.0				?				Eddie Thomas		Created
	1.1				2016-03-15		Chris Ledger		Add functionality by country 
	1.2				2016-06-09		Chris Ledger		Remove functionality by Sample File
*/

AS

BEGIN

	DECLARE @bReturn BIT = 0
	
	--DOES SAMPLEFILED ID EXIST FOR PERMISSABLE LANGUAGES
	IF EXISTS (	SELECT		* 
					FROM		[$(SampleDB)].[dbo].SampleFileOutputLanguages	OL
					INNER JOIN  [$(SampleDB)].[dbo].Languages					LA ON OL.AvailableOutputLanguage = LA.LanguageID
					WHERE		CountryID = @CountryID			-- V1.2
				)
				BEGIN
					--DOES LANGAUGE EXIST FOR THIS SAMPLEFILEID COMBINATION
					IF NOT EXISTS 
					(	
						SELECT		* 
						FROM		[$(SampleDB)].[dbo].SampleFileOutputLanguages	OL
						INNER JOIN  [$(SampleDB)].[dbo].Languages					LA ON OL.AvailableOutputLanguage = LA.LanguageID
						WHERE		CountryID = @CountryID				-- V1.2					
									AND (@Language = LA.ISOAlpha2 OR @Language = ISOAlpha3 OR @Language = Language)
					)
					
					--IT DOESN'T EXIST, DON'T ALLOW OUPUT OF THIS PREFEERED LANGUAGE
					SET @bReturn = 1
						
				END
				


	RETURN @bReturn
	

END
