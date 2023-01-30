CREATE PROCEDURE [CustomerUpdateFeeds].[uspNonSolicitationsReportGen]
AS

/*

	Purpose:		Generates the base table for the non-solicitations report
		
	Version			Date			Developer			Comment
	1.0				02-10-2013		Chris Ross			BUG 9325 - Code taken from package so we have it in 
														a stored procedure (as per common dev practice)
	1.1				08-02-2019		Chris Ledger		BUG 15221 - Add in DealerCode.
	1.2				17-03-2021		Eddie Thomas		Azure DevOPs TASK 287 : Only Reporting Core Markets & Unsubscribe outcomes codes
	1.3				25-06-2021		Eddie Thomas		BUG 18175 : Update Opt-Out report to include Roadside & CRC & CRC General Enquiries
	1.4				10-04-2022		Eddie Thomas		BUG FIX : Prevent records flagged as 'MedalliaDuplicate' from being output 			
*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
		
		--BUILD A DEALER NETWORK THAT INCLUDES ALL STUDIES		-V1.3
		SELECT		DISTINCT 
					DC.PartyIDFrom AS DealerPartyID, 
					Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market,
					DC.DealerCode
		INTO		#DealerNetwork
		FROM		[$(SampleDB)].ContactMechanism.DealerCountries DC
		INNER JOIN	[$(SampleDB)].dbo.Markets MK ON DC.CountryID = MK.CountryID

		UNION

		SELECT	--BR.Brand, 
				PartyIDFrom AS DealerPartyID,
				Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market, 
				CRC.CRCCentreCode + '_CRC'
				--'CRC' AS Questionnaire, 
		FROM	[$(SampleDB)].Party.CRCNetworks CRC
		INNER JOIN [$(SampleDB)].dbo.[Brands] BR ON CRC.PartyIDTo = BR.ManufacturerPartyID
		INNER JOIN [$(SampleDB)].dbo.Markets MK ON CRC.CountryID = MK.CountryID

		UNION

		SELECT	--BR.Brand, 
				PartyIDFrom AS DealerPartyID, 
				Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market,
				ROA.RoadsideNetworkCode + '_Roadside'
				--'Roadside' AS Questionnaire, 
		
		FROM	[$(SampleDB)].Party.RoadsideNetworks ROA
		INNER JOIN [$(SampleDB)].dbo.[Brands] BR ON ROA.PartyIDTo = BR.ManufacturerPartyID
		INNER JOIN [$(SampleDB)].dbo.Markets MK ON ROA.CountryID = MK.CountryID
	

	-- Clear Down the Report Table
	TRUNCATE TABLE CustomerUpdateFeeds.ReportingTable_Nonsolicitations

	-- V1.1 Populate the Report Table - All Dealers
	INSERT INTO CustomerUpdateFeeds.ReportingTable_Nonsolicitations

	SELECT		MK.Market, B.Brand as Manufacturer, 'ALL' AS DealerCode
	FROM		[$(AuditDB)].[Audit].[CustomerUpdate_ContactOutcome]		cuco
	INNER JOIN	[$(SampleDB)].ContactMechanism.OutcomeCodes					OC	ON cuco.OutcomeCode = OC.OutcomeCode
	INNER JOIN	[$(SampleDB)].Meta.CaseDetails								CD	ON cuco.PartyID = CD.PartyID AND cuco.CaseID = CD.CaseID
	INNER JOIN	[$(SampleDB)].dbo.Brands									B	ON CD.ManufacturerPartyID = B.ManufacturerPartyID
	INNER JOIN	[$(SampleDB)].ContactMechanism.PartyContactMechanisms		PCM ON cuco.PartyID = PCM.PartyID
	INNER JOIN	[$(SampleDB)].ContactMechanism.PostalAddresses				PA	ON PCM.ContactMechanismID = PA.ContactMechanismID
	INNER JOIN	[$(SampleDB)].Event.EventPartyRoles							EPR ON CD.EventID = EPR.EventID
	INNER JOIN	#DealerNetwork												DW ON EPR.PartyID = DW.DealerPartyID	--V1.3
	INNER JOIN
	(
		SELECT		DISTINCT COALESCE (DealerTableEquivMarket,Market ) AS DealerMarket, Market				
		FROM		[$(SampleDB)].dbo.Markets MK
		WHERE		FranchiseCountryType ='Core'

	) MK ON DW.Market = MK.DealerMarket		--V1.2
	LEFT JOIN [$(SampleDB)].Party.ContactPreferences			PCP ON CUCO.PartyID = PCP.PartyID 
	WHERE	[CasePartyCombinationValid] =1 AND		--FLAGGED AS VALID OUTCOME IN AUDIT
			[DateProcessed] BETWEEN CONVERT(DATE, GETDATE() -7) AND CONVERT(DATE, GETDATE()) AND
			OC.Unsubscribe = 1  AND		-- ONLY INTERESTED IN UN-SUBSCRIBES
			PCP.PartyUnsubscribe = 1	-- THIS IS THE PARTY'S CURRENT UN-SUBSCRIBE STATUS; CHECKING THAT AUDIT ISN'T OUT OF SYNC
			AND DW.Market NOT IN ('USA','Canada','China')
			AND ISNULL(cuco.MedalliaDuplicate,0) = 0		--V1.4
	UNION

	SELECT		MK.Market, B.Brand as Manufacturer, DW.DealerCode
	FROM		[$(AuditDB)].[Audit].[CustomerUpdate_ContactOutcome]		cuco
	INNER JOIN	[$(SampleDB)].ContactMechanism.OutcomeCodes					OC	ON cuco.OutcomeCode = OC.OutcomeCode
	INNER JOIN	[$(SampleDB)].Meta.CaseDetails								CD	ON cuco.PartyID = CD.PartyID AND cuco.CaseID = CD.CaseID
	INNER JOIN	[$(SampleDB)].dbo.Brands									B	ON CD.ManufacturerPartyID = B.ManufacturerPartyID
	INNER JOIN	[$(SampleDB)].ContactMechanism.PartyContactMechanisms		PCM ON cuco.PartyID = PCM.PartyID
	INNER JOIN	[$(SampleDB)].ContactMechanism.PostalAddresses				PA	ON PCM.ContactMechanismID = PA.ContactMechanismID
	--INNER JOIN	[$(SampleDB)].dbo.DW_JLRCSPDealers						DW	ON CD.DealerPartyID = DW.OutletPartyID
	INNER JOIN	[$(SampleDB)].Event.EventPartyRoles							EPR ON CD.EventID = EPR.EventID
	INNER JOIN	#DealerNetwork												DW ON EPR.PartyID = DW.DealerPartyID		--V1.3
	INNER JOIN
	(
		SELECT		DISTINCT COALESCE (DealerTableEquivMarket,Market ) AS DealerMarket, Market				
		FROM		[$(SampleDB)].dbo.Markets MK
		WHERE		FranchiseCountryType ='Core'

	) MK ON DW.Market = MK.DealerMarket		--V1.2
	LEFT JOIN [$(SampleDB)].Party.ContactPreferences			PCP ON CUCO.PartyID = PCP.PartyID 
	WHERE	[CasePartyCombinationValid] =1 AND		--FLAGGED AS VALID OUTCOME IN AUDIT
			[DateProcessed] BETWEEN CONVERT(DATE, GETDATE() -7) AND CONVERT(DATE, GETDATE()) AND 
			OC.Unsubscribe = 1  AND		-- ONLY INTERESTED IN UN-SUBSCRIBES
			PCP.PartyUnsubscribe = 1	-- THIS IS THE PARTY'S CURRENT UN-SUBSCRIBE STATUS; CHECKING THAT AUDIT ISN'T OUT OF SYNC
			AND DW.Market NOT IN ('USA','Canada','China')
			AND ISNULL(cuco.MedalliaDuplicate,0) = 0	--V1.4

	--BUG13811 - remove single nested quotes, replace with double to avoid SQL string errors.
	UPDATE CustomerUpdateFeeds.ReportingTable_Nonsolicitations
    SET Market = REPLACE(Market,'''','''''')
    


    
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

