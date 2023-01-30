CREATE PROCEDURE [Match].[uspTelephoneNumbers]

AS

/*
	Purpose:	Update VWT with ContactMechanismID for any numbers that already exist
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspMATCH_TelecommunicationsNumbers
	1.1				12-11-2015		Chris Ross			BUG 12081 - Add in ContactMechanismTypeID to matching of telephone numbers to ensure mobile numbers are created/matched correctly
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- Tel
	UPDATE V
	SET V.MatchedODSTelID = A.ContactMechanismID
	FROM dbo.VWT V
	INNER JOIN Audit.vwTelephoneNumbers A ON A.ContactNumberChecksum = CHECKSUM(ISNULL(V.Tel, ''))
											AND A.ContactNumber = ISNULL(V.Tel, '')
											AND A.ContactMechanismTypeID = (SELECT ContactMechanismTypeID 
																			FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes 
																			WHERE ContactMechanismType = 'Phone (landline)') 
	-- PrivTel
	UPDATE V
	SET V.MatchedODSPrivTelID = A.ContactMechanismID
	FROM dbo.VWT V
	INNER JOIN Audit.vwTelephoneNumbers A ON A.ContactNumberChecksum = CHECKSUM(ISNULL(V.PrivTel, ''))
											AND A.ContactNumber = ISNULL(V.PrivTel, '')
											AND A.ContactMechanismTypeID = (SELECT ContactMechanismTypeID 
																			FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes 
																			WHERE ContactMechanismType = 'Phone (landline)') 
	-- BusTel
	UPDATE V
	SET V.MatchedODSBusTelID = A.ContactMechanismID
	FROM dbo.VWT V
	INNER JOIN Audit.vwTelephoneNumbers A ON A.ContactNumberChecksum = CHECKSUM(ISNULL(V.BusTel, ''))
											AND A.ContactNumber = ISNULL(V.BusTel, '')
											AND A.ContactMechanismTypeID = (SELECT ContactMechanismTypeID 
																			FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes 
																			WHERE ContactMechanismType = 'Phone (landline)') 
	-- MobileTel
	UPDATE V
	SET V.MatchedODSMobileTelID = A.ContactMechanismID
	FROM dbo.VWT V
	INNER JOIN Audit.vwTelephoneNumbers A ON A.ContactNumberChecksum = CHECKSUM(ISNULL(V.MobileTel, ''))
											AND A.ContactNumber = ISNULL(V.MobileTel, '')
											AND A.ContactMechanismTypeID = (SELECT ContactMechanismTypeID 
																			FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes 
																			WHERE ContactMechanismType = 'Phone (mobile)') 
	-- PrivMobileTel
	UPDATE V
	SET V.MatchedODSPrivMobileTelID = A.ContactMechanismID
	FROM dbo.VWT V
	INNER JOIN Audit.vwTelephoneNumbers A ON A.ContactNumberChecksum = CHECKSUM(ISNULL(V.PrivMobileTel, ''))
											AND A.ContactNumber = ISNULL(V.PrivMobileTel, '')
											AND A.ContactMechanismTypeID = (SELECT ContactMechanismTypeID 
																			FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes 
																			WHERE ContactMechanismType = 'Phone (mobile)') 

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