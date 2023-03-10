
CREATE PROCEDURE [dbo].[uspServiceDispositionReportFileRowCount]
	@CountryID	INT = 0,
	@Brand NVARCHAR(100) = N'',
	@Questionnaire NVARCHAR(100) = N'',
	@StartDate	DATETIME2 = NULL,
	@EndDate	DATETIME2 = NULL,
	@Market		NVARCHAR(100) = N'',
	@FileName	NVARCHAR(2048) = N'ALL',
	@DEBUG		TINYINT = 0 
AS
/*
	Purpose:	Produce file row counts for the service disposition report 
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Pardip Mudhar		Created
	1.1				07/12/2012		Pardip Mudhar		BUG 7635
	1.2				14/03/2013		Chris Ross			BUG 8766 - Put CaseOutput type into sub query as was returning two records.
	1.3				15/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/
BEGIN
	--
	-- Declare variable
	--
	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	DECLARE @IncludeWarranty NVARCHAR(3) 
	--
	-- Check to see if warranty records needs to be included or excluded.
	--		
	SELECT 
			@IncludeWarranty = CASE CONVERT( INT, VBMQ.SelectWarranty) WHEN 1 THEN 'Yes' ELSE 'No' END 
	FROM 
			[$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VBMQ
	WHERE
			VBMQ.ManufacturerPartyID = (SELECT B.ManufacturerPartyID FROM [$(SampleDB)].[dbo].Brands B WHERE B.Brand = @Brand )
		AND	VBMQ.Brand = @Brand
		AND VBMQ.CountryID = @CountryID
		AND VBMQ.Market = @Market
		AND VBMQ.Questionnaire = @Questionnaire
	
	BEGIN TRY
	
	TRUNCATE TABLE [dbo].ServiceDispositionReportFileRowCount
	--
	-- Build the report
	--
	INSERT INTO [dbo].ServiceDispositionReportFileRowCount
	(
	    FileName		
	   ,FileRowCount	
	   ,ActionDate		
	   ,LoadedDate		
       ,AuditID			
       ,AuditItemID		
       ,PhysicalFileRow				
       ,ManufacturerID				
       ,SampleSupplierPartyID		
       ,OwnershipCycle				
       ,ServiceDateOrig				
       ,ServiceDate					
       ,InvoiceDateOrig				
       ,InvoiceDate					
       ,WarrantyID					
       ,ServiceDealerCode			
       ,ServiceDealerID				
       ,DealerShortName				
       ,VIN							
       ,Brand						
       ,Market						
       ,Questionnaire				
       ,QuestionnaireRequirementID	
       ,StartDays					
       ,EndDays						
       ,SuppliedName				
       ,SuppliedAddress				
       ,SuppliedPhoneNumber			
       ,SuppliedEmail				
       ,SuppliedEventDate			
       ,EventDateOutOfDate			
       ,EventNonSolicitation		
       ,PartyNonSolicitation		
       ,UnmatchedModel				
       ,UncodedDealer				
       ,EventAlreadySelected		
       ,NonLatestEvent				
       ,InvalidOwnershipCycle		
       ,RecontactPeriod				
       ,InvalidVehicleRole			
       ,CrossBorderAddress			
       ,CrossBorderDealer			
       ,ExclusionListMatch			
       ,InvalidEmailAddress			
       ,BarredEmailAddress			
       ,BarredDomain				
       ,CaseID						
       ,SampleRowProcessed			
       ,SampleRowProcessedDate		
       ,MissingStreet				
       ,MissingPostcode	
       ,EMailSuppression
       ,PartySuppression
       ,PostalSuppression
	   ,WrongEventType
       ,InvalidModel				
	   ,OtherRejectionsManual
	   ,CaseOutputType		
	   ,CaseOutputType_CATI
	   ,CaseOutputType_OnLine
	   ,CaseOutputType_Postal
	   ,CaseOutputType_NonOutput
	)
	select 
	   F.FileName AS FileName
	   ,F.FileRowCount AS FileRowCount
	   ,CONVERT( NVARCHAR(24), F.ActionDate, 103) AS ActionDate
	   ,CONVERT( NVARCHAR(24), SQ.[LoadedDate], 103) AS LoadedDate
       ,SQ.[AuditID] AS AuditID
       ,SQ.[AuditItemID] AS AuditItemID
       ,SQ.[PhysicalFileRow] AS PhysicalFileRow
       ,SQ.[ManufacturerID] AS ManufacturerID
       ,SQ.[SampleSupplierPartyID] AS SampleSupplierPartyID
       ,SQ.[OwnershipCycle] AS OwnershipCycle
       ,SQ.[ServiceDateOrig] AS ServiceDateOrig
       ,CONVERT( NVARCHAR(24), SQ.[ServiceDate], 103) AS ServiceDate
       ,SQ.[InvoiceDateOrig] AS InvoiceDateOrig
       ,CONVERT( NVARCHAR(24), SQ.[InvoiceDate], 103) AS InvoiceDate
       ,SQ.[WarrantyID] AS WarrantyID
       ,SQ.[ServiceDealerCode] AS ServiceDealerCode
       ,SQ.[ServiceDealerID] AS ServiceDealerID
       ,DN.Outlet AS DealerShortName
       ,AV.[VIN] AS VIN
       ,SQ.[Brand]  AS Brand
       ,SQ.[Market]  AS Market
       ,SQ.[Questionnaire]  AS Questionnaire
       ,SQ.[QuestionnaireRequirementID] AS QuestionnaireRequirementID
       ,SQ.[StartDays] AS StartDays
       ,SQ.[EndDays] AS EndDays
       ,CONVERT( INT, SQ.[SuppliedName] ) AS SuppliedName
       ,CONVERT( INT, SQ.[SuppliedAddress] ) AS SuppliedAddress
       ,CONVERT( INT, SQ.[SuppliedPhoneNumber] ) AS SuppliedPhoneNumber
       ,CONVERT( INT, SQ.[SuppliedEmail] ) AS SuppliedEmail
       ,CONVERT( INT, SQ.[SuppliedEventDate] ) AS SuppliedEventDate
       ,CONVERT( INT, SQ.[EventDateOutOfDate] ) AS EventDateOutOfDate
       ,CONVERT( INT, SQ.[EventNonSolicitation] ) AS EventNonSolicitation
       ,CONVERT( INT, SQ.[PartyNonSolicitation] ) AS PartyNonSolicitation
       ,CONVERT( INT, SQ.[UnmatchedModel] ) AS UnmatchedModel
       ,CONVERT( INT, SQ.[UncodedDealer] ) AS UncodedDealer
       ,CONVERT( INT, SQ.[EventAlreadySelected] ) AS EventAlreadySelected
       ,CONVERT( INT, SQ.[NonLatestEvent] ) AS NonLatestEvent
       ,CONVERT( INT, SQ.[InvalidOwnershipCycle] ) AS InvalidOwnershipCycle
       ,CONVERT( INT, SQ.[RecontactPeriod] ) AS RecontactPeriod
       ,CONVERT( INT, SQ.[InvalidVehicleRole] ) AS InvalidVehicleRole
       ,CONVERT( INT, SQ.[CrossBorderAddress] ) AS CrossBorderAddress
       ,CONVERT( INT, SQ.[CrossBorderDealer] ) AS CrossBorderDealer
       ,CONVERT( INT, SQ.[ExclusionListMatch] ) AS ExclusionListMatch
       ,CONVERT( INT, SQ.[InvalidEmailAddress] ) AS InvalidEmailAddress
       ,CONVERT( INT, SQ.[BarredEmailAddress] ) AS BarredEmailAddress
       ,CONVERT( INT, SQ.[BarredDomain] ) AS BarredDomain
       ,SQ.[CaseID] AS CaseID
       ,CONVERT( INT, SQ.[SampleRowProcessed] ) AS SampleRowProcessed
       ,CONVERT( NVARCHAR(24), SQ.[SampleRowProcessedDate], 103 ) AS SampleRowProcessedDate
       ,CONVERT( INT, SQ.[MissingStreet] ) AS MissingStreet
       ,CONVERT( INT, SQ.[MissingPostcode] ) AS MissingPostcode
       ,CONVERT( INT, SQ.[EmailSuppression] ) AS MissingEmail
	   ,CONVERT( INT, SQ.[PartySuppression] ) AS MissingStreetAndEmail
	   ,CONVERT( INT, SQ.[PostalSuppression]  ) AS MissingTelephone
	   ,CONVERT( INT, SQ.[WrongEventType] ) AS WrongEventType
       ,CONVERT( INT, SQ.[InvalidModel] ) AS InvalidModel
       ,CONVERT( INT, ISNULL( CD.CaseRejection, 0 ) ) AS OtherRejectionsManual
       ,(SELECT TOP 1 ISNULL(COT.CaseOutputType, '' ) 
		 from [$(SampleDB)].Event.CaseOutput (nolock) CO 
			LEFT JOIN [$(SampleDB)].Event.CaseOutputTypes (nolock) COT 
			ON COT.CaseOutputTypeID = CO.CaseOutputTypeID
			WHERE CO.CaseID = SQ.CaseID
			ORDER BY CO.AuditItemID Desc )	AS CaseOutputType      
--		,ISNULL( COT.CaseOutputType, '' ) AS CaseOutputType
       ,0
       ,0
       ,0
       ,0      
	from [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging (nolock) SQ 
	JOIN [$(AuditDB)].dbo.Files (nolock) F ON SQ.AuditID = F.AuditID 
		AND DATEDIFF( DAY, F.ActionDate, SQ.LoadedDate ) = 0 
		JOIN [$(AuditDB)].dbo.IncomingFiles (nolock) ICF ON ICF.AuditID = F.AuditID AND ICF.LoadSuccess = 1 AND ICF.FileLoadFailureID IS NULL
--	LEFT JOIN [Sample].Event.CaseOutput (nolock) CO ON CO.CaseID = SQ.CaseID 
--	LEFT JOIN [Sample].Event.CaseOutputTypes (nolock) COT ON COT.CaseOutputTypeID = CO.CaseOutputTypeID
	LEFT JOIN [$(AuditDB)].Audit.Vehicles (nolock) AV ON AV.VehicleID = SQ.MatchedODSVehicleID AND AV.AuditItemID = SQ.AuditItemID
	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers (nolock) DN ON DN.OutletPartyID = SQ.ServiceDealerID AND DN.OutletFunction = N'Afterales'
	LEFT JOIN [$(SampleDB)].Meta.CaseDetails (nolock) CD ON CD.CaseID = SQ.CaseID
	where		(SQ.CountryID = @CountryID )
		AND                             (SQ.Market = @Market )
		AND		(SQ.Brand in (@Brand))
		AND		(SQ.Questionnaire = @Questionnaire )
		AND		(F.ActionDate >= @StartDate AND F.ActionDate <= @EndDate)
		AND		(F.FileName NOT IN( @FileName ))
	ORDER BY 
		F.FileName
	--
	-- Remove the warranty f8ile record
	--
	IF ( @IncludeWarranty = 'No' )
	BEGIN
		DELETE [dbo].ServiceDispositionReportFileRowCount
		WHERE FileName like 'Combined_DDW_%'
	END
	--
	-- Update flags for case types
	-- 
	UPDATE	dbo.ServiceDispositionReportFileRowCount
	SET		CaseOutputType_CATI = 1
	WHERE	CaseOutputType = 'CATI'
	
	UPDATE	dbo.ServiceDispositionReportFileRowCount
	SET		CaseOutputType_Postal = 1
	WHERE	CaseOutputType = 'Postal'
	
	UPDATE	dbo.ServiceDispositionReportFileRowCount
	SET		CaseOutputType_OnLine = 1
	WHERE	CaseOutputType = 'Online'
	
	UPDATE	dbo.ServiceDispositionReportFileRowCount
	SET		CaseOutputType_NonOutput = 1
	WHERE	CaseOutputType = 'Non Output'

	END TRY
	--
	-- Write out database errors
	--
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
END

