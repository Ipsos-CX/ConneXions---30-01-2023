CREATE PROCEDURE Load.uspAFRLCode_ClassificationUpdates

AS

/*
	Purpose:	Update the Industry Classifications based on the latest AFRL codes.
	
	Version		Date			Developer			Comment
	1.0			21/09/2015		Chris Ross			Created
	
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	----------------------------------------------------------------
	-- Create temp working tables - used for speed of processing 
	----------------------------------------------------------------
	CREATE TABLE #Vehicles
		(
			VehicleID			bigint
		)

	CREATE TABLE #VehicleParties
		(
			VehicleID			bigint,
			PartyID				bigint
		)

	CREATE TABLE #RemoveIndustryClassificationParties
		(
			ID					BIGINT IDENTITY(1,1) NOT NULL,
			PartyID				BIGINT,
			PartyTypeID			INT,
			FromDate			DATETIME2
		)


	----------------------------------------------------------------
	-- Get list of Party/Industry Classifications to remove 
	----------------------------------------------------------------
	INSERT INTO #Vehicles  (VehicleID)
	SELECT v.VehicleID 
	FROM Lookup.AFRLCodes c
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles v ON v.VIN = c.VIN
	WHERE c.DetailedSalesTypeCode IN ('P','B')

	INSERT INTO #VehicleParties (VehicleID, PartyID)
	SELECT DISTINCT v.VehicleID,  vpre.PartyID
	FROM #Vehicles v
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents vpre ON vpre.VehicleID = v.VehicleID
	INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = vpre.EventID 
											AND e.EventTypeID = 1		-- Sales

	INSERT INTO #RemoveIndustryClassificationParties (PartyID, PartyTypeID, FromDate)
	SELECT DISTINCT vp.PartyID, pt.PartyTypeID, pc.FromDate
	FROM #VehicleParties vp 
	INNER JOIN [$(SampleDB)].Party.PartyClassifications pc ON pc.PartyID = vp.PartyID
	INNER JOIN [$(SampleDB)].Party.PartyTypes pt ON pt.PartyTypeID = pc.PartyTypeID
											AND pt.PartyType = 'Vehicle Leasing Company'





BEGIN TRAN 

	----------------------------------------------------------------
	-- Create Audit File and Items prior to removal of records 
	----------------------------------------------------------------
	DECLARE @FileTypeID		INT,
			@UpdateDate		DATETIME2 ,
			@MaxAuditID		BIGINT,
			@MaxAuditItemID	BIGINT, 
			@TotalRows		INT

	SET @UpdateDate = GETDATE()

	SELECT @FileTypeID		= FileTypeID	FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Sample Updates'
	SELECT @MaxAuditID		= MAX(AuditID)	FROM [$(AuditDB)].dbo.Audit
	SELECT @MaxAuditItemID	= MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems
	SELECT @TotalRows		= MAX(ID)		FROM #RemoveIndustryClassificationParties

	-- Create Audit and AuditItems
	INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
	VALUES (@MaxAuditID + 1)

	INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID)
	SELECT  @MaxAuditID + 1 AS AuditID,
		 	@MaxAuditItemID + ID AS AuditItemID
	FROM #RemoveIndustryClassificationParties

	-- Create a dummy file entry for the update
	INSERT INTO [$(AuditDB)].dbo.Files (AuditID, FileTypeID, FileName, FileRowCount, ActionDate)
	SELECT @MaxAuditID + 1, @FileTypeID, 'AFRL Code - Removal of Industry Classifications - System generated dummy file entry', @TotalRows, @UpdateDate

	-- Insert Audit rows for each record we are going to delete
	INSERT INTO [$(AuditDB)].Audit.PartyClassifications (AuditItemID, PartyTypeID, PartyID, FromDate, ThroughDate)
	SELECT  @MaxAuditItemID + ID AS AuditItemID,
			PartyTypeID,
			PartyID,
			FromDate,
			@UpdateDate  AS ThroughDate
	FROM #RemoveIndustryClassificationParties


	----------------------------------------------------------------
	-- Delete Industry and PartyClassificatons Records
	----------------------------------------------------------------

	DELETE ic
	FROM #RemoveIndustryClassificationParties rc
	INNER JOIN [$(SampleDB)].Party.IndustryClassifications ic ON ic.PartyID = rc.PartyID AND ic.PartyTypeID = rc.PartyTypeID

	DELETE pc
	FROM #RemoveIndustryClassificationParties rc
	INNER JOIN [$(SampleDB)].Party.PartyClassifications pc ON pc.PartyID = rc.PartyID AND pc.PartyTypeID = rc.PartyTypeID


COMMIT TRAN 

	 --- Remove the temp tables ---
	 DROP TABLE #Vehicles
	 DROP TABLE #VehicleParties
	 DROP TABLE #RemoveIndustryClassificationParties



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