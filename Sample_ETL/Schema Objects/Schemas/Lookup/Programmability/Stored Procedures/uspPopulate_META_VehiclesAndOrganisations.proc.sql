CREATE PROCEDURE [Lookup].[uspPopulate_META_VehiclesAndOrganisations]

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
	Purpose:	Match Match vehicles and models in the VWT before loading.
	
	Version			Date			Developer			Comment
	1.0				14-06-2016		Chris Ross			BUG 11771 - NEW procedure to replace the Audit schema version
	1.1				10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/



	BEGIN TRANSACTION

	-- LOAD VehiclePartyRoles DATA INTO TEMPORARY TABLE #LookupVehiclePartyRoles
	IF (OBJECT_ID('tempdb..#LookupVehiclePartyRoles') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupVehiclePartyRoles
	END
	
	SELECT DISTINCT 
		PartyID, 
		VehicleID
	INTO #LookupVehiclePartyRoles
	FROM [$(SampleDB)].Vehicle.VehiclePartyRoles


	-- LOAD Vehicles DATA INTO TEMPORARY TABLE #LookupVehicles
	IF (OBJECT_ID('tempdb..#LookupVehicles') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupVehicles
	END
	
	SELECT DISTINCT 
		VehicleID, 
		VIN
	INTO #LookupVehicles
	FROM [$(SampleDB)].Vehicle.Vehicles
		

	-- LOAD People DATA INTO TEMPORARY TABLE #LookupPeople
	IF (OBJECT_ID('tempdb..#LookupOrganisations') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupOrganisations
	END

	SELECT DISTINCT 
		PartyID, 
		OrganisationName,
		OrganisationNameChecksum
	INTO #LookupOrganisations
	FROM [$(SampleDB)].Party.Organisations
	
	-- CREATE CLUSTERED INDEXES TO SPEED UP CREATION OF #VehiclesAndOrganisations TABLE
	CREATE CLUSTERED INDEX tmp_LookupVehicles_ix ON #LookupVehicles (VehicleID)
	CREATE CLUSTERED INDEX tmp_LookupOrganisations_ix ON #LookupOrganisations (PartyID)

	-- LOAD VehiclesAndPeople DATA INTO TEMPORARY TABLE #VehiclesAndOrganisations
	IF (OBJECT_ID('tempdb..#VehiclesAndOrganisations') IS NOT NULL)
	BEGIN
		DROP TABLE #VehiclesAndOrganisations
	END

	SELECT 
		V.VehicleID, 
		O.PartyID AS MatchedOrganisationID, 
		O.OrganisationName,
		V.VIN,
		CHECKSUM(V.VIN) AS VehicleChecksum, 
		O.OrganisationNameChecksum
	INTO #VehiclesAndOrganisations
	FROM #LookupVehiclePartyRoles VPR
	INNER JOIN #LookupVehicles V ON VPR.VehicleID = V.VehicleID
	INNER JOIN #LookupOrganisations O ON VPR.PartyID = O.PartyID;


	
	MERGE Lookup.META_VehiclesAndOrganisations AS TARGET
	USING (SELECT VehicleID, MatchedOrganisationID, OrganisationName, VIN, VehicleChecksum, OrganisationNameChecksum
			FROM #VehiclesAndOrganisations
	) AS SOURCE
	ON (
		TARGET.VehicleID = SOURCE.VehicleID
		AND TARGET.MatchedOrganisationID = SOURCE.MatchedOrganisationID
		AND TARGET.OrganisationName = SOURCE.OrganisationName
		AND TARGET.VIN = SOURCE.VIN
		AND TARGET.VehicleChecksum = SOURCE.VehicleChecksum
		AND TARGET.OrganisationNameChecksum = SOURCE.OrganisationNameChecksum
	)
	WHEN NOT MATCHED BY TARGET
		THEN INSERT (VehicleID, MatchedOrganisationID, OrganisationName, VIN, VehicleChecksum, OrganisationNameChecksum)
		VALUES (SOURCE.VehicleID, SOURCE.MatchedOrganisationID, SOURCE.OrganisationName, SOURCE.VIN, SOURCE.VehicleChecksum, SOURCE.OrganisationNameChecksum)
	WHEN NOT MATCHED BY SOURCE
		THEN DELETE;


	-- CLEAR TEMPORARY TABLES
	IF (OBJECT_ID('tempdb..#LookupVehiclePartyRoles') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupVehiclePartyRoles
	END
	IF (OBJECT_ID('tempdb..#LookupVehicles') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupVehicles
	END		
	IF (OBJECT_ID('tempdb..#LookupOrganisations') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupOrganisations
	END
	IF (OBJECT_ID('tempdb..#VehiclesAndOrganisations') IS NOT NULL)
	BEGIN
		DROP TABLE #VehiclesAndOrganisations
	END	

	COMMIT TRANSACTION
	
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