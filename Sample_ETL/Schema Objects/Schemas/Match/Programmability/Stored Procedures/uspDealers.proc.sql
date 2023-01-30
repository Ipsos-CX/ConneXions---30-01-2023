CREATE PROCEDURE [Match].[uspDealers]
AS

/*
		Purpose:	Match the dealer codes in the VWT table against the dealer code held in DealerNetworks
	
		Version			Date			Developer			Comment
LIVE	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspCODING_Dealers
LIVE	1.1				01-05-2013		Chris Ross			Bug 8926 - Updated to do two passes.  Firstly matching on Dealer Country only. 
															Then the remaining uncoded will match where the dealer has no country.
LIVE	1.2				13-01-2014		Ali Yuksel			Bug 9733 - Second pass removed 
LIVE	1.3				23-07-2015		Chris Ross			Bug 11675 - Code Dealers with "unknown dealer" party ID where no match
LIVE	1.4				30-11-2015		Chris Ross			BUG 12110 - Added in additional Dealer coding (adapted from uspAddMissingDealerToEvents)
LIVE	1.5				26-01-2016		Chris Ross			BUG 12038 - Add in extra code for PreOwned dealer lookup and Constrain PreOwned and Sales by Category type.
LIVE	1.6				11-07-2016		Ben King			Patch added
LIVE	1.7				19-08-2016		Chris Ross			BUG 12859 - Add in LoadLeads to Sales Dealer lookups	
LIVE	1.8				24-08-2017		Eddie Thomas		BUG 14141 - Add in Bodyshop Dealer lookups
LIVE	1.9				16-11-2017		Chris Ledger		BUG 14347 - Code Uncoded Inter-Company/Own Use Dealers Matched to Dummy Dealer (ICOU)
LIVE	1.10			02-10-2019		Chris Ledger		BUG 15490 - Add in PreOwned LostLeads to PreOwned Dealer lookups
LIVE	1.11			17-10-2019		Chris Ledger		BUG 16673 - Add in CQI to Sales Dealer lookups
LIVE	1.12			10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
LIVE	1.13			19-02-2020		Chris Ledger		BUG 17942 - Add in MCQI to Sales Dealer lookups
LIVE	1.14			03-02-2021		Chris Ledger		TASK 249 - Remove matching on GDD Code
LIVE	1.15			16-08-2021		Chris Ledger		TASK 583 - Use Belgium as Country for Luxembourg to match previous logic
LIVE	1.16			26-05-2022		Eddie Thomas		TASK 877 - Add dealer decoding for Land Rover EXPERIENCE Event Type
LIVE	1.17			31-10-2022		Chris Ledger		TASK 1049 - Add in terminated dealers to CQI dealer matching.
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
		
			-- Declaring Variable to get OriginatorPartyID of Jaguar/Land Rover Australia Service
			DECLARE @JR_DealerCodeOriginatorPartyID INT
			DECLARE @LR_DealerCodeOriginatorPartyID INT
			
			-- Assigning the "Jaguar Australia"  DealerCodeOriginatorPartyID
			SELECT TOP 1 @JR_DealerCodeOriginatorPartyID = PartyID FROM [$(SampleDB)].Party.Organisations WHERE OrganisationName = 'Jaguar Australia'
			
			-- Assigning the "Jaguar Australia"  DealerCodeOriginatorPartyID
			SELECT TOP 1 @LR_DealerCodeOriginatorPartyID = PartyID FROM [$(SampleDB)].Party.Organisations WHERE OrganisationName = 'Land Rover Australia'

			
			----------------------------------------------------------------------------------------------------------------
			--- FIRST PASS - Match where country matches -----------------------			
			-- MATCH SALES DEALERS
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																		 AND EC.EventCategory IN ('Sales', 'LostLeads')  -- V1.5, V1.7, V1.11, V1.17
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15


			-- V1.17 MATCH CQI SALES DEALERS
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwCQIDealers D		-- V1.17
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																		 AND EC.EventCategory IN ('CQI 3MIS', 'CQI 24MIS')  -- V1.5, V1.7, V1.11, V1.17
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15


			-- MATCH PREOWNED DEALERS
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10		
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER    -- V1.5
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
			
		
			-- MATCH SERVICE DEALERS
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM Match.vwDealers D
				INNER JOIN dbo.VWT V ON D.DealerCode = CASE	WHEN ServiceDealerCodeOriginatorPartyID IN (@JR_DealerCodeOriginatorPartyID,@LR_DealerCodeOriginatorPartyID) THEN RIGHT(LTRIM(RTRIM(V.ServiceDealerCode)),LEN(LTRIM(RTRIM(V.ServiceDealerCode)))-1) 
															ELSE LTRIM(RTRIM(V.ServiceDealerCode))  END 
			WHERE D.PartyIDTo = V.ServiceDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
		

			-- MATCH BODYSHOP DEALERS
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.BodyshopDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID	
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'		
			WHERE D.PartyIDTo = V.BodyshopDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15


			-- V1.16 MATCH EXPERIENCE DEALERS
			UPDATE V
			SET V.ExperienceDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.ExperienceDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID	
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID	
																		 AND EC.EventCategory IN ('Land Rover EXPERIENCE')  -- 
			WHERE D.PartyIDTo = V.ExperienceDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwExperienceDealerRoleTypes)  -- EXPERIENCE DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
			----------------------------------------------------------------------------------------------------------------


			----------------------------------------------------------------------------------------------------------------
			-- for "With Responses" sample data 
			-- ================================
			-- ...code Dealer with "unknown dealer" dealer partyID, if not coded in the first pass, above.
			----------------------------------------------------------------------------------------------------------------
			UPDATE V
			SET V.SalesDealerID = CASE WHEN V.ODSEventTypeID = 1 THEN D.OutletPartyID ELSE 0 END,
				V.ServiceDealerID = CASE WHEN V.ODSEventTypeID = 2 THEN D.OutletPartyID ELSE 0 END
			FROM [dbo].VWT V
				INNER JOIN [$(SampleDB)].[Event].EventTypes ET ON ET.EventTypeID = V.ODSEventTypeID						-- V1.5
															AND ET.EventType IN ('Sales', 'Service', 'PreOwned', 'LostLeads', 'PreOwned LostLeads', 'CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.10, V1.11
				INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = V.AuditID 
															AND F.FileName LIKE 'GSL_Resp%'
				INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = V.CountryID
				INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.Market = C.Country
															AND D.ManufacturerPartyID = V.ManufacturerID
															AND D.Outlet = 'Unknown Dealer'
															AND D.OutletFunction = CASE WHEN ET.EventType = 'Service' THEN 'AfterSales' ELSE ET.EventType END
			WHERE (ET.EventType IN ('Sales', 'PreOwned', 'LostLeads', 'PreOwned LostLeads', 'CQI 3MIS', 'CQI 24MIS') AND ISNULL(V.SalesDealerID, 0) = 0)					-- V1.10, V1.11
				OR (ET.EventType = 'Service' AND ISNULL(V.ServiceDealerID, 0) = 0)
			----------------------------------------------------------------------------------------------------------------


			----------------------------------------------------------------------------------------------------------------
			----- SECOND PASS - Where not matched, then link where dealer country is not set and also use ManfucturerPartyID 
			-----               rather than the Sale/ServiceDealerCodeOriginatorPartyID
			----------------------------------------------------------------------------------------------------------------
			
			-- MATCH SALES DEALERS - With country using ManufacturerID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads')		-- V1.5	, V1.7, V1.11, V1.17
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0


			-- V1.17 MATCH CQI SALES DEALERS - With country using ManufacturerID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwCQIDealers D		-- V1.17
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('CQI 3MIS', 'CQI 24MIS')		-- V1.5	, V1.7, V1.11, V1.17
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0


			-- MATCH PREOWNED DEALERS - With country using ManufacturerID							-- V1.5
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10		
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER    
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0


			-- MATCH SERVICE DEALERS - With country using ManufacturerID
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM Match.vwDealers D
				INNER JOIN dbo.VWT V ON D.DealerCode = CASE	WHEN ServiceDealerCodeOriginatorPartyID IN (@JR_DealerCodeOriginatorPartyID,@LR_DealerCodeOriginatorPartyID) THEN RIGHT(LTRIM(RTRIM(V.ServiceDealerCode)),LEN(LTRIM(RTRIM(V.ServiceDealerCode)))-1) 
															ELSE LTRIM(RTRIM(V.ServiceDealerCode)) END 
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.ServiceDealerID, 0) = 0
			
			
			-- MATCH BODYSHOP DEALERS - With country using ManufacturerID
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.BodyshopDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID	
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'		
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER    
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.BodyshopDealerID, 0) = 0	


			-- V1.16 MATCH EXPERIENCE DEALERS - With country using ManufacturerID
			UPDATE V
			SET V.ExperienceDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.ExperienceDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID	
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Land Rover Experience'		
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwExperienceDealerRoleTypes)  -- EXPERIENCE DEALER    
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.ExperienceDealerID, 0) = 0
			----------------------------------------------------------------------------------------------------------------
			

			----------------------------------------------------------------------------------------------------------------
			-- MATCH SALES DEALERS - No country - using DealerCodeOriginatorPartyID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads')	-- V1.5, V1.7, V1.11, V1.17
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0
			
			
			-- V1.17 MATCH CQI SALES DEALERS - No country - using DealerCodeOriginatorPartyID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwCQIDealers D		-- V1.17
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.11, V1.17	
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0
			
			
			-- MATCH PREOWNED DEALERS - No country - using DealerCodeOriginatorPartyID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10		
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0

			
			-- MATCH SERVICE DEALERS - No country - using DealerCodeOriginatorPartyID
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM Match.vwDealers D
				INNER JOIN dbo.VWT V ON D.DealerCode = CASE WHEN ServiceDealerCodeOriginatorPartyID IN (@JR_DealerCodeOriginatorPartyID,@LR_DealerCodeOriginatorPartyID) THEN RIGHT(LTRIM(RTRIM(V.ServiceDealerCode)),LEN(LTRIM(RTRIM(V.ServiceDealerCode)))-1) 
															ELSE LTRIM(RTRIM(V.ServiceDealerCode)) END 
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.ServiceDealerID, 0) = 0
		
	
			-- MATCH BODYSHOP DEALERS - No country - using DealerCodeOriginatorPartyID
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.BodyshopDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'
			WHERE D.PartyIDTo = V.BodyshopDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.BodyshopDealerID, 0) = 0


			-- V1.16 MATCH EXPERIENCE DEALERS - No country - using DealerCodeOriginatorPartyID
			UPDATE V
			SET V.ExperienceDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.ExperienceDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Land Rover Experience'
			WHERE D.PartyIDTo = V.ExperienceDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwExperienceDealerRoleTypes)  -- EXPERIENCE DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.ExperienceDealerID, 0) = 0
			----------------------------------------------------------------------------------------------------------------


			----------------------------------------------------------------------------------------------------------------
			-- MATCH SALES DEALERS - No country - using ManufacturerID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads')	-- V1.5	, V1.7, V1.11, V1.17
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0


			-- V1.17 MATCH CQI SALES DEALERS - No country - using ManufacturerID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwCQIDealers D		-- V1.17
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('CQI 3MIS', 'CQI 24MIS')	-- V1.5	, V1.7, V1.11, V1.17
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0


			-- MATCH PREOWNED DEALERS - No country - using ManufacturerID
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10		
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0


			-- MATCH SERVICE DEALERS - No country - using ManufacturerID
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM Match.vwDealers D
				INNER JOIN dbo.VWT V ON D.DealerCode = CASE WHEN ServiceDealerCodeOriginatorPartyID IN (@JR_DealerCodeOriginatorPartyID,@LR_DealerCodeOriginatorPartyID) THEN RIGHT(LTRIM(RTRIM(V.ServiceDealerCode)),LEN(LTRIM(RTRIM(V.ServiceDealerCode)))-1) 
															ELSE LTRIM(RTRIM(V.ServiceDealerCode))  END 
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.ServiceDealerID, 0) = 0
		
					
			-- MATCH BODYSHOP DEALERS - No country - using ManufacturerID
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.BodyshopDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.BodyshopDealerID, 0) = 0
			

			-- V1.16 MATCH EXPERIENCE DEALERS - No country - using ManufacturerID
			UPDATE V
			SET V.ExperienceDealerID = D.DealerID
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.ExperienceDealerCode)) = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Land Rover Experience'
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwExperienceDealerRoleTypes)  -- EXPERIENCE DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.ExperienceDealerID, 0) = 0


			--------------------------------------------------------------------------------------------------------------
			-- IN ADDITION, TRY THE GDD CODE FROM THE DEALER HIERARCHY TABLE V1.14 - REMOVED
			--------------------------------------------------------------------------------------------------------------
			/*
			-- MATCH SALES DEALERS
			UPDATE V
			SET V.SalesDealerID = D.OutletPartyID
			FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D 
				INNER JOIN Match.vwDealers VW ON D.OutletPartyID = VW.DealerID
													AND D.OutletFunctionID = VW.RoleTypeIDFrom											
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.OutletCode_GDD
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads', 'CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.11
			WHERE VW.PartyIDTo = V.ManufacturerID
				AND VW.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND VW.CountryID = V.CountryID
				AND D.OutletPartyID = D.TransferPartyID
				AND ISNULL(V.SalesDealerID, 0) = 0


			-- MATCH PREOWNED DEALERS
			UPDATE V
			SET V.SalesDealerID = D.OutletPartyID
			FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D 
				INNER JOIN Match.vwDealers VW ON D.OutletPartyID = VW.DealerID
													AND D.OutletFunctionID = VW.RoleTypeIDFrom											
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.SalesDealerCode)) = D.OutletCode_GDD
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10		
			WHERE VW.PartyIDTo = V.ManufacturerID
				AND VW.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER
				AND VW.CountryID = V.CountryID
				AND D.OutletPartyID = D.TransferPartyID
				AND ISNULL(V.SalesDealerID, 0) = 0

			
			-- MATCH SERVICE DEALERS
			UPDATE V
			SET V.ServiceDealerID = D.OutletPartyID
			FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D 
				INNER JOIN Match.vwDealers VW ON D.OutletPartyID = VW.DealerID
													AND D.OutletFunctionID = VW.RoleTypeIDFrom											
				INNER JOIN dbo.VWT V ON D.OutletCode_GDD = CASE WHEN ServiceDealerCodeOriginatorPartyID IN (@JR_DealerCodeOriginatorPartyID,@LR_DealerCodeOriginatorPartyID) THEN RIGHT(LTRIM(RTRIM(V.ServiceDealerCode)),LEN(LTRIM(RTRIM(V.ServiceDealerCode)))-1) 
																ELSE LTRIM(RTRIM(V.ServiceDealerCode))  END 
			WHERE VW.PartyIDTo = V.ManufacturerID
				AND VW.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND VW.CountryID = V.CountryID
				AND D.OutletPartyID = D.TransferPartyID
				AND ISNULL(V.ServiceDealerID, 0) = 0
			
			
			-- MATCH BODYSHOP DEALERS
			UPDATE V
			SET V.BodyshopDealerID = D.OutletPartyID
			FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D 
				INNER JOIN Match.vwDealers VW ON D.OutletPartyID = VW.DealerID
													AND D.OutletFunctionID = VW.RoleTypeIDFrom											
				INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.BodyshopDealerCode)) = D.OutletCode_GDD
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory = 'Bodyshop'					-- V1.5	
			WHERE VW.PartyIDTo = V.ManufacturerID
				AND VW.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND VW.CountryID = V.CountryID
				AND D.OutletPartyID = D.TransferPartyID
				AND ISNULL(V.BodyshopDealerID, 0) = 0
			*/

			--------------------------------------------------------------------------------------------------------------
			-- 27-06-2016 - PATCH IN PLACE FROM NUMERIC CAST ERROR. VWT TO VWDEALERS FALLING OVER FROM CAST CONVERSION   -- V1.6
			-- V1.17 DECIDED NOT TO INCLUDE CQI TERMINATED DEALERS
			--------------------------------------------------------------------------------------------------------------
			SELECT DealerID,
				RoleTypeIDFrom,      
				PartyIDTo,
				RoleTypeIDTo, 
				PartyRelationshipTypeID,   
				CAST(LTRIM(RTRIM(D.DealerCode)) AS BIGINT) AS DealerCode,
				CountryID                        
			INTO #DEALERS2
			FROM Match.vwDealers D 
			WHERE [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1 


			--------------------------------------------------------------------------------------------------------------
			-- IN ADDITION LETS STRIP OUT THE LEADING ZERO AND COMPARE ANY NUMERIC DEALER CODES
			--------------------------------------------------------------------------------------------------------------

			-- MATCH SALES DEALERS - Dealer Code Orig party and Country ID Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads', 'CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.11
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH PREOWNED DEALERS - Dealer Code Orig party and Country ID Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10	
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH SERVICE DEALERS  - Dealer Code Orig party and Country ID Match
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.ServiceDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
			WHERE D.PartyIDTo = V.ServiceDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.ServiceDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.ServiceDealerCode) = 1;


			-- MATCH BODYSHOP DEALERS - Dealer Code Orig party and Country ID Match
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM #DEALERS2 D
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.BodyshopDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'
			WHERE D.PartyIDTo = V.BodyshopDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.BodyshopDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.BodyshopDealerCode) = 1;		
			--------------------------------------------------------------------------------------------------------------


			-- MATCH SALES DEALERS - Manufacturer party ID and Country ID Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads', 'CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.11
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH PREOWNED DEALERS - Manufacturer party ID and Country ID Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10		
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH SERVICE DEALERS  - Dealer Code Orig party and Country ID Match
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.ServiceDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.ServiceDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.ServiceDealerCode) = 1;
		
			
			-- MATCH BODYSHOP DEALERS - Manufacturer party ID and Country ID Match
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.BodyshopDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.BodyshopDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.BodyshopDealerCode) = 1;		
			--------------------------------------------------------------------------------------------------------------


			-- MATCH SALES DEALERS - Dealer Code Orig party and NO Country Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads', 'CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.11
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH PREOWNED DEALERS - Dealer Code Orig party and NO Country Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10		
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH SERVICE DEALERS  - Dealer Code Orig party and NO Country Match
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.ServiceDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
			WHERE D.PartyIDTo = V.ServiceDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.ServiceDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.ServiceDealerCode) = 1;


			-- MATCH BODYSHOP DEALERS - Dealer Code Orig party and NO Country Match
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.BodyshopDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'
			WHERE D.PartyIDTo = V.BodyshopDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.BodyshopDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.BodyshopDealerCode) = 1;

			
			--------------------------------------------------------------------------------------------------------------
			-- MATCH SALES DEALERS - Manufacturer party ID and NO Country Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads', 'CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.11
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH PREOWNED DEALERS - Manufacturer party ID and NO Country Match
			UPDATE V
			SET V.SalesDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.SalesDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID					-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID					-- V1.5
																	 AND EC.EventCategory IN ('PreOwned', 'PreOwned LostLeads')		-- V1.5, V1.10	
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes)  -- PREOWNED DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.SalesDealerCode) = 1;


			-- MATCH SERVICE DEALERS  - Dealer Code Orig party and NO Country Match
			UPDATE V
			SET V.ServiceDealerID = D.DealerID
			FROM #DEALERS2 D -- V1.6
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.ServiceDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes)  -- SERVICE DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.ServiceDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.ServiceDealerCode) = 1;
			
			
			-- MATCH BODYSHOP DEALERS - Manufacturer party ID and NO Country Match
			UPDATE V
			SET V.BodyshopDealerID = D.DealerID
			FROM #DEALERS2 D
				INNER JOIN dbo.VWT V ON CAST(LTRIM(RTRIM(V.BodyshopDealerCode)) AS BIGINT) = CAST(D.DealerCode AS BIGINT)
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
																	 AND EC.EventCategory = 'Bodyshop'	
			WHERE D.PartyIDTo = V.ManufacturerID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyshopDealerRoleTypes)  -- BODYSHOP DEALER
				AND (D.CountryID IS NULL)
				AND ISNULL(V.BodyshopDealerID, 0) = 0
				AND [$(SampleDB)].dbo.udfIsNumeric(D.DealerCode) = 1
				AND [$(SampleDB)].dbo.udfIsNumeric(V.BodyshopDealerCode) = 1;


			-------------------------------------------------------------------------
			-- V1.9 MATCH UNCODED Inter-Company / Own Use SALES DEALERS (ICOU)
			-------------------------------------------------------------------------
			UPDATE V
			SET V.SalesDealerID = D.DealerID, V.SalesDealerCode = D.DealerCode
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON 'ICOU' = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads')	-- V1.5, V1.7, V1.11, V1.17
				INNER JOIN CRM.Vista_Contract_Sales VCS ON V.AuditItemID = VCS.AuditItemID
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND VCS.VEH_SALE_TYPE_DESC = 'Inter-Company / Own Use'									   -- INTER-COMPANY / OWN USE SALES TYPE
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0
			-------------------------------------------------------------------------


			-------------------------------------------------------------------------
			-- V1.17 MATCH UNCODED Inter-Company / Own Use SALES DEALERS (ICOU)
			-------------------------------------------------------------------------
			UPDATE V
			SET V.SalesDealerID = D.DealerID, V.SalesDealerCode = D.DealerCode
			FROM Match.vwCQIDealers D			-- V1.17 
				INNER JOIN dbo.VWT V ON 'ICOU' = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		-- V1.5
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID		-- V1.5
																	 AND EC.EventCategory IN ('Sales', 'LostLeads', 'CQI 3MIS', 'CQI 24MIS')	-- V1.5, V1.7, V1.11, V1.17
				INNER JOIN CRM.Vista_Contract_Sales VCS ON V.AuditItemID = VCS.AuditItemID
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND VCS.VEH_SALE_TYPE_DESC = 'Inter-Company / Own Use'									   -- INTER-COMPANY / OWN USE SALES TYPE
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0
			-------------------------------------------------------------------------


			-------------------------------------------------------------------------
			-- V1.13 MATCH UNCODED Inter-Company / Own Use SALES DEALERS (ICOU) FOR MCQI 1MIS
			-------------------------------------------------------------------------
			UPDATE V
			SET V.SalesDealerID = D.DealerID, V.SalesDealerCode = D.DealerCode
			FROM Match.vwDealers D 
				INNER JOIN dbo.VWT V ON 'ICOU' = D.DealerCode
				INNER JOIN [$(SampleDB)].[Event].EventTypeCategories ETC ON ETC.EventTypeID = V.ODSEventTypeID		
				INNER JOIN [$(SampleDB)].[Event].EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
			WHERE D.PartyIDTo = V.SalesDealerCodeOriginatorPartyID
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = REPLACE(V.CountryID, (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Luxembourg'), (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')))  -- V1.15
				AND ISNULL(V.SalesDealerID, 0) = 0
				AND EC.EventCategory = 'MCQI 1MIS'
			-------------------------------------------------------------------------

			
		COMMIT TRAN

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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
GO

