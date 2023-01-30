CREATE PROCEDURE [CustomerUpdate].[uspTelephoneNumber_Insert]

AS

/*
	Purpose:	Set Telephone Number for Customer Update
	
	Version			Date			Developer			Comment
	1.1				2018-11-27		Chris Ledger		CAST ContactMechanismTypeID AS INT to speed up query.

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

			
		-- Check the CaseID and PartyID combination is valid
		UPDATE CUTN
		SET CUTN.CasePartyCombinationValid = 1
		FROM CustomerUpdate.TelephoneNumber CUTN
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUTN.CaseID
										AND AEBI.PartyID = CUTN.PartyID

		-- HomeNumbers
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_TelephoneNumbers
		(
			AuditItemID,
			ContactMechanismID,
			ContactNumber,
			ContactMechanismTypeID,
			Valid,
			TelephoneType -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
		)
		SELECT 
			AuditItemID,
			ISNULL(HomeTelephoneContactMechanismID, 0) AS ContactMechanismID,
			HomeTelephoneNumber, 
			CAST((SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)') AS INT),
			1 AS Valid,
			NULL AS TelephoneType
		FROM CustomerUpdate.TelephoneNumber
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID

		-- get the ContactMechanismIDs generated
		UPDATE CUTN
		SET CUTN.HomeTelephoneContactMechanismID = ATN.ContactMechanismID
		FROM CustomerUpdate.TelephoneNumber CUTN
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE ATN.ContactNumber = CUTN.HomeTelephoneNumber

		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
			AuditItemID,
			HomeTelephoneContactMechanismID,
			PartyID,
			GETDATE(),
			CAST((SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home number') AS INT)
		FROM CustomerUpdate.TelephoneNumber
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID
		
		
		
		-- WorkNumbers
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_TelephoneNumbers
		(
			AuditItemID,
			ContactMechanismID,
			ContactNumber,
			ContactMechanismTypeID,
			Valid,
			TelephoneType -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
		)
		SELECT 
			AuditItemID,
			ISNULL(WorkTelephoneContactMechanismID, 0) AS ContactMechanismID,
			WorkTelephoneNumber, 
			CAST((SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)') AS INT),
			1 AS Valid,
			NULL AS TelephoneType
		FROM CustomerUpdate.TelephoneNumber
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID

		-- get the ContactMechanismIDs generated
		UPDATE CUTN
		SET CUTN.WorkTelephoneContactMechanismID = ATN.ContactMechanismID
		FROM CustomerUpdate.TelephoneNumber CUTN
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE ATN.ContactNumber = CUTN.WorkTelephoneNumber


		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
			AuditItemID,
			WorkTelephoneContactMechanismID,
			PartyID,
			GETDATE(),
			CAST((SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number') AS INT)
		FROM CustomerUpdate.TelephoneNumber
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID
		
		
		
		-- MobileNumbers
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_TelephoneNumbers
		(
			AuditItemID,
			ContactMechanismID,
			ContactNumber,
			ContactMechanismTypeID,
			Valid,
			TelephoneType -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
		)
		SELECT 
			AuditItemID,
			ISNULL(MobileNumberContactMechanismID, 0) AS ContactMechanismID,
			MobileNumber, 
			CAST((SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)') AS INT),
			1 AS Valid,
			NULL AS TelephoneType
		FROM CustomerUpdate.TelephoneNumber
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID

		-- get the ContactMechanismIDs generated
		UPDATE CUTN
		SET CUTN.MobileNumberContactMechanismID = ATN.ContactMechanismID
		FROM CustomerUpdate.TelephoneNumber CUTN
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE ATN.ContactNumber = CUTN.MobileNumber


		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
			AuditItemID,
			MobileNumberContactMechanismID,
			PartyID,
			GETDATE(),
			CAST((SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private mobile number') AS INT)
		FROM CustomerUpdate.TelephoneNumber
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID
		
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

