CREATE PROCEDURE Load.uspEmailAddresses

AS

/*
	Purpose:	Write email addresses to Sample database
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_ElectronicAddresses
	1.1				01/06/2015		Eddie Thomas		BUG 11545 - Ensuring primary EmailAddress field has highest priority.
														Changing order that the contactmechaniksms are created allows for this
	 
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_EmailAddresses
	(
		AuditItemID, 
		ContactMechanismID, 
		EmailAddress, 
		EmailAddressChecksum,
		ContactMechanismTypeID, 
		Valid, 
		EmailAddressType
	)
	SELECT 
		AuditItemID, 
		ContactMechanismID, 
		EmailAddress, 
		EmailAddressChecksum,
		ContactMechanismTypeID, 
		Valid, 
		EmailAddressType
	FROM Load.vwEmailAddresses
	
	ORDER BY CASE EmailAddressType					--1.1
				WHEN 'PrivEmailAddress'  THEN 1		--1.1
				WHEN 'EmailAddress' THEN 2			--1.1
			END

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