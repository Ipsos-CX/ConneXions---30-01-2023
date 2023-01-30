CREATE PROCEDURE [InternalUpdate].[uspDirectSalesDealerUpdate_Insert]
AS

/*
	Purpose:	Insert DirectSalesDealerUpdate
	
	Version			Date			Developer			Comment
	1.1				10-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases												
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	DECLARE @DT_update DATETIME

	--GET THE EVENTS THAT WE NEED TO CREATE DEALER EVENTS. 
	SELECT		DU.*
	INTO		#DealerEvents
	FROM		[InternalUpdate].[DirectSalesDealerUpdate]		DU 
	LEFT JOIN	[$(SampleDB)].[Event].[EventPartyRoles]	EPR  ON	DU.[SalesDealerID]		=	EPR.[PartyID] AND
																DU.[MatchedODSEventID]	=	EPR.[EventID] AND 
																							EPR.[RoleTypeID] = (SELECT RoleTypeID FROM [$(SampleDB)].[dbo].[vwSalesDealerRoleTypes])													
	WHERE	ISNULL(DU.[SalesDealerID],0) > 0 AND 
			ISNULL(DU.[MatchedODSEventID],0) > 0 AND 
			EPR.EventID	IS NULL	AND
			DU.AuditItemID = DU.ParentAuditItemID	

	INSERT INTO [$(SampleDB)].Event.vwDA_EventPartyRoles
	(
		AuditItemID, 
		PartyID, 
		RoleTypeID, 
		EventID,
		DealerCode,
		DealerCodeOriginatorPartyID
	)
	SELECT
			AuditItemID, 
			[SalesDealerID]	, 
			(SELECT RoleTypeID FROM [$(SampleDB)].[dbo].[vwSalesDealerRoleTypes]) AS RoleTypeID, 
			[MatchedODSEventID],
			[FINAL DESTINATION CODE],
			[ManufacturerPartyID]
	FROM	#DealerEvents
	
	
	--SET THE PROCESSED DATE
	SET @DT_update = GETDATE()
	UPDATE		DU
	SET			ProcessedDate = @DT_update,
				Processed = 1 
	FROM		[InternalUpdate].[DirectSalesDealerUpdate] DU
	INNER JOIN	#DealerEvents t on DU.AuditItemID = t.AuditItemID

	--UPDATE THE DUPLICATE'S TOO!
	UPDATE		DU
	SET			ProcessedDate = @DT_update,
				Processed = 1 
	FROM		[InternalUpdate].[DirectSalesDealerUpdate] DU
	INNER JOIN	#DealerEvents t on DU.ParentAuditItemID = t.AuditItemID


	--UPDATE SAMPLE LOGGING
	UPDATE		SL
	SET			[SalesDealerCode]	= DE.[FINAL DESTINATION CODE],
				[SalesDealerID]		= DE.[SalesDealerID],
				[UncodedDealer]		= 0,
				[SampleRowProcessed]= 1,
				[SampleRowProcessedDate] = @DT_update
	FROM		[$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] SL
	INNER JOIN	#DealerEvents DE ON SL.[MatchedODSEventID] = DE.[MatchedODSEventID]


	--AUDIT THE FILE DESTINATION FILE 
	INSERT INTO [$(AuditDB)].[Audit].[InternalUpdate_DirectSalesDealerUpdate]
			(	
				[AuditID],
				[AuditItemID],
				[ParentAuditItemID],
				[CountryID],
				[ManufacturerPartyID],
				[MatchedODSEventID],
				[SalesDealerID],
				[MatchedODSVehicleID],
				[ConvertedHandoverDate],
				[ORDER NO],
				[ORDER CREATED DATE],
				[COMMON TYPE OF SALE],
				[BRAND ORDER TYPE],
				[PARTNER UNIQUE ID],
				[VIN],
				[SHORT VIN],
				[BUILD PERIOD REFERENCE],
				[ACCEPTED BUILD DATE],
				[CURRENT PLANNED BUILD DATE],
				[REQUESTED DELIVERY DATE],
				[ACCEPTED DELIVERY DATE],
				[CURRENT PLANNED DELIVERY DATE],
				[FINAL DESTINATION CODE],
				[FACTORY COMPLETE DATE],
				[CUSTOMER HANDOVER DATE],
				[CONTRACT DATE],
				[CONTRACT NUMBER],
				[CUSTOMER ID],
				[SALESMAN],
				[SALES TYPE CODE],
				[SELLING PARTNER UNIQUE ID],
				[REGISTRATION DATE],
				[REGISTRATION NUMBER],
				[INVOICE NUMBER],
				[DEALER INVOICE TIMESTAMP],
				[REFERENCE DATE],
				[BRAND],
				[MODEL DESCRIPTION],
				[MODEL YEAR CODE],
				[MODEL YEAR DESCRIPTION],
				[DERIVATIVE CODE],
				[DERIVATIVE DESCRIPTION],
				[TRIM CODE],
				[TRIM DESCRIPTION],
				[COLOUR CODE],
				[COLOUR DESCRIPTION],
				[Processed],
				[ProcessedDate]
			)

	SELECT 
			[AuditID],
			[AuditItemID],
			[ParentAuditItemID],
			[CountryID],
			[ManufacturerPartyID],
			[MatchedODSEventID],
			[SalesDealerID],
			[MatchedODSVehicleID],
			[ConvertedHandoverDate],
			[ORDER NO],
			[ORDER CREATED DATE],
			[COMMON TYPE OF SALE],
			[BRAND ORDER TYPE],
			[PARTNER UNIQUE ID],
			[VIN],
			[SHORT VIN],
			[BUILD PERIOD REFERENCE],
			[ACCEPTED BUILD DATE],
			[CURRENT PLANNED BUILD DATE],
			[REQUESTED DELIVERY DATE],
			[ACCEPTED DELIVERY DATE],
			[CURRENT PLANNED DELIVERY DATE],
			[FINAL DESTINATION CODE],
			[FACTORY COMPLETE DATE],
			[CUSTOMER HANDOVER DATE],
			[CONTRACT DATE],
			[CONTRACT NUMBER],
			[CUSTOMER ID],
			[SALESMAN],
			[SALES TYPE CODE],
			[SELLING PARTNER UNIQUE ID],
			[REGISTRATION DATE],
			[REGISTRATION NUMBER],
			[INVOICE NUMBER],
			[DEALER INVOICE TIMESTAMP],
			[REFERENCE DATE],
			[BRAND],
			[MODEL DESCRIPTION],
			[MODEL YEAR CODE],
			[MODEL YEAR DESCRIPTION],
			[DERIVATIVE CODE],
			[DERIVATIVE DESCRIPTION],
			[TRIM CODE],
			[TRIM DESCRIPTION],
			[COLOUR CODE],
			[COLOUR DESCRIPTION],
			[Processed],
			[ProcessedDate]
	FROM [InternalUpdate].[DirectSalesDealerUpdate]
	ORDER BY [AuditItemID]

	

	----CREATE SELECTIONS FOR THE DEALER EVENTS THAT WE CODED
	--DECLARE @DateStamp VARCHAR(8)
	--DECLARE @Today DATETIME2
	--DECLARE @CreateSelections BIT = 0

	--SELECT @Today = GETDATE()

	--SELECT @DateStamp = CAST(YEAR(@Today) AS CHAR(4))

	--SELECT @DateStamp = @DateStamp + CASE WHEN LEN(CAST(MONTH(@Today) AS VARCHAR(2))) = 1 THEN '0' + CAST(MONTH(@Today) AS CHAR(1)) ELSE CAST(MONTH(@Today) AS CHAR(2)) END

	--SELECT @DateStamp = @DateStamp + CASE WHEN LEN(CAST(DAY(@Today) AS VARCHAR(2))) = 1 THEN '0' + CAST(DAY(@Today) AS CHAR(1)) ELSE CAST(DAY(@Today) AS CHAR(2)) END

	---- CREATE A TABLE TO HOLD ALL THE SELECTIONS WE NEED TO GENERATE
	--CREATE TABLE #Selections
	--(
		--ID INT IDENTITY(1,1) NOT NULL,
		--ManufacturerPartyID INT,
		--QuestionnaireRequirementID INT,
		--SelectionName VARCHAR(255)
	--)

	---- GET THE SELECTIONS WE NEED TO GENERATE; USE THE MATCHED EVENTS TO FIND THE ORIGINAL SAMPLE FILE
	--INSERT INTO #Selections (ManufacturerPartyID, QuestionnaireRequirementID, SelectionName)

	--SELECT DISTINCT DE.ManufacturerPartyID, QuestionnaireRequirementID, SelectionName
	--FROM		#DealerEvents DE
	--INNER JOIN	[$(AuditDB)].Audit.Events	AE ON DE.[MatchedODSEventID] = AE.[EventID]
	--INNER JOIN	[$(AuditDB)].dbo.Audititems AI ON AE.AuditItemID = AI.AuditItemID
	--INNER JOIN	[$(AuditDB)].dbo.Files		FI ON AI.AuditID = FI.AuditID
	--INNER JOIN	[$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] MD ON FI.Filename LIKE MD.SampleFileNamePrefix + '%'   
	--WHERE		CreateSelection = 1

	---- LOOP THROUGH EACH OF THE SELECTIONS AND GENERATE IT
	--DECLARE @ManufacturerPartyID INT
	--DECLARE @QuestionnaireRequirementID INT
	--DECLARE @SelectionName VARCHAR(255)

	--DECLARE @MAXID INT
	--SELECT @MAXID = MAX(ID) FROM #Selections

	--DECLARE @Counter INT
	--SET @Counter = 1

	--WHILE @Counter <= @MAXID
	--BEGIN

		---- GET THE VALUES FROM #Selections
		--SELECT  @ManufacturerPartyID = ManufacturerPartyID,
				--@QuestionnaireRequirementID = QuestionnaireRequirementID,
				--@SelectionName = @DateStamp + '_IU_' + SelectionName
		--FROM	#Selections WHERE ID = @Counter


		--/* V1.2 SET CREATE SELECTION FLAG IF WE HAVE YET TO CREATE SELECTION FOR THIS DATE */
		--SELECT @CreateSelections = 
			--CASE 
				--WHEN COUNT(*) > 0 THEN 0
				--ELSE 1
			--END
		--FROM		[$(SampleDB)].Requirement.QuestionnaireRequirements			QR
		--INNER JOIN	[$(SampleDB)].Requirement.Requirements						Q		ON QR.RequirementID			= Q.RequirementID
		--INNER JOIN	[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	BMQSMD	ON Q.RequirementID			= BMQSMD.QuestionnaireRequirementID
		--INNER JOIN	[$(SampleDB)].Requirement.RequirementRollups					QS		ON Q.RequirementID			= QS.RequirementIDPartOf
		--INNER JOIN	[$(SampleDB)].Requirement.Requirements						S		ON QS.RequirementIDMadeUpOf = S.RequirementID
		--INNER JOIN	[$(SampleDB)].Requirement.SelectionRequirements				SR		ON S.RequirementID			= SR.RequirementID
		--WHERE		QR.RequirementID = @QuestionnaireRequirementID
					--AND SR.SelectionStatusTypeID = 1
					--AND DATEADD(d, DATEDIFF(D, 0, S.RequirementCreationDate), 0) =  @Today
		
			
		--IF @CreateSelections = 1

			--BEGIN
				---- GENERATE THE SELECTION
				--EXEC [$(SampleDB)].Selection.uspCreateSelectionRequirement @ManufacturerPartyID, @QuestionnaireRequirementID, @SelectionName, @DateStamp, 1
			--END

		---- INCREMENT THE COUNTER
		--SET @Counter += 1
	--END




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
