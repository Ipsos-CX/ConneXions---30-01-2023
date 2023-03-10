
CREATE procedure [dbo].[uspServiceDispotionReportFileCount]
	@CountryID			INT = 0,
	@Brand				NVARCHAR(100) = N'',
	@Questionnaire		NVARCHAR(100) = N'',
	@StartDate			DATETIME2 = NULL,
	@EndDate			DATETIME2 = NULL,
	@Market				NVARCHAR(100) = N'',
	@FileName			NVARCHAR(2048) = N'ALL',
	@DEBUG				TINYINT = 0 
AS
/*
	Purpose:	Produce file row counts for the sample file loaded
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Pardip Mudhar		Created
	1.1				15/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/
BEGIN
	-- 
	-- Declare All local variables 
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
	-- Check if the market needs to include or exclude warranty records. Although sales files do not need just make sure that they are delete
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
	
	TRUNCATE TABLE ServiceDispositionReportFileCount
	--
	-- Build the report
	--
	INSERT INTO ServiceDispositionReportFileCount
	(
		FileName,
		FileCount
	)
	SELECT 
			F.FileName AS FileName, 
			F.FileRowCount AS LoadedCount
	FROM 
		[$(AuditDB)].dbo.Files F
			INNER JOIN [$(AuditDB)].dbo.IncomingFiles (nolock) i ON i.AuditID = F.AuditID AND i.LoadSuccess = 1 AND i.FileLoadFailureID is null
			LEFT JOIN [$(AuditDB)].dbo.AuditItems (nolock) ai
			INNER JOIN [$(AuditDB)].Audit.Events (nolock) ae ON ae.AuditItemID = ai.AuditItemID
			INNER JOIN [$(SampleDB)].Event.Events (nolock) e ON e.EventID = ae.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents (nolock) vpre
			INNER JOIN [$(SampleDB)].Vehicle.Vehicles (nolock) v ON v.VehicleID = vpre.VehicleID AND isnull(v.VIN, '') = '' ON vpre.EventID = e.EventID
			LEFT JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews (nolock) aebi ON aebi.EventID = e.EventID ON ai.AuditID = F.AuditID
			JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.AuditID = F.AuditID 
				AND sq.AuditItemID = ai.AuditItemID 
				AND sq.Questionnaire = @Questionnaire 
				AND sq.Brand = @Brand
	WHERE	( F.ActionDate >= @StartDate AND F.ActionDate <= @EndDate )
		AND F.FileTypeID = 1 
		AND sq.CountryID = @CountryID 
		AND sq.Market = @Market
		AND F.FileName NOT IN ( @FileName )
	GROUP BY 
		F.FileName, F.FileRowCount

	IF ( @IncludeWarranty = 'No' )
	BEGIN
		DELETE ServiceDispositionReportFileCount
		WHERE FileName LIKE 'Combined_DDW%'
	END 
	
	END TRY
	--
	-- Error 
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
		,@ErrorLocatiON = Error_Procedure()
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