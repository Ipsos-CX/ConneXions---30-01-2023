
CREATE PROCEDURE [UsableEmailReport].[uspGenerateReportData]
@Brand NVARCHAR (510), @ReportDate DATETIME

AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY


/*
	Purpose:	Builds the report tables required for the UsableEmailReport
		
	Version		Date				Developer			Comment
	1.0			03/06/2015			Chris Ross			Created
	1.1			27/10/2015			Chris Ledger		Changes for AFRL Code & Retailer Emails
	1.2			14/03/2016			Chris Ledger		Split TotalRecs and TotalPB into 2 columns and correct bug with ContactedbyPost
	1.3			05/09/2016			Chris Ross			12859 - Modify Dealer lookup to use Sales dealers for LostLeads.
	1.4			07/07/2017			Ben King			BUG14032 - Add InvalidCRMSaleType to Inidividual sheet, TotalCRMSalesType (count of InvalidCRMSaleType) to Summary sheet
	1.5			16/01/2018			Chris Ledger		BUG 14469: Remove postfix from VIN
	1.6			02/05/2018			Ben King			BUG 14683 - UK Purchase Quality Reports -  Count of SV-CRM Sales Type
	1.7			29/10/2019			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
	1.8			15/01/2020			Chris Ledger 		BUG 15372 - Fix cases
	1.9			01/04/2020			Chris Ledger		BUG 15372 - Fix hard coded database references and cases
*/


	DECLARE @Market VARCHAR (200), @Questionnaire VARCHAR (255)

	--SET @ReportDate = CONVERT (DATE, getdate())
	
	SET @Market = 'United Kingdom'
	SET @Questionnaire = 'Sales'

	-- Get start and end dates to select the previous month 
	DECLARE @StartDate	DATETIME,
			@EndDate	DATETIME

	SELECT @StartDate = DATEADD(qq,DATEDIFF(qq,0,@ReportDate),0)		-- First day of quarter
	SELECT @EndDate = @ReportDate										-- today's date

	
	----------------------------------------------------------------------------------------
	-- Build base table
	----------------------------------------------------------------------------------------

		TRUNCATE TABLE UsableEmailReport.[Base];
		
		
		INSERT INTO [UsableEmailReport].[Base] (
			[ReportDate]			,													  
			[DateFrom]				,													  
			[DateTo]				,													  
			[FileName]				,													  
			FileActionDate			,													  
			FileRowCount			,													  
			[LoadedDate]			,													
			[AuditID]				,													
			[AuditItemID]			,													
			[MatchedODSPartyID]		,													
			[MatchedODSPersonID]	,													
			[PartySuppression]		,													
			[MatchedODSOrganisationID] ,												
			[EmailSuppression]		,													
			[MatchedODSVehicleID]	,													
			[ODSRegistrationID]		,													
			[MatchedODSEventID]		,													
			[ODSEventTypeID]		,													
			[Brand]					,													
			[Market]				,													
			[SuppliedEmail]			,													
			[UncodedDealer]			,
			[ExclusionListMatch]	,
			[InvalidEmailAddress]	,
			[BarredEmailAddress]	,
			[BarredDomain]			,
			[EventDateOutOfDate]	,
			[BounceBackFlag]		,
			[SampleEmailBounceBackFlag]		,
			[OtherReasonsNotSelected], 
			[InternalDealer] ,	
			RegistrationNumber ,
			RegistrationDate ,
			VIN,
			EventDate ,
			[CaseID],
			MatchedODSEmailAddressID,				-- v1.4
			AFRLCode,								-- V1.1
			AFRLCodeUsable,							-- V1.1
			DealerExclusionListMatch,				-- V1.1
			InvalidSaleType						-- V1.4
		
			)
		SELECT 
			@ReportDate,
			@StartDate,
			@EndDate,
			F.[FileName]			,
			F.ActionDate			,
			F.FileRowCount			,
			sq.[LoadedDate]			,
			sq.[AuditID]				,
			sq.[AuditItemID]			,
			sq.[MatchedODSPartyID]		,
			sq.[MatchedODSPersonID]	,
			sq.[PartySuppression]		,
			sq.[MatchedODSOrganisationID] ,
			sq.[EmailSuppression]		,
			sq.[MatchedODSVehicleID]	,
			sq.[ODSRegistrationID]		,
			sq.[MatchedODSEventID]		,
			sq.[ODSEventTypeID]		,
			sq.[Brand]					,
			sq.[Market]				,
			sq.[SuppliedEmail]			,
			sq.[UncodedDealer]			,
			sq.[ExclusionListMatch]	,
			sq.[InvalidEmailAddress]	,
			sq.[BarredEmailAddress]	,
			sq.[BarredDomain]			,
			sq.EventDateOutOfDate	,
			0 AS BounceBackFlag		,
			0 AS SampleEmailBounceBackFlag,
			0 AS OtherReasonsNotSelected, 
			sq.[InternalDealer] ,	
			mve.RegistrationNumber ,
			mve.RegistrationDate ,
			CASE WHEN LEN(v.VIN) = 20 AND SUBSTRING(v.VIN,18,1) = '_' THEN SUBSTRING(v.VIN,1,17) ELSE v.VIN END AS VIN ,		-- V1.5
			e.EventDate ,
			sq.CaseID,
			sq.MatchedODSEmailAddressID,
			sq.SuppliedAFRLCode,								-- V1.1
			CASE WHEN LEN(ISNULL(sq.SuppliedAFRLCode,'')) = 0 THEN 0
				WHEN sq.InvalidAFRLCode = 1 THEN 0 
				ELSE 1 END AS AFRLCodeUsable, 					-- V1.1	
			sq.DealerExclusionListMatch,						-- V1.1	
			sq.InvalidSaleType								-- V1.4	, V1.6			
	  FROM [$(AuditDB)].dbo.Files F 
	  JOIN [$(AuditDB)].dbo.IncomingFiles ICF ON ICF.AuditID = F.AuditID 
	  JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] SQ 
												ON F.AuditID = SQ.AuditID 					
												AND	SQ.Brand = @Brand
												AND	SQ.Questionnaire = @Questionnaire 
												AND	SQ.Market = @Market
	  LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = SQ.MatchedODSVehicleID		
	  LEFT JOIN [$(SampleDB)].Meta.VehicleEvents MVE ON MVE.VehicleID = SQ.MatchedODSVehicleID
											  AND MVE.EventID = SQ.MatchedODSEventID 
	  LEFT JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = MVE.ModelID 
	  LEFT JOIN [$(SampleDB)].Event.Events E ON E.EventID = SQ.MatchedODSEventID 
	  WHERE f.ActionDate >= @StartDate AND f.ActionDate < @EndDate 
	  AND NOT EXISTS (SELECT AuditItemID FROM [$(AuditDB)].[Audit].[IndustryClassifications] ic 
										WHERE ic.AuditItemID = sq.AuditItemID)  -- Only SELECT P&Bs i.e. Unclassified


	 
	 

	---  POPULATE THE Dealer info (Regions and Groups, etc) in SampleReport.Base ------------------------------------------


	UPDATE b
	SET SuperNationalRegion		=  d.SuperNationalRegion,
		BusinessRegion			=  d.BusinessRegion,					-- V1.11
		DealerMarket			=  d.Market,
		SubNationalRegion		=  d.SubNationalRegion,
		CombinedDealer			=  d.CombinedDealer,
		DealerName				=  d.TransferDealer,
		DealerCode				=  d.TransferDealerCode,
		DealerCodeGDD			=  d.TransferDealerCode_GDD
	-- SELECT * 
	FROM UsableEmailReport.Base b
	JOIN [$(SampleDB)].Event.EventPartyRoles epr ON epr.EventID = b.MatchedODSEventID 
	JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers od ON od.OutletPartyID = epr.PartyID
									  AND od.OutletFunction = case @Questionnaire 
															 WHEN 'Service' THEN 'AfterSales'
															 WHEN 'Sales' THEN 'Sales'
															 WHEN 'LostLeads' THEN 'Sales'	-- v1.3
															 WHEN 'PreOwned LostLeads' THEN 'PreOwned'	-- V1.7
															 ELSE '' END
	JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers d ON d.OutletPartyID = od.TransferPartyID			-- Link to the Transfer PartyID for the final Dealer information
									  AND d.OutletFunction = case @Questionnaire 
															 WHEN 'Service' THEN 'AfterSales'
															 WHEN 'Sales' THEN 'Sales'
															 WHEN 'LostLeads' THEN 'Sales'	-- v1.3
															 WHEN 'PreOwned LostLeads' THEN 'PreOwned'	-- V1.7
															 ELSE '' END
 

	--  POPULATE records with an uncoded dealer code with the Dealer code supplied in the sample (Bug #9633)
	
	
	update UsableEmailReport.Base
		set DealerCode = coalesce(nullif(SalesDealerCode, ''), nullif(ServiceDealerCode, ''))
	FROM UsableEmailReport.Base b
	JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] sq ON b.AuditItemID = sq.AuditItemID
	WHERE b.DealerCode IS NULL
	 
	
	--- POPULATE with Customer Name and Organisations Name ------------------------------------------
	UPDATE UsableEmailReport.Base 
	SET FullName =  [$(SampleDB)].Party.udfGetAddressingText(COALESCE (VPRE.PrincipleDriver, VPRE.RegisteredOwner, VPRE.Purchaser, VPRE.OtherDriver)
														, 0, 219, 19, 
											(SELECT AddressingTypeID 
											FROM [$(SampleDB)].Party.AddressingTypes 
											WHERE AddressingType = 'Addressing')),
		OrganisationName = ISNULL(o.OrganisationName, '')
	FROM UsableEmailReport.Base b
	INNER JOIN [$(SampleDB)].Meta.VehiclePartyRoleEvents VPRE ON vpre.EventID = b.MatchedODSEventID 
	LEFT JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = b.MatchedODSOrganisationID


	--- POPULATE with Email Addresses as supplied in Sample file -- v1.4 ------------------------------------
	UPDATE UsableEmailReport.Base 
	SET SampleEmailAddress = ea.EmailAddress
	FROM UsableEmailReport.Base b
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = b.MatchedODSEmailAddressID


	------------------------------------------------------------------------------------------------
	-- Remove uncoded dealers
	------------------------------------------------------------------------------------------------

	DELETE FROM UsableEmailReport.Base
	WHERE DealerName IS NULL


	------------------------------------------------------------------------------------------------
	-- Flag duplicate records
	------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#FirstAuditItemIDs') IS NOT NULL
    DROP TABLE #FirstAuditItemIDs 

	CREATE TABLE #FirstAuditItemIDs 
		(
			MatchedODSEventID	bigint,
			FirstAuditItemID	bigint
		);
	
	INSERT INTO #FirstAuditItemIDs (MatchedODSEventID, FirstAuditItemID)
	SELECT l.MatchedODSEventID,
		   MIN(l.AuditItemID) AS FirstAuditItemID
	FROM UsableEmailReport.Base b
	INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging l ON l.MatchedODSEventID = b.MatchedODSEventID
	GROUP BY l.MatchedODSEventID

	UPDATE b
	SET b.DuplicateRowFlag = CASE WHEN f.FirstAuditItemID IS NULL THEN 1 ELSE 0 END 
	FROM UsableEmailReport.Base b
	LEFT JOIN #FirstAuditItemIDs f ON f.FirstAuditItemID = b.AuditItemID

	-- Remove duplicate rows
	DELETE FROM UsableEmailReport.Base 
	WHERE DuplicateRowFlag = 1


	------------------------------------------------------------------------------------------------
	-- Set CaseEmailAddress
	------------------------------------------------------------------------------------------------

	UPDATE UsableEmailReport.Base 
	SET CaseEmailAddress = ea.EmailAddress
	FROM UsableEmailReport.Base b
	INNER JOIN [$(SampleDB)].Event.CaseContactMechanisms ccm ON ccm.CaseID = b.CaseID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = ccm.ContactMechanismID



	------------------------------------------------------------------------------------------------
	-- Set Bounceback flags
	------------------------------------------------------------------------------------------------

	UPDATE b
	SET BouncebackFlag = 1
	FROM UsableEmailReport.Base B
	INNER JOIN [$(SampleDB)].Event.CaseContactMechanismOutcomes CCO ON CCO.CaseID = B.CaseID 
	INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON CCO.OutcomeCode = OC.OutcomeCode
	WHERE (   OC.OutcomeCode IN ('10', '20', '22', '50', '52', '54', '110')
	       OR (OC.OutcomeCode = '99' AND ISNULL(CaseEmailAddress, '') <> '')		-- v1.7
		  )
	
	UPDATE b
	SET SampleEmailBouncebackFlag = 1
	FROM UsableEmailReport.Base B
	WHERE BouncebackFlag = 1 
	  AND CaseEmailAddress = SampleEmailAddress
	

	------------------------------------------------------------------------------------------------
	-- Set Invalid flag where Email Address has been blacklisted
	------------------------------------------------------------------------------------------------

	UPDATE b
	SET InvalidEmailAddress = 1 
	FROM UsableEmailReport.Base b 
	WHERE EXISTS (SELECT TOP 1 ContactMechanismID 
					FROM [$(SampleDB)].[ContactMechanism].[BlacklistContactMechanisms] bc
					WHERE ContactMechanismID = b.MatchedODSEmailAddressID)


    -------------------------------------------------------------------------------------------------
	--- POPULATE with Previous Event Bounceback -- V1.1 ---------------------------------------------
	UPDATE  B
    SET     PreviousEventBounceBack = 1
    FROM    [$(SampleDB)].dbo.NonSolicitations ns
            INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts nst ON ns.NonSolicitationTextID = nst.NonSolicitationTextID
                                                          AND nst.NonSolicitationText = 'Email Bounce Back'
            INNER JOIN UsableEmailReport.Base B ON ns.PartyID = COALESCE(NULLIF(B.MatchedODSPersonID,0),NULLIF(B.MatchedODSOrganisationID,0),NULLIF(B.MatchedODSPartyID,0))
            LEFT JOIN [$(SampleDB)].Meta.PartyBestEmailAddresses pbe ON ns.PartyID = pbe.PartyID
    WHERE   ( ns.FromDate < B.LoadedDate )
            AND    
            ( pbe.ContactMechanismID IS NULL );
    -------------------------------------------------------------------------------------------------


    -------------------------------------------------------------------------------------------------
	--- POPULATE with Previous Email Address -- V1.1 ------------------------------------------------
    IF ( OBJECT_ID('tempdb..#PreviousEmails') IS NOT NULL )
        BEGIN
            DROP TABLE #PreviousEmails;
        END;

	SELECT 
	B.AuditItemID,
	MAX(PCM.ContactMechanismID) AS ContactMechanismID
	INTO #PreviousEmails
	FROM UsableEmailReport.Base B
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON COALESCE(NULLIF(B.MatchedODSPersonID,0),NULLIF(B.MatchedODSOrganisationID,0),NULLIF(B.MatchedODSPartyID,0)) = PCM.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON PCM.ContactMechanismID = EA.ContactMechanismID
	WHERE EA.ContactMechanismID <> B.MatchedODSEmailAddressID
	AND LEN(EA.EmailAddress) > 0
	GROUP BY B.AuditItemID

	UPDATE B
	SET B.PreviousEmailAddress = EA.EmailAddress
	FROM UsableEmailReport.Base B
	INNER JOIN #PreviousEmails PE ON B.AuditItemID = PE.AuditItemID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON PE.ContactMechanismID = EA.ContactMechanismID
    -------------------------------------------------------------------------------------------------


    -------------------------------------------------------------------------------------------------
	--- Set Retailer Flag Where Industry Classification is Customer-facing Dealership -- V1.1 -------
	UPDATE B
	SET B.RetailerFlag = 1
	FROM UsableEmailReport.Base B
	INNER JOIN [$(SampleDB)].Party.PartyClassifications PC ON COALESCE(NULLIF(B.MatchedODSPersonID,0),NULLIF(B.MatchedODSOrganisationID,0),NULLIF(B.MatchedODSPartyID,0)) = PC.PartyID
	INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
										AND PC.PartyTypeID = IC.PartyTypeID
	INNER JOIN [$(SampleDB)].Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID AND PT.PartyType IN ('Manufacturer Internal Dealership', 'Customer-facing Dealership') 
    -------------------------------------------------------------------------------------------------


    -------------------------------------------------------------------------------------------------
	--- Set Retailer Email Flag Where Industry Classification is Customer-facing Dealership -- V1.1 -------
	UPDATE B
	SET B.RetailerEmailFlag = 1
	FROM UsableEmailReport.Base B
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON COALESCE(NULLIF(B.MatchedODSPersonID,0),NULLIF(B.MatchedODSOrganisationID,0),NULLIF(B.MatchedODSPartyID,0)) = PCM.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.vwBlacklistedEmail BCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
	WHERE BCM.PreventsSelection = 1
	AND BCM.BlacklistTypeID IN (33)
    -------------------------------------------------------------------------------------------------


    -------------------------------------------------------------------------------------------------
	--- Set ContactedbyEmail Flag  -- V1.1 -------
	UPDATE B
	SET B.ContactedbyEmail = 1
	FROM UsableEmailReport.Base B
	INNER JOIN [$(SampleDB)].[Event].CaseOutput CO ON B.CaseID = CO.CaseID
	INNEr JOIN [$(SampleDB)].[Event].CaseOutputTypes [COT] ON CO.CaseOutputTypeID = [COT].CaseOutputTypeID
	WHERE [COT].CaseOutputType = 'Online'
    -------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------
	--- Set ContactedbyPost Flag  -- V1.1 -------
	UPDATE B
	SET B.ContactedbyPost = 1
	FROM UsableEmailReport.Base B
	INNER JOIN [$(SampleDB)].[Event].CaseOutput CO ON B.CaseID = CO.CaseID
	INNEr JOIN [$(SampleDB)].[Event].CaseOutputTypes [COT] ON CO.CaseOutputTypeID = [COT].CaseOutputTypeID
	WHERE [COT].CaseOutputType = 'Postal'
    -------------------------------------------------------------------------------------------------



	------------------------------------------------------------------------------------------------
	-- Set flags	
	------------------------------------------------------------------------------------------------

	UPDATE UsableEmailReport.Base 
	SET EmailSuppression = 1
	WHERE PartySuppression	= 1
		

	UPDATE UsableEmailReport.Base
	SET InvalidEmailAddress = 1 
	WHERE  ExclusionListMatch	= 1
		OR BarredEmailAddress	= 1
		OR BarredDomain			= 1	
		OR InternalDealer		= 1
		OR SampleEmailBouncebackFlag = 1



	UPDATE UsableEmailReport.Base 
	SET UsableFlag = 1
	WHERE   SuppliedEmail		= 1
		AND EmailSuppression	= 0
		--AND PartySuppression	= 0		-- Rolled up into EmailSuppression (above)
		AND InvalidEmailAddress = 0 
		

	UPDATE UsableEmailReport.Base
	SET OtherReasonsNotSelected = 1
	WHERE   UsableFlag		  = 1
	  AND	ISNULL(CaseID, 0) = 0 


	------------------------------------------------------------------------------------------------
	-- Populate Detail Table
	------------------------------------------------------------------------------------------------

	TRUNCATE TABLE [UsableEmailReport].[Detail];

	INSERT INTO [UsableEmailReport].[Detail] (ReportDate, DateFrom, DateTo, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, 
				UsableFlag, EmailSuppression, PartySuppression, SuppliedEmail, UncodedDealer, InvalidEmailAddress, BarredEmailAddress, BarredDomain, InternalDealer, VIN, EventDate, SampleEmailAddress
				,CaseEmailAddress, BounceBackFlag, SampleEmailBounceBackFlag, EventDateOutOfDate, [MatchedODSEventID], OtherReasonsNotSelected, RegistrationNumber, AuditItemID
				, GlobalExclusionListMatch, PreviousEmailAddress, PreviousEventBounceBack, AFRLCode, AFRLCodeUsable, RetailerFlag, RetailerEmailFlag  -- V1.1
				, ContactedbyEmail, ContactedbyPost, InvalidSaleType)		-- V1.1 & V1.4
	SELECT ReportDate, DateFrom, DateTo, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, FullName, OrganisationName, UsableFlag, EmailSuppression, PartySuppression, 
				SuppliedEmail, UncodedDealer, InvalidEmailAddress, BarredEmailAddress, BarredDomain, InternalDealer, VIN, EventDate, SampleEmailAddress 
				,CaseEmailAddress, BounceBackFlag, 
				CASE WHEN BounceBackFlag = 1 AND CaseEmailAddress = SampleEmailAddress THEN 1 ELSE 0 END AS SampleEmailBounceBackFlag, 
				EventDateOutOfDate, [MatchedODSEventID], OtherReasonsNotSelected, RegistrationNumber, AuditItemID, 
				CASE WHEN ExclusionListMatch = 1 THEN 1 ELSE 0 END AS GlobalExclusionListMatch, PreviousEmailAddress, CASE WHEN PreviousEventBounceBack = 1 THEN 1 ELSE 0 END AS PreviousEventBounceBack, AFRLCode, AFRLCodeUsable,			-- V1.1
				CASE WHEN RetailerFlag = 1 THEN 1 ELSE 0 END AS RetailerFlag, CASE WHEN RetailerEmailFlag = 1 THEN 1 ELSE 0 END AS RetailerEmailFlag,	-- V1.1
				CASE WHEN ISNULL(ContactedbyEmail,0) = 1 AND ISNULL(ContactedbyPost,0) = 0 THEN 1 ELSE 0 END AS ContactedbyEmail, 							-- V1.1
				CASE WHEN ISNULL(ContactedbyPost,0) = 1 THEN 1 ELSE 0 END AS ContactedbyPost,
				InvalidSaleType -- V1.4 														-- V1.1
	FROM UsableEmailReport.Base b
	WHERE ISNULL(b.DuplicateRowFlag, 0) = 0

	------------------------------------------------------------------------------------------------
	-- Populate Summary Table
	------------------------------------------------------------------------------------------------

	TRUNCATE TABLE [UsableEmailReport].[Summary] ;

	INSERT INTO [UsableEmailReport].[Summary]  (ReportDate, DateFrom, DateTo, SubNationalRegion, CombinedDealer, DealerName, DealerCode, DealerCodeGDD, TotalRecs, TotalPB, NoEmailSuppliedSum, 
													InvalidEmailSum, EmailSuppressionSum, OtherReasonsNotSelectedSum, UsableEmailSum, TotalSalesType) -- V1.4
	SELECT	ReportDate, 
			DateFrom, 
			DateTo, 
			SubNationalRegion, 
			CombinedDealer, 
			CASE WHEN DealerName IS NULL THEN '[Uncoded Dealers]' ELSE DealerName END AS DealerName, 
			CASE WHEN DealerName IS NULL THEN '' ELSE DealerCode END AS DealerCode,	-- Blank out where uncoded Dealer so that all uncoded roll up into one row
			DealerCodeGDD, 
			COUNT(*) AS TotalRecs,
			SUM(CASE AFRLCode WHEN 'P' THEN 1 WHEN 'B' THEN 1 ELSE 0 END) AS TotalPB,	-- V1.2 Add TotalPB
			SUM(CASE SuppliedEmail WHEN 1 THEN 0 ELSE 1 END) AS NoEmailSuppliedSum, 
			SUM(ISNULL(InvalidEmailAddress , 0)) AS InvalidEmailSum, 
			SUM(ISNULL(EmailSuppression, 0)) AS EmailSuppressionSum,  
			SUM(OtherReasonsNotSelected) AS OtherReasonsNotSelectedSum,
			SUM(UsableFlag) AS UsableEmailSum,
			SUM(CASE InvalidSaleType WHEN 1 THEN 0 ELSE 1 END) AS TotalSalesType -- V1.4
			
	FROM [UsableEmailReport].[Detail]
	GROUP BY ReportDate, 
			DateFrom, 
			DateTo, 
			SubNationalRegion, 
			CombinedDealer, 
			CASE WHEN DealerName IS NULL THEN '[Uncoded Dealers]' ELSE DealerName END, 
			CASE WHEN DealerName IS NULL THEN '' ELSE DealerCode END, 
			DealerCodeGDD


	-- Set the percentages
	UPDATE [UsableEmailReport].[Summary] 
	SET [NoEmailSupplied%]	= CONVERT(DECIMAL(5,4), ROUND(((NoEmailSuppliedSum * 1.0 )/ TotalRecs ),4)), 
		[InvalidEmail%]		= CONVERT(DECIMAL(5,4), ROUND(((InvalidEmailSum * 1.0 )		/ TotalRecs ),4)) , 
		[EmailSuppression%]	= CONVERT(DECIMAL(5,4), ROUND(((EmailSuppressionSum * 1.0 )	/ TotalRecs ),4)) , 
		[OtherReasonsNotSelected%]	= CONVERT(DECIMAL(5,4), ROUND(((OtherReasonsNotSelectedSum * 1.0 )	/ TotalRecs ),4)) , 
		[UsableEmail%]		= CONVERT(DECIMAL(5,4), ROUND(((UsableEmailSum * 1.0 )			/ TotalRecs ),4))  
	FROM [UsableEmailReport].[Summary]  

	--SELECT * FROM [UsableEmailReport].[Summary] 


	  
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

