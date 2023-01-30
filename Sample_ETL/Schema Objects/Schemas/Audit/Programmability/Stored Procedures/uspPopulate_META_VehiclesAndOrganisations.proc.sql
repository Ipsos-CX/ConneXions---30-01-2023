/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This procedure can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated
					
					
CREATE PROCEDURE [Audit].[uspPopulate_META_VehiclesAndOrganisations]

AS
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
	FROM [$(AuditDB)].Audit.VehiclePartyRoles


	-- LOAD Vehicles DATA INTO TEMPORARY TABLE #AuditVehicles
	IF (OBJECT_ID('tempdb..#AuditVehicles') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditVehicles
	END
	
	SELECT DISTINCT 
		VehicleID, 
		VIN
	INTO #AuditVehicles
	FROM [$(AuditDB)].Audit.Vehicles
		

	-- LOAD People DATA INTO TEMPORARY TABLE #AuditPeople
	IF (OBJECT_ID('tempdb..#AuditOrganisations') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditOrganisations
	END

	SELECT DISTINCT 
		PartyID, 
		OrganisationName,
		OrganisationNameChecksum
	INTO #AuditOrganisations
	FROM [$(AuditDB)].Audit.Organisations
	
	-- CREATE CLUSTERED INDEXES TO SPEED UP CREATION OF #VehiclesAndOrganisations TABLE
	CREATE CLUSTERED INDEX tmp_AuditVehicles_ix ON #AuditVehicles (VehicleID)
	CREATE CLUSTERED INDEX tmp_AuditOrganisations_ix ON #AuditOrganisations (PartyID)

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
	FROM #AuditVehiclePartyRoles VPR
	INNER JOIN #AuditVehicles V ON VPR.VehicleID = V.VehicleID
	INNER JOIN #AuditOrganisations O ON VPR.PartyID = O.PartyID;


	
	MERGE Audit.META_VehiclesAndOrganisations AS TARGET
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
	IF (OBJECT_ID('tempdb..#AuditVehiclePartyRoles') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditVehiclePartyRoles
	END
	IF (OBJECT_ID('tempdb..#AuditVehicles') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditVehicles
	END		
	IF (OBJECT_ID('tempdb..#AuditOrganisations') IS NOT NULL)
	BEGIN
		DROP TABLE #AuditOrganisations
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
*/