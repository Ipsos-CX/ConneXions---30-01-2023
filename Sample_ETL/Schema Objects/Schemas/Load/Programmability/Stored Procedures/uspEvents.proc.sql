CREATE PROCEDURE Load.uspEvents

AS

/*
	Purpose:	Write event information to Sample database
	
			Version			Date			Developer			Comment
			1.0				$(ReleaseDate)	Simon Peacock		Created FROM [Prophet-ETL].dbo.uspODSLOAD_Events
	LIVE	1.1				14-10-2014		Chris Ross			Add in CRC 
	LIVE	1.2				17-07-2015		Chris Ross			BUG 11675 - And in BypassEventMatching functionality
	LIVE	1.3				13-10-2015		Chris Ross			BUG 11933 - Add in AFRLCode 
	LIVE	1.4				01-02-2016		Chris Ross			BUG 12038 - Add in PreOwned event type functionality
	LIVE	1.5				07-04-2016		Chris Ross			BUG 12507 - Add in CRC CaseID matching for uniqueness
	LIVE	1.6				19-08-2016		Chris Ross			BUG 12859 - Add in LostLeads events
	LIVE	1.7				23-08-2017		Eddie Thomas		BUG 14141 - Add in Bodyshop events
	LIVE	1.8				14-05-2018		Eddie Thomas		BUG	14557 - China CRC PII - Extend CRC event matching/loading to support China CRC with Responses
	LIVE	1.9				14-09-2018		Chris Ledger		BUG 14917 - Match Lost Leads on Vehicle and Person	
	LIVE	1.10			22-10-2018		Chris Ledger		BUG 15056 - Add in IAssistance Events
	LIVE	1.11			01-10-2019		Chris Ledger		BUG 15490 - Add in PreOwned LostLeads Events
	LIVE	1.12			17-10-2019		Chris Ledger		BUG 16673 - Add in CQI Events
	LIVE	1.13			18-02-2020		Chris Ledger		BUG 17942 - Add in MCQI Events
	LIVE	1.14			02-03-2020		Chris Ledger		BUG 17981 - Fix bug which prevents deduplication of CQI/MCQI because SelectionOutputActive = 0	
	LIVE	1.15			10-03-2020		Chris Ledger		BUG 18001 - Use Temporary Table to Speed Up Query
	LIVE	1.16			24-03-2021		Chris Ledger		TASK 299 - Add General Enquiry
	LIVE	1.17			26-04-2021		Chris Ledger		TASK 408 - Set SaleDate to LoadedDate - 5 for Germany/Austria/Czech Republic where null or outside selection window
	LIVE	1.18			19-05-2021		Chris Ledger		TASK 299 - Add in CaseNumber for General Enquiry
	LIVE	1.19			20-08-2021		Chris Ledger		TASK 567 - Add in LEAD_ID for CRM Lost Leads
	LIVE	1.20			09-09-2021		Chris Ledger		TASK 585 - Include non CRM Lost Leads
	LIVE	1.21			13-09-2021		Chris Ledger		TASK 601 - Check that SalesDate hasn't already been forced for Germany/Austria/Czech Republic
	LIVE	1.22			14-09-2021		Chris Ledger		TASK 601 - Switch off forcing of date for Germany/Austria/Czech Republic
	LIVE	1.23			29-09-2021		Chris Ledger		TASK 601 - Set SaleDate to RegistrationDate or LoadedDate - 5 for Germany/Austria/Czech Republic where null or outside selection window
	LIVE	1.24			01-06-2022		Ben King			TASK 880 - Land Rover Experience - Update Load from VWT package
	LIVE	1.25			20-06-2022		Chris Ledger		TASK 917 - Add in CQI 1MIS Events
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- V1.17 Set SaleDate to LoadedDate - 5 for Germany/Austria/Czech Republic where null or outside selection window
		--SELECT BMQ.Market, BMQ.Questionnaire, QR.EndDays, F.ActionDate, V.SaleDate, V.RegistrationDate, EVC.*, AE.*						-- V1.21
		;WITH CTE_ExistingVCS AS																											-- V1.21
		(
			SELECT MIN(VCS.AuditItemID) AS AuditItemID,
				VCS.VEH_VIN, 
				VCS.VISTACONTRACT_HANDOVER_DATE, 
				VCS.VEH_REGISTRATION_DATE
			FROM CRM.Vista_Contract_Sales VCS
			GROUP BY VCS.VEH_VIN, 
				VCS.VISTACONTRACT_HANDOVER_DATE, 
				VCS.VEH_REGISTRATION_DATE
		)
		UPDATE V
		SET V.SaleDate = CASE	WHEN AE.EventDate IS NOT NULL THEN CAST(AE.EventDate AS DATE)																			-- V1.21
								WHEN ISNULL(V.RegistrationDate,'1900-01-01') >= DATEADD(DD, QR.EndDays, CAST(GETDATE() AS DATE)) THEN CAST(V.RegistrationDate AS DATE)	-- V1.23
								ELSE DATEADD(DD, -5, CAST(F.ActionDate AS DATE)) END																					-- V1.21
		FROM dbo.VWT V
			INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = V.AuditID 
			INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON F.[FileName] LIKE BMQ.SampleFileNamePrefix + '%'
																					AND BMQ.CountryID = V.CountryID
																					AND BMQ.ManufacturerPartyID = V.ManufacturerID
																					AND BMQ.SampleFileNamePrefix LIKE 'CSD_%'
																					AND BMQ.SampleLoadActive = 1
			INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = BMQ.QuestionnaireRequirementID
			INNER JOIN CRM.Vista_Contract_Sales VCS ON V.AuditItemID = VCS.AuditItemID														-- V1.21
			LEFT JOIN CTE_ExistingVCS EVCS ON VCS.VEH_VIN = EVCS.VEH_VIN																	-- V1.21
												AND VCS.VISTACONTRACT_HANDOVER_DATE = EVCS.VISTACONTRACT_HANDOVER_DATE
												AND VCS.VEH_REGISTRATION_DATE = EVCS.VEH_REGISTRATION_DATE
												AND VCS.AuditItemID <> EVCS.AuditItemID
			LEFT JOIN [$(AuditDB)].Audit.Events AE ON EVCS.AuditItemID = AE.AuditItemID														-- V1.21
		WHERE BMQ.Questionnaire = 'Sales'
			AND BMQ.Market IN ('Germany','Austria','Czech Republic')
			AND (	COALESCE(V.SaleDate, V.RegistrationDate) IS NULL
					OR COALESCE(V.SaleDate, V.RegistrationDate) < DATEADD(DD, QR.EndDays, CAST(GETDATE() AS DATE)))
		

		-- MATCH STANDARD EVENTS WE ALREADY HAVE
		
		-- V1.15 Create Temporary Table for LoadedEvents
		CREATE TABLE #LoadedEvents
		(
			EventID						INT,
			EventTypeID					INT,
			EventDate					DATETIME2,
			DealerID					INT,
			RoadsideNetworkPartyID		INT,
			CRCCentrePartyID			INT,
			IAssistanceCentrePartyID	INT,
			VehicleID					INT,
			PersonPartyID				INT,
			CaseNumber					NVARCHAR(100),
			Respondent_Serial			NVARCHAR(100),
			LostLeadID					NVARCHAR(100),			-- V1.19
			LandRoverExperienceID       VARCHAR (20) NULL,      -- V1.24
			ExperienceDealerID          INT NULL				-- V1.24
		)

		-- SALES
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID)	-- V1.15	
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			COALESCE(E.EventDate, R.RegistrationDate) AS EventDate, 
			EPR.PartyID AS DealerID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
				INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'Sales')
		
		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID) AS		-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS														-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON COALESCE(V.SaleDate, V.RegistrationDate) = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.SalesDealerID = LE.DealerID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15



		-- PREOWNED																	-- V1.4
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID)		-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS DealerID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
				INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'PreOwned')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID) AS 			-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON V.SaleDate = LE.EventDate
									AND V.ODSEventTypeID = LE.EventTypeID
									AND V.MatchedODSVehicleID = LE.VehicleID
									AND V.SalesDealerID = LE.DealerID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15

		
		
		-- SERVICE
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS DealerID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
				INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'Service')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID) AS 				-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS															-- V1.2
		 (
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
			)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON V.ServiceDate = LE.EventDate
									AND V.ODSEventTypeID = LE.EventTypeID
									AND V.MatchedODSVehicleID = LE.VehicleID
									AND V.ServiceDealerID = LE.DealerID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15


		
		-- LOST LEADS							-- V1.6 
		;WITH DistinctEvents (EventID, EventTypeID, EventDate, DealerID, PersonPartyID, VehicleID, AuditItemID) AS		-- V1.19
		(
			SELECT 
				E.EventID, 
				E.EventTypeID, 
				E.EventDate, 
				EPR.PartyID AS DealerID,
				P.PartyID AS PersonPartyID,
				VPRE.VehicleID,
				MAX(AE.AuditItemID) AS AuditItemID				-- V1.19
			FROM [$(SampleDB)].[Event].[Events] E
				INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
				INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = VPRE.PartyID
				INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
				LEFT JOIN [$(AuditDB)].Audit.Events AE ON E.EventID = AE.EventID					-- V1.19
			WHERE E.EventTypeID IN (	SELECT EventTypeID 
										FROM [$(SampleDB)].[Event].vwEventTypes 
										WHERE EventCategory = 'LostLeads')
			GROUP BY E.EventID, 
				E.EventTypeID, 
				E.EventDate, 
				EPR.PartyID,
				P.PartyID,
				VPRE.VehicleID
		)
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, PersonPartyID, VehicleID, LostLeadID)			-- V1.19
		SELECT 
			DE.EventID,
			DE.EventTypeID, 
			DE.EventDate, 
			DE.DealerID,
			DE.PersonPartyID,
			DE.VehicleID,
			ISNULL(LL.LEAD_LEAD_ID,'') AS LostLeadID							-- V1.19
		FROM DistinctEvents DE
			LEFT JOIN CRM.Lost_Leads LL ON DE.AuditItemID = LL.AuditItemID		-- V1.19	-- V1.20

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, PersonPartyID, VehicleID, LostLeadID) AS 			-- V1.15	-- V1.19
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				PersonPartyID, 
				VehicleID,
				LostLeadID																		-- V1.19
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			LEFT JOIN CRM.Lost_Leads LL ON V.AuditItemID = LL.AuditItemID			-- V1.19
			INNER JOIN LoadedEvents LE ON V.LostLeadDate = LE.EventDate
									AND V.ODSEventTypeID = LE.EventTypeID
									AND V.MatchedODSPersonID = LE.PersonPartyID		-- Match lost leads events by person rather than vehicle
									AND V.MatchedODSVehicleID = LE.VehicleID		-- V1.9
									AND V.SalesDealerID = LE.DealerID
									AND ISNULL(LL.LEAD_LEAD_ID,'') = LE.LostLeadID					-- V1.19	-- V1.20
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15



		-- ROADSIDE 
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, RoadsideNetworkPartyID, VehicleID)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS RoadsideNetworkPartyID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			--LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
				--INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			--ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'Roadside')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, RoadsideNetworkPartyID, VehicleID) AS 				-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				RoadsideNetworkPartyID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS														-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON V.RoadsideDate = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.RoadsideNetworkPartyID = LE.RoadsideNetworkPartyID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15



		-- CRC  
		CREATE TABLE #CRCEventIDMatches
		(
			AuditItemID BIGINT,
			EventID		BIGINT
		)
		
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, CRCCentrePartyID, VehicleID, CaseNumber)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS CRCCentrePartyID,
			VPRE.VehicleID,
			CRC.CaseNumber							-- V1.5 - Add in Case Number as vehicle can be blank
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			INNER JOIN CRC.CRCEvents CRC ON CRC.ODSEventID = EPR.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'CRC')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, CRCCentrePartyID, VehicleID, CaseNumber) AS 				-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				CRCCentrePartyID, 
				VehicleID, 
				CaseNumber
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1				-- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0	-- Only recs where ByPassEventMatching is set OFF
		)
		INSERT INTO #CRCEventIDMatches (AuditItemID, EventID)
		SELECT V.AuditItemID, 
			LE.EventID
		FROM dbo.VWT V
			INNER JOIN CRC.CRCEvents CRCL ON CRCL.AuditItemID = V.AuditItemID     -- V1.5 
			INNER JOIN LoadedEvents LE ON V.CRCDate = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.CRCCentrePartyID = LE.CRCCentrePartyID
										AND CRCL.CaseNumber = LE.CaseNumber							-- V1.5 
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15
		
		
		
		--v1.8
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, CRCCentrePartyID, VehicleID, Respondent_Serial)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS CRCCentrePartyID,
			VPRE.VehicleID,
			CRC.Respondent_Serial							-- Add in Respondent_Serial as vehicle can be blank
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			INNER JOIN [China].[CRC_WithResponses] CRC ON CRC.ODSEventID = EPR.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'CRC')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, CRCCentrePartyID, VehicleID, Respondent_Serial) AS 			-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				CRCCentrePartyID, 
				VehicleID, 
				Respondent_Serial
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		INSERT INTO #CRCEventIDMatches (AuditItemID, EventID)
		SELECT V.AuditItemID, 
			LE.EventID
		FROM dbo.VWT V
			INNER JOIN [China].[CRC_WithResponses] CRCL ON CRCL.AuditItemID = V.AuditItemID  
			INNER JOIN LoadedEvents LE ON V.CRCDate = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.CRCCentrePartyID = LE.CRCCentrePartyID
										AND CRCL.Respondent_Serial = LE.Respondent_Serial
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID		
		--v1.8
		
		UPDATE V																					-- V1.5
		SET V.MatchedODSEventID = CM.EventID
		FROM #CRCEventIDMatches CM
			INNER JOIN dbo.VWT V ON V.AuditItemID = CM.AuditItemID
	
		DROP TABLE IF EXISTS #CRCEventIDMatches			-- V1.15

		TRUNCATE TABLE #LoadedEvents					-- V1.15
		


		-- BODYSHOP
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS DealerID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
				INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'Bodyshop')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID) AS 			-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				VehicleID
			FROM #LoadedEvents
		)
		,CTE_AllowsEventMatching AS																-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON V.BodyShopEventDate = LE.EventDate
									AND V.ODSEventTypeID = LE.EventTypeID
									AND V.MatchedODSVehicleID = LE.VehicleID
									AND V.BodyshopDealerID = LE.DealerID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID	

		TRUNCATE TABLE #LoadedEvents		-- V1.15



		-- IASSISTANCE 
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, IAssistanceCentrePartyID, VehicleID)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS IAssistanceCentrePartyID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'I-Assistance')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, IAssistanceCentrePartyID, VehicleID) AS 				-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				IAssistanceCentrePartyID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS 
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON V.IAssistanceDate = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.IAssistanceCentrePartyID = LE.IAssistanceCentrePartyID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15


		
		-- PREOWNED LOSTLEADS							-- V1.11 
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, PersonPartyID, VehicleID)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS DealerID,
			P.PartyID AS PersonPartyID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = VPRE.PartyID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
		WHERE E.EventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].[Event].vwEventTypes WHERE EventCategory = 'PreOwned LostLeads')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, PersonPartyID, VehicleID) AS 			-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				PersonPartyID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON V.LostLeadDate = LE.EventDate
									AND V.ODSEventTypeID = LE.EventTypeID
									AND V.MatchedODSPersonID = LE.PersonPartyID		-- Match PreOwned LostLeads events by person rather than vehicle
									AND V.MatchedODSVehicleID = LE.VehicleID		-- V1.9
									AND V.SalesDealerID = LE.DealerID	
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15



		-- CQI		-- V1.12
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			COALESCE(E.EventDate, R.RegistrationDate) AS EventDate, 
			EPR.PartyID AS DealerID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
				INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory IN ('CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS'))	-- V1.25

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID) AS 				-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  --AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc	V1.14
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON COALESCE(V.SaleDate, V.RegistrationDate) = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.SalesDealerID = LE.DealerID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.15



		-- MCQI		-- V1.13
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID)			-- V1.15
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			COALESCE(E.EventDate, R.RegistrationDate) AS EventDate, 
			EPR.PartyID AS DealerID,
			VPRE.VehicleID
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
				INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory IN ('MCQI 1MIS'))

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, DealerID, VehicleID) AS 			-- V1.15
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				DealerID, 
				VehicleID
			FROM #LoadedEvents
		)
		, CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  --AND BMQ.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc	V1.14
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE V
		SET V.MatchedODSEventID = LE.EventID
		FROM dbo.VWT V
			INNER JOIN LoadedEvents LE ON COALESCE(V.SaleDate, V.RegistrationDate) = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.SalesDealerID = LE.DealerID
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.16



		-- CRC General Enquiry Events 
		CREATE TABLE #GeneralEnquiryEventIDMatches
		(
			AuditItemID BIGINT,
			EventID		BIGINT
		)
		
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, CRCCentrePartyID, VehicleID, CaseNumber)			-- V1.16
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS CRCCentrePartyID,
			VPRE.VehicleID,
			GE.CaseNumber																					-- V1.18 - Add in Case Number as vehicle can be blank
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			INNER JOIN GeneralEnquiry.GeneralEnquiryEvents GE ON GE.ODSEventID = EPR.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'CRC General Enquiry')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, CRCCentrePartyID, VehicleID, CaseNumber) AS 				-- V1.16, V1.18
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				CRCCentrePartyID, 
				VehicleID,
				CaseNumber																	-- V1.18
			FROM #LoadedEvents
		)
		,CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1				-- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0	-- Only recs where ByPassEventMatching is set OFF
		)
		INSERT INTO #GeneralEnquiryEventIDMatches (AuditItemID, EventID)
		SELECT V.AuditItemID, 
			LE.EventID
		FROM dbo.VWT V
			INNER JOIN GeneralEnquiry.GeneralEnquiryEvents GE ON GE.AuditItemID = V.AuditItemID     -- V1.5 
			INNER JOIN LoadedEvents LE ON V.GeneralEnquiryDate = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.CRCCentrePartyID = LE.CRCCentrePartyID
										AND GE.CaseNumber = LE.CaseNumber							-- V1.18
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.16			
		
		UPDATE V																					-- V1.5
		SET V.MatchedODSEventID = CM.EventID
		FROM #GeneralEnquiryEventIDMatches CM
			INNER JOIN dbo.VWT V ON V.AuditItemID = CM.AuditItemID
	
		DROP TABLE IF EXISTS #GeneralEnquiryEventIDMatches			-- V1.16

		TRUNCATE TABLE #LoadedEvents								-- V1.16


		--LAND ROVER EXPERIENCE
		CREATE TABLE #LandRoverExperienceEventIDMatches
		(
			AuditItemID BIGINT,
			EventID		BIGINT
		)
		
		INSERT INTO #LoadedEvents (EventID, EventTypeID, EventDate, ExperienceDealerID, VehicleID, LandRoverExperienceID)			-- V1.16
		SELECT DISTINCT
			E.EventID, 
			E.EventTypeID, 
			E.EventDate, 
			EPR.PartyID AS ExperienceDealerID,
			VPRE.VehicleID,
			AI.LandRoverExperienceID																					-- V1.18 - Add in Case Number as vehicle can be blank
		FROM [$(SampleDB)].[Event].[Events] E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].[Event].EventPartyRoles EPR ON E.EventID = EPR.EventID
			--INNER JOIN GeneralEnquiry.GeneralEnquiryEvents GE ON GE.ODSEventID = EPR.EventID
			INNER JOIN [$(SampleDB)].[Event].[AdditionalInfoSales] AI ON E.EventID = AI.EventID
		WHERE E.EventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].[Event].vwEventTypes 
									WHERE EventCategory = 'Land Rover Experience')

		;WITH LoadedEvents (EventID, EventTypeID, EventDate, ExperienceDealerID, VehicleID, LandRoverExperienceID) AS 				-- V1.16, V1.18
		(	
			SELECT EventID, 
				EventTypeID, 
				EventDate, 
				ExperienceDealerID, 
				VehicleID,
				LandRoverExperienceID																	-- V1.18
			FROM #LoadedEvents
		)
		,CTE_AllowsEventMatching AS															-- V1.2
		(
			SELECT V.AuditItemID, 
				ISNULL(BMQ.BypassEventMatching, 0) AS BypassEventMatching 
			FROM dbo.VWT V
				INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerID
				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
				INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON Q.Questionnaire = EC.EventCategory
				INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BrandID = B.BrandID
																		  AND BMQ.MarketID = M.MarketID
																		  AND BMQ.QuestionnaireID = Q.QuestionnaireID 
																		  AND BMQ.SelectionOutputActive = 1				-- to ensure we do not pick up Enprecis, etc
																		  AND ISNULL(BMQ.BypassEventMatching, 0) = 0	-- Only recs where ByPassEventMatching is set OFF
		)
		INSERT INTO #LandRoverExperienceEventIDMatches (AuditItemID, EventID)
		SELECT V.AuditItemID, 
			LE.EventID
		FROM dbo.VWT V
			--INNER JOIN GeneralEnquiry.GeneralEnquiryEvents GE ON GE.AuditItemID = V.AuditItemID     -- V1.5 
			INNER JOIN LoadedEvents LE ON V.GeneralEnquiryDate = LE.EventDate
										AND V.ODSEventTypeID = LE.EventTypeID
										AND V.MatchedODSVehicleID = LE.VehicleID
										AND V.ExperienceDealerID = LE.ExperienceDealerID
										AND V.LandRoverExperienceID = LE.LandRoverExperienceID							-- V1.18
			INNER JOIN CTE_AllowsEventMatching AM ON AM.AuditItemID = V.AuditItemID					-- V1.2

		TRUNCATE TABLE #LoadedEvents			-- V1.16			
		
		UPDATE V																					-- V1.5
		SET V.MatchedODSEventID = CM.EventID
		FROM #LandRoverExperienceEventIDMatches CM
			INNER JOIN dbo.VWT V ON V.AuditItemID = CM.AuditItemID
	
		DROP TABLE IF EXISTS #LandRoverExperienceEventIDMatches			-- V1.16

		TRUNCATE TABLE #LoadedEvents								-- V1.16




		/* LOAD MATCHED AND NEW EVENTS */
		INSERT INTO [$(SampleDB)].[Event].vwDA_Events
		(
			AuditItemID, 
			EventID, 
			EventDate, 
			EventDateOrig,
			EventTypeID, 
			TypeOfSaleOrig,
			InvoiceDate, 
			PartyID, 
			VehicleRoleTypeID, 
			VehicleID,
			DealerID,  
			AFRLCode,
			FromDate,
			CRCCaseNumber,							-- V1.5 - CRC CaseNumber for determining unique events
			LostLeadID,								-- V1.19
			LandRoverExperienceID					-- V1.24
		)
		SELECT 
			V.AuditItemID, 
			ISNULL(V.MatchedODSEventID, 0), 
			V.EventDate, 
			V.EventDateOrig,
			V.EventTypeID, 
			V.TypeOfSaleOrig,
			V.InvoiceDate, 
			V.PartyID,
			V.VehicleRoleTypeID, 
			V.VehicleID,
			CASE	WHEN CRC.ClosedBy IS NOT NULL													-- Added new code to include the CRC Owner (checksum) in the DealerID 
						THEN CAST(CHECKSUM (CRC.ClosedBy) AS BIGINT) + CAST(V.DealerID AS BIGINT)	-- to ensure we don't match to the wrong call as we potentially have no VIN for CRC.
						ELSE CASE	WHEN GE.EmployeeResponsibleName IS NOT NULL						-- V1.16
										THEN CAST(CHECKSUM (GE.EmployeeResponsibleName) AS BIGINT) + CAST(V.DealerID AS BIGINT)
										ELSE CAST(V.DealerID AS BIGINT) 
									END 
					END AS DealerID,	
			V.AFRLCode,														-- V1.3
			CURRENT_TIMESTAMP AS FromDate,
			COALESCE(CRC.CaseNumber, CWR.Respondent_Serial, GE.CaseNumber) AS CRCCaseNumber,				-- V1.5 - CRC CaseNumber for determining unique events  -- V1.8 Including Respondent_Serial	-- V1.18
			ISNULL(LL.LEAD_LEAD_ID,'') AS LostLeadID,																-- V1.19	-- V1.20
			V.LandRoverExperienceID -- V1.24
		FROM Load.vwVehiclePartyRoleEvents V
			LEFT JOIN CRC.CRCEvents CRC ON CRC.AuditItemID = V.AuditItemID
			LEFT JOIN China.CRC_WithResponses CWR ON CWR.AuditItemID = V.AuditItemID
			LEFT JOIN GeneralEnquiry.GeneralEnquiryEvents GE ON GE.AuditItemID = V.AuditItemID
			LEFT JOIN CRM.Lost_Leads LL ON LL.AuditItemID = V.AuditItemID									-- V1.19
		WHERE V.EventTypeID > 0
		ORDER BY V.EventTypeID
		
	COMMIT TRAN

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


