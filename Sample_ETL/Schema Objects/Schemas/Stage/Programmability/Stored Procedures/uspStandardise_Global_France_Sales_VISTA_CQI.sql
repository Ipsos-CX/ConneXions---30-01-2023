CREATE PROCEDURE [Stage].[uspStandardise_Global_France_Sales_VISTA_CQI]


/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				05/05/2021		Ben King		    BUG 18201

*/

		@SampleFileName  NVARCHAR(100)

AS

DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)


BEGIN TRY

	SET LANGUAGE british;
	SET DATEFORMAT ymd;


	-- Convert RegistrationDate in DateTime data type format
	UPDATE	Stage.Global_France_Sales_VISTA_CQI
	SET		ConvertedRegistrationDate = CONVERT( DATETIME, [Registration Date], 120)		
	WHERE	ISDATE ( [Registration Date] ) = 1
	AND		LEN([Registration Date]) = 10


	-- Convert HandoverDate  in DateTime data type format
	UPDATE	Stage.Global_France_Sales_VISTA_CQI
	SET		ConvertedHandoverDate = CONVERT( DATETIME, [Handover Date], 120)
	WHERE	ISDATE ( [Handover Date] ) = 1
	AND		LEN([Handover Date]) = 10



	UPDATE	Stage.Global_France_Sales_VISTA_CQI
	SET		ConvertedDateOfBirth = CONVERT( DATETIME, [Date of Birth], 120) 
	WHERE	ISDATE ([Date of Birth]) = 1
	AND		LEN([Date of Birth]) = 10



	UPDATE Stage.Global_France_Sales_VISTA_CQI
	SET Manufacturer = 'Jaguar',
		EventType = 'CQI'
    WHERE @SampleFileName LIKE '%Jaguar%CQI%'


	UPDATE Stage.Global_France_Sales_VISTA_CQI
	SET Manufacturer = 'Land Rover',
		EventType = 'CQI'
	WHERE @SampleFileName LIKE '%Landrover%CQI%'


	UPDATE S
	SET S.LanguageID = L.LanguageID
	FROM Stage.Global_France_Sales_VISTA_CQI S
	INNER JOIN [$(SampleDB)].dbo.Languages L ON S.Country = L.ISOAlpha3
	


	INSERT INTO [dbo].[Removed_Records_Prevent_PartialLoad] (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, CountryCode, RemovalReason)
	SELECT 
		S.[AuditID], 
		F.[FileName], 
		F.[ActionDate],
		S.[PhysicalRowID],
		S.[VIN], 
		S.[Country], 
		'Invalid Country Code'
	FROM Stage.Global_France_Sales_VISTA_CQI S
	INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
	WHERE S.Country NOT IN ('FRA')
	OR LEN(ISNULL(S.Country,'')) = 0

	
	DELETE S
	FROM Stage.Global_France_Sales_VISTA_CQI S
	WHERE S.Country NOT IN ('FRA')
	OR LEN(ISNULL(S.Country,'')) = 0


	----------------------------------------------------------------------------------------------------
	-- Set the BMQ specific load variables 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate (ID, Manufacturer, CountryCode, EventType, Country, CountryID) AS
	(
		--Add In CountryID
		SELECT GC.ID, 
			GC.Manufacturer, 
			GC.Country, 
			GC.EventType, 
			C.Country, 
			C.CountryID
		FROM Stage.Global_France_Sales_VISTA_CQI GC
		INNER JOIN [$(AuditDB)].dbo.Files F ON GC.AuditID = F.AuditID		
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON GC.Country = (CASE	WHEN LEN(GC.Country) = 2 THEN C.ISOAlpha2
																						ELSE C.ISOAlpha3 END)	
		WHERE F.FileName = @SampleFileName								
	)
	--Retrieve Metadata values for each event in the table
	SELECT DISTINCT 
		RU.*, 
		MD.ManufacturerPartyID, 
		MD.EventTypeID, 
		MD.LanguageID, 
		MD.SetNameCapitalisation,
		MD.DealerCodeOriginatorPartyID, 
		MD.CreateSelection, 
		MD.SampleTriggeredSelection,
		MD.QuestionnaireRequirementID, 
		MD.SampleFileID
	INTO #Completed							
	FROM RecordsToUpdate RU 
		INNER JOIN (	SELECT DISTINCT M.ManufacturerPartyID, 
							M.CountryID, ET.EventTypeID,  
							C.DefaultLanguageID AS LanguageID, 
							M.SetNameCapitalisation, 
							M.DealerCodeOriginatorPartyID,
							M.Brand, 
							M.Questionnaire, 
							M.SampleLoadActive, 
							M.SampleFileNamePrefix,
							M.CreateSelection, 
							M.SampleTriggeredSelection, 
							M.QuestionnaireRequirementID,
							M.SampleFileID					
						FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
							INNER JOIN [$(SampleDB)].[Event].EventTypes ET ON ET.EventType = M.Questionnaire
							INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON C.CountryID = M.CountryID
						WHERE M.SampleLoadActive = 1 
							AND @SampleFileName LIKE SampleFileNamePrefix + '%') MD ON RU.Manufacturer = MD.Brand 
																						AND	RU.CountryID = MD.CountryID
							
							
	--Populate the meta data fields for each record
	UPDATE GC
	SET ManufacturerPartyID	= C.ManufacturerPartyID,	 
		SampleSupplierPartyID = C.ManufacturerPartyID,
		CountryID = C.CountryID,
		EventTypeID	= C.EventTypeID,
		DealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
		SetNameCapitalisation = C.SetNameCapitalisation,
		SampleTriggeredSelectionReqID = (CASE	WHEN C.CreateSelection = 1 AND C.SampleTriggeredSelection = 1 THEN 0	
										 		ELSE 0 
												END
										 )

	FROM Stage.Global_France_Sales_VISTA_CQI GC
		INNER JOIN #Completed C ON GC.ID = C.ID	

	
	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].Global_France_Sales_VISTA_CQI 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						SetNameCapitalisation  IS NULL) 
			)			 
			
			RAISERROR(	N'Data in Stage.Global_France_Sales_VISTA_CQI has missing Meta-Data.', 
						16,
						1
					 )
	
	
END TRY
BEGIN CATCH

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
		
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.Global_France_Sales_VISTA_CQI_' + @TimestampString + '
		FROM Stage.Global_France_Sales_VISTA_CQI
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH
