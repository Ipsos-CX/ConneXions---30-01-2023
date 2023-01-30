CREATE PROCEDURE [Selection].[uspRunScheduledSelections]

AS

/*
		Purpose:	Run the scheduled selections
		
		Version			Date			Developer			Comment
LIVE	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.uspIP_RunScheduledSelections
LIVE	2.0				25-08-2015		Chris Ross			BUG 11705 - modified to include building of base (pool) table before 
																		running each of the associated selections against it.
LIVE	2.1				25-01-2017		Chris Ledger		BUG 13160 - order by requirement so CQI done before Enprecis
LIVE	2.2				08-05-2017		Chris Ledger		BUG 13897 - Exclude Lost Lead Events If Not Most Recent Event
LIVE	2.3				31-07-2017		Chris Ross			BUG 13144 - Add in check which stops Selections Running when we are nearing the 
																		start point for China CQI CaseID range.  Remedial action is then required.
LIVE	2.4				24-08-2017		Eddie Thomas		BUG 14141 - Add in Bodyshop event processing	
LIVE	2.5				25-01-2018		Chris Ross			BUG 14435 - Only update logging if the NonLatestEvent value has changed.
LIVE	2.6				25-02-2019		Chris Ross			BUG 15271 - TEMP PATCH -  Remove any Austria or Czech Republic records from the Selection.Pool table
																				  	  so that we do not pick them up under cross-border selections.
LIVE	2.7				02-10-2019		Chris Ledger		BUG 15460 - Add in PreOwned LostLeads
LIVE	2.8				17-10-2019		Chris Ledger		BUG 16673 - Add in CQI
LIVE	2.9				21-11-2019		Chris Ledger		Add Index to #MaxEvents 
LIVE	2.10			18-12-2019		Chris Ledger		BUG 16673 - Split out CQI 24MIS and CQI 3MIS
LIVE	2.11			18-02-2020		Chris Ledger		BUG 17942 - Split out MCQI 1MIS
LIVE	2.12			19-02-2021		Chris Ledger		TASK 299 - Add in CRC General Enquiry
LIVE	2.13			22-04-2021		Ben King			BUG 18052 - Austria Purchase Test Data
LIVE	2.14			24-06-2021		Chris Ledger		Fix bug with CRC General Enquiry
LIVE	2.15			21-01-2022		Chris Ledger		TASK 739 - Move selection of organisations at same address to uspRunSelection SP
LIVE	2.16			08-02-2022		Chris Ledger		TASK 628 - Do not set NonLatestEvent flag if event already selected or event not in selection window
LIVE	2.17			21-02-2022		Chris Ledger		TASK 628 - Flag parties where party country does not match selection country as CrossBorderAddress
LIVE	2.18			23-02-2022		Chris Ledger		TASK 628 - Add PreOwned to NonLatestEvent flagging
LIVE	2.19			06-06-2022		Eddie Thomas		TASK 877 - Land Rover Experience
LIVE	2.20			20-06-2022		Chris Ledger		TASK 917 - Add CQI 1MIS
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	
	------------------------------------------------------------------------------------------------
	-- Check we have not reached the 80,000,000 limit set for CaseIDs.  China CQI CaseIDs start at 
	-- 90,000,000 so we have set this alert to ensure that we take action in plenty of time.
	------------------------------------------------------------------------------------------------
	DECLARE @MaxCaseID  BIGINT
	SELECT @MaxCaseID = MAX(CaseID) FROM Event.Cases

	IF @MaxCaseID > 80000000
	RAISERROR ('Approaching China CQI CaseID start point.  Remedial action required.', -- Message text.  
               16, -- Severity.  
               1 -- State.  
               );  


	------------------------------------------------------------------------------------------------
	-- CREATE TABLE TO HOLD THE SCHEDULED SELECTIONS
	------------------------------------------------------------------------------------------------	
	CREATE TABLE #Selections 
	(
		ID INT IDENTITY(1, 1),
		SelectionRequirementID INT,
		QuestionniareRequirementID INT,
		StartDays INT, 
		EndDays INT, 
		EventCategoryID INT, 
		CountryID INT,
		SelectionDate  DATETIME2,
		UpdateSelectionLogging  BIT
	)


	------------------------------------------------------------------------------------------------
	-- GET THE SCHEDULED SELECTIONS
	------------------------------------------------------------------------------------------------
	INSERT INTO #Selections
	(
		SelectionRequirementID,
		QuestionniareRequirementID,
		StartDays, 
		EndDays, 
		EventCategoryID,
		CountryID,
		SelectionDate,
		UpdateSelectionLogging
	)
	SELECT SR.RequirementID AS SelectionRequirementID, 
		RR.RequirementIDPartOf AS QuestionnaireRequirementID,
		QR.StartDays, 
		QR.EndDays, 
		QR.EventCategoryID,
		QR.CountryID,
		SR.SelectionDate,
		ISNULL((	SELECT TOP 1 B.UpdateSelectionLogging 
					FROM dbo.vwBrandMarketQuestionnaireSampleMetadata B
					WHERE B.QuestionnaireRequirementID = QR.RequirementID
						AND B.UpdateSelectionLogging = 1), 0) AS UpdateSelectionLogging
	FROM Requirement.SelectionRequirements SR
		INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = SR.RequirementID
		INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementId = RR.RequirementIDPartOf
		INNER JOIN Requirement.Requirements R ON SR.RequirementID = R.RequirementID		-- V2.1
	WHERE SR.ScheduledRunDate <= GETDATE()
		AND (	SR.DateLastRun < SR.ScheduledRunDate
				OR SR.DateLastRun IS NULL)
	ORDER BY SR.SelectionDate,				-- These must be in order so that our selection run loop works later
		QR.StartDays,							
		QR.EndDays, 
		QR.EventCategoryID,
		R.Requirement				-- V2.1


	------------------------------------------------------------------------------------------------
	-- Build the selection pool for the schedule selections to work from 
	------------------------------------------------------------------------------------------------
	CREATE TABLE #BaseTableReqs
	(
		ID INT IDENTITY(1, 1),
		StartDays INT, 
		EndDays INT, 
		EventCategoryID INT,
		SelectionDate DATETIME2
	)


	INSERT INTO #BaseTableReqs (StartDays, EndDays, EventCategoryID, SelectionDate)
	SELECT SR.StartDays, 
		SR.EndDays, 
		SR.EventCategoryID, 
		SR.SelectionDate
	FROM #Selections SR 
	GROUP BY SR.StartDays, 
		SR.EndDays, 
		SR.EventCategoryID, 
		SR.SelectionDate


	CREATE TABLE #BaseTableReqLoop
	(
		ID INT IDENTITY(1, 1),
		StartDays INT, 
		EndDays INT,
		SelectionDate DATETIME2
	)


	INSERT INTO #BaseTableReqLoop (StartDays, EndDays, SelectionDate)
	SELECT StartDays, 
		EndDays, 
		SelectionDate
	FROM #BaseTableReqs
	GROUP BY StartDays, 
		EndDays, 
		SelectionDate
	

	------------------------------------------------------------------------------------------------
	-- LOOP THROUGH Requirements Building base tables and then selecting on them
	------------------------------------------------------------------------------------------------

	/* V2.15 - Move selection of organisations at same address to uspRunSelection SP
	-- Get Organisation's contact mechanisms for lookup
	CREATE TABLE #Org_ContactMechanismIDs
	(
		ContactMechanismID	BIGINT,
		PartyID				BIGINT
	)

	INSERT INTO #Org_ContactMechanismIDs (ContactMechanismID, PartyID)
	SELECT PCM.ContactMechanismID, 
		MAX(O.PartyID) As PartyID 
	FROM Party.Organisations O
		INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = O.PartyID
	WHERE EXISTS (	SELECT PA.ContactMechanismID 
					FROM ContactMechanism.PostalAddresses PA 
					WHERE PA.ContactMechanismID = PCM.ContactMechanismID)
	GROUP BY PCM.ContactMechanismID
	
	
	CREATE INDEX IX_Org_ContactMechanismIDs 
    ON #Org_ContactMechanismIDs (ContactMechanismID, PartyID);
	*/

	-- Create table to hold categories (by start and end dates which require logging - see further below)
	CREATE TABLE #LoggingCategories 
	(
		CategoryID  INT,
		Category	VARCHAR(50)
	)


	-- Create table and counter for looping through countries in the Organisation Name get (further down)
	CREATE TABLE #Countries
	(
		ID INT IDENTITY(1, 1),
		CountryID INT
	)

	DECLARE @CountryMaxID INT,
			@CountryCounter INT,
			@CurrentCountryID  INT


	-- Variables for loop
	DECLARE @Counter INT,
			@LoopMax INT,
			@StartDays INT,
			@EndDays   INT,
			@SelectionDate DATETIME2
	


	SELECT @LoopMax = MAX(ID) FROM #BaseTableReqLoop
	SET @Counter = 1
	
	WHILE @Counter <= @LoopMax
	BEGIN ------------------------------------------------------------------------------

			------------------------------------------------------
			-- Get Selection Window Params
			------------------------------------------------------ 
			SELECT	@StartDays = StartDays, 
					@EndDays = EndDays,
					@SelectionDate = SelectionDate
			FROM #BaseTableReqLoop 
			WHERE ID = @Counter

			DROP TABLE IF EXISTS #MaxEvents

			------------------------------------------------------
			-- Select latest event dates within date window for all 
			-- required event categories
			------------------------------------------------------
			SELECT
				VPRE.VehicleID, 
				ET.EventCategoryID, 
				EPR.PartyID AS DealerID, 
				VPRE.PartyID, 
				VPRE.VehicleRoleTypeID, 
				COALESCE(MAX(E.EventDate), MAX(REG.RegistrationDate)) AS MaxEventDate
			INTO #MaxEvents
			FROM Vehicle.VehiclePartyRoleEvents VPRE
				INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
				INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
				INNER JOIN Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
				LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
					INNER JOIN Vehicle.Registrations REG ON REG.RegistrationID = VRE.RegistrationID
														AND REG.RegistrationDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)
						ON VRE.EventID = E.EventID AND VRE.VehicleID = VPRE.VehicleID
				WHERE ET.EventCategoryID IN (	SELECT R.EventCategoryID 
												FROM #BaseTableReqs R 
												WHERE R.StartDays = @StartDays 
													AND R.EndDays = @EndDays
													AND R.SelectionDate = @SelectionDate)
					AND COALESCE(E.EventDate, REG.RegistrationDate) BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)
			GROUP BY
				VPRE.VehicleID, 
				ET.EventCategoryID, 
				EPR.PartyID, 
				VPRE.PartyID, 
				VPRE.VehicleRoleTypeID

			CREATE NONCLUSTERED INDEX IX_MaxEvents ON #MaxEvents ([EventCategoryID]) INCLUDE ([VehicleID],[DealerID],[PartyID],[MaxEventDate])		-- V2.9


			------------------------------------------------------------------------------------------
			-- Determine which of the event categories (based on associates requirement IDs and BMW)
			-- we should be doing selection logging for Non-Latest event on
			------------------------------------------------------------------------------------------
			TRUNCATE TABLE #LoggingCategories
	
			INSERT INTO #LoggingCategories (CategoryID, Category)
			SELECT DISTINCT S.EventCategoryID, 
				EC.EventCategory
			FROM #Selections S
				INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = S.EventCategoryID
			WHERE S.StartDays = @StartDays
			  AND S.EndDays = @EndDays
			  AND S.SelectionDate = @SelectionDate
			  AND S.UpdateSelectionLogging = 1


			------------------------------------------------------------------------------------------
			--DO THE REQUIRED LOGGING
			------------------------------------------------------------------------------------------
			
			-------------------------------------------------------
			-- PERSONS
			-------------------------------------------------------
			
			-- SALES - PERSONS
			IF 'Sales' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Sales') 
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window

			
			-- SERVICE - PERSONS
			IF 'Service' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Service')
				AND ME.MaxEventDate > SL.ServiceDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.ServiceDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-- V2.18 PREOWNED - PERSONS
			IF 'PreOwned' IN (SELECT Category FROM #LoggingCategories)											-- V2.18 
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'PreOwned')									-- V2.18
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-- CRC - PERSONS																-- V2.3
			IF 'CRC' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CRC')
				AND ME.MaxEventDate > SL.CRCDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.[CRCCentrePartyID]
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				
 
			-- ROADSIDE - PERSONS																-- V2.3
			IF 'Roadside' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Roadside')
				AND ME.MaxEventDate > SL.RoadsideDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.[RoadsideNetworkPartyID]
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- LOST LEAD - PERSONS																-- V2.2
			IF 'LostLeads' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'LostLeads')
				AND ME.MaxEventDate > SL.LostLeadDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- BODYSHOP - PERSONS																-- V2.2
			IF 'Bodyshop' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Bodyshop')
				AND ME.MaxEventDate > SL.BodyshopEventDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- PREOWNED LOST LEAD - PERSONS																-- V2.7
			IF 'PreOwned LostLeads' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'PreOwned LostLeads')
				AND ME.MaxEventDate > SL.LostLeadDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CQI 3MIS - PERSONS	-- V2.10
			IF 'CQI 3MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 3MIS') 
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CQI 24MIS - PERSONS	-- V2.10
			IF 'CQI 24MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 24MIS') 
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- MCQI 1MIS - PERSONS	-- V2.11
			IF 'MCQI 1MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'MCQI 1MIS') 
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CRC GENERAL ENQUIRY - PERSONS	-- V2.12
			IF 'CRC General Enquiry' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CRC General Enquiry') 
				AND ME.MaxEventDate > SL.GeneralEnquiryDate			-- V2.14
				AND ME.VehicleID = SL.MatchedODSVehicleID			
				AND ME.DealerID = SL.CRCCentrePartyID				-- V2.14
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5	
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
									

			-- LR EXPERIENCE - PERSONS		--V2.19
			IF 'Land Rover Experience' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Land Rover Experience') 
				AND ME.MaxEventDate > SL.ExperienceEventDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.ExperienceDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-- CQI 1MIS - PERSONS	-- V2.20
			IF 'CQI 1MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPersonID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 1MIS') 
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-------------------------------------------------------
			-- ORGANISATIONS
			-------------------------------------------------------

			-- SALES - ORGANISATIONS
			IF 'Sales' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Sales')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- SERVICE - ORGANISATIONS
			IF 'Service' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Service')
				AND ME.MaxEventDate > SL.ServiceDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.ServiceDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- V2.18 PREOWNED - ORGANISATIONS
			IF 'PreOwned' IN (SELECT Category FROM #LoggingCategories)											-- V2.17
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'PreOwned')									-- V2.17
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-- CRC - ORGANISATIONS																-- V2.3
			IF 'CRC' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CRC')
				AND ME.MaxEventDate > SL.CRCDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.[CRCCentrePartyID]
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				
				
			-- ROADSIDE - ORGANISATIONS																-- V2.3
			IF 'Roadside' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Roadside')
				AND ME.MaxEventDate > SL.RoadsideDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.[RoadsideNetworkPartyID]
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- LOST LEAD - PERSONS																-- V2.2
			IF 'LostLeads' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'LostLeads')
				AND ME.MaxEventDate > SL.LostLeadDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- BODYSHOP - ORGANISATIONS																-- V2.2
			IF 'Bodyshop' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories
											WHERE EventCategory = 'Bodyshop')
				AND ME.MaxEventDate > SL.BodyshopEventDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- PREOWNED LOST LEAD - PERSONS																-- V2.7
			IF 'PreOwned LostLeads' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'PreOwned LostLeads')
				AND ME.MaxEventDate > SL.LostLeadDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CQI 3MIS - ORGANISATIONS		-- V2.10
			IF 'CQI 3MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 3MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CQI 24MIS - ORGANISATIONS		-- V2.10
			IF 'CQI 24MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 24MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0						-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- MCQI 1MIS - ORGANISATIONS		-- V2.11
			IF 'MCQI 1MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'MCQI 1MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5			
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CRC GENERAL ENQUIRY - ORGANISATIONS		-- V2.12
			IF 'CRC General Enquiry' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CRC General Enquiry')
				AND ME.MaxEventDate > SL.GeneralEnquiryDate			-- V2.14
				AND ME.VehicleID = SL.MatchedODSVehicleID			
				AND ME.DealerID = SL.CRCCentrePartyID				-- V2.14
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5	
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				
			
			-- LR EXPERIENCE - ORGANISATIONS		--V2.19
			IF 'Land Rover Experience' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Land Rover Experience') 
				AND ME.MaxEventDate > SL.ExperienceEventDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.ExperienceDealerID
				AND ISNULL(SL.NonLatestEvent, 0) = 0				-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-- CQI 1MIS - ORGANISATIONS		-- V2.20
			IF 'CQI 1MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSOrganisationID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 1MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-------------------------------------------------------
			-- PARTIES
			-------------------------------------------------------

			-- SALES - PARTIES
			IF 'Sales' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Sales')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- SERVICE - PARTIES
			IF 'Service' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Service')
				AND ME.MaxEventDate > SL.ServiceDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.ServiceDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				
	
			-- V2.18 PREOWNED - PARTIES
			IF 'PreOwned' IN (SELECT Category FROM #LoggingCategories)											-- V2.17
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'PreOwned')									-- V2.17
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-- CRC - PARTIES																-- V2.3
			IF 'CRC' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CRC')
				AND ME.MaxEventDate > SL.CRCDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.[CRCCentrePartyID]
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				
			
			-- LOST LEAD - PARTIES																-- V2.2
			IF 'LostLeads' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'LostLeads')
				AND ME.MaxEventDate > SL.LostLeadDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				
				
			-- BODYSHOP - PARTIES																-- V2.2
			IF 'Bodyshop' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Bodyshop')
				AND ME.MaxEventDate > SL.BodyshopEventDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				
	
			-- PREOWNED LOST LEAD - PARTIES																-- V2.7
			IF 'PreOwned LostLeads' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'PreOwned LostLeads')
				AND ME.MaxEventDate > SL.LostLeadDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CQI 3MIS - PARTIES	-- V2.10
			IF 'CQI 3MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 3MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CQI 24MIS - PARTIES	-- V2.10
			IF 'CQI 24MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 24MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- MCQI 1MIS - PARTIES	-- V2.11
			IF 'MCQI 1MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'MCQI 1MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
				

			-- CRC GENERAL ENQUIRY - PARTIES	-- V2.12
			IF 'CRC General Enquiry' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CRC General Enquiry')
				AND ME.MaxEventDate > SL.GeneralEnquiryDate			-- V2.14
				AND ME.VehicleID = SL.MatchedODSVehicleID			
				AND ME.DealerID = SL.CRCCentrePartyID				-- V2.14
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window
							

			--	LR EXPERIENCE - PARTIES			--V2.19
			IF 'Land Rover Experience' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'Land Rover Experience')
				AND ME.MaxEventDate > SL.ExperienceEventDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.ExperienceDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			-- CQI 1MIS - PARTIES	-- V2.20
			IF 'CQI 1MIS' IN (SELECT Category FROM #LoggingCategories)  
			UPDATE SL
			SET SL.NonLatestEvent = CASE	WHEN CD.CaseID IS NULL THEN 1										-- V2.16 Only flag NonLatestEvent if not selected previously
											ELSE 0 END,															-- V2.16
				SL.EventAlreadySelected = CASE	WHEN CD.CaseID IS NULL THEN 0									-- V2.16
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Flag EventAlreadySelected if not first selection
												ELSE SL.EventAlreadySelected END,								-- V2.16 
				SL.SampleRowProcessed = CASE	WHEN CD.CaseID IS NULL THEN 1									-- V2.16 Set SampleRowProcessed if flagging NonLatestEvent
												WHEN ISNULL(SL.CaseID,0) = 0 THEN 1								-- V2.16 Set SampleRowProcessed if flagging EventAlreadySelected
												ELSE SL.SampleRowProcessed END,									-- V2.16 Otherwise leave unchanged
				SL.SampleRowProcessedDate = CASE	WHEN CD.CaseID IS NULL THEN GETDATE()						-- V2.16 Set SampleRowProcessedDate if flagging NonLatestEvent
													WHEN ISNULL(SL.CaseID,0) = 0 THEN GETDATE()					-- V2.16 Set SampleRowProcessedDate if flagging EventAlreadySelected
													ELSE SL.SampleRowProcessedDate END							-- V2.16 Otherwise leave unchanged
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN #MaxEvents ME ON ME.PartyID = SL.MatchedODSPartyID
				INNER JOIN Event.Events E ON SL.MatchedODSEventID = E.EventID										-- V2.16
				LEFT JOIN Meta.CaseDetails CD ON SL.MatchedODSEventID = CD.EventID									-- V2.16
												AND SL.QuestionnaireRequirementID = CD.QuestionnaireRequirementID	-- V2.16
												AND SL.MatchedODSVehicleID = CD.VehicleID							-- V2.16
			WHERE ME.EventCategoryID = (	SELECT EventCategoryID 
											FROM Event.EventCategories 
											WHERE EventCategory = 'CQI 1MIS')
				AND ME.MaxEventDate > SL.SaleDate
				AND ME.VehicleID = SL.MatchedODSVehicleID
				AND ME.DealerID = SL.SalesDealerID
				AND ISNULL(SL.NonLatestEvent,0) = 0					-- V2.5
				AND E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)	-- V2.16 Only log events in selection window


			--------------------------------------------------------------------------------------------------------
			-- Now build the base table pool of records  (from #MaxEvents)
			--------------------------------------------------------------------------------------------------------
		
			-- TRUNCATE THE BASE TABLE TO HOLD THE POOL OF SELECTION DATA
			TRUNCATE TABLE Selection.Pool


			-- NOW GET THE EVENT DETAILS FOR THE LATEST EVENTS FOR EACH PARTY FOR THE CORRECT BRAND, OWNERSHIP CYCLE, FOR NON INTERNAL DEALERS AND WHERE WE HAVE PEOPLE OR ORGANISATION INFORMATION
			INSERT INTO Selection.Pool
			(
				EventID,
				VehicleID,
				VehicleRoleTypeID,
				VIN,
				EventCategory,
				EventCategoryID,
				EventType,
				EventTypeID,
				EventDate,
				ManufacturerPartyID,
				ModelID,
				PartyID,
				RegistrationNumber,
				RegistrationDate,
				OwnershipCycle,
				DealerPartyID,
				DealerCode,
				OrganisationPartyID
			)
			SELECT DISTINCT
				VE.EventID,
				VE.VehicleID,
				VE.VehicleRoleTypeID,
				VE.VIN,
				VE.EventCategory,
				VE.EventCategoryID,
				VE.EventType,
				VE.EventTypeID,
				VE.EventDate,
				VE.ManufacturerPartyID,
				VE.ModelID,
				VE.PartyID,
				VE.RegistrationNumber,
				VE.RegistrationDate,
				VE.OwnershipCycle,
				VE.DealerPartyID,
				VE.DealerCode,
				COALESCE(O.PartyID, BE.PartyID) AS OrganisationPartyID
			FROM #MaxEvents M
				INNER JOIN Meta.VehicleEvents VE ON VE.VehicleID = M.VehicleID
												AND VE.EventCategoryID = M.EventCategoryID
												AND VE.PartyID = M.PartyID
												AND VE.VehicleRoleTypeID = M.VehicleRoleTypeID
												AND VE.EventDate = M.MaxEventDate
				LEFT JOIN Meta.BusinessEvents BE ON BE.EventID = VE.EventID		
				LEFT JOIN Party.Organisations O ON O.PartyID = VE.PartyID
				

		---------------------------------------------------------------------------------------------------------
		-- TEMP PATCH - Remove records for Austria or Czech Republic dealers OR markets, if present.    -- V2.6
		---------------------------------------------------------------------------------------------------------		
		
		-- Remove based on Market
		--DELETE P
		--FROM Selection.Pool P
		--WHERE EXISTS (	SELECT SL.MatchedODSEventID 
		--				FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
		--				WHERE SL.MatchedODSEventID = P.EventID 
		--					AND SL.Market in ('Czech Republic', 'Austria'))	
		
		---- Remove based on Dealer
		--V2.13 - PATCH REMOVED
		--DELETE P
		--FROM Selection.Pool P
		--WHERE EXISTS (	SELECT D.OutletPartyID 
		--				FROM dbo.DW_JLRCSPDealers D 
		--				WHERE D.OutletPartyID = P.DealerPartyID
		--				  AND D.Market in ('Czech Republic', 'Austria'))
						  
						  
		------------------------------------------------------------------------------------------
		-- Get the country details here so that the selections procedure can filter based 
		-- on Country.  This should improve over selection speed by filtering earlier on.
		------------------------------------------------------------------------------------------
		
		-- NOW GET THE COUNTRY DETAILS: FIRSTLY USE THE POSTAL ADDRESS OF THE CUSOMTER, SECONDLY USE THE MARKET OF THE DEALER
		-- WHILE WE'RE HERE GET THE ADDRESS DETAILS AS WELL
		UPDATE SB
		SET SB.CountryID = PA.CountryID,
			SB.PostalContactMechanismID = PA.ContactMechanismID,
			SB.Street = PA.Street,
			SB.Postcode = PA.Postcode
		FROM Selection.Pool SB
			INNER JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = SB.PartyID
			INNER JOIN ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID

		;WITH DealerCountries (DealerPartyID, CountryID) AS 
		(
			SELECT DISTINCT
				DC.PartyIDFrom, 
				DC.CountryID
			FROM ContactMechanism.DealerCountries DC
			UNION
			SELECT CRC.PartyIDFrom, 
				CRC.CountryID				
			FROM Party.CRCNetworks CRC
			UNION
			SELECT RN.PartyIDFrom,
				RN.CountryID				
			FROM Party.RoadsideNetworks RN
		)
		UPDATE SB
		SET SB.CountryID = DC.CountryID
		FROM Selection.Pool SB
			INNER JOIN DealerCountries DC ON DC.DealerPartyID = SB.DealerPartyID
		WHERE SB.CountryID IS NULL


		------------------------------------------------------------------------------------------------------------
		-- V.2.17 Flag parties where party country does not match selection country as CrossBorderAddress
		------------------------------------------------------------------------------------------------------------
		UPDATE SL
		SET SL.SampleRowProcessed = 1,
			SL.SampleRowProcessedDate = GETDATE(),
			SL.CrossBorderAddress = 1
		FROM Selection.Pool SP
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SP.EventID = SL.MatchedODSEventID
																						AND SP.PartyID = COALESCE(NULLIF(SL.MatchedODSPersonID,0), NULLIF(SL.MatchedODSOrganisationID,0))														
																						AND SP.CountryID <> SL.CountryID
		WHERE SP.CountryID NOT IN (	SELECT S.CountryID 
									FROM #Selections S 
									WHERE S.StartDays = @StartDays 
										AND S.EndDays = @EndDays
										AND S.SelectionDate = @SelectionDate)
			AND SL.CountryID IN (	SELECT S.CountryID 
									FROM #Selections S 
									WHERE S.StartDays = @StartDays 
										AND S.EndDays = @EndDays
										AND S.SelectionDate = @SelectionDate) 
			AND ISNULL(SL.CrossBorderAddress,0) <> 1							-- V2.17 Only update once


		------------------------------------------------------------------------------------------------------------
		-- REMOVE ALL COUNTRIES FROM POOL WHICH ARE NOT IN OUR SELECTION LIST
		------------------------------------------------------------------------------------------------------------
		DELETE 
		FROM Selection.Pool 
		WHERE CountryID NOT IN (	SELECT S.CountryID 
									FROM #Selections S 
									WHERE S.StartDays = @StartDays 
										AND S.EndDays = @EndDays
										AND S.SelectionDate = @SelectionDate)
	
	
		/* V2.15 - Move selection of organisations at same address to uspRunSelection SP
		------------------------------------------------------------------------------------------------------------
		-- Check for Organisations at the same address for markets (using CountryID) 
		------------------------------------------------------------------------------------------------------------
		
		-- Get the Address Matching MethodologyID for reference
		DECLARE @AddressMatchingMethodology INT

		SELECT @AddressMatchingMethodology = ID 
		FROM PartyMatchingMethodologies 
		WHERE PartyMatchingMethodology = 'Name and Postal Address'

		-- Get the countries and loop through each one (to make the selects smaller)
		TRUNCATE TABLE #Countries
		
		INSERT INTO #Countries (CountryID)
		SELECT DISTINCT CountryID 
		FROM Selection.Pool

		SELECT @CountryMaxID = MAX(ID) 
		FROM #Countries
		
		SET @CountryCounter = 1

		WHILE @CountryCounter <= @CountryMaxID
		BEGIN

			-- Get the countryID
			SELECT @CurrentCountryID = CountryID 
			FROM #Countries 
			WHERE ID = @CountryCounter

			IF @CurrentCountryID <> (	SELECT C.CountryID 
										FROM ContactMechanism.Countries C 
										WHERE C.Country = 'South Africa')
				AND @AddressMatchingMethodology = (	SELECT DISTINCT M.PartyMatchingMethodologyID 
													FROM dbo.Markets M
													WHERE  M.CountryID = @CurrentCountryID )
			
			BEGIN 
				-- GET THE ORGANISATION PARTYID IF WE'VE NOT ALREADY GOT IT BY CHECKING FOR ORGANISATIONS AT THE SAME ADDRESS
				UPDATE SB
				SET SB.OrganisationPartyID = OCM.PartyID
				FROM Selection.[Pool] SB
					INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = SB.PartyID
					INNER JOIN #Org_ContactMechanismIDs OCM ON OCM.ContactMechanismID = PCM.ContactMechanismID 
				WHERE SB.OrganisationPartyID IS NULL
					AND SB.CountryID = @CurrentCountryID
				  
			END
			
			-- Increment the counter
			SET @CountryCounter += 1
		END 
		*/


			--------------------------------------------------------------------------------------------
			-- Run through the selections
			--------------------------------------------------------------------------------------------

			-- DECLARE VARIABLES
			DECLARE @SelectionsMaxID INT
			DECLARE @SelectionsCounter INT
			DECLARE @SelectionRequirementID INT
			DECLARE @QuestionniareRequirementID INT
	
			-- As the selections are ordered we can identify them using start and end days and then run 
			-- through the IDs in a while loop 
			SELECT @SelectionsCounter = MIN(ID) 
			FROM #Selections 
			WHERE StartDays = @StartDays 
				AND EndDays = @EndDays
				AND SelectionDate = @SelectionDate
			
			SELECT @SelectionsMaxID = MAX(ID) 
			FROM #Selections 
			WHERE StartDays = @StartDays 
				AND EndDays = @EndDays	
				AND SelectionDate = @SelectionDate

			WHILE @SelectionsCounter <= @SelectionsMaxID
			BEGIN
			
				-- GET THE CURRENT RequirementID
				SELECT
					@SelectionRequirementID = SelectionRequirementID,
					@QuestionniareRequirementID = QuestionniareRequirementID
				FROM #Selections 
				WHERE ID = @SelectionsCounter

				-- RUN THE SELECTION
				EXEC Selection.uspRunSelection @QuestionniareRequirementID, @SelectionRequirementID;
			
				-- INCREMENT THE COUNTER
				SET @SelectionsCounter += 1
		
			END

			--Increment counter
			SET @Counter += 1

	END --- END OF BASE POOL TABLE BUILD - AND RUN SELECTION - LOOP -------------------------------------------


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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH	

