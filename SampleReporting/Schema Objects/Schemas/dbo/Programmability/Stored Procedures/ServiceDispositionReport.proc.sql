CREATE PROCEDURE [dbo].[ServiceDispostionReport]
	@CountryID	INT = 0,
	@Brand NVARCHAR(100) = N'',
	@Questionnaire NVARCHAR(100) = N'',
	@StartDate	DATETIME2 = NULL,
	@EndDate	DATETIME2 = NULL,
	@Market		NVARCHAR(100) = N'',
	@FileName	NVARCHAR(2048) = N'ALL',
	@DEBUG		TINYINT = 0 
WITH RECOMPILE
AS

/*
	Purpose:	Produce a disposition report for a country for given date range. The @filename was added to exclude loaded files from the reports.
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Pardip Mudhar		Created
	1.1				11/Sep/2012		Pardip Mudhar		Added DealerName, DealerRegion 
	1.2				23/Oct/2012		Pardip Mudhar		UK Dealer Region Fix
	1.3				07/Dec/2012		Pardip Mudhar		BUG 7635
	1.4				14/03/2013		Chris Ross			BUG 8779 - MissingTelephone field not being set correctly
	1.5				15/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases

*/

BEGIN

SET NOCOUNT ON
	--
	-- Note if you pass in the debug variable as non zero that no tables are cleared down so that you can investigate how the data uis aggregated
	-- 
	-- declare all the variables
	--
	DECLARE @ErrorNumber INT
	DECLARE @ErrorCode INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	DECLARE @DealerMarket NVARCHAR(255)
	DECLARE @StrLine VARCHAR(8000)
	DECLARE @Size BIGINT
	DECLARE @Start BIGINT
	DECLARE @Separator VARCHAR(1)
	DECLARE @TempImport TABLE(Idx BIGINT IDENTITY(1,1), SplitedLine VARCHAR(8000), Size INT)
	DECLARE @IncludeWarranty NVARCHAR(255) 
	
	--
	-- Separate the file names into individual components and insert it into temprary working table
	-- These file name are than used to exclude from the report
	--
		SET @Size = 1
		SET @Start = 1
		SET @Separator = ','

		WHILE (@Start < DATALENGTH(@FileName) + 1) 
		BEGIN
			SET @Size = CHARINDEX(@Separator, SUBSTRING(@FileName, @Start, DATALENGTH(@FileName)), 1)
			IF @Size = 0 SET @Size = DATALENGTH(@FileName) - @Start + 1
			SET @StrLine = SUBSTRING(SUBSTRING(@FileName, @Start, DATALENGTH(@FileName)), 1, @Size)
			SET @StrLine = REPLACE(@StrLine,@Separator,'')
			INSERT INTO @TempImport(SplitedLine, Size) VALUES(@StrLine, LEN(@StrLine))
			SET @Start = @Start + @Size
		END

	IF ( @DEBUG != 0 )
	BEGIN
		PRINT 'Input Variable'
		PRINT @CountryID
		PRINT @Brand
		PRINT @Questionnaire
		PRINT @StartDate
		PRINT @EndDate
		PRINT @Market
		PRINT @FileName
		PRINT @DEBUG
		SELECT 'TempImport', * FROM @TempImport
	END
	--
	-- Set market correctly
	--
	SELECT @DealerMarket = ISNULL( M.DealerTableEquivMarket, @Market) FROM [$(SampleDB)].dbo.Markets M WHERE M.Market = @Market
	
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
	--
	-- remove all data from the reporting previously stored
	--
	TRUNCATE TABLE dbo.ServiceDispositionReport
	--
	-- main report building
	--
	--  drop the temporary tables used to build the report
	--
	BEGIN TRY
	
	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpServiceDispositionReport' ) > 0 )
	BEGIN
		DROP TABLE #tmpServiceDispositionReport
	END

	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpSums' ) > 0 )
	BEGIN
		DROP TABLE #tmpSums
	END

	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpSDRSum' ) > 0 )
	BEGIN
		DROP TABLE #tmpSDRSum
	END
	
	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpAllDealerCount' ) > 0 )
	BEGIN
		DROP TABLE #tmpAllDealerCount
	END
	--
	-- create the reporting table and insert all the data into the reporting table
	-- 
	CREATE TABLE #tmpServiceDispositionReport (
	   AuditItemID					INT NULL
	  ,DealerName					NVARCHAR(255) NULL	
	  ,DealerRegion					NVARCHAR(255) NULL
	  ,LoadedFileName				NVARCHAR(255) NULL	
      ,ServiceDealerCode 			NVARCHAR(255) NULL
      ,ServiceDealerID              INT NULL
      ,Brand 						NVARCHAR(255) NULL
      ,Market 						NVARCHAR(255) NULL
      ,CaseOutputType				NVARCHAR(255) NULL
      ,Questionnaire				NVARCHAR(255) NULL
      ,CaseID						INT NULL
      ,ModelDescription 			NVARCHAR(255) NULL
      ,OwnershipCycle				INT NULL
      ,SuppliedName					INT NULL
      ,SuppliedAddress				INT NULL
      ,SuppliedPhoneNumber			INT NULL
      ,SuppliedEmail				INT NULL
      ,SuppliedVehicle				INT NULL
      ,SuppliedRegistration			INT NULL
      ,EventNonSolicitation			INT NULL
      ,PartyNonSolicitation			INT NULL
      ,UnmatchedModel				INT NULL
      ,UncodedDealer				INT NULL
      ,EventAlreadySelected			INT NULL
      ,NonLatestEvent				INT NULL
      ,InvalidOwnershipCycle		INT NULL
      ,RecontactPeriod				INT NULL
      ,InvalidVehicleRole			INT NULL
      ,CrossBorderAddress			INT NULL
      ,CrossBorderDealer			INT NULL
      ,ExclusionListMatch			INT NULL
      ,InvalidEmailAddress			INT NULL
      ,BarredEmailAddress			INT NULL
      ,BarredDomain					INT NULL
      ,WrongEventType				INT NULL
      ,MissingStreet				INT NULL
      ,MissingPostcode				INT NULL
      ,MissingEmail					INT NULL
      ,MissingStreetAndEmail		INT NULL
      ,MissingTelephone				INT NULL
      ,MissingTelephoneAndEmail		INT NULL
      ,EmailSuppession				INT NULL
      ,PartySuppession				INT NULL
      ,PostalSuppession				INT NULL
      ,InvalidModel					INT NULL
      ,SuppliedEventDate			INT NULL
      ,EventDateOutOfDate			INT NULL
      ,RejectionCount				INT NULL
      ,CaseOutputType_CATI			INT NULL
      ,CaseOutputType_Postal		INT NULL
      ,CaseOutputType_Online		INT NULL
      ,CaseOutputType_NonOutput		INT NULL
      ,MatchedODSEventID			BIGINT NULL
      ,VIN							NVARCHAR(255) NULL
	)
	
	INSERT INTO #tmpServiceDispositionReport (
	   AuditItemID
	  ,LoadedFileName
      ,ServiceDealerCode
      ,ServiceDealerID
      ,Brand
      ,Market
      ,CaseOutputType
      ,Questionnaire
      ,CaseID
      ,ModelDescription 
      ,OwnershipCycle
      ,SuppliedName
      ,SuppliedAddress
      ,SuppliedPhoneNumber
      ,SuppliedEmail
      ,SuppliedVehicle
      ,SuppliedRegistration
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
      ,WrongEventType
      ,MissingStreet
      ,MissingPostcode
      ,MissingEmail
      ,MissingTelephone
      ,MissingStreetAndEmail
      ,MissingTelephone
      ,MissingTelephoneAndEmail
      ,EmailSuppession 
      ,PartySuppession 
      ,PostalSuppession 
      ,InvalidModel
      ,SuppliedEventDate
      ,EventDateOutOfDate
      ,RejectionCount
      ,CaseOutputType_CATI
      ,CaseOutputType_Postal
      ,CaseOutputType_Online
      ,CaseOutputType_NonOutput
      ,MatchedODSEventID
      ,VIN
	)
	SELECT 
	   SQ.AuditItemID
	  ,F.FileName
      ,SQ.[ServiceDealerCode] 
      ,SQ.ServiceDealerID
      ,SQ.[Brand] 
      ,SQ.[Market] 
      ,COT.[CaseOutputType] 
      ,SQ.Questionnaire
      ,SQ.[CaseID] 
      ,( CASE ISNULL( (CONVERT( INT, ISNULL( SQ.InvalidModel, 0)) + CONVERT( INT, ISNULL( SQ.UnmatchedModel, 0))), 0 ) WHEN 0 THEN N'' ELSE ISNULL( CD.ModelDescription, N'') END ) 
      ,( CONVERT( INT, SQ.[OwnershipCycle] )) 
      ,( CONVERT( INT, SQ.[SuppliedName] )) 
      ,( CONVERT( INT, SQ.[SuppliedAddress] )) 
      ,( CONVERT( INT, SQ.[SuppliedPhoneNumber] )) 
      ,( CONVERT( INT, SQ.[SuppliedEmail] )) 
      ,( CONVERT( INT, SQ.[SuppliedVehicle] )) 
      ,( CONVERT( INT, SQ.[SuppliedRegistration] )) 
      ,( CONVERT( INT, SQ.[EventNonSolicitation] )) 
      ,( CONVERT( INT, SQ.[PartyNonSolicitation] )) 
      ,( CONVERT( INT, SQ.[UnmatchedModel] )) 
      ,( CONVERT( INT, SQ.[UncodedDealer] )) 
      ,( CONVERT( INT, SQ.[EventAlreadySelected] )) 
      ,( CONVERT( INT, SQ.[NonLatestEvent] )) 
      ,( CONVERT( INT, SQ.[InvalidOwnershipCycle] )) 
      ,( CONVERT( INT, SQ.[RecontactPeriod] )) 
      ,( CONVERT( INT, SQ.[InvalidVehicleRole] )) 
      ,( CONVERT( INT, SQ.[CrossBorderAddress] )) 
      ,( CONVERT( INT, SQ.[CrossBorderDealer] )) 
      ,( CONVERT( INT, SQ.[ExclusionListMatch] )) 
      ,( CONVERT( INT, SQ.[InvalidEmailAddress] )) 
      ,( CONVERT( INT, SQ.[BarredEmailAddress] )) 
      ,( CONVERT( INT, SQ.[BarredDomain] )) 
      ,( CONVERT( INT, SQ.[WrongEventType] )) 
      ,( CONVERT( INT, SQ.[MissingStreet] )) 
      ,( CONVERT( INT, SQ.[MissingPostcode] )) 
      ,( CONVERT( INT, SQ.MissingEmail ))
      ,( CONVERT( INT, SQ.MissingTelephone ))
      ,( CONVERT( INT, SQ.MissingStreetAndEmail ))
      ,( CONVERT( INT, SQ.MissingTelephone ))
      ,( CONVERT( INT, SQ.MissingTelephoneAndEmail ))
      ,( CONVERT( INT, SQ.[EmailSuppression] )) 
      ,( CONVERT( INT, SQ.[PartySuppression] )) 
      ,( CONVERT( INT, SQ.[PostalSuppression]  )) 
      ,( CONVERT( INT, SQ.[InvalidModel] )) 
      ,( CONVERT( INT, SQ.[SuppliedEventDate] )) 
      ,( CONVERT( INT, SQ.[EventDateOutOfDate] )) 
      ,0 
      ,0 
      ,0 
      ,0 
      ,0 
      ,SQ.MatchedODSEventID
      ,V.VIN
  FROM [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] SQ
  JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = SQ.AuditID JOIN [$(AuditDB)].dbo.IncomingFiles ICF ON ICF.AuditID = F.AuditID AND ICF.LoadSuccess = 1 AND ICF.FileLoadFailureID IS NULL
  LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = SQ.MatchedODSVehicleID
  LEFT JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CaseID = SQ.CaseID AND CD.VehicleID = SQ.MatchedODSVehicleID AND CD.PartyID = SQ.MatchedODSPartyID 
	AND CD.EventID = SQ.MatchedODSEventID AND CD.DealerCode = SQ.ServiceDealerCode
  LEFT JOIN [$(SampleDB)].Event.CaseOutput CO on CO.CaseID = SQ.CaseID
  LEFT JOIN [$(SampleDB)].Event.CaseOutputTypes COT on COT.CaseOutputTypeID = CO.CaseOutputTypeID
  JOIN [$(SampleDB)].Requirement.Requirements R ON R.Requirement = 'JLR 2004'
  JOIN [$(SampleDB)].Requirement.RequirementRollups rr on rr.RequirementIDPartOf = r.RequirementID
  join [$(SampleDB)].Requirement.Requirements Q on Q.RequirementID = rr.RequirementIDMadeUpOf
  WHERE		(SQ.CountryID = @CountryID)
  AND		(SQ.Brand = @Brand)
  AND		(SQ.Questionnaire = @Questionnaire )
  AND		(SQ.Market = @Market)
  AND		(SQ.LoadedDate >= @StartDate and SQ.LoadedDate <= @EndDate)
  AND		DATEDIFF( DAY, F.ActionDate, SQ.LoadedDate ) = 0
  AND		F.FileName NOT IN ( select SplitedLine from @TempImport )
  AND		(SQ.QuestionnaireRequirementID = Q.RequirementID)
  order by 
	 SQ.ServiceDealerCode
  --
  -- for unknown reason some file were still being picked up.
  -- so try deleting them from the report just incase they filter through
  --
  DELETE #tmpServiceDispositionReport
  WHERE LoadedFileName in (@FileName)
  --
  -- If Warranty is not be selected than remove records.
  IF (@IncludeWarranty = 'No')
  BEGIN
		DELETE #tmpServiceDispositionReport
		WHERE LoadedFileName like 'Combined_DDW_Service%'
		
		SET @IncludeWarranty = 'Combined_DDW_Service%'
  END
  --
  -- Get data that will deleted as repeated data set
  --
  IF ( @DEBUG != 0 )
  BEGIN	
	;With CTE_SERVICE_1 AS
	(
		SELECT ROW_NUMBER() 
			OVER(PARTITION BY CaseID, MatchedODSEventID, ServiceDealerCode, VIN
			ORDER BY MatchedODSEventID, CaseID, ServiceDealerCode, VIN) 
				As RowID, CaseID, MatchedODSEventID, ServiceDealerCode, VIN
		FROM #tmpServiceDispositionReport
	)
	Select 'CTE 1', * from CTE_SERVICE_1

	;With CTE_SERVICE_2 AS
	(
		SELECT ROW_NUMBER() 
			OVER(PARTITION BY CaseID, MatchedODSEventID, ServiceDealerCode, VIN
			ORDER BY MatchedODSEventID, CaseID, ServiceDealerCode, VIN) 
		    As RowID, CaseID, MatchedODSEventID, ServiceDealerCode, VIN
		FROM #tmpServiceDispositionReport
	)
	Select 'CTE 2', * from CTE_SERVICE_2 WHERE RowID > 1
	Select 'raw Data', * from #tmpServiceDispositionReport
  END
  --
  -- Delete the repeated for events
  --
  ;With CTE_SERVICE_WORK_TBL AS
  (
	SELECT ROW_NUMBER() 
		OVER(PARTITION BY CaseID, MatchedODSEventID, ServiceDealerCode, VIN
		ORDER BY MatchedODSEventID, CaseID, ServiceDealerCode, VIN)
		As RowID, CaseID, MatchedODSEventID, ServiceDealerCode, VIN
	FROM #tmpServiceDispositionReport
  )
  DELETE FROM CTE_SERVICE_WORK_TBL
  WHERE RowID > 1

  IF ( @DEBUG != 0 )
  BEGIN
	select 'Less repeated  Delete #tmpServiceDispositionReport', * from #tmpServiceDispositionReport
  END
 
   DELETE #tmpServiceDispositionReport 
   WHERE UPPER(RTRIM(LTRIM(LoadedFileName))) in (select UPPER(RTRIM(LTRIM(SplitedLine))) from @TempImport)
  
	--
	-- The all dealer count only counts the files that were process on the same day. This exclude and same file names repeatedly loaded
	-- and not processed on the same day
	--
	CREATE TABLE #tmpAllDealerCount
	(
		ServiceDealerCode NVARCHAR(255) null,
		AllDealerCount INT NULL
	)
	
	INSERT INTO #tmpAllDealerCount
	(
		ServiceDealerCode,
		AllDealerCount
	)
	select 
		sq.ServiceDealerCode, 
		count(sq.ServiceDealerCode) AS AllCount
	from [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQ 
	JOIN [$(AuditDB)].dbo.Files F ON SQ.AuditID = F.AuditID JOIN [$(AuditDB)].dbo.IncomingFiles ICF ON ICF.AuditID = F.AuditID AND ICF.LoadSuccess = 1 AND ICF.FileLoadFailureID IS NULL
		AND F.FileName NOT LIKE ( @IncludeWarranty )
	LEFT JOIN [$(SampleDB)].Event.CaseOutput CO ON CO.CaseID = SQ.CaseID AND CO.AuditID = SQ.AuditID AND SQ.AuditItemID = CO.AuditItemID
	LEFT JOIN [$(SampleDB)].Event.CaseStatusTypes COTS ON COTS.CaseStatusTypeID = CO.CaseOutputTypeID 
	LEFT JOIN [$(AuditDB)].Audit.Vehicles AV ON AV.VehicleID = SQ.MatchedODSVehicleID AND AV.AuditItemID = SQ.AuditItemID
    JOIN [$(SampleDB)].Requirement.Requirements R ON R.Requirement = 'JLR 2004'
    JOIN [$(SampleDB)].Requirement.RequirementRollups RR on rr.RequirementIDPartOf = r.RequirementID
    join [$(SampleDB)].Requirement.Requirements Q on Q.RequirementID = RR.RequirementIDMadeUpOf
	where	(sq.CountryID = @CountryID)
	and     (sq.Market = @Market )
	and		(sq.Brand in (@Brand))
	and		(SQ.Questionnaire = @Questionnaire )
	and		(SQ.LoadedDate >= @StartDate and SQ.LoadedDate <= @EndDate)
	AND		DATEDIFF( DAY, F.ActionDate, SQ.LoadedDate ) = 0
	AND		F.FileName NOT IN ( select SplitedLine from @TempImport ) 
	AND		(SQ.QuestionnaireRequirementID = Q.RequirementID)
	group by sq.ServiceDealerCode
	order by sq.ServiceDealerCode
	--
	-- Update Dealer descriptors
	--
  	UPDATE	T
			SET 
				T.DealerName = J.Outlet,
				T.DealerRegion = J.SubNationalRegion
	FROM	
			#tmpServiceDispositionReport AS T,
			[$(SampleDB)].[dbo].DW_JLRCSPDealers AS J
	WHERE 
			J.OutletPartyID = T.ServiceDealerID
		AND	J.OutletFunction = 'Aftersales'
  --
  -- Now get totals for Service dealer code and model
  -- if the model is uncoded it will have seprate row
  --
  CREATE TABLE #tmpSDRSum
  (
	 ServiceDealerCode NVARCHAR(255) NULL
	,ModelDescription NVARCHAR(255) NULL
	,CaseOutputType_CATI INT NULL
	,CaseOutputType_Postal INT NULL
	,CaseOutputType_Online INT NULL
	,CaseOutputType_NonOutput INT NULL
	,CaseOutputType_NULL INT NULL
	,SampleLoadedFromFile INT NULL
	,ValidSampleFromFile INT NULL
	,ValidSampleThisPeriod INT NULL
  )
  
  INSERT INTO #tmpSDRSum
  (
	 ServiceDealerCode
	,ModelDescription
	,SampleLoadedFromFile
	,ValidSampleFromFile
	,ValidSampleThisPeriod
  )
  SELECT DISTINCT 
		T.ServiceDealerCode, 
		(CASE T.ModelDescription WHEN NULL THEN N'' ELSE T.ModelDescription END), 
		COUNT( T.MatchedODSEventID ),
		SUM( CASE T.CaseID WHEN NULL THEN 0 ELSE 1 END ),
		SUM( CASE (T.BarredDomain+T.BarredEmailAddress+T.EventAlreadySelected+T.EventDateOutOfDate+T.EventNonSolicitation+T.ExclusionListMatch+
			T.InvalidEmailAddress+T.InvalidModel+T.InvalidOwnershipCycle+T.InvalidVehicleRole+
			T.MissingEmail+T.MissingPostcode+T.MissingStreet+T.MissingStreetAndEmail+T.MissingTelephone+T.MissingTelephoneAndEmail+
			T.UncodedDealer+T.UnmatchedModel+T.WrongEventType) WHEN 0 THEN 1 ELSE 0 END )
  FROM #tmpServiceDispositionReport T
  GROUP BY 
	T.ServiceDealerCode, 
	T.ModelDescription
	
  UPDATE #tmpSDRSum
  SET ModelDescription = N''
  WHERE ModelDescription IS NULL

  IF ( @DEBUG != 0 )
  BEGIN
  	select '#tmpSDRSum 1', * from #tmpSDRSum
  END
  --
  -- now insert the sums across the rows
  -- for dealers
  --
  CREATE TABLE #tmpSums
  (
	 ServiceDealerCode NVARCHAR(255) NULL
	,ModelDescription NVARCHAR(255) NULL
	,CaseType NVARCHAR(255) NULL
	,CaseCount INT NULL
  )
  --
  -- Generate the individual case type totals
  -- 
  INSERT INTO #tmpSums
  (
	 ServiceDealerCode
	,CaseType
	,CaseCount
  )
  SELECT 
	ServiceDealerCode, 
	T.CaseOutputType,
	COUNT(T.MatchedODSEventID) as CaseCount
  FROM #tmpServiceDispositionReport T
  WHERE T.CaseOutputType = 'CATI'
--  AND T.CaseID is not NULL
  GROUP BY 
	  T.ServiceDealerCode
	 ,T.CaseOutputType
	ORDER BY ServiceDealerCode

  UPDATE T2
  SET T2.CaseOutputType_CATI = X.CaseCount
  FROM #tmpSDRSum T2, #tmpSums X
  WHERE T2.ServiceDealerCode = X.ServiceDealerCode and X.CaseType = 'CATI'

  IF ( @DEBUG != 0 )
  BEGIN
	select '#tmpSums CATI', * from #tmpSums
	select '#tmpSDRSum CATI', * from #tmpSDRSum
  END

  DELETE #tmpSums
   
  INSERT INTO #tmpSums
  (
	 ServiceDealerCode
	,CaseType
	,CaseCount
  )
  SELECT 
	ServiceDealerCode, 
	T.CaseOutputType,
	COUNT(T.CaseOutputType) as CaseCount
  FROM #tmpServiceDispositionReport T
  WHERE T.CaseOutputType = 'Online'
  AND T.CaseID is not NULL
  GROUP BY 
	  T.ServiceDealerCode
	 ,T.CaseOutputType
	ORDER BY ServiceDealerCode

  UPDATE T2
  SET T2.CaseOutputType_Online = X.CaseCount
  FROM #tmpSDRSum T2, #tmpSums X
  WHERE T2.ServiceDealerCode = X.ServiceDealerCode and X.CaseType = 'Online'

  IF ( @DEBUG != 0 )
  BEGIN
	select '#tmpSums Online', * from #tmpSums
	select '#tmpSDRSum Online', * from #tmpSDRSum
  END

  DELETE #tmpSums

  INSERT INTO #tmpSums
  (
	 ServiceDealerCode
	,CaseType
	,CaseCount
  )
  SELECT 
	ServiceDealerCode, 
	T.CaseOutputType,
	COUNT(T.MatchedODSEventID) as CaseCount
  FROM #tmpServiceDispositionReport T
  WHERE T.CaseOutputType = 'Postal'
  AND T.CaseID is not NULL
  GROUP BY 
	  T.ServiceDealerCode
	 ,T.CaseOutputType
	ORDER BY ServiceDealerCode

  UPDATE T2
  SET T2.CaseOutputType_Postal = X.CaseCount
  FROM #tmpSDRSum T2, #tmpSums X
  WHERE T2.ServiceDealerCode = X.ServiceDealerCode and X.CaseType = 'Postal'

  IF ( @DEBUG != 0 )
  BEGIN
	select '#tmpSums Postal', * from #tmpSums
	select '#tmpSDRSum Postal', * from #tmpSDRSum
  END

  DELETE #tmpSums

  INSERT INTO #tmpSums
  (
	 ServiceDealerCode
	,CaseType
	,CaseCount
  )
  SELECT 
	ServiceDealerCode, 
	T.CaseOutputType,
	COUNT(T.MatchedODSEventID) as CaseCount
  FROM #tmpServiceDispositionReport T
  WHERE T.CaseOutputType = 'Non Output'
  AND T.CaseID is not NULL
  GROUP BY 
	  T.ServiceDealerCode
	 ,T.CaseOutputType
	ORDER BY ServiceDealerCode

  UPDATE T2
  SET T2.CaseOutputType_NonOutput = X.CaseCount
  FROM #tmpSDRSum T2, #tmpSums X
  WHERE T2.ServiceDealerCode = X.ServiceDealerCode and X.CaseType = 'Non Output'

  IF ( @DEBUG != 0 )
  BEGIN
	select '#tmpSums Non Output', * from #tmpSums
	select '#tmpSDRSum Non Output', * from #tmpSDRSum
  END

  DELETE #tmpSums

  INSERT INTO #tmpSums
  (
	 ServiceDealerCode
	,CaseCount
  )
  SELECT 
	ServiceDealerCode, 
	COUNT(T.ServiceDealerCode) as CaseCount
  FROM #tmpServiceDispositionReport T
  WHERE T.CaseOutputType IS NULL
  GROUP BY 
	  T.ServiceDealerCode
	ORDER BY ServiceDealerCode

	IF ( @DEBUG != 0 )
	BEGIN
		select 'Null', * from #tmpSums 
		select 'Null 2', * from #tmpSDRSum
	END

  UPDATE T2
  SET T2.CaseOutputType_NonOutput = T2.CaseOutputType_NonOutput + X.CaseCount
  FROM #tmpSDRSum T2, #tmpSums X
  WHERE T2.ServiceDealerCode = X.ServiceDealerCode and X.CaseType = 'NULL'

	IF ( @DEBUG != 0 )
	BEGIN
		select 'Null 3', * from #tmpSums 
		select 'Null 4', * from #tmpSDRSum
	END
	
  DELETE #tmpSums

  --
  --
  
  -- IF ( @Market != 'United Kingdom' )
  BEGIN
  UPDATE T
  SET T.RejectionCount = 1
  FROM 
	#tmpServiceDispositionReport T WITH (NOLOCK),
	[$(SampleDB)].Vehicle.Vehicles V WITH (NOLOCK),
	[$(SampleDB)].Vehicle.VehiclePartyRoles VPR WITH (NOLOCK),
	[$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging L WITH (NOLOCK)
  WHERE 
		T.VIN = V.VIN
	AND	L.MatchedODSVehicleID = V.VehicleID 
	AND	v.VehicleID = VPR.VehicleID
	AND VPR.VehicleRoleTypeID = 5
	END
	--
	-- Now build the report table to be output
	--
   INSERT INTO [dbo].[ServiceDispositionReport] 
	(	[ServiceDealerCode] ,
		[Brand] ,
		[Market],
		[Questionnaire],
		[SampleLoadedFromFile],
		[ValidSampleFromFile] ,
		[ValidSampleThisPeriod],
		[CaseOutputType_CATI] ,
		[CaseOutputType_Online],
		[CaseOutputType_Postal] ,
		[CaseOutputType_NonOutput] ,
		[SumOFSuppliedName] ,
		[SumOFSuppliedAddress] ,
		[SumOFSuppliedPhoneNumber] ,
		[SumOFSuppliedEmail] ,
		[SumOFSuppliedVehicle] ,
		[SumOFSuppliedRegistration] ,
		[SumSuppliedEventDate] ,
		[SumEventDateOutOfDate] ,
		[SumEventNonSolicitation] ,
		[SumPartyNonSolicitation] ,
		[SumUnmatchedModel] ,
		[SumUncodedDealer] ,
		[SumEventAlreadySelected] ,
		[SumNonLatestEvent] ,
		[SumInvalidOwnershipCycle] ,
		[SumRecontactPeriod] ,
		[SumInvalidVehicleRole] ,
		[SumCrossBorderAddress] ,
		[SumCrossBorderDealer] ,
		[SumExclusionListMatch] ,
		[SumInvalidEmailAddress] ,
		[SumBarredEmailAddress] ,
		[SumBarredDomain] ,
		[SumWrongEventType] ,
		[SumMissingStreet] ,
		[SumMissingPostCode] ,
		[SumEMailSuppression] ,
		[SumPartySuppression] ,
		[SumPostalSuppression] ,
		[SumInvalidModel] ,
		[ModelDescription] ,
		[OtherRejectionsManual] 
	) 
  SELECT DISTINCT
	 T.ServiceDealerCode AS ServiceDealerCode
	,T.Brand AS Brand
	,T.Market AS Market
	,T.Questionnaire AS Questionnaire
	,T2.SampleLoadedFromFile AS SampleLoadedFromFile
	,T2.ValidSampleFromFile AS ValidSampleFromFile
	,T2.ValidSampleThisPeriod AS ValidSampleThisPeriod
	,ISNULL( T2.CaseOutputType_CATI, 0 ) AS CaseOutputType_CATI
 	,ISNULL( T2.CaseOutputType_Online, 0 ) AS CaseOutputType_Online
	,ISNULL( T2.CaseOutputType_Postal, 0 ) AS CaseOutputType_Postal
	,ISNULL( T2.CaseOutputType_NonOutput, 0 ) AS CaseOutputType_NonOutput
	,ISNULL( SUM(T.SuppliedName), 0 ) AS SumOFSuppliedName
	,ISNULL( SUM(T.SuppliedAddress), 0 ) AS SumOFSuppliedAddress
	,ISNULL( SUM(T.SuppliedPhoneNumber), 0 ) AS SumOFSuppliedPhoneNumber
	,ISNULL( SUM(T.SuppliedEmail), 0 ) AS SumOFSuppliedEmail
	,ISNULL( SUM(T.SuppliedVehicle), 0 ) AS SumOFSuppliedVehicle
	,ISNULL( SUM(T.SuppliedRegistration), 0 ) AS SumOFSuppliedRegistration
	,ISNULL( SUM(T.SuppliedEventDate), 0 ) AS SumSuppliedEventDate
	,ISNULL( SUM(T.EventDateOutOfDate), 0 ) AS SumEventDateOutOfDate
	,ISNULL( SUM(T.EventNonSolicitation), 0 ) AS SumEventNonSolicitation
	,ISNULL( SUM(T.PartyNonSolicitation), 0 ) AS SumPartyNonSolicitation
	,ISNULL( SUM(T.UnmatchedModel), 0 ) AS SumUnmatchedModel
	,ISNULL( SUM(T.UncodedDealer), 0 ) AS SumUncodedDealer
	,ISNULL( SUM(T.EventAlreadySelected), 0 ) AS SumEventAlreadySelected
	,ISNULL( SUM(T.NonLatestEvent), 0 ) AS SumNonLatestEvent
	,ISNULL( SUM(T.InvalidOwnershipCycle), 0 ) AS SumInvalidOwnershipCycle
	,ISNULL( SUM(T.RecontactPeriod), 0 ) AS SumRecontactPeriod
	,ISNULL( SUM(T.InvalidVehicleRole), 0 ) AS SumInvalidVehicleRole
	,ISNULL( SUM(T.CrossBorderAddress), 0 ) AS SumCrossBorderAddress
	,ISNULL( SUM(T.CrossBorderDealer), 0 ) AS SumCrossBorderDealer
	,ISNULL( SUM(T.ExclusionListMatch), 0 ) AS SumExclusionListMatch
	,ISNULL( SUM(T.InvalidEmailAddress), 0 ) AS SumInvalidEmailAddress
	,ISNULL( SUM(T.BarredEmailAddress), 0 ) AS SumBarredEmailAddress
	,ISNULL( SUM(T.BarredDomain), 0 ) AS SumBarredDomain
	,ISNULL( SUM(T.WrongEventType), 0 ) AS SumWrongEventType
	,ISNULL( SUM(T.MissingStreet), 0 ) AS SumMissingStreet
	,ISNULL( SUM(T.MissingPostcode), 0 ) AS SumMissingPostCode
	,ISNULL( SUM(T.EmailSuppession ), 0 ) AS SumEMailSuppession
	,ISNULL( SUM(T.PartySuppession ), 0 ) AS SumPartySuppession
	,ISNULL( SUM(T.PostalSuppession ), 0 ) AS SumPostalSuppession
	,ISNULL( SUM(T.InvalidModel), 0 ) AS SumInvalidModel
	, T.ModelDescription
	,ISNULL( SUM( CONVERT( INT, CD.CaseRejection )), 0 ) AS OtherRejectionsManual
  FROM #tmpServiceDispositionReport T  WITH (NOLOCK) 
  LEFT JOIN #tmpSDRSum T2  WITH (NOLOCK) ON T2.ServiceDealerCode = T.ServiceDealerCode AND T2.ModelDescription = T.ModelDescription
  LEFT JOIN [$(SampleDB)].Meta.CaseDetails CD  WITH (NOLOCK) ON CD.CaseID = T.CaseID
  GROUP
	BY   
	 T.ServiceDealerCode
	,T.Brand
	,T.Market
	,T.Questionnaire
	,T.ModelDescription
	,T2.SampleLoadedFromFile 
	,T2.ValidSampleFromFile 
	,T2.ValidSampleThisPeriod 
	,T2.CaseOutputType_CATI
	,T2.CaseOutputType_Online
	,T2.CaseOutputType_Postal
	,T2.CaseOutputType_NonOutput
  ORDER BY
  	 T.ServiceDealerCode
	,T.Brand
	,T.Market
	,T.Questionnaire
	,T.ModelDescription
	--
	--
	UPDATE SDR
	SET 
		SDR.AllDealerCount = T.AllDealerCount
	FROM #tmpAllDealerCount T, [dbo].[ServiceDispositionReport] SDR
	WHERE SDR.ServiceDealerCode = T.ServiceDealerCode
	
	
	UPDATE SDR
	SET
		SDR.DealerName = T.DealerName,
		SDR.DealerRegion = T.DealerRegion
	FROM #tmpServiceDispositionReport T, [dbo].[ServiceDispositionReport] SDR
	WHERE 
			SDR.ServiceDealerCode = T.ServiceDealerCode

	--
	-- This is to update for fleet manager
	-- 
	UPDATE SDR
	SET SDR.OtherRejectionsManual = SDR.OtherRejectionsManual + T.RejectionCount
	FROM [dbo].[ServiceDispositionReport] SDR, #tmpServiceDispositionReport T
	WHERE SDR.ServiceDealerCode = T.ServiceDealerCode
	--
	-- drop all the table
	-- 	
	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpServiceDispositionReport' ) > 0 )
	BEGIN
		IF ( @DEBUG = 0 )
		BEGIN
			DROP TABLE #tmpServiceDispositionReport
		END
	END

	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpSums' ) > 0 )
	BEGIN
		IF ( @DEBUG = 0 )
		BEGIN
			DROP TABLE #tmpSums
		END
	END

	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpSDRSum' ) > 0 )
	BEGIN
		IF ( @DEBUG = 0 )
		BEGIN
			DROP TABLE #tmpSDRSum
		END 
	END

	IF ( (SELECT COUNT(name) FROM sysobjects WHERE name = '#tmpAllDealerCount' ) > 0 )
	BEGIN
		DROP TABLE #tmpAllDealerCount
	END

	END TRY
	BEGIN CATCH

	SET @ErrorCode = @@Error

	IF ( @@TRANCOUNT > 0 )
	BEGIN
		ROLLBACK
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

