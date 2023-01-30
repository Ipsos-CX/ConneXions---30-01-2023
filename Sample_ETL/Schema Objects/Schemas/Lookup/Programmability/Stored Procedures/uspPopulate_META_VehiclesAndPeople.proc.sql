CREATE PROCEDURE [Lookup].[uspPopulate_META_VehiclesAndPeople]
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
	FROM [$(SampleDB)].[Vehicle].VehiclePartyRoles


	-- LOAD Vehicles DATA INTO TEMPORARY TABLE #LookupVehicles
	IF (OBJECT_ID('tempdb..#LookupVehicles') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupVehicles
	END
	
	SELECT DISTINCT 
		VehicleID, 
		VIN
	INTO #LookupVehicles
	FROM [$(SampleDB)].[Vehicle].Vehicles

	-- LOAD People DATA INTO TEMPORARY TABLE #LookupPeople
	IF (OBJECT_ID('tempdb..#LookupPeople') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupPeople
	END
	
	SELECT DISTINCT 
		PartyID, 
		TitleID, 
		FirstName, 
		LastName, 
		SecondLastName,
		NameChecksum		
	INTO #LookupPeople
	FROM [$(SampleDB)].Party.People

	-- CREATE CLUSTERED INDEXES TO SPEED UP CREATION OF #VehiclesAndPeople TABLE
	CREATE CLUSTERED INDEX tmp_LookupVehicles_ix ON #LookupVehicles (VehicleID)
	CREATE CLUSTERED INDEX tmp_LookupPeople_ix ON #LookupPeople (PartyID)


	-- LOAD VehiclesAndPeople DATA INTO TEMPORARY TABLE #VehiclesAndPeople
	IF (OBJECT_ID('tempdb..#VehiclesAndPeople') IS NOT NULL)
	BEGIN
		DROP TABLE #VehiclesAndPeople
	END

	SELECT 
		V.VehicleID, 
		P.PartyID AS MatchedPersonID, 
		V.VIN,
		CHECKSUM(V.VIN) AS VehicleChecksum, 
		P.NameChecksum,
		P.LastName
	INTO #VehiclesAndPeople
	FROM #LookupVehiclePartyRoles VPR
	INNER JOIN #LookupVehicles V ON VPR.VehicleID = V.VehicleID
	INNER JOIN #LookupPeople P ON VPR.PartyID = P.PartyID;


	-- MERGE DATA INTO Lookup.META_VehiclesAndPeople
	MERGE Lookup.META_VehiclesAndPeople AS TARGET
	USING (SELECT VehicleID, MatchedPersonID, VIN, VehicleChecksum, NameChecksum, LastName
			FROM #VehiclesAndPeople
	) AS SOURCE
	ON (
		TARGET.VehicleID = SOURCE.VehicleID
		AND TARGET.MatchedPersonID = SOURCE.MatchedPersonID
		AND TARGET.VIN = SOURCE.VIN
		AND TARGET.VehicleChecksum = SOURCE.VehicleChecksum
		AND TARGET.NameChecksum = SOURCE.NameChecksum
		AND TARGET.LastName = SOURCE.LastName					
	)
	WHEN NOT MATCHED BY TARGET
		THEN INSERT (VehicleID, MatchedPersonID, VIN, VehicleChecksum, NameChecksum, LastName)
		VALUES (SOURCE.VehicleID, SOURCE.MatchedPersonID, SOURCE.VIN, SOURCE.VehicleChecksum, SOURCE.NameChecksum, SOURCE.LastName)
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
	IF (OBJECT_ID('tempdb..#LookupPeople') IS NOT NULL)
	BEGIN
		DROP TABLE #LookupPeople
	END
	IF (OBJECT_ID('tempdb..#VehiclesAndPeople') IS NOT NULL)
	BEGIN
		DROP TABLE #VehiclesAndPeople
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