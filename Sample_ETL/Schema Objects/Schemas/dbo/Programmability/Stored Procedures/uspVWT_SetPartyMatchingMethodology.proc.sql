CREATE PROCEDURE [dbo].[uspVWT_SetPartyMatchingMethodology]

AS

/*
	Purpose:	Set the PartyMatchingMethodologyTypeID for use in the Person De-dupe and Person matching routines
	
	Version			Date			Developer			Comment
	1.0				02-12-2014		Chris Ross			Original version
	1.1				22-04-2015		Chris Ross			Bug 11483 - Modify to set default matching methodology to 1 where market does not exist.
																	Still error though if market exists but methodolgy not set.
	1.2				19-02-2020		Chris Ledger		Bug 17942 - Set PartyMatchingMethodologyID to Name and Email Address for MCQI 1MIS Survey											
--

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE v
	SET v.PartyMatchingMethodologyID = CASE WHEN m.CountryID IS NULL THEN 1 ELSE m.PartyMatchingMethodologyID END   -- 1.1
	FROM dbo.VWT v
	LEFT JOIN [$(SampleDB)].[dbo].Markets m ON m.CountryID = v.CountryID				

	-- V1.2 Set PartyMatchingMethodologyID to Name and Email Address for MCQI 1MIS Survey
	UPDATE v SET v.PartyMatchingMethodologyID = (SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address')
	FROM dbo.VWT v
	INNER JOIN [$(SampleDB)].[Event].[EventTypeCategories] etc ON etc.EventTypeID = V.ODSEventTypeID		
	INNER JOIN [$(SampleDB)].[Event].[EventCategories] ec ON ec.EventCategoryID = etc.EventCategoryID
	WHERE ec.EventCategory = 'MCQI 1MIS'

	IF EXISTS (SELECT * FROM dbo.VWT WHERE PartyMatchingMethodologyID IS NULL)
	  RAISERROR('ERROR: Row(s) in VWT where PartyMatchingMethodologyID NOT set.  See procedure Sample_ETL.dbo.uspVWT_SetPartyMatchingMethodology', 16, 1) 


END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH