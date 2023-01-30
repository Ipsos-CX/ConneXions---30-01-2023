CREATE PROCEDURE Load.uspAFRLLookupCodes

AS

/*
	Purpose:	Write/merge the AFRL data into the lookup table
	
	Version		Date			Developer				Comment
	1.0			10/09/2015		Peter Doyle/Chris Ross	Created
	2.0			15/10/2015		Chris Ross				BUG 11933 - Changed to now Audit all changes and update the AFRL code 
																	on the VehicleEventPartyRole table.
	2.1			10/01/2020		Chris Ledger			BUG 15372 - Fix Hard coded references to databases
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

        SET DATEFORMAT YMD;

		------------------------------------------------------------------
		-- Remove the excel footer row from the staging table
		------------------------------------------------------------------
		DELETE FROM Stage.AFRLCodeLookupData WHERE [Vin Chassis Frame Number] IS NULL


		------------------------------------------------------------------
		-- Load/update the AFRL codes in the Lookup table from Staging
		------------------------------------------------------------------
		
		-- Create a temp table     (CGR - mod'd to use this rather than the CTE as MERGE command not working properly with CTE)
		CREATE TABLE #Match 
			(
				[AuditID]	[bigint],
				[RowID]		[bigint],
				[Marque] [nvarchar](500) NULL,
				[Vin Chassis Frame Number] [nvarchar](500) NULL,
				[Registration Date] [nvarchar](500) NULL,
				[Registration Mark] [nvarchar](500) NULL,
				[Detailed Sales Type Code] [nvarchar](500) NULL
			)	

		INSERT INTO #Match ([AuditID],
							[RowID],
							[Marque] ,
							[Vin Chassis Frame Number] ,
							[Registration Date] ,
							[Registration Mark] ,
							[Detailed Sales Type Code])
		SELECT  [AuditID],
				[RowID],
				[Marque] ,
				[Vin Chassis Frame Number] ,
				[Registration Date] ,
				[Registration Mark] ,
				[Detailed Sales Type Code]
		FROM     ( SELECT    ROW_NUMBER() OVER ( PARTITION BY [Vin Chassis Frame Number] ORDER BY CONVERT(DATE, [Registration Date]) DESC ) AS nos ,
							[AuditID],
							[ID] AS RowID,
							[Marque] ,
							[Vin Chassis Frame Number] ,
							CONVERT(DATE, [Registration Date]) AS [Registration Date] ,
							[Registration Mark] ,
							[Detailed Sales Type Code]
					FROM      Stage.AFRLCodeLookupData
					WHERE     ISDATE([Registration Date]) = 1
							AND [Vin Chassis Frame Number] IS NOT NULL
							AND LEN([Vin Chassis Frame Number]) = 17
				) AS X
		WHERE    X.nos = 1
	


		-- Create table to record required updates (so that we can apply them but also use to check for and update associated Vehicle Events)
		CREATE TABLE #Differences 
		(
			[ID] [int] IDENTITY(1,1) NOT NULL,
			[AuditID]	[bigint] NOT NULL,
			[RowID]		[bigint] NOT NULL,
			[Marque] [nvarchar](500) NULL,
			[Vin Chassis Frame Number] [nvarchar](500) NULL,
			[Registration Date] [nvarchar](500) NULL,
			[Registration Mark] [nvarchar](500) NULL,
			[Detailed Sales Type Code] [nvarchar](500) NULL,
			[UpdateType]  VARCHAR(1)		-- Either insert or update
		)	


		-- Record records for UPDATE
		INSERT INTO #Differences ([AuditID], [RowID], [Marque], [Vin Chassis Frame Number], [Registration Date], [Registration Mark], [Detailed Sales Type Code], UpdateType)
		SELECT M.[AuditID],
				M.[RowID],
				M.[Marque] ,
				M.[Vin Chassis Frame Number] ,
				M.[Registration Date] ,
				M.[Registration Mark] ,
				M.[Detailed Sales Type Code], 
				'U' AS UpdateType
		FROM Lookup.AFRLCodes AS C
        INNER JOIN #Match M
        ON C.Vin = M.[Vin Chassis Frame Number]
        AND          (    C.Marque <> M.Marque 
                       OR C.RegistrationDate <> M.[Registration Date] 
                       OR C.RegistrationMark <> M.[Registration Mark] 
					   OR C.DetailedSalesTypeCode <> M.[Detailed Sales Type Code]
					)
		
	
		-- Record new records for INSERT
		INSERT INTO #Differences ([AuditID], [RowID], [Marque], [Vin Chassis Frame Number], [Registration Date], [Registration Mark], [Detailed Sales Type Code], UpdateType)
		SELECT M.[AuditID],
				M.[RowID],
				M.[Marque] ,
				M.[Vin Chassis Frame Number] ,
				M.[Registration Date] ,
				M.[Registration Mark] ,
				M.[Detailed Sales Type Code], 
				'I' AS UpdateType
		FROM #Match M
		WHERE NOT EXISTS (SELECT VIN FROM Lookup.AFRLCodes C WHERE C.VIN = M.[Vin Chassis Frame Number]) 
   


	BEGIN TRAN 

		-- Create AuditItems 
		DECLARE @MaxAuditItemID		BIGINT,
				@CurrentDate		DATETIME2

		SET @CurrentDate = GETDATE()
		
		SELECT @MaxAuditItemID = MAX(AuditItemID) FROM [$(AuditDB)].dbo.Audititems

		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID)
		SELECT	AuditID, ID + @MaxAuditItemID AS AuditItemID FROM #Differences

		-- Create FileRow Entries
		INSERT INTO [$(AuditDB)].dbo.FileRows (AuditItemID, PhysicalRow)
		SELECT	ID + @MaxAuditItemID AS AuditItemID, RowID FROM #Differences

		-- Insert new and changed Rows into Audit tables
		INSERT INTO [$(AuditDB)].Audit.AFRLCodesLookup (AuditItemID, Marque, VIN, RegistrationDate, RegistrationMark, DetailedSalesTypeCode, UpdateDate, UpdateType)
		SELECT	ID + @MaxAuditItemID AS AuditItemID,
				[Marque], 
				[Vin Chassis Frame Number], 
				[Registration Date], 
				[Registration Mark], 
				[Detailed Sales Type Code],
				@CurrentDate AS UpdateDate, 
				UpdateType
		FROM #Differences


		-- Apply updates to AFRL lookup table
		UPDATE C
		SET	C.Marque				= D.Marque,
			C.RegistrationDate		= D.[Registration Date],
			C.RegistrationMark		= D.[Registration Mark],
			C.DetailedSalesTypeCode	= D.[Detailed Sales Type Code]
		FROM #Differences D 
        INNER JOIN Lookup.AFRLCodes AS C ON C.Vin = D.[Vin Chassis Frame Number] 
		WHERE D.UpdateType = 'U'
				

		-- Apply inserts to AFRL lookup table
		INSERT INTO Lookup.AFRLCodes (Marque, VIN, RegistrationDate, RegistrationMark, DetailedSalesTypeCode)
		SELECT	[Marque], 
				[Vin Chassis Frame Number], 
				[Registration Date], 
				[Registration Mark], 
				[Detailed Sales Type Code]
		FROM #Differences D 
        WHERE D.UpdateType = 'I'
		

		-- Find any associated Vehicle Events (UK Sales only) where AFRL code different is different
		-- We will save these changes into the Audit table first and then use this to update main table
		INSERT INTO [$(AuditDB)].Audit.VehiclePartyRoleEventsAFRL (AuditItemID, VehiclePartyRoleEventID, EventID, PartyID, VehicleRoleTypeID, VehicleID, AFRLCode, ThroughDate) 
		SELECT	ID + @MaxAuditItemID AS AFRLAuditItemID,
				vpre.VehiclePartyRoleEventID, 
				vpre.EventID, 
				vpre.PartyID, 
				vpre.VehicleRoleTypeID, 
				vpre.VehicleID, 
				D.[Detailed Sales Type Code] AS AFRLCode,
				NULL AS ThroughDate
		FROM #Differences D
		INNER JOIN [$(SampleDB)].Vehicle.Vehicles v ON v.VIN = D.[Vin Chassis Frame Number]
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents vpre ON vpre.VehicleID = v.VehicleID
		INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = vpre.EventID
												AND e.EventTypeID = (select EventTypeID 
																	from [$(SampleDB)].Event.EventTypes 
																	WHERE EventType = 'Sales')
		WHERE ISNULL(vpre.AFRLCode, '') <> D.[Detailed Sales Type Code]
		
		-- Update the Vehicle PartyRoleEvents table
		UPDATE vpre
		SET vpre.AFRLCode = D.[Detailed Sales Type Code]
		FROM #Differences D
		INNER JOIN [$(AuditDB)].Audit.VehiclePartyRoleEventsAFRL avpre ON avpre.AuditItemID = (D.ID + @MaxAuditItemID) 
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents vpre ON vpre.[EventID]				= avpre.[EventID]				
															 AND vpre.[PartyID]				= avpre.[PartyID]				
															 AND vpre.[VehicleRoleTypeID]	= avpre.[VehicleRoleTypeID]	
															 AND vpre.[VehicleID]			= avpre.[VehicleID]			


	COMMIT

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