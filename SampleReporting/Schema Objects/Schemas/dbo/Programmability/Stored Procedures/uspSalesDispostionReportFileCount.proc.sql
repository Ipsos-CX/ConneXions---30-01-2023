
CREATE PROCEDURE [dbo].[uspSalesDispotionReportFileCount]
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
	Purpose:	Produce row counts for sample files loaded
		
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
	
	TRUNCATE TABLE SalesDispositionReportFileCount
	--
	-- Build the report counts
	--
	INSERT INTO [dbo].SalesDispositionReportFileCount
	(
		FileName,
		FileCount
	)
	select 
			f.FileName AS FileName, 
			f.FileRowCount AS LoadedCount
	from [$(AuditDB)].dbo.Files f
	inner join [$(AuditDB)].dbo.IncomingFiles (nolock) i on i.AuditID = f.AuditID and i.LoadSuccess = 1 and i.FileLoadFailureID is null
	left join [$(AuditDB)].dbo.AuditItems (nolock) ai
	inner join [$(AuditDB)].Audit.Events (nolock) ae on ae.AuditItemID = ai.AuditItemID
	inner join [$(SampleDB)].Event.Events (nolock) e on e.EventID = ae.EventID
	left join [$(SampleDB)].Vehicle.VehiclePartyRoleEvents (nolock) vpre
		inner join [$(SampleDB)].Vehicle.Vehicles (nolock) v on v.VehicleID = vpre.VehicleID and isnull(v.VIN, '') = ''
	on vpre.EventID = e.EventID
	left join [$(SampleDB)].Event.AutomotiveEventBasedInterviews (nolock) aebi on aebi.EventID = e.EventID
	on ai.AuditID = f.AuditID
	join [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq on 
		sq.AuditID = f.AuditID and sq.AuditItemID = ai.AuditItemID and sq.Questionnaire = @Questionnaire and sq.Brand = @Brand
	where f.ActionDate >= @StartDate and f.ActionDate <= @EndDate
	and f.FileTypeID = 1 and sq.CountryID = @CountryID and sq.Market = @Market
	and f.FileName NOT IN ( @FileName )
	group by f.FileName, F.FileRowCount

	IF ( @IncludeWarranty = 'No' )
	BEGIN
		DELETE [dbo].SalesDispositionReportFileCount
		WHERE FileName LIKE 'Combined_DDW_%'
	END 
	
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
END