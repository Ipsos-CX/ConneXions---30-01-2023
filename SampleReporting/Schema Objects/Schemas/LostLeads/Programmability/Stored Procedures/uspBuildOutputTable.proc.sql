CREATE PROCEDURE [LostLeads].[uspBuildOutputTable]
AS 
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY


/*
	Purpose:	Populate the LostLeads.OutputBase table for output
		
	Version		Date				Developer			Comment
	1.0			06/03/2018			Chris Ross			Created (See BUG 14413)
	1.1			05/09/2018			Chris Ross			BUG 14966 - Add new data check on Brand and Model Brand match.
	1.3			15/01/2020			Chris Ledger 		BUG 15372 - Correct incorrect cases
*/



		------------------------------------------------------------
		-- Clear down the output base table 
		------------------------------------------------------------
		TRUNCATE TABLE LostLeads.OutputBase 


		------------------------------------------------------------
		-- Initial build of base data 
		------------------------------------------------------------

		;WITH CTE_StatusesByPrecedence
		AS (
			SELECT EventID, CaseID, CLS.LeadStatusID, OutputAgencyCode, DateAddedForOutput,
					ROW_NUMBER() OVER(PARTITION BY CLS.EventID ORDER BY LS.Precedence) AS RowID
			FROM LostLeads.CaseLostLeadStatuses CLS
			INNER JOIN LostLeads.LostLeadStatuses LS ON LS.LeadStatusID = CLS.LeadStatusID
			WHERE OutputDate is NULL
		),
		CTE_StatusForOutput
		AS (
			SELECT EventID, CaseID, LeadStatusID, OutputAgencyCode, DateAddedForOutput
			FROM CTE_StatusesByPrecedence
			WHERE RowID = 1
		)
		INSERT INTO LostLeads.OutputBase (EventID, CaseID, LostLeadStatusID, ValidationFailed, ValidationFailReasons, LostLeadAgency, LeadStatus, ContactedByGfKFlag, PassedToLLAFlag, PassedToLLATimestamp, VehicleSaleType, AuditItemID)
		SELECT	sfo.EventID, 
				sfo.CaseID, 
				sfo.LeadStatusID, 
				0 AS ValidationFailed,
				'' AS ValidationFailReasons,
				ISNULL(CONVERT(NVARCHAR(5), lla.ID), '') AS OutputAgencyCode, 
				lls.LeadStatusCRMKeyValue, 
				lls.ContactedByGfKFlag,
				lls.PassedToLLAFlag,
				CASE WHEN lls.PassedToLLAFlag = 'X' 
					 THEN CONVERT(NVARCHAR(14), REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), CONVERT(DATETIME, sfo.DateAddedForOutput, 112), 126), '-', ''), 'T', ''), ':', '')) 
					 ELSE '' END AS PassedToLLATimestamp,
				'NEW' AS VehicleSaleType,
				ais.ParentAuditItemID
		FROM CTE_StatusForOutput sfo
		INNER JOIN LostLeads.LostLeadStatuses lls ON lls.LeadStatusID = sfo.LeadStatusID
		LEFT JOIN [$(SampleDB)].Event.AdditionalInfoSales ais ON ais.EventID = sfo.EventID
		LEFT JOIN [$(SampleDB)].SelectionOutput.LostLeadAgencies lla ON lla.AgencyShortName = sfo.OutputAgencyCode

		
	
		-------------------------------------------------------------------------
		-- Get the latest AuditItemID for the Lost Lead records where we have not
		-- been able to set the AuditItemID using the Event ParentAuditItemID
		-- (in the AdditionalInfoSales table).  This is to cater for historical 
		-- data records where it will not have been set.
		-------------------------------------------------------------------------

		;WITH CTE_OrderAuditItemIDs												
		AS (
			SELECT	ob.EventID, 
					sl.AuditItemID,
					ROW_NUMBER() OVER(PARTITION BY ob.EventID ORDER BY ISNULL(sl.CaseID, 0) DESC, sl.AuditItemID DESC) AS RowID       ----- USE THE MAX AuditItemID RECORD - AND FIRSTLY FOR THE RECORDS THAT HAVE A CASEID (IF ONE EXISTS) - to match selection output proc.
			FROM LostLeads.OutputBase ob
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sl ON sl.MatchedODSEventID = ob.EventID
			WHERE ob.AuditItemID IS NULL
		)
		UPDATE b
		SET b.AuditItemID = ai.AuditItemID 
		FROM CTE_OrderAuditItemIDs ai
		INNER JOIN LostLeads.OutputBase b ON b.EventID = ai.EventID 
		WHERE ai.RowID = 1
	

		--------------------------------------------------------
		-- Initial population of columns in output table 
		--------------------------------------------------------

		UPDATE ob
		SET		ob.RegionCode = rc.RegionCode, 
				ob.MarketCode = rc.MarketCode, 
				ob.CountryCode = c.ISOAlpha2, 
				ob.SourceSystemLeadID = ISNULL(acr.CustomerIdentifier, ''),
				ob.Brand = bc.KeyValue, 
				ob.Nameplate = np.KeyValue, 
				ob.LeadOrigin = '',
				ob.RetailerPAGNumber = d.PAGCode,
				ob.RetailerCICode = d.OutletCode_GDD,
				ob.RetailerBrand = bcd.KeyValue,
				ob.LeadStartTimestamp = '',		-- Set to blank for now
				ob.LeadLostTimestamp = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), CONVERT(DATETIME, sl.LostLeadDate, 112), 126), '-', ''), 'T', ''), ':', ''),
				ob.ReasonsCode = '',
				ob.ResurrectedFlag = '',
				ob.LastUpdatedByLLA = '',
				ob.BoughtElsewhereCompetitorFlag = '',
				ob.BoughtElsewhereJLRFlag = '',
				ob.VehicleLostBrand = '',
				ob.VehicleLostModelRange = ''
		FROM LostLeads.OutputBase ob
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sl ON sl.AuditItemID = ob.AuditItemID
		INNER JOIN [$(SampleDB)].dbo.Markets m ON m.Market = sl.Market
		LEFT JOIN LostLeads.CRMMarketRegionCodes rc ON rc.MarketID = m.MarketID
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.CountryID = m.CountryID
		LEFT JOIN LostLeads.CRMBrandCodes bc ON bc.Brand = sl.Brand
		LEFT JOIN LostLeads.CRMNameplateCodes np ON np.ConnexionsModelID = sl.MatchedODSModelID
		--LEFT JOIN LostLeads.CRMLeadOriginCodes lo ON lo.LeadOrigin = 'Central (JLR)'										--- Set to blank for now.
		LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers d ON d.OutletPartyID = sl.SalesDealerID AND d.[OutletFunction] = 'Sales'
		LEFT JOIN [$(SampleDB)].dbo.Brands b ON b.ManufacturerPartyID = d.ManufacturerPartyID
		LEFT JOIN LostLeads.CRMBrandCodes bcd ON bcd.BrandID = b.BrandID
		LEFT JOIN [$(AuditDB)].Audit.CustomerRelationships acr ON acr.AuditItemID = ob.AuditItemID


		--------------------------------------------------------------------------------
		-- Lost Lead Date of Creation (from Additional Invoice table)							
		--------------------------------------------------------------------------------
		UPDATE ob
		SET ob.LeadStartTimestamp = CONVERT(NVARCHAR(14), SUBSTRING(LostLead_DateOfLeadCreation, 7,4)+ SUBSTRING(LostLead_DateOfLeadCreation, 4,2)+SUBSTRING(LostLead_DateOfLeadCreation, 1,2)+'000000') 
		FROM LostLeads.OutputBase ob
		INNER JOIN [$(SampleDB)].Event.AdditionalInfoSales ais ON ais.EventID = ob.EventID
		WHERE ISDATE(CONVERT(NVARCHAR(14), SUBSTRING(LostLead_DateOfLeadCreation, 7,4)+ SUBSTRING(LostLead_DateOfLeadCreation, 4,2)+SUBSTRING(LostLead_DateOfLeadCreation, 1,2))) = 1
		

		--------------------------------------------------------------------------------------
		-- Split out reason codes to a row per code and where matched convert the "Other" 
		-- reason codes.
		--------------------------------------------------------------------------------------
		
		IF OBJECT_ID('tempdb..#ConversionValues') IS NOT NULL
			DROP TABLE #ConversionValues

		CREATE TABLE #ConversionValues
			(
				FromValue		NVARCHAR(50),
				ToValue			NVARCHAR(50)
			)

		INSERT INTO #ConversionValues (FromValue, ToValue)
		VALUES
		('LLeadsQ5A10', 'LLeadsQ16'),
		('LLeadsQ6A6' , 'LLeadsQ16'),
		('LLeadsQ4R6' , 'LLeadsQ16')


		IF OBJECT_ID('tempdb..#ConvertedRows') IS NOT NULL
			DROP TABLE #ConvertedRows

		CREATE TABLE #ConvertedRows
			(
				CaseID		BIGINT,
				ReasonCode	NVARCHAR(50)
			)

		;WITH CTE_List (CaseID, DataItem , ReasonsCode) 
		AS (
			SELECT ob.CaseID, CONVERT(NVARCHAR(1000), LEFT(llr.ReasonsCode, CHARINDEX(',', llr.ReasonsCode + ',')-1)),
				CONVERT(NVARCHAR(1000), STUFF(llr.ReasonsCode, 1, CHARINDEX(',', llr.ReasonsCode +','), ''))
			FROM LostLeads.OutputBase ob 
				INNER JOIN [$(SampleDB)].[Event].[CaseLostLeadResponses] llr ON llr.CaseID = ob.CaseID
			UNION ALL
			SELECT CaseID, CONVERT(NVARCHAR(1000),LEFT(ReasonsCode, CHARINDEX(',',ReasonsCode+',')-1)),
				CONVERT(NVARCHAR(1000),STUFF(ReasonsCode, 1, CHARINDEX(',',ReasonsCode+','), ''))
			FROM CTE_List
			WHERE ReasonsCode > ''
		)
		INSERT INTO #ConvertedRows (CaseID, ReasonCode)
		SELECT DISTINCT CaseID, COALESCE(cv.ToValue, LTRIM(RTRIM(DataItem))) AS ReasonCode
		FROM CTE_List cl
		LEFT JOIN #ConversionValues cv ON cv.FromValue = LTRIM(RTRIM(DataItem))
		ORDER BY CaseID


		
		--------------------------------------------------------------------------------
		-- Add in responses from DP
		--------------------------------------------------------------------------------
		
		UPDATE ob
		SET ob.ReasonsCode = ISNULL(ReasonCode, ''),
			ob.ResurrectedFlag = llr.ResurrectedFlag ,
			ob.BoughtElsewhereCompetitorFlag = llr.BoughtElsewhereCompetitorFlag,
			ob.BoughtElsewhereJLRFlag = llr.BoughtElsewhereJLRFlag,
			ob.VehicleLostBrand = llr.VehicleLostBrand,
			ob.VehicleLostModelRange = REPLACE(llr.VehicleLostModelRange, 'NA', ''),
			ob.LastUpdatedByLLA = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), CONVERT(DATETIME, llr.ResponseDate, 112), 126), '-', ''), 'T', ''), ':', '')
		FROM LostLeads.OutputBase ob
		INNER JOIN [$(SampleDB)].Event.CaseLostLeadResponses llr ON llr.CaseID = ob.CaseID
		LEFT JOIN #ConvertedRows spr  ON spr.CaseID = llr.CaseID		-- Link to the split out and converted rows table to get the Reason Code
									 AND spr.CaseID IN (	
													SELECT CaseID FROM #ConvertedRows
													GROUP BY CaseID HAVING COUNT(*) = 1			-- Only link to the table if there is a SINGLE value for the CaseID to report (otherwise we report blank)
													)


		--------------------------------------------------------------------------------
		-- Add in Agency IDs and set PassedToLLAFlag for any Status where we have 
		-- previously sent via LLA
		--------------------------------------------------------------------------------
		UPDATE ob
		SET ob.LostLeadAgency = CONVERT(NVARCHAR(5), lla.ID),
			ob.PassedToLLAFlag = 'X',
			ob.PassedToLLATimestamp = CONVERT(NVARCHAR(14), REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), CONVERT(DATETIME, clls.DateAddedForOutput, 112), 126), '-', ''), 'T', ''), ':', '')) 
		FROM LostLeads.OutputBase ob
		INNER JOIN LostLeads.CaseLostLeadStatuses clls ON clls.EventID = ob.EventID 
													  AND clls.LeadStatusID <> ob.LostLeadStatusID
		INNER JOIN LostLeads.LostLeadStatuses lls ON lls.LeadStatusID = clls.LeadStatusID and lls.LeadStatus = 'Sent via CATI'
		LEFT JOIN [$(SampleDB)].SelectionOutput.LostLeadAgencies lla ON lla.AgencyShortName = clls.OutputAgencyCode


		--------------------------------------------------------------------------------
		-- Add in PassedToGfKFlag for any Status where we have previously sent via Email
		--------------------------------------------------------------------------------
		UPDATE ob
		SET ob.ContactedByGfKFlag = 'X'
		FROM LostLeads.OutputBase ob
		INNER JOIN LostLeads.CaseLostLeadStatuses clls ON clls.EventID = ob.EventID 
													  AND clls.LeadStatusID <> ob.LostLeadStatusID
		INNER JOIN LostLeads.LostLeadStatuses lls ON lls.LeadStatusID = clls.LeadStatusID and lls.LeadStatus = 'Sent via Email'
	

		-------------------------------------------------------------
		-- Check whether data required for output is present 
		-------------------------------------------------------------
		
		-- Check for Region and Market Code 
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'Region or Market; '
		FROM LostLeads.OutputBase ob 
		WHERE ISNULL(RegionCode, '') = ''
		   OR ISNULL(MarketCode, '') = ''

		-- Check for Country Code 
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'Country Code; '
		FROM LostLeads.OutputBase ob 
		WHERE ISNULL(CountryCode, '') = ''
		   
		-- Check for Brand 
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'Brand; '
		FROM LostLeads.OutputBase ob 
		WHERE ISNULL(Brand, '') = ''
		   		
		-- Check for NamePlate (Model)
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'Nameplate (Model); '
		FROM LostLeads.OutputBase ob 
		WHERE ISNULL(Nameplate, '') = ''
		   		
		-- Check for Retailer info
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'Retailer Information; '
		FROM LostLeads.OutputBase ob 
		WHERE ISNULL(RetailerPAGNumber, '') = ''
		   OR ISNULL(RetailerCICode, '') = ''
		   		
		-- Check LeadStartTimestamp set
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'LeadStartTimestamp not set; '
		FROM LostLeads.OutputBase ob 
		WHERE ISNULL(LeadStartTimestamp, '') = ''

		-- Check for SourceSystemLeadID
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'SourceSystemLeadID; '
		FROM LostLeads.OutputBase ob 
		WHERE ISNULL(SourceSystemLeadID, '') = ''
	
	
		-- Check that Brand and Retailer Brand match
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'Brand and Retailer Mismatch; '
		FROM LostLeads.OutputBase ob 
		WHERE Brand <> RetailerBrand


		-- Check that Brand and Model Brand match
		;WITH CTE_BrandNameplateEventIDs
		AS (
			SELECT DISTINCT EventID
			FROM LostLeads.OutputBase ob 
			INNER JOIN LostLeads.CRMBrandCodes bc ON bc.KeyValue = ob.Brand
			INNER JOIN LostLeads.CRMNameplateCodes npc ON npc.KeyValue = ob.Nameplate
			INNER JOIN [$(SampleDB)].Vehicle.Models m ON m.ModelID = npc.ConnexionsModelID
			INNER JOIN [$(SampleDB)].dbo.Brands b ON b.ManufacturerPartyID = m.ManufacturerPartyID
			WHERE bc.Brand <> b.Brand
		)
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'Brand and Nameplate Mismatch; '
		FROM LostLeads.OutputBase ob 
		INNER JOIN CTE_BrandNameplateEventIDs eid ON eid.EventID = ob.EventID
	
	
		--------------------------------------------------------
		-- Add ExternalEventID prefix to SourceSystemLeadID
		--------------------------------------------------------
	
		-- Check EventID present.  (This should never fail as generated by trigger but just in case of unexpected error)
		UPDATE ob
		SET ValidationFailed = 1 ,
			ValidationFailReasons = ValidationFailReasons + 'ExternalEventID; '
		FROM LostLeads.OutputBase ob 
		LEFT JOIN LostLeads.ExternalEventID eei ON eei.EventID = ob.EventID
		WHERE eei.EventID IS NULL
		
		-- Add prefix 
		UPDATE ob
		SET ob.SourceSystemLeadID = CONVERT(VARCHAR(10), eei.ExternalID) + '_' + ob.SourceSystemLeadID
		FROM LostLeads.OutputBase ob 
		INNER JOIN LostLeads.ExternalEventID eei ON eei.EventID = ob.EventID
		
		
				
		--------------------------------------------------------
		-- Set SequenceID for output
		--------------------------------------------------------
		;WITH CTE_MaxSeqIDs
		AS (
			SELECT ob.EventID, MAX(ISNULL(lls.SequenceID, 0)) AS MaxSeqID 
			FROM LostLeads.OutputBase ob
			INNER JOIN LostLeads.CaseLostLeadStatuses lls ON lls.EventID = ob.EventID
			WHERE ValidationFailed = 0		-- Only valid records are output
			GROUP BY ob.EventID
		)
		UPDATE ob 
		SET ob.SequenceID = CONVERT(NVARCHAR(5), MaxSeqID + 1)
		FROM CTE_MaxSeqIDs msi
		INNER JOIN LostLeads.OutputBase ob ON ob.EventID = msi.EventID
		


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