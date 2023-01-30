CREATE PROCEDURE CustomerUpdate.uspRegistrationNumber_Insert

AS

/*
	Purpose:	Update Registrations with the data from the customer update and load into Audit

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSInsert_RegistrationNumber

*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- CHECK IF WE'VE GOT AN ENTRY IN VehicleRegistrationEvents FOR THE EVENT FOR THIS CASE
		UPDATE CURN
		SET	 CURN.VehicleRegistrationEventMatch = 1
			,CURN.EventID = AEBI.EventID
		FROM CustomerUpdate.RegistrationNumber CURN
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CURN.CaseID AND AEBI.PartyID = CURN.PartyID
		INNER JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE ON VRE.EventID = AEBI.EventID
																	AND VRE.VehicleID = AEBI.VehicleID

		-- INSERT THE NEW REG NUMBERS
		SELECT
			 IDENTITY(INT, 1, 1) AS ID
			,AuditItemID
			,RegNumber
		INTO #RegNumbers
		FROM CustomerUpdate.RegistrationNumber
		WHERE AuditItemID = ParentAuditItemID

		DECLARE @MaxRegistrationID INT
		SELECT @MaxRegistrationID = MAX(RegistrationID) FROM [$(SampleDB)].Vehicle.Registrations

		UPDATE CURN
		SET CURN.NewRegistrationID = @MaxRegistrationID + R.ID
		FROM CustomerUpdate.RegistrationNumber CURN
		INNER JOIN #RegNumbers R ON R.AuditItemID = CURN.AuditItemID

		DROP TABLE #RegNumbers

		SET IDENTITY_INSERT [$(SampleDB)].Vehicle.Registrations ON

		INSERT INTO [$(SampleDB)].Vehicle.Registrations (RegistrationID, RegistrationNumber)
		SELECT DISTINCT NewRegistrationID, RegNumber
		FROM CustomerUpdate.RegistrationNumber
		WHERE AuditItemID = ParentAuditItemID

		SET IDENTITY_INSERT [$(SampleDB)].Vehicle.Registrations OFF

		INSERT INTO [$(AuditDB)].Audit.Registrations
		(
			AuditItemID,
			RegistrationID,
			RegistrationNumber
		)
		SELECT DISTINCT AuditItemID, NewRegistrationID, RegNumber
		FROM CustomerUpdate.RegistrationNumber
		WHERE AuditItemID = ParentAuditItemID

		-- NOW DELETE THE EXISTING VehicleRegistrationEvents
		DELETE VRE
		FROM CustomerUpdate.RegistrationNumber CURN
		INNER JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE ON VRE.EventID = CURN.EventID

		-- ADD THE NEW VehicleRegistrationEvents
		INSERT INTO [$(SampleDB)].Vehicle.VehicleRegistrationEvents (VehicleID, RegistrationID, EventID)
		SELECT AEBI.VehicleID, CURN.NewRegistrationID, AEBI.EventID
		FROM CustomerUpdate.RegistrationNumber CURN
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CURN.CaseID AND AEBI.PartyID = CURN.PartyID
		WHERE CURN.AuditItemID = CURN.ParentAuditItemID

		INSERT INTO [$(AuditDB)].Audit.VehicleRegistrationEvents (AuditItemID, VehicleID, RegistrationID, EventID)
		SELECT CURN.AuditItemID, AEBI.VehicleID, CURN.NewRegistrationID, AEBI.EventID
		FROM CustomerUpdate.RegistrationNumber CURN
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CURN.CaseID AND AEBI.PartyID = CURN.PartyID
		WHERE CURN.AuditItemID = CURN.ParentAuditItemID

	COMMIT TRAN

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
