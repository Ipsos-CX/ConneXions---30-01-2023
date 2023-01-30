CREATE PROCEDURE CustomerUpdate.uspLostLeadModelOfInterest_Update

AS

/*
	Purpose:	Update Lost Lead Events with the Lost Lead Vehicle corresponding to the model of interest provided

	
	Version			Date			Developer			Comment
	1.0				17-08-2016		Chris Ross			Created from CustomerUpdate.uspOrganisaton_Update

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
		UPDATE LLM
		SET LLM.CasePartyCombinationValid = 1
		FROM CustomerUpdate.LostLeadModelOfInterest LLM
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = LLM.CaseID
										AND AEBI.PartyID = LLM.PartyID


		-- Populate NewVehicleIDs
		UPDATE MOI
		SET NewVehicleID = MS.VehicleID 
		FROM CustomerUpdate.LostLeadModelOfInterest MOI
		INNER JOIN LostLeads.ModelVehicleMatchStrings MS ON MOI.ModelOfInterest LIKE MS.ModelVehicleMatchString
		WHERE MOI.CasePartyCombinationValid = 1

		-- Create new Vehicle Party Role if it doesn't alreay exist
		INSERT INTO [$(SampleDB)].Vehicle.VehiclePartyRoles  (PartyID, VehicleRoleTypeID, VehicleID, FromDate, ThroughDate)
		SELECT VPRE.PartyID,
				VPRE.VehicleRoleTypeID,
				MOI.NewVehicleID AS VehicleID,
				GETDATE() AS FromDate,
				NULL AS ThroughDate
		FROM CustomerUpdate.LostLeadModelOfInterest MOI
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = MOI.CaseID
										AND AEBI.PartyID = MOI.PartyID
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.EventID = AEBI.EventID
		LEFT JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = VPRE.PartyID
														AND VPR.VehicleID = MOI.NewVehicleID
														AND VPR.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
		WHERE MOI.CasePartyCombinationValid = 1
		AND VPR.PartyID IS NULL  -- Only add if it doesn't already exist
		AND MOI.NewVehicleID IS NOT NULL

		-- Update the Vehicle Event with the new VehicleID
		UPDATE VPRE
		SET VPRE.VehicleID = MOI.NewVehicleID 
		FROM CustomerUpdate.LostLeadModelOfInterest MOI
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = MOI.CaseID
										AND AEBI.PartyID = MOI.PartyID
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.EventID = AEBI.EventID
		WHERE MOI.CasePartyCombinationValid = 1
		AND MOI.NewVehicleID IS NOT NULL
		
		-- Update AutomotiveEventBasedInterviews with the new VehicleID   
		UPDATE AEBI
		SET AEBI.VehicleID = MOI.NewVehicleID 
		FROM CustomerUpdate.LostLeadModelOfInterest MOI
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = MOI.CaseID
										AND AEBI.PartyID = MOI.PartyID
		WHERE MOI.CasePartyCombinationValid = 1
		AND MOI.NewVehicleID IS NOT NULL
		

		-- UPDATE the Sample Logging tables
		UPDATE sq
		SET sq.MatchedODSVehicleID =  MOI.NewVehicleID ,
			sq.MatchedODSModelID = v.ModelID
		FROM CustomerUpdate.LostLeadModelOfInterest MOI
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = MOI.CaseID
										AND AEBI.PartyID = MOI.PartyID
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.MatchedODSEventID = AEBI.EventID
		INNER JOIN [$(SampleDB)].Vehicle.Vehicles v ON v.VehicleID = MOI.NewVehicleID 
		WHERE MOI.CasePartyCombinationValid = 1
		AND MOI.NewVehicleID IS NOT NULL
				

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








