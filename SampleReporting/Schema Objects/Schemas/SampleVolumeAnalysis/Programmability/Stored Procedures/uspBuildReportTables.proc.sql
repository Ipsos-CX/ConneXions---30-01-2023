CREATE PROCEDURE [SampleVolumeAnalysis].[uspBuildReportTables]
	@MarketOrRegionFlag	CHAR(1),
	@MarketRegion	NVARCHAR(255), 
	@Questionnaire  VARCHAR(255)
	
AS

SET NOCOUNT ON;

DECLARE @ErrorNumber INT;
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @ErrorLocation NVARCHAR(500);
DECLARE @ErrorLine INT;
DECLARE @ErrorMessage NVARCHAR(2048);

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRY



/*
	Purpose:	Builds tables for the Sample Receipt Report package to output.
		
	Version		Date				Developer			Comment
	1.0			13/06/2017			Chris Ross			Created
	1.1			06/09/2017			Chris Ross			Fix to ensure that the correct Dealers are selected for Survey.
	1.2			08/09/2017			Eddie Thomas		BUG 14141 - New Bodyshop questionnaire
	1.3			02/01/2018			Ben King			BUG 14386 - Belux Market Equivalent does not match Market
																	in SampleReceipt.ReportOutputs
	1.4			29/10/2019			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
	1.5			15/01/2020			Chris Ledger 		BUG 15372 - Correct incorrect cases
*/




		------------------------------------------------------------------
		-- Set the job variables 
		------------------------------------------------------------------

		DECLARE @ReportDate DATETIME,
				@FromDate	DATETIME,
				@QuarterStart DATETIME

		SET @ReportDate = GETDATE()
		SET @FromDate = DATEADD(yy, DATEDIFF(yy, 0, @ReportDate), 0)
		SET @QuarterStart = DATEADD(q, DATEDIFF(q, 0, @ReportDate), 0) 


		------------------------------------------------------------------
		-- Clear the rteport tables
		------------------------------------------------------------------

		TRUNCATE TABLE SampleReceipt.FileSummary 
		TRUNCATE TABLE SampleReceipt.RetailerSummary


		------------------------------------------------------------------
		-- Populate the file data 
		------------------------------------------------------------------

		INSERT INTO SampleReceipt.FileSummary (
												ReportDate			,
												MarketOrRegionFlag	,
												MarketRegion		,
												Questionnaire		,
												AuditID				,
												Filename			,
												FileLoadDate		,
												FileRowCount		,
												TotalRowsLoaded		,
												RowsLoadedJaguar	,
												RowsLoadedLandRover
												)
		SELECT	@ReportDate AS ReportDate,
				@MarketOrRegionFlag AS MarketOrRegionFlag ,
				@MarketRegion AS MarketRegion,
				sq.Questionnaire,
				f.AuditID,
				f.FileName ,
				CAST(f.ActionDate AS DATE) AS FileLoadDate,
				f.FileRowCount ,
				COUNT(*) AS TotalRowsLoaded,
				SUM(CASE WHEN ISNULL(sq.Brand, '') = 'Jaguar' THEN 1 ELSE 0 END) AS RowsLoadedJaguar,
				SUM(CASE WHEN ISNULL(sq.Brand, '') = 'Land Rover' THEN 1 ELSE 0 END) AS RowsLoadedLandRover
		FROM    [$(AuditDB)].dbo.Files f
				INNER	JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.AuditID = f.AuditID
				INNER	JOIN [$(SampleDB)].[dbo].[Markets] m ON m.Market = sq.Market
				INNER	JOIN [$(SampleDB)].dbo.Regions r ON r.RegionID = m.RegionID
		WHERE  f.ActionDate > @FromDate
		  AND  sq.LoadedDate >  @FromDate
				AND (    (@MarketOrRegionFlag = 'M' --V1.3
						  AND CASE @MarketRegion
						  WHEN 'Belgium' THEN m.Market
						  WHEN 'Luxembourg' THEN m.Market
						  ELSE COALESCE(m.DealerTableEquivMarket, m.Market)
						  END  = @MarketRegion)
					 OR  (@MarketOrRegionFlag = 'R' AND r.Region = @MarketRegion)
					)
				AND sq.Questionnaire = @Questionnaire
		GROUP BY sq.Questionnaire,
				f.AuditID,
				f.FileName , 
				f.ActionDate,
				f.FileRowCount 
		ORDER BY f.ActionDate DESC,
				 f.FileName ASC




		------------------------------------------------------------------
		-- get the dealer report data 
		------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#DealerInfo') IS NOT NULL
			DROP TABLE #DealerInfo

		CREATE TABLE #DealerInfo (
									Region					NVARCHAR(255) NOT NULL,
									Brand					NVARCHAR(510) NULL,
									Market					VARCHAR(200) NOT NULL,
									SubNationalTerritory	NVARCHAR(255) NULL,
									SubNationalRegion		NVARCHAR(255) NULL,
									Questionnaire			VARCHAR(255) NULL,
									OutletCode				NVARCHAR(20) NULL,
									OutletCode_GDD			NVARCHAR(20) NULL,
									Outlet					NVARCHAR(150) NULL,
									AuditID					BIGINT NOT NULL,
									AuditItemID				BIGINT NOT NULL,
									EventID					BIGINT NOT NULL,
									EventDate				DATETIME2 NULL,
									FileLoadDate			DATETIME2 NOT NULL
								) 




		INSERT INTO #DealerInfo (
								Region					,
								Brand					,
								Market					,
								SubNationalTerritory	,
								SubNationalRegion		,
								Questionnaire			,
								OutletCode				,
								OutletCode_GDD			,
								Outlet					,
								AuditItemID				,
								AuditID					,
								EventID					,
								EventDate				,
								FileLoadDate
								)
		SELECT	r.Region,
				sq.Brand,
				COALESCE(m.DealerTableEquivMarket, m.Market) AS Market,
				d.SubNationalTerritory,
				d.SubNationalRegion,
				sq.Questionnaire,
				REPLACE(d.OutletCode, '_BUG', '') AS OutletCode,
				REPLACE(d.OutletCode_GDD, '_BUG', '') AS OutletCode_GDD, 
				d.Outlet,
				SQ.AuditItemID,
				SQ.AuditID,
				e.EventID,
				e.EventDate,
				CAST(f.ActionDate AS DATE)  AS FileLoadDate
		FROM    [$(AuditDB)].dbo.Files f
				INNER	JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.AuditID = f.AuditID
				INNER	JOIN [$(SampleDB)].[dbo].[Markets] m ON m.Market = sq.Market
				INNER	JOIN [$(SampleDB)].dbo.Regions r ON r.RegionID = m.RegionID
				INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = sq.MatchedODSEventID
				LEFT JOIN [$(SampleDB)].Event.EventPartyRoles epr on epr.EventID = sq.MatchedODSEventID
				LEFT JOIN [$(SampleDB)].[dbo].[DW_JLRCSPDealers] d ON d.OutletPartyID = epr.PartyID
															AND d.OutletFunction = CASE WHEN sq.Questionnaire = 'Service' THEN 'Aftersales'			-- v1.1
																						WHEN sq.Questionnaire = 'LostLeads' THEN 'Sales' 
																						WHEN sq.Questionnaire = 'PreOwned LostLeads' THEN 'PreOwned'	-- V1.4 
																						ELSE sq.Questionnaire END
		WHERE  f.ActionDate > @FromDate
		  AND  sq.LoadedDate >  @FromDate
				AND (    (@MarketOrRegionFlag = 'M' --V1.3
						  AND CASE @MarketRegion
						  WHEN 'Belgium' THEN m.Market
						  WHEN 'Luxembourg' THEN m.Market
						  ELSE COALESCE(m.DealerTableEquivMarket, m.Market)
						  END  = @MarketRegion)
					 OR  (@MarketOrRegionFlag = 'R' AND r.Region = @MarketRegion)
					)
		  AND sq.Questionnaire = @Questionnaire


		--------------------------------------------------------------------------------------------
		-- Clear NULLs for reporting.  Seperate update as was slowing down previous step too much.		
		--------------------------------------------------------------------------------------------

		UPDATE 	#DealerInfo	
		SET SubNationalTerritory = ISNULL(SubNationalTerritory, ''),
			SubNationalRegion = ISNULL(SubNationalRegion, ''),
			OutletCode = ISNULL(OutletCode, ''),
			OutletCode_GDD = ISNULL(OutletCode_GDD,  ''),
			Outlet = ISNULL(Outlet, '')



		-- Get the latest file load date 
		DECLARE @LatestFileDateForMarketRegion DATETIME
		SELECT @LatestFileDateForMarketRegion = MAX(FileLoadDate) 
		FROM #DealerInfo i



		------------------------------------------------------------------
		-- Write the records we have data for to the Retailer summary table. 
		------------------------------------------------------------------

		INSERT INTO SampleReceipt.RetailerSummary (
													ReportDate						,
													Region							,
													Brand							,
													Market							,
													SubNationalTerritory			,
													SubNationalRegion				,
													Questionnaire					,
													OutletCode						,
													OutletCode_GDD					,
													Outlet							,
													LatestFileReceivedDate			,
													TotalFilesReceived				,
													TotalRowsInLatestFiles			,
													TotalEventsInLatestFiles		,
													OldestEventDateInLatestFiles	,
													LatestEventDateInLatestFiles	,
													TotalRowsReceivedYTD			,
													TotalEventsYTD					,
													OldestEventDateYTD				,
													LatestEventDateYTD					,
													LatestFileDateForMarketRegion 
												)
		SELECT	@ReportDate AS ReportDate,
				i.Region,
				i.Brand,
				i.Market, 
				i.SubNationalTerritory, 
				i.SubNationalRegion, 
				Questionnaire,
				i.OutletCode,
				i.OutletCode_GDD, 
				i.Outlet,
				CAST(MAX(FileLoadDate) AS date) AS LatestFilesReceivedDate,
				0 AS TotalFilesReceived				,
				0 AS TotalRowsInLatestFiles			,
				0 AS TotalEventsInLatestFiles		,
				NULL AS OldestEventDateInLatestFile		,
				NULL AS LatestEventDateInLatestFile		,
				COUNT (DISTINCT AuditITemID) AS TotalRowsReceivedYTD,
				COUNT(DISTINCT EventID) AS TotalEventsYTD,
				MIN(EventDate) AS OldestEventDateYTD,
				MAX(EventDate) AS LatestEventDate,
				@LatestFileDateForMarketRegion AS LatestFileDateForMarketRegion 
		FROM   #DealerInfo i 
		GROUP BY 
				i.Region,
				i.Brand,
				i.Market, 
				i.SubNationalTerritory, 
				i.SubNationalRegion, 
				i.Questionnaire,
				i.OutletCode,
				i.OutletCode_GDD, 
				i.Outlet



		-----------------------------------------------------------------------------------
		-- Update the QTD values from this years data
		-----------------------------------------------------------------------------------

		;WITH CTE_QTD_Values
		AS(
			SELECT	i.Region,
					i.Brand,
					i.Market, 
					i.SubNationalTerritory, 
					i.SubNationalRegion, 
					Questionnaire,
					i.OutletCode,
					i.OutletCode_GDD, 
					i.Outlet,
					COUNT (DISTINCT AuditITemID) AS TotalRowsReceivedQTD,
					COUNT(DISTINCT EventID) AS TotalEventsQTD,
					MIN(EventDate) AS OldestEventDateQTD,
					MAX(EventDate) AS LatestEventDateQTD
			FROM   #DealerInfo i 
			WHERE FileLoadDate >= @QuarterStart
			GROUP BY 
					i.Region,
					i.Brand,
					i.Market, 
					i.SubNationalTerritory, 
					i.SubNationalRegion, 
					i.Questionnaire,
					i.OutletCode,
					i.OutletCode_GDD, 
					i.Outlet
		)
		UPDATE s
		SET s.TotalRowsReceivedQTD = v.TotalRowsReceivedQTD,
			s.TotalEventsQTD		= v.TotalEventsQTD,
			s.LatestEventDateQTD	= v.LatestEventDateQTD,
			s.OldestEventDateQTD	= v.OldestEventDateQTD
		FROM SampleReceipt.RetailerSummary s
		INNER JOIN CTE_QTD_Values v ON s.Region					= v.Region					
									AND s.Brand					= v.Brand					
									AND s.Market 				= v.Market 				
									AND s.SubNationalTerritory	= v.SubNationalTerritory	
									AND s.SubNationalRegion		= v.SubNationalRegion		
									AND s.Questionnaire			= v.Questionnaire			
									AND s.OutletCode				= v.OutletCode				
									AND s.OutletCode_GDD			= v.OutletCode_GDD			
									AND s.Outlet					= v.Outlet					



		-----------------------------------------------------------------------------------
		-- Add in missing Dealers from Dealer table - link to logging to get questionnaires
		-----------------------------------------------------------------------------------

		-- Now add the dealers which have existing sample, includes Questionnaire from logging
		INSERT INTO SampleReceipt.RetailerSummary (
													ReportDate						,
													Region							,
													Brand							,
													Market							,
													SubNationalTerritory			,
													SubNationalRegion				,
													Questionnaire					,
													OutletCode						,
													OutletCode_GDD					,
													Outlet							,
													LatestFileReceivedDate			,
													TotalFilesReceived				,
													TotalRowsInLatestFiles			,
													TotalEventsInLatestFiles		,
													OldestEventDateInLatestFiles	,
													LatestEventDateInLatestFiles	,
													TotalRowsReceivedYTD			,
													TotalEventsYTD					,
													OldestEventDateYTD				,
													LatestEventDateYTD					,
													LatestFileDateForMarketRegion 
												)
		SELECT DISTINCT		
				@ReportDate AS ReportDate,
				d.BusinessRegion, 
				d.Manufacturer,
				d.Market,
				d.SubNationalTerritory,
				d.SubNationalRegion,
				sq.Questionnaire AS Questionnaire,
				REPLACE(d.OutletCode, '_BUG', '') AS OutletCode, 
				REPLACE(d.OutletCode_GDD, '_BUG', '') AS OutletCode_GDD,
				d.Outlet,
				NULL AS LatestFileReceivedDate,
				NULL AS TotalFilesReceived,
				NULL AS TotalRowsInLatestFiles,
				NULL AS TotalEventsInLatestFiles,
				NULL AS OldestEventDateInLatestFiles,
				NULL AS LatestEventDateInLatestFiles,
				NULL AS TotalRowsReceivedYTD,
				NULL AS TotalEventsYTD,
				NULL AS OldestEventDateYTD,
				NULL AS LatestEventDateYTD,
				@LatestFileDateForMarketRegion AS LatestFileDateForMarketRegion 
		FROM [$(SampleDB)].dbo.DW_JLRCSPDealers d
		INNER JOIN [$(SampleDB)].Event.EventPartyRoles epr ON epr.PartyID = OutletPartyID
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.MatchedODSEventID = epr.EventID
																		   AND sq.LoadedDate >= '2012-03-05' 
		WHERE		(    (@MarketOrRegionFlag = 'M' AND d.Market = @MarketRegion)
					 OR  (@MarketOrRegionFlag = 'R' AND d.BusinessRegion = @MarketRegion)
					)
		AND sq.Questionnaire = @Questionnaire
		AND ISNULL(d.ThroughDate, getdate()+1) > GETDATE()
		AND NOT EXISTS (SELECT * FROM SampleReceipt.RetailerSummary  ds 
						WHERE ds.OutletCode = REPLACE(d.OutletCode, '_BUG', '')
						AND ds.OutletCode_GDD = REPLACE(d.OutletCode_GDD, '_BUG', '')
						AND ds.Market = d.Market
						)
		AND SubNationalRegion <> 'Inactive'


		-- Now add any dealers which are still not present, Questionnaire is left blank
		INSERT INTO SampleReceipt.RetailerSummary (
													ReportDate						,
													Region							,
													Brand							,
													Market							,
													SubNationalTerritory			,
													SubNationalRegion				,
													Questionnaire					,
													OutletCode						,
													OutletCode_GDD					,
													Outlet							,
													LatestFileReceivedDate			,
													TotalFilesReceived				,
													TotalRowsInLatestFiles			,
													TotalEventsInLatestFiles		,
													OldestEventDateInLatestFiles	,
													LatestEventDateInLatestFiles	,
													TotalRowsReceivedYTD			,
													TotalEventsYTD					,
													OldestEventDateYTD				,
													LatestEventDateYTD					,
													LatestFileDateForMarketRegion 
												)
		SELECT DISTINCT		
				@ReportDate AS ReportDate,
				d.BusinessRegion, 
				d.Manufacturer,
				d.Market,
				d.SubNationalTerritory,
				d.SubNationalRegion,
				@Questionnaire AS Questionnaire,
				REPLACE(d.OutletCode, '_BUG', '') AS OutletCode, 
				REPLACE(d.OutletCode_GDD, '_BUG', '') AS OutletCode_GDD,
				d.Outlet,
				NULL AS LatestFileReceivedDate,
				NULL AS TotalFilesReceived,
				NULL AS TotalRowsInLatestFiles,
				NULL AS TotalEventsInLatestFiles,
				NULL AS OldestEventDateInLatestFiles,
				NULL AS LatestEventDateInLatestFiles,
				NULL AS TotalRowsReceivedYTD,
				NULL AS TotalEventsYTD,
				NULL AS OldestEventDateYTD,
				NULL AS LatestEventDateYTD,
				@LatestFileDateForMarketRegion AS LatestFileDateForMarketRegion 
		FROM [$(SampleDB)].dbo.DW_JLRCSPDealers d
		WHERE		(    (@MarketOrRegionFlag = 'M' AND d.Market = @MarketRegion)
					 OR  (@MarketOrRegionFlag = 'R' AND d.BusinessRegion = @MarketRegion)
					)
		AND d.OutletFunction = CASE WHEN @Questionnaire = 'Service' THEN 'Aftersales'	-- v1.1
									WHEN @Questionnaire = 'LostLeads' THEN 'Sales' 
									WHEN @Questionnaire = 'PreOwned LostLeads' THEN 'PreOwned'	-- V1.4 
									ELSE @Questionnaire END								
		AND ISNULL(d.ThroughDate, getdate()+1) > GETDATE()
		AND NOT EXISTS (SELECT * FROM SampleReceipt.RetailerSummary  ds 
						WHERE ds.OutletCode = REPLACE(d.OutletCode, '_BUG', '')
						AND ds.OutletCode_GDD = REPLACE(d.OutletCode_GDD, '_BUG', '')
						AND ds.Market = d.Market
						)
		AND SubNationalRegion <> 'Inactive'



		------------------------------------------------------------------
		-- Now get last file received dates
		------------------------------------------------------------------

		; WITH CTE_RemainingDealerLatestFileDates
		AS (
			SELECT rs.OutletCode, rs.OutletCode_GDD, sq.Brand, rs.Market, sq.Questionnaire, MAX(sq.LoadedDate) AS LoadedDate
			FROM SampleReceipt.RetailerSummary  rs 
			INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers d ON rs.OutletCode = d.OutletCode
													AND rs.OutletCode_GDD = d.OutletCode_GDD
													AND rs.Market = d.Market
			INNER JOIN [$(SampleDB)].Event.EventPartyRoles epr ON epr.PartyID = OutletPartyID
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.MatchedODSEventID = epr.EventID
			WHERE rs.LatestFileReceivedDate IS NULL 
			  AND sq.LoadedDate >= '2012-03-05' -- Connexions inception date. When SampleLogging table populated from. Any dates before this are for fixes and manual interventions
			GROUP BY rs.OutletCode, rs.OutletCode_GDD, sq.Brand, rs.Market, sq.Questionnaire
		)
		UPDATE rs
		SET rs.LatestFileReceivedDate = CAST(fd.LoadedDate AS DATE)
		FROM SampleReceipt.RetailerSummary  rs 
		INNER JOIN CTE_RemainingDealerLatestFileDates fd ON fd.OutletCode = rs.OutletCode
														AND fd.OutletCode_GDD = rs.OutletCode_GDD
														AND fd.Brand = rs.Brand
														AND fd.Market = rs.Market
														AND fd.Questionnaire = rs.Questionnaire


		------------------------------------------------------------------
		-- Now get the totals for last file(s) received 
		------------------------------------------------------------------

		-- For YTD files 
		; WITH CTE_LatestFileCountsYTD
		AS (
			SELECT rs.OutletCode, rs.OutletCode_GDD, rs.Market, d.FileLoadDate, d.Brand, d.Questionnaire, 
					COUNT(DISTINCT d.AuditID) AS TotalFilesReceived,
					COUNT(DISTINCT d.AuditItemID) AS TotalRowsInLatestFiles,
					COUNT(DISTINCT d.EventID) AS TotalEventsInLatestFiles,
					MIN(d.EventDate) AS OldestEventDateInLatestFiles,
					MAX(d.EventDate) AS LatestEventDateInLatestFiles
			FROM SampleReceipt.RetailerSummary  rs 
			INNER JOIN #DealerInfo d ON rs.OutletCode = d.OutletCode
									AND rs.OutletCode_GDD = d.OutletCode_GDD
									AND rs.Market = d.Market
									AND d.Questionnaire =  rs.Questionnaire 
									AND d.Brand = rs.Brand
			WHERE d.FileLoadDate = rs.LatestFileReceivedDate 
			GROUP BY rs.OutletCode, rs.OutletCode_GDD, rs.Market, d.FileLoadDate, d.Brand, d.Questionnaire
		)
		UPDATE rs
		SET rs.TotalFilesReceived = c.TotalFilesReceived,
			rs.TotalRowsInLatestFiles = c.TotalRowsInLatestFiles,
			rs.TotalEventsInLatestFiles = c.TotalEventsInLatestFiles,
			rs.OldestEventDateInLatestFiles = c.OldestEventDateInLatestFiles,
			rs.LatestEventDateInLatestFiles = c.LatestEventDateInLatestFiles
		FROM SampleReceipt.RetailerSummary  rs 
		INNER JOIN CTE_LatestFileCountsYTD c ON c.Market = rs.Market
											AND c.OutletCode = rs.OutletCode
											AND c.OutletCode_GDD = rs.OutletCode_GDD
											AND c.Questionnaire = rs.Questionnaire
											AND c.Brand = rs.Brand





		-- For Previous files
		; WITH CTE_LatestFileCounts_Remaining
		AS (
			SELECT rs.OutletCode, rs.OutletCode_GDD, rs.Market, sq.Questionnaire, sq.Brand, 
					COUNT(DISTINCT sq.AuditID) AS TotalFilesReceived,
					COUNT(DISTINCT sq.AuditItemID) AS TotalRowsInLatestFiles,
					COUNT(DISTINCT epr.EventID) AS TotalEventsInLatestFiles,
					MIN(e.EventDate) AS OldestEventDateInLatestFiles,
					MAX(e.EventDate) AS LatestEventDateInLatestFiles
			FROM SampleReceipt.RetailerSummary  rs 
			INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers d ON rs.OutletCode = REPLACE(d.OutletCode, '_BUG', '')
													AND rs.OutletCode_GDD = REPLACE(d.OutletCode_GDD, '_BUG', '')
													AND rs.Market = d.Market
			INNER JOIN [$(SampleDB)].Event.EventPartyRoles epr ON epr.PartyID = OutletPartyID
			INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = epr.EventID
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.MatchedODSEventID = epr.EventID
																			   AND sq.LoadedDate >= rs.LatestFileReceivedDate 
																			   AND sq.LoadedDate < DATEADD(day, 1, rs.LatestFileReceivedDate)
			WHERE rs.LatestFileReceivedDate IS NOT NULL
			  AND rs.TotalFilesReceived = 0 -- i.e. not already updated from the YTD data
			GROUP BY rs.OutletCode, rs.OutletCode_GDD, rs.Market, sq.Questionnaire, sq.Brand
		)
		UPDATE rs
		SET rs.TotalFilesReceived = c.TotalFilesReceived,
			rs.TotalRowsInLatestFiles = c.TotalRowsInLatestFiles,
			rs.TotalEventsInLatestFiles = c.TotalEventsInLatestFiles,
			rs.OldestEventDateInLatestFiles = c.OldestEventDateInLatestFiles,
			rs.LatestEventDateInLatestFiles = c.LatestEventDateInLatestFiles
		FROM SampleReceipt.RetailerSummary  rs 
		INNER JOIN CTE_LatestFileCounts_Remaining c ON c.Market = rs.Market
											AND c.OutletCode = rs.OutletCode
											AND c.OutletCode_GDD = rs.OutletCode_GDD
											AND c.Questionnaire = rs.Questionnaire
											AND c.Brand = rs.Brand


		----------------------------------------------------------------------------------------------------
		-- Update days since sample received values + popuate "Uncoded" in dealer code for uncoded dealers 
		----------------------------------------------------------------------------------------------------

		UPDATE SampleReceipt.RetailerSummary
		SET DaysSinceSampleReceived = DATEDIFF(DAY, LatestFileReceivedDate, ReportDate),
			OutletCode = CASE WHEN OutletCode = '' AND Questionnaire IN ('Sales', 'Service', 'LostLeads', 'PreOwned','Bodyshop', 'PreOwned LostLeads')		--V1.2 -- V1.4
							THEN 'Uncoded' ELSE OutletCode END,
			OutletCode_GDD = CASE WHEN OutletCode_GDD = '' AND Questionnaire IN ('Sales', 'Service', 'LostLeads', 'PreOwned','Bodyshop', 'PreOwned LostLeads') --V1.2 -- V1.4
							THEN 'Uncoded' ELSE OutletCode END



END TRY

BEGIN CATCH

    SELECT  @ErrorNumber = ERROR_NUMBER() ,
            @ErrorSeverity = ERROR_SEVERITY() ,
            @ErrorState = ERROR_STATE() ,
            @ErrorLocation = ERROR_PROCEDURE() ,
            @ErrorLine = ERROR_LINE() ,
            @ErrorMessage = ERROR_MESSAGE();

    EXEC [$(ErrorDB)].[dbo].uspLogDatabaseError @ErrorNumber,
        @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine,
        @ErrorMessage;
	
    RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);
	
END CATCH;
