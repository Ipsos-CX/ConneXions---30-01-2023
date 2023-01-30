CREATE PROCEDURE [Match].[uspPostalAddresses]

AS

/*
	Purpose:	Match postal addresses from VWT against addresses in the Audit database writing back the contact 
				mechanism to the VWT. This ContactMechanismID can then be used later for match People 
				and Organisations.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspMATCH_Addresses
	1.1				14/11/2013		Chris Ross			9678 - Add in additional matching on postcode
	1.2				12/11/2019		Chris Ledger		Use Temporary Table	to Avoid TEMPDB running out of space
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	CREATE TABLE #PostalAddresses
	(
		ContactMechanismID INT,
		CountryID INT,
		AddressChecksum INT,					
		PostCode NVARCHAR(60)
	)

	INSERT INTO #PostalAddresses
	SELECT DISTINCT 
	PA.ContactMechanismID,
	PA.CountryID,
	PA.AddressChecksum,					
	PA.PostCode
	FROM [$(AuditDB)].Audit.PostalAddresses PA

	UPDATE V
	SET V.MatchedODSAddressID = AA.ContactMechanismID
	FROM dbo.vwVWT_PostalAddresses VA
	INNER JOIN #PostalAddresses AA ON VA.AddressChecksum = AA.AddressChecksum
									AND VA.CountryID = AA.CountryID
									AND REPLACE(REPLACE(VA.PostCode, '-', ''), ' ', '') = REPLACE(REPLACE(AA.PostCode , '-', '') , ' ', '')	-- v1.1
	INNER JOIN VWT V ON VA.AuditItemID = V.AuditItemID

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

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
			
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
