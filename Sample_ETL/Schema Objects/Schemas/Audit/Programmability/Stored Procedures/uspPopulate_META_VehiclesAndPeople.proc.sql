/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This procedure can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated

CREATE PROCEDURE [Audit].[uspPopulate_META_VehiclesAndPeople]

AS



	--Purpose:	Match Match vehicles and models in the VWT before loading.
	
	--Version			Date			Developer			Comment
	--1.0				$(ReleaseDate)		?					Created.
	--1.1				03-04-13		Chris Ross			Added in LastName to ensure better/faster matching 





SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRANSACTION

	-- LOAD VehiclePartyRoles DATA INTO TEMPORARY TABLE #AuditVehiclePartyRoles
	IF (OBJECT_ID('tempdb..#AuditVehiclePartyRoles') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditVehiclePartyRoles
	END
	
	SELECT DISTINCT 
		PartyID, 
		VehicleID
	INTO #AuditVehiclePartyRoles
	FROM [$(AuditDB)].[Audit].VehiclePartyRoles


	-- LOAD Vehicles DATA INTO TEMPORARY TABLE #AuditVehicles
	IF (OBJECT_ID('tempdb..#AuditVehicles') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditVehicles
	END
	
	SELECT DISTINCT 
		VehicleID, 
		VIN
	INTO #AuditVehicles
	FROM [$(AuditDB)].[Audit].Vehicles

	-- LOAD People DATA INTO TEMPORARY TABLE #AuditPeople
	IF (OBJECT_ID('tempdb..#AuditPeople') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditPeople
	END
	
	SELECT DISTINCT 
		PartyID, 
		TitleID, 
		FirstName, 
		LastName, 
		SecondLastName,
		NameChecksum		
	INTO #AuditPeople
	FROM [$(AuditDB)].Audit.People

	-- CREATE CLUSTERED INDEXES TO SPEED UP CREATION OF #VehiclesAndPeople TABLE
	CREATE CLUSTERED INDEX tmp_AuditVehicles_ix ON #AuditVehicles (VehicleID)
	CREATE CLUSTERED INDEX tmp_AuditPeople_ix ON #AuditPeople (PartyID)


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
	FROM #AuditVehiclePartyRoles VPR
	INNER JOIN #AuditVehicles V ON VPR.VehicleID = V.VehicleID
	INNER JOIN #AuditPeople P ON VPR.PartyID = P.PartyID;


	-- MERGE DATA INTO Audit.META_VehiclesAndPeople
	MERGE Audit.META_VehiclesAndPeople AS TARGET
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
	IF (OBJECT_ID('tempdb..#AuditVehiclePartyRoles') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditVehiclePartyRoles
	END
	IF (OBJECT_ID('tempdb..#AuditVehicles') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditVehicles
	END		
	IF (OBJECT_ID('tempdb..#AuditPeople') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditPeople
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

*/