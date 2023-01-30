CREATE FUNCTION [SelectionOutput].[udfFormatTelNoForDimensions]

		(
			@TelephoneNumber	[dbo].[ContactNumber],
			@CountryId			[dbo].[CountryID]
		)

RETURNS [dbo].[ContactNumber]
AS
BEGIN

	DECLARE	@CleanedTelno [dbo].[ContactNumber]  = '',
			@CTRYDialCode [dbo].[ContactNumber]  = ''	


	--CLEAN TELEPHONE NUMBER
	SET		@CleanedTelno = RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@TelephoneNumber,'-'
						  ,''),'(',''),')',''),'/',''),'-',''),' ',''),' ',''),'.','')))


	--GET DIALLING CODE FOR SPECIFIC COUNTRY
	SELECT	@CTRYDialCode = InternationalDiallingCode
	FROM	[ContactMechanism].[Countries]
	WHERE	CountryID = @CountryId

	IF ISNULL(@CleanedTelno,'') <> ''
			--ADD FORMATTING TO TEL NUMBER
			SELECT @CleanedTelno = CASE  
										WHEN @CleanedTelno LIKE '00%' THEN '+' + @CTRYDialCode + SUBSTRING(@CleanedTelno,3,LEN(@CleanedTelno)-2)	-- STRIP 00 AND REPLACE WITH INTL PREFIX
										WHEN @CleanedTelno LIKE '0%' THEN '+' + @CTRYDialCode + SUBSTRING(@CleanedTelno,2,LEN(@CleanedTelno)-1)		-- STRIP 0 AND REPLACE WITH INTL PREFIX
										WHEN @CleanedTelno LIKE '+%' THEN @CleanedTelno																-- ALREADY INCLUDES INTL DIAL CODE
										ELSE '+' + @CTRYDialCode + @CleanedTelno																	-- ADD DIALING CODE TO ANYTHING ELSE
									END
	ELSE 	
			SELECT @CleanedTelno =''
			
	RETURN @CleanedTelno
END