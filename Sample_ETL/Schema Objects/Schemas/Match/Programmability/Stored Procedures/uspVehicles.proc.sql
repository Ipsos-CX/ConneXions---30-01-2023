CREATE PROCEDURE [Match].[uspVehicles]

AS

/*
		Purpose:	Match Match vehicles and models in the VWT before loading.
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created.
LIVE	1.1			14/03/2013		Chris Ross			BUG 8766 - Ensure Model ID is updated on records not just the parent vehicle record.
																This is to ensure the Audit and Logging tables do not contain blank models where the VIN is valid.
																Also removed matching of vehicles where VIN is blank.
LIVE	1.2			26/07/2013		Martin Riverol		BUG 9254 - Remove explicit model description matching for LR France supplied records.
LIVE	1.3			23/05/2014		Martin Riverol		BUG 10398 - Only allow model matching using a vehicles VIN when the VIN is 17 chars in length.
LIVE	1.4			21/07/2014		Eddie Thomas		BUG 10590 - Removed superflous code that prevented Jaguar Germany 17 digit VIN's from being correctly coded
LIVE	1.5			04/09/2014		Chris Ross			BUG 10398 - Only match vehicles using 17 digit VIN numbers.
																  - Remove matching of vehicle models using model names
LIVE	1.6			06/07/2015		Chris Ledger		BUG 11666 - Match child VehicleID to parent VehicleID.
LIVE	1.7			12/01/2018		Chris Ledger		BUG 14463 - New VehicleID matching ignoring Manufacturer and Using most recent VehicleID (N.B. Duplicate VINs have been removed)
LIVE	1.8			12/12/2018		Chris Ledger		Replace commented out variables to Allow Schema Compare to match
LIVE	1.9			10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
LIVE	1.10		17/03/2022		Chris Ledger		TASK 729 - New vehicle matching
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
	
	-- MATCH VEHICLEID'S BY VIN'S WE'VE ALREADY LOADED -- V1.7
	;WITH CTE_VehicleMatch (VehicleChecksum, ModelID, VehicleID) AS
	(
		SELECT OV.VehicleChecksum, 
			OV.ModelID,
			MAX(OV.VehicleID) AS VehicleID
		FROM [$(SampleDB)].Vehicle.vwVehicles OV
		WHERE ISNULL(OV.VehicleIdentificationNumberUsable,0) = 1							-- V1.10
		GROUP BY OV.VehicleChecksum, 
			OV.ModelID
	), CTE_Vehicles (VehicleChecksum, ModelID, ModelVariantID, ModelYear, VehicleID) AS		-- V1.10
	(
		SELECT V.VehicleChecksum,
			V.ModelID,
			V.ModelVariantID,
			V.ModelYear,
			V.VehicleID
		FROM CTE_VehicleMatch VM
			INNER JOIN [$(SampleDB)].Vehicle.vwVehicles V ON VM.VehicleID = V.VehicleID
	)
	UPDATE VV
	SET VV.MatchedODSVehicleID = V.VehicleID,
		VV.MatchedODSModelID = V.ModelID,
		VV.MatchedModelVariantID = V.ModelVariantID,				-- V1.10
		VV.MatchedModelYear = V.ModelYear							-- V1.10
	FROM dbo.vwVWT_Vehicles VV
		INNER JOIN CTE_Vehicles V ON VV.VehicleChecksum = V.VehicleChecksum
	WHERE VV.Usable = 1
		AND ISNULL(VV.MatchedODSVehicleID, 0) = 0
	

	/*
	-- MATCH VEHICLEID'S BY VIN'S WE'VE ALREADY LOADED -- V1.8 REPLACED
	UPDATE VV
	SET VV.MatchedODSVehicleID = OV.VehicleID,
		VV.MatchedODSModelID = OV.ModelID
	FROM dbo.vwVWT_Vehicles VV
		INNER JOIN [$(SampleDB)].Vehicle.vwVehicles OV ON VV.VehicleChecksum = OV.VehicleChecksum
														AND VV.ManufacturerID = OV.ManufacturerID
	WHERE VV.Usable = 1
		AND ISNULL(VV.MatchedODSVehicleID, 0) = 0
	*/


	-- MATCH VEHICLEID'S OF CHILDREN TO PARENTS V1.6
	UPDATE VV 
	SET VV.MatchedODSVehicleID = VV1.MatchedODSVehicleID
	FROM dbo.vwVWT_Vehicles VV 
		INNER JOIN dbo.vwVWT_Vehicles VV1 ON VV.VehicleParentAuditItemID = VV1.AuditItemID
	WHERE VV.Usable = 1 
		AND ISNULL(VV.MatchedODSVehicleID, 0) = 0


	/*
	-- IF THE VIN IS BLANK SET THE VehicleID    <<<< v1.2 - REMOVED 
	UPDATE VV
	SET VV.MatchedODSVehicleID = V.VehicleID,
		VV.MatchedODSModelID = V.ModelID
	FROM dbo.vwVWT_Vehicles VV
		INNER JOIN (	SELECT VV.VehicleParentAuditItemID, 
							MAX(OV.VehicleID) AS MaxVehicleID
						FROM dbo.vwVWT_Vehicles VV
							INNER JOIN [$(SampleDB)].Vehicle.vwVehicles OV ON VV.VehicleChecksum = OV.VehicleChecksum
																			AND VV.ManufacturerID = OV.ManufacturerID
						WHERE VV.Usable = 0
							AND OV.VIN = ''
							AND ISNULL(VV.MatchedODSVehicleID, 0) = 0
						GROUP BY VV.VehicleParentAuditItemID) M ON M.VehicleParentAuditItemID = VV.AuditItemID
		INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = M.MaxVehicleID
	*/

	
	-- IF UNUSABLE SET THE VehicleID
	UPDATE VV
	SET VV.MatchedODSVehicleID = OV.VehicleID,
		VV.MatchedODSModelID = OV.ModelID,
		VV.MatchedModelVariantID = OV.ModelVariantID,				-- V1.10
		VV.MatchedModelYear = OV.ModelYear							-- V1.10
	FROM dbo.vwVWT_Vehicles VV
		INNER JOIN [$(SampleDB)].Vehicle.vwVehicles OV ON VV.VehicleChecksum = OV.VehicleChecksum
														AND VV.ManufacturerID = OV.ManufacturerID
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = OV.ModelID
	WHERE VV.Usable = 0
		AND VV.VehicleIdentificationNumber  <> ''						-- V1.1  Only match where a VIN has been supplied
		AND LEN(REPLACE(VV.VehicleIdentificationNumber, ' ', '')) = 17  -- V1.5  And VIN is 17 digits long
		AND ISNULL(VV.MatchedODSVehicleID, 0) = 0
		AND M.ModelDescription = 'Unknown Vehicle'
	

	/*
	-- DO LAND ROVER FRANCE MATCHING BASED ON MODEL DESCRIPTION
	-- REMOVED V1.3
	UPDATE V
	SET V.MatchedODSModelID = MM.ModelID
	FROM dbo.VWT V
		INNER JOIN [$(SampleDB)].Vehicle.VehicleMatchingStrings VMS ON V.ModelDescription LIKE VMS.VehicleMatchingString
		INNER JOIN [$(SampleDB)].Vehicle.ModelMatching MM ON MM.VehicleMatchingStringID = VMS.VehicleMatchingStringID
	WHERE V.ManufacturerID = 3 -- LAND ROVER
		AND ISNULL(V.MatchedODSModelID, 0) = 0
		AND VMS.VehicleMatchingStringTypeID = 2 -- MODEL DESCRIPTION MATCHING
		AND V.AuditItemID = V.VehicleParentAuditItemID
		AND V.CountryID = (SELECT CountryID FROM Lookup.vwCountries WHERE Country = 'France')
	*/


	-- MATCH USING THE VIN AGAINST THE GENERIC VIN MATCHING STRINGS.
	UPDATE V
	SET V.MatchedODSModelID = MVM.ModelID,
		V.MatchedModelVariantID = MVM.ModelVariantID			-- V1.10
	FROM dbo.VWT V
		INNER JOIN [$(SampleDB)].Vehicle.VehicleMatchingStrings VMS ON V.VehicleIdentificationNumber LIKE VMS.VehicleMatchingString
		INNER JOIN [$(SampleDB)].Vehicle.ModelVariantMatching MVM ON VMS.VehicleMatchingStringID = MVM.VehicleMatchingStringID			-- V1.10
	WHERE ISNULL(V.MatchedODSModelID, 0) = 0
		AND VMS.VehicleMatchingStringTypeID = 1								-- VIN MATCHING
		AND LEN(REPLACE(V.VehicleIdentificationNumber, ' ', '')) = 17
		AND V.VehicleIdentificationNumberUsable = 1							-- V1.10
		--AND V.AuditItemID = V.VehicleParentAuditItemID					-- V1.1


	/* V1.5 -- Removed model matching using model descriptions <<<<
	-- MATCH USING THE MODEL DESCRIPTION AGAINST THE GENERIC MODEL MATCHING STRINGS.
	UPDATE V
	SET V.MatchedODSModelID = MM.ModelID
	FROM dbo.VWT V
		INNER JOIN [$(SampleDB)].Vehicle.VehicleMatchingStrings VMS ON V.ModelDescription LIKE VMS.VehicleMatchingString
		INNER JOIN [$(SampleDB)].Vehicle.ModelMatching MM ON MM.VehicleMatchingStringID = VMS.VehicleMatchingStringID
	WHERE ISNULL(V.MatchedODSModelID, 0) = 0
		AND VMS.VehicleMatchingStringTypeID = 2				-- MODEL DESCRIPTION MATCHING
		--AND V.AuditItemID = V.VehicleParentAuditItemID	-- V1.1
	*/


	-- WRITE BACK UNMATCHED MODELS TO VWT
	UPDATE V
	SET V.MatchedODSModelID = M.ModelID,
		V.MatchedModelVariantID = MV.VariantID													-- V1.10
	FROM dbo.VWT V
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ManufacturerPartyID = V.ManufacturerID
		INNER JOIN [$(SampleDB)].Vehicle.ModelVariants MV ON M.ModelID = MV.ModelID				-- V1.10
	WHERE ISNULL(V.MatchedODSModelID, 0) = 0
		--AND V.AuditItemID = V.VehicleParentAuditItemID  -- V1.1
		AND M.ModelDescription = 'Unknown Vehicle'

	
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