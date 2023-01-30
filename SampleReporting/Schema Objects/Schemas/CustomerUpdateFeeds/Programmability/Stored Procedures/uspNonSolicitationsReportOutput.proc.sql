CREATE PROCEDURE [CustomerUpdateFeeds].[uspNonSolicitationsReportOutput]
	@Market varchar(100), 
	@Brand varchar(50),
	@DealerCode varchar(100)
AS

/*

***************************************************************************
**
**  Description: Outputs the Non-solicitation report data.   
**
**
**	Date		Author			Ver		Desctiption
**	----		------			----	-----------
**	13/02/2013	Chris Ross		1.0		Original version (Taken from pre-existing code)
**	06/05/2013	Chris Ross		1.1		Updated to remove dupes and ensure all rows, not
**										just those with Cases are reported.
**  05/09/2016	Chris Ross		1.2		12859 - Modify Dealer lookup to use Sales dealers for LostLeads.
**  05/02/2019	Chris Ledger	1.3		Bug 15221 - Add in DealerCode parameter.
**	06/04/2021	Eddie Thomas	1.4		Azure DevOps 287 - Return dw.Dealer10DigitCode for the dealer code
**  25/06/2021	Eddie Thomas	1.5		BUG 18175 : Update Opt-Out report to include Roadside & CRC & CRC General Enquiries
**  13/08/2021	Eddie Thomas	1.6		Inserting directly from SELECT was erroring when reporting period set to 01/04/2021 - 13/08/2021.
**										Use temp table as an intermediary, then insert from Temp.
**	01/09/2021	Eddie Thomas	1.7		Added CustomerID and EmailAdress to the reports
**	09/09/2022	Eddie Thomas	1.8		TASK 1031 : CQI RECORDS NOT BEING RETURNED
**  04/10/2022	Eddie Thomas	1.9		BUG FIX : Prevent records flagged as 'MedalliaDuplicate' from being output
***************************************************************************

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	--BUILD A DEALER NETWORK THAT INCLUDES ALL SURVEYS		--V1.5
	SELECT		DISTINCT Manufacturer As Brand, Market, OutletFunction AS EventCategory, OutletPartyID, Dealer10DigitCode, Outlet, OutletCode
	INTO		#DealerNetwork
	FROM		[$(SampleDB)].dbo.DW_JLRCSPDealers
		
	UNION

	SELECT	BR.Brand, 
			Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market,
			'CRC' AS EventCategory,
			PartyIDFrom AS OutletPartyID,
			'' AS Dealer10DigitCode,
			CRCCentreName AS Outlet,
			CRC.CRCCentreCode + '_CRC'
	FROM	[$(SampleDB)].Party.CRCNetworks CRC
	INNER JOIN [$(SampleDB)].dbo.[Brands] BR ON CRC.PartyIDTo = BR.ManufacturerPartyID
	INNER JOIN [$(SampleDB)].dbo.Markets MK ON CRC.CountryID = MK.CountryID

	UNION

	SELECT	BR.Brand, 
			Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market,
			'Roadside' AS EventCategory,
			PartyIDFrom AS OutletPartyID,
			'' AS Dealer10DigitCode,
			RoadsideNetworkName AS Outlet,
			ROA.RoadsideNetworkCode + '_Roadside'
	FROM	[$(SampleDB)].Party.RoadsideNetworks	ROA
	INNER JOIN [$(SampleDB)].dbo.[Brands] BR ON ROA.PartyIDTo = BR.ManufacturerPartyID
	INNER JOIN [$(SampleDB)].dbo.Markets MK ON ROA.CountryID = MK.CountryID



	TRUNCATE TABLE CustomerUpdateFeeds.ReportingTable_Nonsolicitations_Output 

	-- Get non-solicitations for time period
	
	SELECT	 distinct CD.EventID, cuco.PartyID, EA.EmailAddress		--V1.7
	INTO	#NonSols
	FROM	[$(AuditDB)].[Audit].[CustomerUpdate_ContactOutcome]	cuco
	INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes			OC	ON cuco.OutcomeCode = OC.OutcomeCode
	INNER JOIN [$(SampleDB)].Meta.CaseDetails						CD	ON cuco.PartyID = CD.PartyID AND cuco.CaseID = CD.CaseID

	LEFT JOIN [$(SampleDB)].Party.ContactPreferences			PCP ON CUCO.PartyID = PCP.PartyID
	LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses	EA ON CD.EmailAddressContactMechanismID = EA.ContactMechanismID
	WHERE	[CasePartyCombinationValid] =1 AND		--FLAGGED AS VALID OUTCOME IN AUDIT
			[DateProcessed] BETWEEN CONVERT(DATE, GETDATE() -7) AND CONVERT(DATE, GETDATE()) AND
			OC.Unsubscribe = 1  AND		-- ONLY INTERESTED IN UN-SUBSCRIBES
			PCP.PartyUnsubscribe = 1	-- THIS IS THE PARTY'S CURRENT UN-SUBSCRIBE STATUS; CHECKING THAT AUDIT ISN'T OUT OF SYNC
			AND ISNULL(cuco.MedalliaDuplicate,0) = 0		--V1.9
	;WITH CTE_LatestAuditID		-- Get latest AuditItemID for non-solicitation	
	AS 
	(
		SELECT		MAX(AuditItemID) AS AuditItemID, EV.EventID, CTE.PartyID
		FROM		[$(AuditDB)].Audit.Events	EV
		INNER JOIN	#NonSols					CTE ON EV.EventID = CTE.EventID
		GROUP BY	EV.EventID, CTE.PartyID
	)	
	
	SELECT	la.PartyID, 
			CASE WHEN la.PartyID = ISNULL(o.PartyID, 0) THEN '' ELSE ISNULL(p.FirstName, '') END AS FirstName,
			CASE WHEN la.PartyID = ISNULL(o.PartyID, 0) THEN '' ELSE ISNULL(p.LastName, '') END AS LastName,
			ISNULL(o.OrganisationName, '') AS OrganisationName,
			a.StreetNumber,
			a.Street,
			a.SubLocality,
			a.Locality,
			a.Town,
			a.Region,
			a.PostCode,
			c.Country,
			sq.ManufacturerID,
			--dw.OutletCode,
			dw.Dealer10DigitCode,			--V1.4
			dw.Outlet,
			ISNULL(r.RegistrationNumber, '') AS RegistrationNumber,
			v.VIN,
			Case 
				WHEN ec.EventCategory = 'Sales' THEN 'CLP Sales' 
				WHEN ec.EventCategory = 'Service' THEN 'CLP Service'
				ELSE ec.EventCategory END AS [Source],
			f.FileName AS UpdateFileName,
			CONVERT(VARCHAR(10), f.ActionDate, 103) AS DateOfUpdate,
			ISNULL(CR.[CustomerIdentifier],'') AS CustomerID,
			NS.EmailAddress
	INTO	[#TempResults]		--v1.6
	FROM CTE_LatestAuditID la
	INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq 
									ON sq.AuditItemID = la.AuditItemID
									AND sq.Market = @Market
									AND sq.Brand = @Brand
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = sq.AuditID
	INNER JOIN #NonSols  NS ON la.EventID = NS.EventID		--V1.7

	LEFT JOIN [$(SampleDB)].Party.People p ON p.PartyID = sq.MatchedODSPersonID
	LEFT JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = sq.MatchedODSOrganisationID
	LEFT JOIN [$(SampleDB)].ContactMechanism.PostalAddresses a ON a.ContactMechanismID = sq.MatchedODSAddressID
	LEFT JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.CountryID = a.CountryID
	LEFT JOIN [$(SampleDB)].Vehicle.Vehicles v ON v.VehicleID = sq.MatchedODSVehicleID
	LEFT JOIN [$(SampleDB)].Event.EventTypeCategories etc ON etc.EventTypeID = sq.ODSEventTypeID
	LEFT JOIN [$(SampleDB)].Event.EventCategories ec ON ec.EventCategoryID = etc.EventCategoryID 	
	LEFT JOIN [$(SampleDB)].Event.EventPartyRoles EPR	ON	EPR.EventID = sq.MatchedODSEventID
	LEFT JOIN #DealerNetwork dw ON dw.OutletPartyID = ISNULL(EPR.PartyID,0)			--V1.5
									AND dw.EventCategory = CASE WHEN ec.EventCategory = 'Service' THEN 'Aftersales' 
															WHEN ec.EventCategory = 'LostLeads' THEN 'Sales'		--v1.2
															WHEN ec.EventCategory = 'CRC General Enquiry' THEN 'CRC'	--V1.5
															WHEN ec.EventCategory LIKE 'CQI%' THEN 'Sales'				--V1.8
															ELSE ec.EventCategory END


	LEFT JOIN [$(SampleDB)].Vehicle.Registrations r 
								ON r.RegistrationID = (SELECT MAX(vre.RegistrationID) 
														FROM [$(SampleDB)].Vehicle.VehicleRegistrationEvents vre 
														WHERE vre.VehicleID = sq.MatchedODSVehicleID
														  AND vre.EventID = sq.MatchedODSEventID)
	
	--V1.7
	LEFT JOIN [$(AuditDB)].Audit.CustomerRelationships CR ON sq.AuditItemID = CR.AuditItemID AND COALESCE(NULLIF(sq.MatchedODSPersonID,0), NULLIF(sq.MatchedODSOrganisationID,0), 0) = CR.PartyIDFrom
	WHERE	DW.Market NOT IN ('USA','Canada','China') AND
			ISNULL(OutletCode,'') = CASE @DealerCode 
											WHEN 'ALL' THEN ISNULL(OutletCode,'') 
											ELSE @DealerCode 
									END		-- V1.3
	
	----------------------------------------------------------------------
	--V1.6
	---------------------------------------------------------------------
	INSERT INTO CustomerUpdateFeeds.ReportingTable_Nonsolicitations_Output 
				(
					PartyID, 
					FirstName, 
					LastName, 
					OrganisationName, 
					StreetNumber, 
					Street, 
					SubLocality, 
					Locality, 
					Town, 
					Region, 
					PostCode, 
					Country, 
					ManufacturerPartyID, 
					DealerCode, 
					DealerName, 
					RegistrationNumber, 
					VIN, 
					Source, 
					UpdateFileName, 
					DateOfUpdate,
					CustomerID,		--V1.7
					EmailAddress	--V1.7
				)
	SELECT	PartyID, 
			Nullif(ltrim(rtrim(FirstName)),''),
			Nullif(ltrim(rtrim(LastName)),''),
			Nullif(ltrim(rtrim(OrganisationName)),''),
			Nullif(ltrim(rtrim(StreetNumber)),''),
			Nullif(ltrim(rtrim(Street)),''),
			Nullif(ltrim(rtrim(SubLocality)),''),
			Nullif(ltrim(rtrim(Locality)),''),
			Nullif(ltrim(rtrim(Town)),''),
			Nullif(ltrim(rtrim(Region)),''),
			Nullif(ltrim(rtrim(PostCode)),''),
			Nullif(ltrim(rtrim(Country)),''),
			Nullif(ltrim(rtrim(ManufacturerID)),''),
			Nullif(ltrim(rtrim(Dealer10DigitCode)),''),
			Nullif(ltrim(rtrim(Outlet)),''),
			Nullif(ltrim(rtrim(RegistrationNumber)),''),
			Nullif(ltrim(rtrim(VIN)),''),
			Nullif(ltrim(rtrim(Source)),''),
			Nullif(ltrim(rtrim(UpdateFileName)),''),
			Nullif(ltrim(rtrim(DateOfUpdate)),''),
			Nullif(ltrim(rtrim(CustomerID)),''),		--V1.7
			Nullif(ltrim(rtrim(EmailAddress)),'')		--V1.7
	FROM	[#TempResults]


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
