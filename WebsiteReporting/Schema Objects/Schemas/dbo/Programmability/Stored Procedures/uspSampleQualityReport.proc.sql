CREATE PROCEDURE [dbo].[uspSampleQualityReport]
(
	 @DealerMDXSlice NVARCHAR(1000)
	,@SurveyType INT
	,@EventDateFrom SMALLDATETIME
	,@EventDateTo SMALLDATETIME
)
AS

/*
	Purpose:	Get the sample quality data for display on the website.
				Filter by dealer slicer, survey type and an event date range
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created
	1.1				19/04/2012			Attila Kubanda		BUG 6753 - During development we used the Sample.dbo.DW_JLRCSPDealers but in the Production Environment the dealer information will come from another table.Changes made to point to the right table.
	1.2				24/04/2012			AttilaKubanda		BUG 6766 - According to the request the aftersales and sales region was returning incorrectly, the changes fix this issue.
	1.3				08/05/2012			Pardip Mudhar		BUG 6879 - name was supressed when it contain.
	1.4				05/02/2020			Chris Ledger		Fix hard coded database references.
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


/*
DECLARE @DealerMDXSlice NVARCHAR(1000)
DECLARE @SurveyType INT
DECLARE @EventDateFrom SMALLDATETIME
DECLARE @EventDateTo SMALLDATETIME

SET @EventDateFrom = '1 Jan 2011'
SET @EventDateTo = '31 Dec 2012'
SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover]'
--SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[Europe]'
--SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom]'
--SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified]'
--SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified].[UK]'
--SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified].[UK].[Region 8]'
--SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified].[UK].[Region 8].[Westover Land Rover, Dorset (A6443)]'

SET @SurveyType = 0 -- ALL
--SET @SurveyType = 1 -- SALES
--SET @SurveyType = 2 -- SERVICE
*/
	
	DECLARE @HierarchyType TINYINT
	DECLARE @OutletParties TABLE 			
	(
		  TransferPartyID BIGINT PRIMARY KEY
		, ManufacturerPartyID INT
	)
	DECLARE @Pos INT
	DECLARE	@MemberOnRow TABLE
	(
		Row_ID INT IDENTITY (1,1) PRIMARY KEY, 
		Member NVARCHAR(500)
	)

	DECLARE	@SliceOnColumn TABLE	
	(
		Dimsn NVARCHAR(10)
		, Hrchy NVARCHAR(15)
		, Man NVARCHAR(15)
		, Sup NVARCHAR(100)
		, Ter NVARCHAR(100)
		, Mar NVARCHAR(100)
		, Sub NVARCHAR(100)
		, Del NVARCHAR(100)
	)


	SET @HierarchyType = CASE WHEN PATINDEX('%DealerGroups%', @DealerMDXSlice) > 1 THEN 2 ELSE 1 END
		
		
	IF @DealerMDXSlice != ''
	BEGIN
		/********** REPLACE '.' WITH ',  ' SO WE CAN REMOVE PERIODS IN THE DEALER NAME **********/
		SET @DealerMDXSlice = REPLACE(@DealerMDXSlice,'].[','],  [')

		-- PRIME SLICE TABLE
		INSERT INTO @SliceOnColumn VALUES ('', '', '', '', '', '', '', '')

		SELECT @Pos = CHARINDEX(', ', @DealerMDXSlice)

		INSERT INTO @MemberOnRow
		(
			Member
		)
		SELECT	
			REPLACE (REPLACE (SUBSTRING(@DealerMDXSlice, 1, @Pos - 1) ,'[','') ,']','')

		WHILE @Pos > 0
		BEGIN
			SELECT @DealerMDXSlice = SUBSTRING(@DealerMDXSlice, @Pos + 1, LEN(@DealerMDXSlice))
			SELECT @Pos = CHARINDEX(',  ', @DealerMDXSlice)

			IF @Pos > 0
			BEGIN
				INSERT INTO @MemberOnRow
				SELECT
					REPLACE (REPLACE (SUBSTRING(@DealerMDXSlice, 1, @pos - 1) ,'[','')
										,']','')
			END -- if @pos
		END -- while @pos
		
		

		SELECT @Pos = CHARINDEX(']', @DealerMDXSlice)

		INSERT INTO @MemberOnRow
		(
			Member
		)
		SELECT	
			REPLACE (REPLACE (SUBSTRING(@DealerMDXSlice, 1, @Pos) ,'[','') ,']','')
		BEGIN
			UPDATE @SliceOnColumn SET Dimsn = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 1)
			UPDATE @SliceOnColumn SET Hrchy = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 2)
			UPDATE @SliceOnColumn SET Man = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 3)
			UPDATE @SliceOnColumn SET Sup = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 4)
			UPDATE @SliceOnColumn SET Ter = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 5)
			UPDATE @SliceOnColumn SET Mar = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 6)
			UPDATE @SliceOnColumn SET Sub = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 7)
			UPDATE @SliceOnColumn SET Del = (SELECT REPLACE(LTRIM(Member), '.' ,'') FROM @MemberOnRow WHERE Row_ID = 8)

		END
		
		
		-- WORK OUT WHICH LEVEL IN THE HIERARCHY WE ARE RUNNING THE REPORT FOR
		DECLARE @Dealer BIT
		DECLARE @Region BIT
		DECLARE @Market BIT
		DECLARE @Territory BIT
		DECLARE @SuperNationalRegion BIT
		DECLARE @Manufacturer BIT
		
		IF (SELECT Del FROM @SliceOnColumn) IS NOT NULL
		BEGIN
			SET @Dealer = 1
		END
		IF (SELECT Sub FROM @SliceOnColumn) IS NOT NULL
		BEGIN
			SET @Region = 1
		END
		IF (SELECT Mar FROM @SliceOnColumn) IS NOT NULL
		BEGIN
			SET @Market = 1
		END
		IF (SELECT Ter FROM @SliceOnColumn) IS NOT NULL
		BEGIN
			SET @Territory = 1
		END
		IF (SELECT Sup FROM @SliceOnColumn) IS NOT NULL
		BEGIN
			SET @SuperNationalRegion = 1
		END
		IF (SELECT Man FROM @SliceOnColumn) IS NOT NULL
		BEGIN
			SET @Manufacturer = 1
		END
		
			
		/*
		INSERT INTO @OutletParties 
		(
			TransferPartyID, 
			ManufacturerPartyID 
		)
		SELECT DISTINCT
			TransferPartyID,
			CASE Manufacturer
				WHEN 'Jaguar' THEN 2
				WHEN 'Land Rover' THEN 3
			END
		FROM [NUEW-SQUKCXP02].[CNX_JLR_TransactionRepository].dbo.LU_DealerHierarchy D
		INNER JOIN @SliceOnColumn DS ON 
		(	
			CASE
				WHEN NULLIF(DS.Man, '') IS NULL THEN 1
				WHEN (D.Manufacturer = DS.Man) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Sup, '') IS NULL THEN 1
				WHEN (D.SuperNationalRegion = DS.Sup) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Ter, '') IS NULL THEN 1
				WHEN (D.Territory = DS.Ter) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Mar, '') IS NULL THEN 1
				WHEN (D.Market = DS.Mar) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Sub, '') IS NULL THEN 1
				WHEN @HierarchyType = 2 AND (D.SalesDealerGroup = DS.Sub) THEN 1
				WHEN @HierarchyType = 2 AND (D.AftersalesDealerGroup = DS.Sub) THEN 1
				WHEN @HierarchyType = 1 AND (D.SalesSubNationalRegion = DS.Sub) THEN 1
				WHEN @HierarchyType = 1 AND (D.AftersalesSubNationalRegion = DS.Sub) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Del, '') IS NULL THEN 1
				WHEN (D.SalesOutlet + ' (' + d.SalesOutletCode + ')' = DS.Del) THEN 1
				WHEN (D.AftersalesOutlet + ' (' + d.AftersalesOutletCode + ')' = DS.Del) THEN 1
				ELSE 0
				END = 1
		)
		*/
		
		END

		
	-- RETURN THE DATA FOR THE DEALER LEVEL
	IF @Dealer = 1
	BEGIN
		SELECT
			 X.Dealer
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		FROM (
			SELECT
				 D.TransferDealer + ' (' + D.TransferDealerCode + ')' AS Dealer
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.TransferDealer + ' (' + D.TransferDealerCode + ')'
		 ) X
		 ORDER BY X.Dealer
	END
	-- RETURN THE DATA FOR THE REGION LEVEL
	ELSE IF @Region = 1
	BEGIN
		-- GET THE TOTALS AT THE REGION LEVEL
		SELECT
			IDENTITY(INT,1,1) AS ID
			,X.Region AS Dealer
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		INTO #RegionLevelOutput
		FROM (
			SELECT
				 D.SubNationalRegion AS Region
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.SubNationalRegion
		 ) X
		 ORDER BY X.Region
		 
		-- GET THE INDIVIDUAL DEALER LEVEL TOTALS
		INSERT INTO #RegionLevelOutput
		(
			 Dealer
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		)
		SELECT
			 X.Dealer
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		FROM (
			SELECT
				 D.TransferDealer + ' (' + D.TransferDealerCode + ')' AS Dealer
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.TransferDealer + ' (' + D.TransferDealerCode + ')'
		 ) X
		 ORDER BY X.Dealer
		 
		SELECT
			 Dealer
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		FROM #RegionLevelOutput
		ORDER BY ID
		
		DROP TABLE #RegionLevelOutput
	END
	-- RETURN THE DATA FOR THE MARKET LEVEL
	ELSE IF @Market = 1
	BEGIN
		-- GET THE TOTALS AT THE Market LEVEL
		SELECT
			IDENTITY(INT,1,1) AS ID
			,X.Market AS Region
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		INTO #MarketLevelOutput
		FROM (
			SELECT
				 D.Market
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.Market
		 ) X
		 ORDER BY X.Market
		 
		-- GET THE INDIVIDUAL REGION LEVEL TOTALS
		INSERT INTO #MarketLevelOutput
		(
			 Region
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		)
		SELECT
			 X.Region
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		FROM (
			SELECT
				 D.SubNationalRegion AS Region
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.SubNationalRegion
		 ) X
		 ORDER BY X.Region
		 
		SELECT
			 Region
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		FROM #MarketLevelOutput
		ORDER BY ID
		
		DROP TABLE #MarketLevelOutput
	END
	
	-- RETURN THE DATA FOR THE SUPER NATIONAL REGION LEVEL
	ELSE IF @SuperNationalRegion = 1
	BEGIN
		-- GET THE TOTALS AT THE SUPER NATIONAL REGION LEVEL
		SELECT
			IDENTITY(INT,1,1) AS ID
			,X.SuperNationalRegion AS Market
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		INTO #SuperNationalRegionLevelOutput
		FROM (
			SELECT
				 D.SuperNationalRegion
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.SuperNationalRegion
		 ) X
		 ORDER BY X.SuperNationalRegion
		 
		-- GET THE INDIVIDUAL MARKET LEVEL TOTALS
		INSERT INTO #SuperNationalRegionLevelOutput
		(
			 Market
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		)
		SELECT
			 X.Market
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		FROM (
			SELECT
				 D.Market
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.Market
		 ) X
		 ORDER BY X.Market
		 
		SELECT
			 Market
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		FROM #SuperNationalRegionLevelOutput
		ORDER BY ID
		
		DROP TABLE #SuperNationalRegionLevelOutput
	END
	
	-- RETURN THE DATA FOR THE MANUFACTURER LEVEL
	ELSE IF @Manufacturer = 1
	BEGIN
		-- GET THE TOTALS AT THE MANUFACTUER LEVEL
		SELECT
			IDENTITY(INT,1,1) AS ID
			,X.Manufacturer AS SuperNationalRegion
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		INTO #ManufacturerLevelOutput
		FROM (
			SELECT
				 D.Manufacturer
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.Manufacturer
		 ) X
		 ORDER BY X.Manufacturer
		 
		-- GET THE INDIVIDUAL SUPER NATIONAL REGION LEVEL TOTALS
		INSERT INTO #ManufacturerLevelOutput
		(
			 SuperNationalRegion
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		)
		SELECT
			 X.SuperNationalRegion
			,X.TotalReceived
			,X.TotalSelected
			,CAST((CAST(X.TotalSelected AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentSelected
			,CAST((CAST(X.TotalEmail AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentWithEmail
			,CAST((CAST(X.TotalOutOfDate AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentOutOfDate
			,CAST((CAST(X.TotalNonSolicitation AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentNonSolicitation
			,CAST((CAST(X.TotalUncodedDealer AS DECIMAL(9,2)) / CAST(X.TotalReceived AS DECIMAL(9,2))) * 100 AS DECIMAL(11,0)) AS PercentUncodedDealer
		FROM (
			SELECT
				 D.SuperNationalRegion
				,COUNT(L.AuditItemID) AS TotalReceived
				,COUNT(L.CaseID) AS TotalSelected
				,SUM(CAST(ISNULL(L.SuppliedEmail, 0) AS INT)) AS TotalEmail
				,SUM(CAST(ISNULL(L.EventDateOutOfDate, 0) AS INT)) AS TotalOutOfDate
				,SUM(CAST(COALESCE(NULLIF(ISNULL(L.EventNonSolicitation, 0), 0), NULLIF(ISNULL(L.PartyNonSolicitation, 0), 0), 0) AS INT)) AS TotalNonSolicitation
				,SUM(CAST(ISNULL(L.UncodedDealer, 0) AS INT)) AS TotalUncodedDealer
			 FROM dbo.SampleQualityAndSelectionLogging L
			 INNER JOIN @OutletParties OP ON OP.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
										AND OP.ManufacturerPartyID = L.ManufacturerID
			 LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.TransferPartyID = COALESCE(NULLIF(L.SalesDealerID, 0), NULLIF(L.ServiceDealerID, 0))
													AND D.ManufacturerPartyID = L.ManufacturerID
													AND CASE 
															WHEN D.OutletFunction = 'Aftersales' THEN 'Service'
															ELSE D.OutletFunction
													END = L.Questionnaire
			WHERE L.LoadedDate >= @EventDateFrom
			AND L.LoadedDate <= @EventDateTo
			AND CASE
				WHEN @SurveyType = 0 THEN L.Questionnaire
				WHEN @SurveyType = 1 THEN 'Sales'
				WHEN @SurveyType = 2 THEN 'Service'
			END = L.Questionnaire
			GROUP BY D.SuperNationalRegion
		 ) X
		 ORDER BY X.SuperNationalRegion
		 
		SELECT
			 SuperNationalRegion
			,TotalReceived
			,TotalSelected
			,PercentSelected
			,PercentWithEmail
			,PercentOutOfDate
			,PercentNonSolicitation
			,PercentUncodedDealer
		FROM #ManufacturerLevelOutput
		ORDER BY ID
		
		DROP TABLE #ManufacturerLevelOutput
	END

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	--EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 --@ErrorNumber
		--,@ErrorSeverity
		--,@ErrorState
		--,@ErrorLocation
		--,@ErrorLine
		--,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

GO


