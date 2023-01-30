CREATE PROCEDURE [dbo].[uspVWT_StandardiseLanguages]
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		DECLARE	 @NewLanguageID INT	
	
		--GET THE LANGUAGE ID FOR AMERICAN ENGLISH
		SELECT	@NewLanguageID = LanguageID
		FROM	[$(SampleDB)].[dbo].Languages
		WHERE	ISOAlpha3 = 'ENA'
	

		--UPDATE NORTH AMERICAN RECORDS THAT ARE SET TO UK ENGLISH
		UPDATE		V
		SET			LanguageID							= @NewLanguageID
		FROM		dbo.VWT V
		INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	CN ON V.CountryID	= CN.CountryID AND CN.Country IN ('United States of America','Canada')
		INNER JOIN	[$(SampleDB)].[dbo].Languages				LG ON V.LanguageID	= LG.LanguageID AND LG.ISOAlpha3 = 'ENG'


		--GET THE LANGUAGE ID FOR AMERICAN SPANISH
		SELECT	@NewLanguageID = LanguageID
		FROM	[$(SampleDB)].[dbo].Languages
		WHERE	ISOAlpha3 = 'AES'


		--UPDATE NORTH AMERICAN RECORDS THAT ARE SET TO A SPANISH VARIANT, OTHER THAN AMERICAN SPANISH
		UPDATE		V
		SET			LanguageID							= @NewLanguageID
		FROM		dbo.VWT V
		INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	CN ON V.CountryID	= CN.CountryID AND CN.Country IN ('United States of America','Canada')
		INNER JOIN	[$(SampleDB)].[dbo].Languages				LG ON V.LanguageID	= LG.LanguageID AND LG.ISOAlpha3 = 'ESL'


		--GET THE LANGUAGE ID FOR CANADIAN FRENCH 
		SELECT	@NewLanguageID = LanguageID
		FROM	[$(SampleDB)].[dbo].Languages
		WHERE	ISOAlpha3 = 'FRC'
	
		--UPDATE CANADIAN RECORDS THAT ARE SET TO A FRENCH VARIANT, OTHER THAN CANADIAN FRENCH
		UPDATE		V
		SET			LanguageID							= @NewLanguageID
		FROM		dbo.VWT V
		INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	CN ON V.CountryID	= CN.CountryID AND CN.Country ='Canada'
		INNER JOIN	[$(SampleDB)].[dbo].Languages				LG ON V.LanguageID	= LG.LanguageID AND LG.ISOAlpha3 IN ('CPF','FRA','FRM','FRO','CPF')

	COMMIT

END TRY
BEGIN CATCH
	
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].[dbo].uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH