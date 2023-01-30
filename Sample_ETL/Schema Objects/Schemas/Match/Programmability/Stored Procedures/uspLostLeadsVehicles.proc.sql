CREATE PROCEDURE [Match].[uspLostLeadsVehicles]

AS



SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


/*
	 	Purpose:	Match special Lost Lead vehicles based on the model names supplied in the sample.
	
		Version		Date			Developer			Comment
LIVE	1.0			10-08-2016		Chris Ross			Created.
LIVE	1.1			02-10-2019		Chris Ledger		BUG 15490 - Add PreOwned LostLeads
LIVE	1.2			23-08-2021      Ben King			TASK 567 - Setup SV-CRM Lost Leads Loader
LIVE	1.3			16-02-2022		Chris Ledger		TASK 779 - Change matching to check first on '%' + ModelVehicleMatchingString
LIVE	1.4			18-02-2022		Chris Ledger		TASK 779 - Add Manufacturer to matching updates
LIVE	1.5			06-05-2022		Chris Ledger		TASK 729 - Add direct matching check and further matching strings to be excluded from initial matching string checks
*/


	BEGIN TRAN
	
		-- V1.5 First try and match Vehicles (via the LostLeads.ModelVehicleMatchStrings) using the ModelDescription directly on ModelVehicleMatchingString 
		UPDATE V
		SET V.VehicleIdentificationNumber = VH.VIN,
			V.VehicleIdentificationNumberUsable = 0,
			V.MatchedODSVehicleID = VH.VehicleID,
			V.MatchedODSModelID = VH.ModelID
		FROM dbo.VWT V
			INNER JOIN LostLeads.ModelVehicleMatchStrings MVMS ON V.ModelDescription = MVMS.ModelVehicleMatchString							-- V1.5
			INNER JOIN [$(SampleDB)].Vehicle.Vehicles VH ON VH.VehicleID = MVMS.VehicleID
			INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = VH.ModelID 
														  AND M.ManufacturerPartyID = V.ManufacturerID										-- V1.4
		WHERE (V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')
				OR V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'PreOwned LostLeads'))		-- V1.1


		-- V1.3 First try and match Vehicles (via the LostLeads.ModelVehicleMatchStrings) using the ModelDescription on '%' + ModelVehicleMatchingString excluding Range Rover & Discovery
		UPDATE V
		SET V.VehicleIdentificationNumber = VH.VIN,
			V.VehicleIdentificationNumberUsable = 0,
			V.MatchedODSVehicleID = VH.VehicleID,
			V.MatchedODSModelID = VH.ModelID
		FROM dbo.VWT V
			INNER JOIN LostLeads.ModelVehicleMatchStrings MVMS ON V.ModelDescription LIKE '%' + MVMS.ModelVehicleMatchString				-- V1.3
			INNER JOIN [$(SampleDB)].Vehicle.Vehicles VH ON VH.VehicleID = MVMS.VehicleID
			INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = VH.ModelID 
														  AND M.ManufacturerPartyID = V.ManufacturerID										-- V1.4
		WHERE (V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')
				OR V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'PreOwned LostLeads'))		-- V1.1
			AND MVMS.ModelVehicleMatchString NOT IN ('Defender','Discovery','Range Rover','Range Rover Evoque','Range Rover Sport')			-- V1.3, V1.5


		-- V1.3 Then try and match Vehicles (via the LostLeads.ModelVehicleMatchStrings) using the ModelDescription on '%' + ModelVehicleMatchingString + '%' excluding Range Rover & Discovery
		UPDATE V
		SET V.VehicleIdentificationNumber = VH.VIN,
			V.VehicleIdentificationNumberUsable = 0,
			V.MatchedODSVehicleID = VH.VehicleID,
			V.MatchedODSModelID = VH.ModelID
		FROM dbo.VWT V
			INNER JOIN LostLeads.ModelVehicleMatchStrings MVMS ON V.ModelDescription LIKE '%' + MVMS.ModelVehicleMatchString + '%'			-- V1.2
			INNER JOIN [$(SampleDB)].Vehicle.Vehicles VH ON VH.VehicleID = MVMS.VehicleID
			INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = VH.ModelID 
														  AND M.ManufacturerPartyID = V.ManufacturerID										-- V1.4
		WHERE (V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')
				OR V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'PreOwned LostLeads'))		-- V1.1
			AND ISNULL(V.MatchedODSVehicleID, 0) = 0																						-- V1.3
			AND MVMS.ModelVehicleMatchString NOT IN ('Defender','Discovery','Range Rover','Range Rover Evoque','Range Rover Sport')			-- V1.3, V1.5


		-- V1.3 Then try and match Vehicles (via the LostLeads.ModelVehicleMatchStrings) using the ModelDescription on '%' + ModelVehicleMatchingString + '%' for Range Rover & Discovery
		UPDATE V
		SET V.VehicleIdentificationNumber = VH.VIN,
			V.VehicleIdentificationNumberUsable = 0,
			V.MatchedODSVehicleID = VH.VehicleID,
			V.MatchedODSModelID = VH.ModelID
		FROM dbo.VWT V
			INNER JOIN LostLeads.ModelVehicleMatchStrings MVMS ON V.ModelDescription LIKE '%' + MVMS.ModelVehicleMatchString + '%'			-- V1.2
			INNER JOIN [$(SampleDB)].Vehicle.Vehicles VH ON VH.VehicleID = MVMS.VehicleID
			INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = VH.ModelID 
														  AND M.ManufacturerPartyID = V.ManufacturerID										-- V1.4
		WHERE (V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')
				OR V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'PreOwned LostLeads'))		-- V1.1
			AND ISNULL(V.MatchedODSVehicleID, 0) = 0																						-- V1.3
			AND MVMS.ModelVehicleMatchString IN ('Defender','Discovery','Range Rover','Range Rover Evoque','Range Rover Sport')				-- V1.3, V1.5


		-- For any that still haven't matched, assign then "Unknown" Lost Lead vehicle (based on manufacturer)
		UPDATE V
		SET V.VehicleIdentificationNumber = VH.VIN,
			V.VehicleIdentificationNumberUsable = 0,
			V.MatchedODSVehicleID = VH.VehicleID,
			V.MatchedODSModelID = VH.ModelID
		FROM dbo.VWT V
			INNER JOIN LostLeads.ModelVehicleMatchStrings MVMS ON MVMS.ModelVehicleMatchString = 'Unknown Vehicle'
			INNER JOIN [$(SampleDB)].Vehicle.Vehicles VH ON VH.VehicleID = MVMS.VehicleID
			INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = VH.ModelID 
														  AND M.ManufacturerPartyID = V.ManufacturerID
		WHERE ISNULL(V.MatchedODSVehicleID, 0) = 0 
			AND (V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')
				OR V.ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'PreOwned LostLeads'))		-- V1.1
	
	
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