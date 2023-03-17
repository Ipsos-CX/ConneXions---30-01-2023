CREATE PROCEDURE [Selection].[uspRunSelection]
	@QuestionnaireRequirementID [dbo].[RequirementID], 
	@SelectionRequirementID [dbo].[RequirementID]
AS
/*
STATUS: CHECKED OUT – BK <2023-03-17>
		Purpose: main sample selection run
		
		Version			Date			Developer			Comment
LIVE	1.0				$(ReleaseDate)	Simon Peacock		Created
LIVE	1.1				06/Nov/2012		Pasrdip Mudhar		BUG 7842: Update sample quality logging to set flags correctly for sample data loaded.
															The logging match is done on VehicleID, EventID and DealerID (Sales/Service)
LIVE	1.2				21/Feb/2013		Chris Ross			BUG 8614: Fix where NonLatestEvent flag being set for all Sales records.
LIVE	1.3				11/06/2013		Chris Ross			PersonRequired/OrganisationRequired checks setting the excluded flags the wrong way round.
LIVE	1.4				21/06/2013		Chris Ross			BUG 8969: Lookup on IndustryClassifications to be done on Person PartyId as well as Organisation PartyID
LIVE	1.5				09/01/2014		Chris Ross			BUG 9500: Filter on MobilePhone and MobilePhoneAndEmail and flag in Loggin table accordingly.
LIVE														Replace Drop and recreate of Base table with Truncate statement.
LIVE	1.6				20/02/2014		Ali Yuksel			Bug 10008: Set EventDateOutOfDate=0 in SampleQualityAndSelectionLogging when selection is done
LIVE	1.7				27/03/2014		Chris Ross			BUG 10075: Do not match Organisations based on address for South Africa as the the addresses are populated/reliable
LIVE	1.8				14/05/2014		Ali Yuksel			BUG 10346: Parties with no name marked in MissingPartyName
LIVE	1.9				23/05/2014		Eddie Thomas		BUG 10079: Add Relative recontact period rule logic
LIVE	1.91			23/05/2014		Martin Riverol		BUG 10240: Add RequiredLanguage rule logic
LIVE	1.92			17/06/2014		Ali Yuksel			BUG 10436: InternalDealer added and InvalidOwnershipCycle fixed 
LIVE	1.93			24/06/2014		Martin Riverol		BUG 10079: Store the previous CaseID of selections whether it is captured by relative recontact or not
LIVE	2.1				15/12/2014		Eddie Thomas		BUG 11047: set new flag PreviousEventBounceBack
LIVE	2.2				08/01/2015		Chris Ross			BUG 11025: Add in check on "Organisation name at address lookup" to exclude those markets who 
															           are Email matching.
LIVE	2.3				27/04/2015		Chris Ross			BUG 6061: Add in changes for CRC (plus some Roadside).
LIVE	2.4				24/06/2015		Chris Ross			BUG 11595: Add in CRCNetworks and RoadsideNetworks into Dealer Country lookup
LIVE	3.0				25/08/2015		Chris Ross			BUG 11705: Moved the main base table build selections and updates into RunScheduledSelections proc
																		and modified this procedure to just select from the pre-build pool of data.
LIVE	3.1				08/09/2015		Chris Ross			BUG 11796: Add in checks on RoleType and (where flagged in QuestionnaireRequirement) Sale Type validation
LIVE	3.2				16/10/2015		Chris Ross			BUG 11933: Add in selective AFRL code and Dealer Exclusion list filtering, including Barred Email 
																		functionality, where flagged in QuestionnaireRequirement.
LIVE	3.3				27/11/2015		Chris Ross			BUG 12137: Add barred email functionality back in for all selections
LIVE	3.4				20/01/2016		Chris Ross			BUG 12137: Modify barred 1email functionality so that AFRL only applies the "Dealer specific email address - manually added" list
																		of emails.  Non-AFRL will apply all "Prevents Selection" lists of emails blacklist strings. To implement this I we
																		use the PreventsSelection and AFRLFilter flags so that we can control via the MetaData. In other words only Barred Email 
																		lists with the AFRLFilter flag set to 1 will be applied to AFRL.
LIVE	3.5				02/02/2016		Chris Ross			BUG 12038: Add in PreOwned event types	
LIVE	3.6				22/02/2016		Chris Ross			BUG 12226: Modify Best Email Address for alternative LatestEmail table to now use UseLatestEmailTable flag.
LIVE	3.7				13/04/2016		Chris Ross			BUG 12226: Add in new bared email functionality for Latest Email surveys. Also, contrain LatestEmails and AFRL email lookups by EventCategoryId
LIVE	3.8				29/11/2016		Chris Ledger		BUG 13160: Add in quotas for CQI
LIVE	3.9				02/12/2016		Chris Ross			BUG 13364: Add in Customer Contact Preferences filtering and logging	RELEASED LIVE
LIVE	3.10			21/12/2016		Chris Ledger		BUG 13422: Add in US Pilot Questionnaire filtering and logging
LIVE	3.11			05/01/2017		Chris Ledger		BUG 13063: SV-CRM - UK Purchase - Changing AFRL to VEH_SALE_TYPE_DESC
LIVE	3.12			23/01/2017		Chris Ledger		BUG 13160: Fix bug with Zero Quota Rounding
LIVE	3.13			03/02/2017		Chris Ledger		BUG 13063: Select most recent VEH_SALE_TYPE_DESC
LIVE	3.14			08/02/2017		Eddie Thomas		BUG 13525: Rockar dealer questionnaire flag
LIVE	3.15			26/04/2017		Chris Ledger		BUG 13854: Exclude records without CQI Extra Vehicle Feed from CQI selections	RELEASED LIVE
LIVE	3.16			27/04/2017		Chris Ledger		BUG 13378: Change Customer Contact Preferences to fix issue in Mixed Methodology markets	RELEASED LIVE
LIVE	3.17			27/04/2017		Chris Ledger		BUG 13378: Exclude records without associated Agency from UK Lost Leads		RELEASED LIVE: CL 2017-05-02
LIVE	3.18			09/05/2017		Chris Ledger		BUG 13897: Exclude non LostLead events from LostLead selections			RELEASED LIVE: CL 2017-05-09
LIVE	3.19			04/08/2017		Chris Ledger		BUG 14143: Add Total Quotas for CQI (N.B. Quota applies over multiple weeks)	RELEASED LIVE: ET 2017-08-14
LIVE	3.20			25/08/2017		Eddie Thomas		BUG 14141: Adding support for new survey Bodyshop								RELEASED LIVE
LIVE	3.21			25/08/2017		Chris Ledger		BUG 14189: Change CQI EVF exclusions	RELEASED LIVE: CL 2017-08-26
LIVE	3.22			05/09/2017		Chris Ross			BUG 14122: Add in PDI Flag check.
LIVE	3.23			31/10/2017		Chris Ross			BUG 14344: Comment out old AFRL Code check as redundant. Modify CRM Sale Type and Type of Sale checks to be date CRM 4.0 release date dependent.
LIVE	3.24			14/11/2017		Chris Ledger		BUG 14272: Exclude records without associated Agency from US Lost Leads
LIVE	3.25			16/11/2017		Ben King			BUG 14197: Respondent selected again after responding to survey
LIVE	3.26			21/11/2017		Chris Ledger		BUG 14347: Add MCQI and fix bug in Sales Type checks
LIVE	3.27			29/12/2017		Chris Ross			BUG 14200: Modify to check whether Unsubscribe is present for the party and set the new Unsubscribed flag on Sample Logging.
LIVE	3.28			22/01/2017		Chris Ross			BUG 14435: Add in new columns SelectionOrgPartyID, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID and SelectionMobileID
																		Also, temporarily store logging update values so that only a single write to the SampleQualityAndSelectionLogging table is performed.	RELEASED LIVE: CL 2018-03-26
LIVE	3.29			21/02/2018		Chris Ledger		BUG 14207: Event Already selected no longer dependent on PartyID	NOT RELEASED LIVE: CL 2018-03-26
LIVE	3.30			22/02/2018		Chris Ledger		BUG 14555: Change Exclude Query for Lost Lead Agencies				RELEASED LIVE
LIVE	3.31			23/05/2018		Eddie Thomas		BUG 14711: Prevent market DDW events from being selected
LIVE	3.32			21/09/2018		Eddie Thomas		BUG 14820: Localised suppression functionailty, introduced for LostLeads  
LIVE	3.33			01/10/2018		Chris Ledger		BUG 14964: Remove CQI EVF exclusions
LIVE	3.34			29/10/2018		Chris Ledger		BUG 15056: Add I-Assistance
LIVE	3.35			22/01/2019		Chris Ledger		BUG 15199: Add CQI EVF exclusions back in
LIVE	3.36			24/01/2019		Eddie Thomas		BUG 14820: Lost Leads Bug fix 
LIVE	3.37			15/04/2019		Chris Ledger		BUG 15321: Add Invalid Variant exclusions
LIVE	3.38			30/09/2019		Chris Ledger		BUG 15616: Remove redundant TypeofSale check code replaced by V3.23
LIVE	3.39			01/10/2019		Chris Ledger		BUG 15490: Add PreOwned LostLeads
LIVE	3.40			17/10/2019		Chris Ledger		BUG 16673: Add CQI Survey
LIVE	3.41			11/11/2019		Chris Ledger		BUG 15576: Add Canada to Exclusion of Lost Lead Selections records without Agency
LIVE	3.42			23/01/2020		Chris Ross			BUG 16816: Include new check on ValidateSaleTypeFromDate. If present, then only apply SaleType check to records loaded after that date. 
LIVE	3.43			18/02/2020		Chris Ledger		BUG 17942: Add MCQI Survey
LIVE	3.44			19/03/2021		Chris Ledger		TASK 299: Add CRC General Enquiry
LIVE	3.45			12/04/2021		Chris Ledger		TASK 325: Exclude VISTACONTRACT_PREVIOUS_RET_USE = Z002 (Outcycled service loaners) from US/Canada in CRM Sale Type check
LIVE	3.46			23/04/2021		Chris Ledger		TASK 387: Fix bug in NotInQuota logging
LIVE	3.47			13/05/2021		Chris Ledger		TASK 441: Change CQI/MCQI setting and log MissingPerson/MissingOrganisation
LIVE	3.48			25/05/2021		Chris Ledger		TASK 461: Exclude EventDate <= VEH_REGISTRATION_DATE for UK Service
LIVE	3.49			08/06/2021		Chris Ledger		TASK 476: Include old method of identifying CQI as well
LIVE	3.50			20/08/2021		Chris Ledger		TASK 567: Drop UK from LostLead exclusions without Agency checks
LIVE	3.51			08/09/2021		Chris Ledger		TASK 585: Change LostLeads Agency check to use OutletCode
LIVE	3.52			08/09/2021		Chris Ledger		TASK 585: Drop US/Canada from LostLead exclusions without Agency checks
LIVE	3.53			29/09/2021		Chris Ledger		TASK 601: Exclude Germany/Austria/Czech Republic Sales if existing Service event exists
LIVE	3.54			20/01/2022		Chris Ledger		TASK 739: Selection of organisations at same address moved from uspRunSelection SP
LIVE	3.55			04/02/2022		Chris Ledger		TASK 585: Disable Lost Lead Suppressions
LIVE	3.56			08/02/2022		Chris Ledger		TASK 628: Do not log previously selected events 
LIVE	3.57			08/02/2022		Chris Ledger		TASK 628: Change logging of PreviousCaseID from BIT to INT
LIVE	3.58			03/03/2022		Chris Ledger		TASK 791: Add QuestionnaireRequirementID to #LoggingValues JOIN for United Kingdom Land Rover Sales
LIVE	3.59			07/06/2022		Eddie Thomas		TASK 877: Add Land Rover Survey
LIVE	3.60			20/06/2022		Chris Ledger		TASK 917: Add CQI 1MIS
LIVE	3.61			20/06/2022		Eddie Thomas		TASK 900: Business & Fleet Vehicle Selection Rule changes 
LIVE	3.62			12/07/2022		Ben King			TASK 943: BUG 19536 - Company exclusions
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

		-- DECLARE SELECTION VARIABLES
		DECLARE @StartDays INT
		DECLARE @EndDays INT
		DECLARE @SelectionDate DATETIME2
		DECLARE @EventCategory VARCHAR(50)
		DECLARE @EventCategoryID INT
		DECLARE @ManufacturerPartyID dbo.PartyID
		DECLARE @OwnershipCycle dbo.OwnershipCycle
		DECLARE @CountryID dbo.CountryID
		DECLARE @SelectSales BIT					
		DECLARE @SelectPreOwned BIT					-- V3.5
		DECLARE @SelectService BIT
		DECLARE @SelectWarranty BIT
		DECLARE @SelectRoadside BIT
		DECLARE @SelectCRC	BIT						-- V2.3
		DECLARE @SelectLostLeads	BIT				-- V3.18
		DECLARE @SelectBodyshop	BIT					-- V3.20
		DECLARE @SelectIAssistance	BIT				-- V3.34
		DECLARE @SelectPreOwnedLostLeads	BIT		-- V3.39
		DECLARE @SelectCQI3MIS	BIT					-- V3.40
		DECLARE @SelectCQI24MIS	BIT					-- V3.40
		DECLARE @SelectMCQI1MIS BIT					-- V3.43
		DECLARE @SelectCQI1MIS BIT					-- V3.60
		DECLARE @SelectGeneralEnquiry BIT			-- V3.44
		DECLARE @SelectLandRoverExperience BIT		-- V3.59
		DECLARE @PersonRequired BIT
		DECLARE @OrganisationRequired BIT
		DECLARE @StreetRequired BIT
		DECLARE @PostcodeRequired BIT
		DECLARE @EmailRequired BIT
		DECLARE @TelephoneRequired BIT
		DECLARE @StreetOrEmailRequired BIT
		DECLARE @TelephoneOrEmailRequired BIT
		DECLARE @MobilePhoneRequired BIT
		DECLARE @MobilePhoneOrEmailRequired BIT
		DECLARE @LanguageRequired BIT
		DECLARE @QuestionnaireIncompatibilityDays INT
		DECLARE @UpdateSelectionLogging BIT
		DECLARE @RelativeRecontactDays INT
		DECLARE @ValidateSaleTypes INT
		DECLARE @ValidateSaleTypeFromDate   DATETIME	-- V3.42
		DECLARE @ValidateAFRLCodes INT					-- V3.2
		DECLARE @UseLatestEmailTable INT				-- V3.5
		DECLARE @UseQuotas BIT							-- V3.8
		DECLARE @FilterOnDealerPilotOutputCodes BIT		-- V3.10
		DECLARE @CRMSaleTypeCheck BIT					-- V3.11
		DECLARE @CQISurvey BIT							-- V3.15	
		DECLARE @PDIFlagCheck BIT						-- V3.22
		DECLARE @SampleLoadActive BIT					-- V3.25
		DECLARE @MCQISurvey BIT							-- V3.26	
		DECLARE @IgnoreWarrantyEvents BIT				-- V3.31
		DECLARE @NumberOfDaysToExclude	INT				-- V3.32
		DECLARE @ValidateCommonSaleType	INT				-- V3.61	
		
		SELECT
			 @StartDays = QR.StartDays
			,@EndDays = QR.EndDays
			,@SelectionDate = SR.SelectionDate
			,@EventCategory = B.Questionnaire
			,@EventCategoryID = (	SELECT EventCategoryID 
									FROM Event.EventCategories 
									WHERE EventCategory = B.Questionnaire)
			,@ManufacturerPartyID = B.ManufacturerPartyID
			,@OwnershipCycle = QR.OwnershipCycle
			,@CountryID = B.CountryID
			,@SelectSales = B.SelectSales
			,@SelectPreOwned = B.SelectPreOwned						-- V3.5
			,@SelectService = B.SelectService
			,@SelectWarranty = B.SelectWarranty
			,@SelectRoadside = B.SelectRoadside
			,@SelectCRC = B.SelectCRC								-- V2.3
			,@SelectLostLeads = B.SelectLostLeads					-- V3.18
			,@SelectBodyshop = B.SelectBodyshop						-- V3.20
			,@SelectIAssistance = B.SelectIAssistance				-- V3.34
			,@SelectPreOwnedLostLeads = B.SelectPreOwnedLostLeads	-- V3.39
			,@SelectCQI3MIS = B.SelectCQI3MIS						-- V3.40
			,@SelectCQI24MIS = B.SelectCQI24MIS						-- V3.40
			,@SelectMCQI1MIS = B.SelectMCQI1MIS						-- V3.43
			,@SelectCQI1MIS = B.SelectCQI1MIS						-- V3.60
			,@SelectGeneralEnquiry = B.SelectGeneralEnquiry			-- V3.44
			,@SelectLandRoverExperience = b.SelectLandRoverExperience -- V3.59  
			,@PersonRequired = B.PersonRequired
			,@OrganisationRequired = B.OrganisationRequired
			,@StreetRequired = B.StreetRequired
			,@PostcodeRequired = B.PostcodeRequired
			,@EmailRequired = B.EmailRequired
			,@TelephoneRequired = B.TelephoneRequired
			,@StreetOrEmailRequired = B.StreetOrEmailRequired
			,@TelephoneOrEmailRequired = B.TelephoneOrEmailRequired
			,@MobilePhoneRequired = B.MobilePhoneRequired					-- V1.5
			,@MobilePhoneOrEmailRequired = B.MobilePhoneOrEmailRequired		-- V1.5
			,@LanguageRequired = B.LanguageRequired
			,@QuestionnaireIncompatibilityDays = QR.QuestionnaireIncompatibilityDays
			,@UpdateSelectionLogging = B.UpdateSelectionLogging
			,@RelativeRecontactDays = QR.RelativeRecontactDays
			,@ValidateSaleTypes = QR.ValidateSaleTypes
			,@ValidateSaleTypeFromDate = ISNULL(QR.ValidateSaleTypeFromDate, '1900-01-01')	-- V3.42
			,@ValidateAFRLCodes = QR.ValidateAFRLCodes										-- V3.2
			,@UseLatestEmailTable = QR.UseLatestEmailTable									-- V3.5
			,@UseQuotas = SR.UseQuotas														-- V3.8
			,@FilterOnDealerPilotOutputCodes = QR.FilterOnDealerPilotOutputCodes			-- V3.10
			,@CRMSaleTypeCheck = QR.CRMSaleTypeCheck										-- V3.11
			,@CQISurvey	= CASE	WHEN B.Questionnaire LIKE '%CQI%' THEN 1					-- V3.47
								WHEN SUBSTRING(R.Requirement,1,3) = 'CQI' THEN 1			-- V3.49
								ELSE 0 END											
			,@PDIFlagCheck = QR.PDIFlagCheck												-- V3.22
			,@SampleLoadActive = B.SampleLoadActive											-- V3.25
			,@MCQISurvey = CASE	WHEN B.Questionnaire LIKE '%MCQI%' THEN 1					-- V3.47
								WHEN SUBSTRING(R.Requirement,1,4) = 'MCQI' THEN 1			-- V3.49
								ELSE 0 END
			,@IgnoreWarrantyEvents = QR.IgnoreWarranty										-- V3.31
			,@NumberOfDaysToExclude = QR.NumberOfDaysToExclude								-- V3.32
			,@ValidateCommonSaleType = QR.ValidateCommonSaleType							-- V3.61
		FROM dbo.vwBrandMarketQuestionnaireSampleMetadata B
			INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = B.QuestionnaireRequirementID
			INNER JOIN Requirement.Requirements R ON QR.RequirementID = R.RequirementID		-- V3.15
			INNER JOIN Requirement.RequirementRollups QS ON QS.RequirementIDPartOf = QR.RequirementID
			INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = QS.RequirementIDMadeUpOf
		WHERE QR.RequirementID = @QuestionnaireRequirementID
			AND SR.RequirementID = @SelectionRequirementID


		-- Get the switch over date for CRM VEH_SALE_TYPE_DESC to stop being used and Sale Type Code checks to be used instead.   -- V3.23
		DECLARE @CRMSaleTypeCheckSwitchDate DATE
		SELECT @CRMSaleTypeCheckSwitchDate = CRMSaleTypeCheckSwitchDate 
		FROM Selection.System


		-- TRUNCATE THE BASE TABLE TO HOLD THE FINAL DATA
		TRUNCATE TABLE Selection.Base								-- V1.5


		-- NOW GET THE APPROPRIATE EVENT DETAILS FROM THE POOL INTO THE BASE TABLE 
		INSERT INTO Selection.Base
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
			OrganisationPartyID, 
			CountryID, 
			PostalContactMechanismID, 
			Street, 
			Postcode, 
			EmailContactMechanismID, 
			PhoneContactMechanismID, 
			LandlineContactMechanismID, 
			MobileContactMechanismID,
			QuestionnaireRequirementID
		)
		SELECT DISTINCT
			P.EventID, 
			P.VehicleID, 
			P.VehicleRoleTypeID, 
			P.VIN, 
			P.EventCategory, 
			P.EventCategoryID, 
			P.EventType, 
			P.EventTypeID, 
			P.EventDate, 
			P.ManufacturerPartyID, 
			P.ModelID, 
			P.PartyID, 
			P.RegistrationNumber, 
			P.RegistrationDate, 
			P.OwnershipCycle, 
			P.DealerPartyID, 
			P.DealerCode, 
			P.OrganisationPartyID, 
			P.CountryID, 
			P.PostalContactMechanismID, 
			P.Street, 
			P.Postcode, 
			P.EmailContactMechanismID, 
			P.PhoneContactMechanismID, 
			P.LandlineContactMechanismID, 
			P.MobileContactMechanismID,
			@QuestionnaireRequirementID
		FROM Selection.[Pool] P
		WHERE EventCategoryID = @EventCategoryID
			AND ManufacturerPartyID = @ManufacturerPartyID
			AND ISNULL(CountryID,0) = @CountryID				


		-------------------------------------------------------------------------------------
		-- Now run through data checks 
		-------------------------------------------------------------------------------------
			

		-----------------------------------------	
		-- V1.8 -- EXCLUDE PARTIES WITH NO NAME
		-----------------------------------------	
		UPDATE SB
		SET DeletePartyName = 1
		FROM Selection.Base SB
			LEFT JOIN Party.People PP ON PP.PartyID = SB.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = SB.PartyID		
		WHERE COALESCE(PP.PartyID, O.PartyID) IS NULL 
		
		
		-----------------------------------------	
		-- V2.0 -- EXCLUDE INTERNAL DEALERS
		-----------------------------------------
		IF ISNULL(@MCQISurvey,0) = 0		-- V3.26 Don't exclude for MCQI survey
		BEGIN	
			UPDATE SB
			SET DeleteInternalDealer = 1
			FROM Selection.Base SB
				LEFT JOIN Party.DealershipClassifications DC ON DC.PartyID = SB.DealerPartyID 
							AND DC.PartyTypeID = (	SELECT PartyTypeID 
													FROM Party.PartyTypes 
													WHERE PartyType = 'Manufacturer Internal Dealership')		
			WHERE DC.PartyID IS NOT NULL 
		END
		
		-----------------------------------------	
		-- V2.0 -- Mark InvalidOwnershipCycle
		-----------------------------------------	
		UPDATE SB
		SET DeleteInvalidOwnershipCycle = 1
		FROM Selection.Base SB
			JOIN Event.OwnershipCycle OC ON OC.EventID = SB.EventID
		WHERE ISNULL(OC.OwnershipCycle, 1) <> COALESCE(@OwnershipCycle, OC.OwnershipCycle, 1)
		
		

		-----------------------------------------	
		-- NOW CHECK IF WE ARE SELECTION THE EVENT TYPES
		-----------------------------------------	
		IF ISNULL(@SelectSales, 0) = 0
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'Sales'
		END
		IF ISNULL(@SelectPreOwned, 0) = 0				-- V3.5
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'PreOwned'
		END
		IF ISNULL(@SelectService, 0) = 0
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'Service'
		END
		IF ISNULL(@SelectWarranty, 0) = 0
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'Warranty'
		END		
		IF ISNULL(@SelectRoadside, 0) = 0
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'Roadside'
		END
		IF ISNULL(@SelectCRC, 0) = 0				-- V2.3
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'CRC'
		END
		IF ISNULL(@SelectLostLeads, 0) = 0			-- V3.18
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'LostLeads'
		END
		IF ISNULL(@SelectBodyshop, 0) = 0			-- V3.20
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'Bodyshop'
		END
		IF ISNULL(@SelectIAssistance, 0) = 0		-- V3.34
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'I-Assistance'
		END		
		IF ISNULL(@SelectPreOwnedLostLeads, 0) = 0	-- V3.39
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'PreOwned LostLeads'
		END		
		IF ISNULL(@SelectCQI3MIS, 0) = 0			-- V3.40
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'CQI 3MIS'
		END		
		IF ISNULL(@SelectCQI24MIS, 0) = 0			-- V3.40
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'CQI 24MIS'
		END	
		IF ISNULL(@SelectMCQI1MIS, 0) = 0			-- V3.43
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'MCQI 1MIS'
		END	
		IF ISNULL(@SelectCQI1MIS, 0) = 0			-- V3.60
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'CQI 1MIS'
		END	
		IF ISNULL(@SelectGeneralEnquiry, 0) = 0		-- V3.44
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'CRC General Enquiry'
		END
		IF ISNULL(@SelectLandRoverExperience, 0) = 0		-- V3.59
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'Land Rover Experience'
		END
		
		-----------------------------------------	
		-- ADD IN EMAIL ContactMechanismID
		-----------------------------------------	
		IF ISNULL(@MCQISurvey,0) = 1						-- V3.26 Use Blacklist Included best party email table for MCQI
		BEGIN
			UPDATE SB
			SET SB.EmailContactMechanismID = PBEAB.ContactMechanismID
			FROM Selection.Base SB
				INNER JOIN Meta.PartyBestEmailAddressesBlacklistIncluded PBEAB ON PBEAB.PartyID = SB.PartyID 
																 AND PBEAB.EventCategoryID = SB.EventCategoryID		-- V3.7 - AFRL Emails are now contrained by EventCategoryId
		END
		ELSE BEGIN
			IF ISNULL(@ValidateAFRLCodes,0) = 1					-- V3.2	- Conditionally use the AFRL best party email table for lookup
			BEGIN 
				UPDATE SB
				SET SB.EmailContactMechanismID = PBEAA.ContactMechanismID
				FROM Selection.Base SB
					INNER JOIN Meta.PartyBestEmailAddressesAFRL PBEAA ON PBEAA.PartyID = SB.PartyID 
																	 AND PBEAA.EventCategoryID = SB.EventCategoryID		-- V3.7 - AFRL Emails are now contrained by EventCategoryId
			END
			ELSE BEGIN 
				IF ISNULL(@UseLatestEmailTable,0) = 1			-- V3.5	- Conditionally use the Latest Email best party email table for lookup
				BEGIN 
					UPDATE SB
					SET SB.EmailContactMechanismID = PBEAL.ContactMechanismID
					FROM Selection.Base SB
						INNER JOIN Meta.PartyBestEmailAddressesLatestOnly PBEAL ON PBEAL.PartyID = SB.PartyID
																			   AND PBEAL.EventCategoryID = SB.EventCategoryID   -- V3.7 - LatestEmails are now contrained by EventCategoryId
				END
				ELSE
				BEGIN
					UPDATE SB
					SET SB.EmailContactMechanismID = PBEA.ContactMechanismID
					FROM Selection.Base SB
						INNER JOIN Meta.PartyBestEmailAddresses PBEA ON PBEA.PartyID = SB.PartyID
				END
			END
		END


		-----------------------------------------	
		-- ADD IN TELEPHONE ContactMechanismIDs
		-----------------------------------------	
		UPDATE SB
		SET  SB.PhoneContactMechanismID = TN.PhoneID,
			SB.LandlineContactMechanismID = TN.LandlineID,
			SB.MobileContactMechanismID = TN.MobileID
		FROM Selection.Base SB
			INNER JOIN Meta.PartyBestTelephoneNumbers TN ON TN.PartyID = SB.PartyID		
		

		----------------------------------------------------------------------	-- V3.28
		-- Save the ContactMechanismIDs and Organisation PartyID for writing 
		-- to the logging table.
		-- 
		-- Note: we save here as values may get cleared or overwritten later
		-- as part of the selection process.
		----------------------------------------------------------------------

		UPDATE Selection.Base
		SET SelectionOrganisationID  = OrganisationPartyID,
			SelectionPostalID		 = PostalContactMechanismID,
			SelectionEmailID		 = EmailContactMechanismID,
			SelectionPhoneID		 = PhoneContactMechanismID,
			SelectionLandlineID		 = LandlineContactMechanismID,
			SelectionMobileID		 = MobileContactMechanismID
			

		--------------------------------------------------------------------		
		-- Checks based on Required field flags
		--------------------------------------------------------------------		
		IF @PersonRequired = 1 AND @OrganisationRequired = 0
		BEGIN
			UPDATE SB
			SET DeletePersonRequired = 1
			FROM Selection.Base SB
				INNER JOIN Party.Organisations O ON O.PartyID = SB.PartyID
		END
		IF @PersonRequired = 0 AND @OrganisationRequired = 1
		BEGIN
			UPDATE SB
			SET DeleteOrganisationRequired = 1
			FROM Selection.Base SB
				INNER JOIN Party.People PP ON PP.PartyID = SB.PartyID
		END
		IF @PersonRequired = 1 AND @OrganisationRequired = 1
		BEGIN
			UPDATE Selection.Base
			SET DeleteOrganisationRequired = 0, DeletePersonRequired = 0
		END 
		IF @StreetRequired = 1
		BEGIN
			UPDATE Selection.Base
			SET DeleteStreet = 1
			WHERE ISNULL(Street, '') = ''
		END
		IF @PostcodeRequired = 1
		BEGIN
			UPDATE Selection.Base
			SET DeletePostcode = 1
			WHERE ISNULL(Postcode, '') = ''
		END
		IF @EmailRequired = 1
		BEGIN
			UPDATE Selection.Base
			SET DeleteEmail = 1
			WHERE ISNULL(EmailContactMechanismID, 0) = 0
		END
		IF @TelephoneRequired = 1
		BEGIN
			UPDATE Selection.Base
			SET DeleteTelephone = 1
			WHERE ISNULL(PhoneContactMechanismID, 0) = 0
				AND ISNULL(LandlineContactMechanismID, 0) = 0
				AND ISNULL(MobileContactMechanismID, 0) = 0
		END	
		IF @MobilePhoneRequired = 1							-- V1.5
		BEGIN
			UPDATE Selection.Base
			SET DeleteMobilePhone = 1
			WHERE ISNULL(MobileContactMechanismID, 0) = 0
		END
		
		IF @LanguageRequired = 1
		BEGIN
		
			;WITH PreferredLanguage (PartyID) AS 
			(
				SELECT PartyID
				FROM Party.PartyLanguages
				WHERE PreferredFlag = 1
			)
			UPDATE SB
			SET DeleteLanguage = 1
			FROM Selection.Base SB
			WHERE NOT EXISTS (	SELECT 1 
								FROM PreferredLanguage PL
								WHERE PL.PartyID = SB.PartyID)
		END
		
		--- Now check "OR" filters -------
		IF @StreetRequired = 0 
			AND @PostcodeRequired = 0 
			AND @EmailRequired = 0 
			AND @MobilePhoneRequired = 0
		BEGIN 
			IF @StreetOrEmailRequired = 1
			BEGIN
				UPDATE Selection.Base
				SET DeleteStreetOrEmail = 1
				WHERE ISNULL(EmailContactMechanismID, 0) = 0
					AND ISNULL(Street, '') = ''
			END
			IF @TelephoneOrEmailRequired = 1
			BEGIN
				UPDATE Selection.Base
				SET DeleteTelephoneOrEmail = 1
				WHERE ISNULL(EmailContactMechanismID, 0) = 0
					AND ISNULL(PhoneContactMechanismID, 0) = 0
					AND ISNULL(LandlineContactMechanismID, 0) = 0
					AND ISNULL(MobileContactMechanismID, 0) = 0
			END
			IF @MobilePhoneOrEmailRequired = 1								-- V1.5
			BEGIN
				UPDATE Selection.Base
				SET DeleteMobilePhoneOrEmail = 1
				WHERE ISNULL(EmailContactMechanismID, 0) = 0
					AND ISNULL(MobileContactMechanismID, 0) = 0
			END
		END 
		------------------------------


		--------------------------------------------------------------------		
		-- Further general checks 
		--------------------------------------------------------------------		
		
		-----------------------------------------			
		-- NOW CHECK FOR ANY RECONTACT PERIODS
		-----------------------------------------
		;WITH RecontactPeriod (PartyID) AS 
		(
			SELECT AEBI.PartyID
			FROM Event.AutomotiveEventBasedInterviews AEBI
				INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
				INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
				INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
				INNER JOIN Requirement.QuestionnaireAssociations QA ON SQ.RequirementIDPartOf = QA.RequirementIDTo
				INNER JOIN Requirement.QuestionnaireIncompatibilities QI ON QA.RequirementIDFrom = QI.RequirementIDFrom
															AND QA.RequirementIDTo = QI.RequirementIDTo
															AND QA.FromDate = QI.FromDate
															AND QI.ThroughDate IS NULL
			WHERE C.CreationDate >= DATEADD(DAY, @QuestionnaireIncompatibilityDays, GETDATE())
				AND QI.RequirementIDFrom = @QuestionnaireRequirementID
		)
		UPDATE SB
		SET SB.DeleteRecontactPeriod = 1
		FROM Selection.Base SB
			INNER JOIN RecontactPeriod ON RecontactPeriod.PartyID = SB.PartyID


		-----------------------------------------------------------
		-- SERVICE RE-CONTACT PERIOD AMENDED TO 45 DAYS (BUG 10079)
		-----------------------------------------------------------
		IF ISNULL(@RelativeRecontactDays,0) <> 0
			
			BEGIN 
			
				;WITH RelativeRecontactPeriod (CreationDate, PartyID, MaxCaseID) AS 
				(
					SELECT C.CreationDate,
						AEBI.PartyID,
						AEBI.MaxCaseID   
					FROM  (	SELECT MAX(AEBI.CaseID) AS MaxCaseID, 
								PartyID
							FROM Event.AutomotiveEventBasedInterviews AEBI
								INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = AEBI.CaseID
								INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf 
																			AND SQ.RequirementIDPartOf = @QuestionnaireRequirementID
							GROUP BY PartyID) AEBI
						INNER JOIN Event.Cases C ON AEBI.MaxCaseID = C.CaseID
				)
				UPDATE SB
				SET SB.DeleteRelativeRecontactPeriod = 1,
					SB.CaseIDPrevious = RRP.MaxCaseID
				FROM Selection.Base SB
				INNER JOIN	RelativeRecontactPeriod RRP ON RRP.PartyID = SB.PartyID 
				WHERE DATEDIFF(DAY, RRP.CreationDate, SB.EventDate) <= (@RelativeRecontactDays)
				
				
				;WITH RelativeRecontactPeriod (CreationDate, PartyID, MaxCaseID) AS 
				(
					SELECT C.CreationDate,
						AEBI.PartyID,
						AEBI.MaxCaseID   
					FROM  ( SELECT MAX(AEBI.CaseID) AS MaxCaseID, 
								PartyID
							FROM Event.AutomotiveEventBasedInterviews AEBI
								INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = AEBI.CaseID
								INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf 
																			AND SQ.RequirementIDPartOf = @QuestionnaireRequirementID					
							GROUP BY PartyID) AEBI
						INNER JOIN Event.Cases C ON AEBI.MaxCaseID = C.CaseID
				)
				UPDATE SB
				SET SB.CaseIDPrevious = RRP.MaxCaseID
				FROM Selection.Base SB
					INNER JOIN	RelativeRecontactPeriod RRP ON RRP.PartyID = SB.PartyID;
				
			END

		
		-----------------------------------------
		-- NOW CHECK FOR ANY EVENTS ALREADY SELECTED
		-----------------------------------------
		;WITH EXSELS (PartyID, VehicleRoleTypeID, VehicleID, EventID) AS 
		(	
			SELECT
				AEBI.PartyID,
				AEBI.VehicleRoleTypeID,
				AEBI.VehicleID,
				AEBI.EventID
			FROM Event.AutomotiveEventBasedInterviews AEBI
				INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = AEBI.CaseID
				INNER JOIN Requirement.SelectionRequirements SR ON SC.RequirementIDPartOf = SR.RequirementID 
																	AND SelectionTypeID = (	SELECT SelectionTypeID 
																							FROM Requirement.SelectionRequirements 
																							WHERE RequirementID = @SelectionRequirementID)
				INNER JOIN Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = SR.RequirementID
			WHERE SQ.RequirementIDPartOf = @QuestionnaireRequirementID
		)
		UPDATE SB
		SET SB.DeleteSelected = 1
		FROM Selection.Base SB
			INNER JOIN EXSELS ON EXSELS.EventID = SB.EventID
								--AND EXSELS.PartyID = SB.PartyID		-- V3.29
								AND EXSELS.VehicleRoleTypeID = SB.VehicleRoleTypeID
								AND EXSELS.VehicleID = SB.VehicleID


		--------------------------------------------------------------------------------------------------------------------------------
		-- V3.25 NOW CHECK FOR ANY EVENTS ALREADY SELECTED IN ALL QUESTIONNAIRE SELECTIONS (EXCLUDING AD-HOC SELECTION - SAMPLELOADACTIVE = 0)
		--------------------------------------------------------------------------------------------------------------------------------
		IF ISNULL(@SampleLoadActive, 0) = 1
		
			BEGIN

				UPDATE SB
				SET SB.DeleteSelected = 1
				FROM Selection.Base SB
					INNER JOIN Meta.CaseDetails CD ON CD.EventID = SB.EventID
													--AND CD.PartyID = SB.PartyID		-- V3.29
													AND CD.VehicleRoleTypeID = SB.VehicleRoleTypeID
													AND CD.VehicleID = SB.VehicleID
					INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata VSM ON VSM.QuestionnaireRequirementID = CD.QuestionnaireRequirementID
				WHERE VSM.SampleLoadActive = 1
				
			END


		-----------------------------------------	
		-- V3.54 GET ORGANISATIONS AT SAME ADDRESS
		-----------------------------------------	
		DROP TABLE IF EXISTS #OrganisationsAtAddress
		
		SELECT PCM.ContactMechanismID AS PostalContactMechanismID, 
			O.PartyID AS OrganisationPartyID 
		INTO #OrganisationsAtAddress
		FROM Selection.Base SB
			INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON SB.PostalContactMechanismID = PCM.ContactMechanismID
			INNER JOIN Party.Organisations O ON PCM.PartyID = O.PartyID
		WHERE ISNULL(SB.OrganisationPartyID,0) = 0
		AND NOT EXISTS (SELECT PA.ContactMechanismID -- V3.62 (Exclude these Address contact ID's Address was forced to "Unknown")
                    FROM ContactMechanism.PostalAddresses PA
                    WHERE PA.ContactMechanismID = PCM.ContactMechanismID
                        AND PA.Postcode = 'Unknown'
                        AND PA.Street = 'Unknown'
                        AND PA.CountryID = (SELECT CountryID FROM ContactMechanism.Countries WHERE Country = 'South Africa'))
		GROUP BY PCM.ContactMechanismID,
			O.PartyID


		------------------------------------------------------------------------------------------------------
		-- IF AFRL Code Validation is set TRUE, then do AFRL validation and Dealer Only Exclusions		-- V3.2
		------------------------------------------------------------------------------------------------------
		IF ISNULL(@ValidateAFRLCodes, 0) = 1  
		BEGIN 
					
			-----------------------------------------
			-- EXCLUDE PARTIES THAT HAVE BEEN CATEGORISED WITH 
			-- EITHER 'Manufacturer Internal Dealership' OR 'Customer-facing Dealership'
			-- IN THE PARTY TYPE EXCLUSIONS LIST FOR THE QUESTIONNAIRE
			-----------------------------------------

			-- V3.54 First check against organisations at address and set SelectionOrganisationID accordingly
			;WITH CTE_OrganisationsAtAddress (PostalContactMechanismID, PartyID) AS 
			(	
				SELECT OAA.PostalContactMechanismID,
					MAX(PC.PartyID) AS PartyID
				FROM  #OrganisationsAtAddress OAA
					INNER JOIN Party.PartyClassifications PC ON OAA.OrganisationPartyID = PC.PartyID
					INNER JOIN Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
														AND PC.PartyTypeID = IC.PartyTypeID
					INNER JOIN Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
														AND PT.PartyType IN ('Manufacturer Internal Dealership', 'Customer-facing Dealership') 
					INNER JOIN Requirement.QuestionnairePartyTypeRelationships QPTR ON PT.PartyTypeID = QPTR.PartyTypeID
					INNER JOIN Requirement.QuestionnairePartyTypeExclusions QPTE ON QPTR.RequirementID = QPTE.RequirementID
																					AND QPTR.PartyTypeID = QPTE.PartyTypeID
																					AND QPTR.FromDate = QPTE.FromDate
				WHERE QPTR.RequirementID = @QuestionnaireRequirementID 
				GROUP BY OAA.PostalContactMechanismID
			)
			UPDATE SB
			SET SB.DeleteDealerExclusion = 1,
				SB.SelectionOrganisationID = OAA.PartyID
			FROM Selection.Base SB
				INNER JOIN CTE_OrganisationsAtAddress OAA ON SB.PostalContactMechanismID = OAA.PostalContactMechanismID
			WHERE ISNULL(SB.OrganisationPartyID,0) = 0				-- ONLY UPDATE RECORDS WHERE THERE ISN'T AN EXISTING ORGANISATION


			;WITH EXPARTYTYPES (PartyID) AS 
			(	
				SELECT PC.PartyID
				FROM Party.PartyClassifications PC
					INNER JOIN Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
														AND PC.PartyTypeID = IC.PartyTypeID
					INNER JOIN Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
														AND PT.PartyType IN ('Manufacturer Internal Dealership', 'Customer-facing Dealership') 
					INNER JOIN Requirement.QuestionnairePartyTypeRelationships QPTR ON PT.PartyTypeID = QPTR.PartyTypeID
					INNER JOIN Requirement.QuestionnairePartyTypeExclusions QPTE ON QPTR.RequirementID = QPTE.RequirementID
																					AND QPTR.PartyTypeID = QPTE.PartyTypeID
																					AND QPTR.FromDate = QPTE.FromDate
				WHERE QPTR.RequirementID = @QuestionnaireRequirementID 
			)
			UPDATE SB
			SET SB.DeleteDealerExclusion = 1
			FROM Selection.Base SB
				INNER JOIN EXPARTYTYPES ON EXPARTYTYPES.PartyID = COALESCE(NULLIF(SB.OrganisationPartyID, 0), NULLIF(SB.PartyID, 0)) -- V1.4
						
			-------------------------------------------------------------------------------------------
			-- NOW CHECK PARTIES WITH BARRED EMAILS - BUT ONLY THOSE WHICH ARE APPLICABLE FOR AFRL !!!	-- V3.3
			-- !!* ANY CHANGE TO DeleteBarredEmail LOGIC MUST BE APPLIED TO 
			--  SP WebsiteReporting.[dbo].[uspRunPreSelectionFlags] *!!*
			-------------------------------------------------------------------------------------------
			IF ISNULL(@UseLatestEmailTable,0) = 1				-- V3.7 -- Add in lookup of barred emails based ON Latest emails received for Party and EventCategory
			BEGIN 
				UPDATE SB
				SET SB.DeleteBarredEmail = 1
				FROM Selection.Base SB
					INNER JOIN Meta.PartyLatestReceivedEmails LRE ON LRE.PartyID = SB.PartyID
																 AND LRE.EventCategoryID = SB.EventCategoryID
					INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = LRE.ContactMechanismID
					INNER JOIN ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
					INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
				WHERE CMBT.PreventsSelection = 1
					AND CMBT.AFRLFilter = 1
			END
			ELSE BEGIN
				;WITH BarredEmails (PartyID) AS 
				(	
					SELECT PCM.PartyID
					FROM ContactMechanism.vwBlacklistedEmail BCM
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
					WHERE BCM.PreventsSelection = 1
						AND BCM.AFRLFilter = 1
				)
				UPDATE SB
				SET SB.DeleteBarredEmail = 1
				FROM Selection.Base SB
					INNER JOIN BarredEmails BE ON BE.PartyID = SB.PartyID
			END				
		
			--------------------------------------------------
			-- DO CRM SALE TYPE CHECK ON VEH_SALE_TYPE_DESC INSTEAD OF AFRL CHECKS V3.11
			--------------------------------------------------
			IF ISNULL(@CRMSaleTypeCheck,0) = 1
				BEGIN

					UPDATE B 
					SET B.DeleteCRMSaleType = CASE	WHEN ISNULL(VCS.VEH_SALE_TYPE_DESC, '') IN ('Retail Sold','Small Business Fleet') THEN 0 
													ELSE 1 END 			
					FROM Selection.Base B
						INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.EventID = B.EventID
																		AND VPRE.VehicleID = B.VehicleID
																		AND VPRE.PartyID = COALESCE(B.PartyID, B.OrganisationPartyID)
						INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
						INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = B.EventID			-- V3.23	
																						  AND SL.LoadedDate < @CRMSaleTypeCheckSwitchDate		-- V3.23 Only do the check for those records loaded before the switchover date 
						LEFT JOIN (	SELECT MAX(AuditItemID) AS AuditItemID, 
										VEH_VIN, 
										VEH_SALE_TYPE_DESC
									FROM [Sample_ETL].CRM.Vista_Contract_Sales
									GROUP BY VEH_VIN, 
										VEH_SALE_TYPE_DESC) VCS ON V.VIN = VCS.VEH_VIN	-- V3.13				

					-- V3.45 Canada/US Exclusion of Outcycled service loaners (i.e. VISTACONTRACT_PREVIOUS_RET_USE = Z002)
					UPDATE B 
					SET B.DeleteCRMSaleType = CASE	WHEN ISNULL(VCS.VISTACONTRACT_PREVIOUS_RET_USE, '') = 'Z002' THEN 1
													ELSE 0 END 			
					FROM Selection.Base B
						INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.EventID = B.EventID
																		AND VPRE.VehicleID = B.VehicleID
																		AND VPRE.PartyID = COALESCE(B.PartyID, B.OrganisationPartyID)
						INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
						INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = B.EventID	
						LEFT JOIN (	SELECT MAX(AuditItemID) AS AuditItemID, 
										VEH_VIN, 
										VISTACONTRACT_PREVIOUS_RET_USE
									FROM [Sample_ETL].CRM.Vista_Contract_Sales
									GROUP BY VEH_VIN, 
										VISTACONTRACT_PREVIOUS_RET_USE) VCS ON V.VIN = VCS.VEH_VIN
					WHERE SL.Market IN ('Canada','United States of America')

				END
		
		/* BUG 14344 --- Remove old AFRL and CRM Sales Type Desc checks.  All now covered by "TypeOfSale" checks
				
			ELSE BEGIN
				--------------------------------------------------
				-- GET AFRL Codes for the Events in the sample pool and, if not a 'P' or 'B', then set appropriate delete flag (and do not select)
				-- NO LONGER USED AS VEH_SALE_TYPE_DESC USED V3.11
				--------------------------------------------------
				UPDATE B 
				SET B.AFRLCode = ISNULL(VPRE.AFRLCode, ''),
					B.DeleteAFRLCode = CASE		WHEN ISNULL(VPRE.AFRLCode, '') IN ('P', 'B') THEN 0 
												ELSE 1 END 
				FROM Selection.Base B
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.EventID = B.EventID
																AND VPRE.VehicleID = B.VehicleID
																AND VPRE.PartyID = COALESCE(B.PartyID, B.OrganisationPartyID)
			END
		*/
			
		END


		--------------------------------------------------
		-- V3.45 Canada/US Exclusion of Outcycled service loaners (i.e. VISTACONTRACT_PREVIOUS_RET_USE = Z002)
		--------------------------------------------------
		IF ISNULL(@CRMSaleTypeCheck,0) = 1
		BEGIN

			UPDATE B 
			SET B.DeleteCRMSaleType = CASE	WHEN ISNULL(VCS.VISTACONTRACT_PREVIOUS_RET_USE, '') = 'Z002' THEN 1
											ELSE 0 END 			
			FROM Selection.Base B
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.EventID = B.EventID
																AND VPRE.VehicleID = B.VehicleID
																AND VPRE.PartyID = COALESCE(B.PartyID, B.OrganisationPartyID)
				INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
				INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = B.EventID	
				LEFT JOIN (	SELECT MAX(AuditItemID) AS AuditItemID, 
								VEH_VIN, 
								VISTACONTRACT_PREVIOUS_RET_USE
							FROM [Sample_ETL].CRM.Vista_Contract_Sales
							GROUP BY VEH_VIN, 
								VISTACONTRACT_PREVIOUS_RET_USE) VCS ON V.VIN = VCS.VEH_VIN
			WHERE SL.Market IN ('Canada','United States of America')

		END
		--------------------------------------------------------------------------------------------------------


		------------------------------------------------------------------------------------------------------
		-- IF AFRL Code Validation is not set, then do normal Exclusion List					-- V3.2
		------------------------------------------------------------------------------------------------------
		IF ISNULL(@ValidateAFRLCodes, 0) = 0  
		BEGIN 
			-----------------------------------------
			-- EXCLUDE PARTIES THAT HAVE BEEN CATEGORISED BY ONE 
			-- OF THE PARTY TYPES WHICH HAS BEEN SET AS AN EXCLUSION
			-- PARTY TYPE CATEGORY FOR THIS QUESTIONNAIRE
			-----------------------------------------

			-- V3.54 First check against organisations at address and set SelectionOrganisationID accordingly
			;WITH CTE_OrganisationsAtAddress (PostalContactMechanismID, PartyID) AS 
			(	
				SELECT OAA.PostalContactMechanismID,
					MAX(PC.PartyID) AS PartyID
				FROM  #OrganisationsAtAddress OAA
					INNER JOIN Party.PartyClassifications PC ON OAA.OrganisationPartyID = PC.PartyID
					INNER JOIN Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
																	AND PC.PartyTypeID = IC.PartyTypeID
					INNER JOIN Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
					INNER JOIN Requirement.QuestionnairePartyTypeRelationships QPTR ON PT.PartyTypeID = QPTR.PartyTypeID
					INNER JOIN Requirement.QuestionnairePartyTypeExclusions QPTE ON QPTR.RequirementID = QPTE.RequirementID
																					AND QPTR.PartyTypeID = QPTE.PartyTypeID
																					AND QPTR.FromDate = QPTE.FromDate
				WHERE QPTR.RequirementID = @QuestionnaireRequirementID 
				GROUP BY OAA.PostalContactMechanismID
			)
			UPDATE SB
			SET SB.DeletePartyTypes = 1,
				SB.SelectionOrganisationID = OAA.PartyID
			FROM Selection.Base SB
				INNER JOIN CTE_OrganisationsAtAddress OAA ON SB.PostalContactMechanismID = OAA.PostalContactMechanismID
			WHERE ISNULL(SB.OrganisationPartyID,0) = 0				-- ONLY UPDATE RECORDS WHERE THERE ISN'T AN EXISTING ORGANISATION

			
			;WITH EXPARTYTYPES (PartyID) AS 
			(
				SELECT PC.PartyID
				FROM Party.PartyClassifications PC
					INNER JOIN Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
																	AND PC.PartyTypeID = IC.PartyTypeID
					INNER JOIN Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
					INNER JOIN Requirement.QuestionnairePartyTypeRelationships QPTR ON PT.PartyTypeID = QPTR.PartyTypeID
					INNER JOIN Requirement.QuestionnairePartyTypeExclusions QPTE ON QPTR.RequirementID = QPTE.RequirementID
																					AND QPTR.PartyTypeID = QPTE.PartyTypeID
																					AND QPTR.FromDate = QPTE.FromDate
				WHERE QPTR.RequirementID = @QuestionnaireRequirementID 
			)
			UPDATE SB
			SET SB.DeletePartyTypes = 1
			FROM Selection.Base SB
				INNER JOIN EXPARTYTYPES ON EXPARTYTYPES.PartyID = COALESCE(NULLIF(SB.OrganisationPartyID, 0), NULLIF(SB.PartyID, 0)) -- V1.4


			-----------------------------------------
			-- NOW CHECK PARTIES WITH BARRED EMAILS
			-- !!* ANY CHANGE TO DeleteBarredEmail LOGIC MUST BE APPLIED TO 
			--  SP WebsiteReporting.[dbo].[uspRunPreSelectionFlags] *!!*
			-----------------------------------------
			IF ISNULL(@UseLatestEmailTable,0) = 1				-- V3.7 -- Add in lookup of barred emails based ON Latest emails received for Party and EventCategory
			BEGIN 
				IF ISNULL(@MCQISurvey,0) = 0		-- V3.26 Don'T exclude for MCQI survey
				BEGIN
					UPDATE SB
					SET SB.DeleteBarredEmail = 1
					
					FROM Selection.Base SB
						INNER JOIN Meta.PartyLatestReceivedEmails LRE ON LRE.PartyID = SB.PartyID
																	 AND LRE.EventCategoryID = SB.EventCategoryID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = LRE.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
					WHERE CMBT.PreventsSelection = 1
				END
			END
			ELSE BEGIN
				;WITH BarredEmails (PartyID) AS 
				(
					SELECT PCM.PartyID
					FROM ContactMechanism.vwBlacklistedEmail BCM
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
					WHERE BCM.PreventsSelection = 1
				)
				UPDATE SB
				SET SB.DeleteBarredEmail = 1
				FROM Selection.Base SB
					INNER JOIN BarredEmails BE ON BE.PartyID = SB.PartyID
			END			

		END
		--------------------------------------------------------------------------------------------------------


		-----------------------------------------
		-- NOW CHECK EVENT NON SOLICITATIONS
		-----------------------------------------
		;WITH EventNonSol (EventID) AS 
		(
			SELECT DISTINCT EventID
			FROM dbo.NonSolicitations NS
				INNER JOIN Event.NonSolicitations ENS ON NS.NonSolicitationID = ENS.NonSolicitationID
		)
		UPDATE SB
		SET SB.DeleteEventNonSolicitation = 1
		FROM Selection.Base SB
			INNER JOIN EventNonSol ON EventNonSol.EventID = SB.EventID
			

		-----------------------------------------
		-- NOW CHECK FOR INVALID MODELS
		-----------------------------------------
		;WITH Models (ModelID) AS 
		(
			SELECT DISTINCT MR.ModelID
			FROM Requirement.RequirementRollups SM
				INNER JOIN Requirement.ModelRequirements MR ON MR.RequirementID = SM.RequirementIDMadeUpOf
			WHERE SM.RequirementIDPartOf = @SelectionRequirementID
		)
		UPDATE Selection.Base
		SET DeleteInvalidModel = 1
		WHERE ModelID NOT IN (SELECT ModelID FROM Models)


		-----------------------------------------
		-- V3.37 NOW CHECK FOR VALID MODEL VARIANTS
		-----------------------------------------
		-- Models For Which Variant Matching Required
		;WITH CTEModels (ModelID)  AS 
		(
			SELECT DISTINCT MV.ModelID
			FROM Requirement.QuestionnaireVariantRequirements QVR
				INNER JOIN Requirement.VariantRequirements VR ON QVR.RequirementIDMadeUpOf = VR.RequirementID
				INNER JOIN Vehicle.ModelVariants MV ON VR.VariantID = MV.VariantID
			WHERE QVR.RequirementIDPartOf = @QuestionnaireRequirementID
				AND QVR.FromDate < GETDATE() 
				AND (QVR.ThroughDate IS NULL OR QVR.ThroughDate > GETDATE())
		)
		-- Valid Variants 
		, CTEVariants (ModelID, VariantID)  AS 
		(
			SELECT DISTINCT MV.ModelID, VR.VariantID
			FROM Requirement.QuestionnaireVariantRequirements QVR
				INNER JOIN Requirement.VariantRequirements VR ON QVR.RequirementIDMadeUpOf = VR.RequirementID
				INNER JOIN Vehicle.ModelVariants MV ON VR.VariantID = MV.VariantID
			WHERE QVR.RequirementIDPartOf = @QuestionnaireRequirementID
				AND QVR.FromDate < GETDATE() 
				AND (QVR.ThroughDate IS NULL OR QVR.ThroughDate > GETDATE())
		)
		UPDATE B SET B.DeleteInvalidVariant = 1
		FROM Selection.Base B
			INNER JOIN Vehicle.Vehicles V ON B.VehicleID = V.VehicleID
			INNER JOIN CTEModels M ON V.ModelID = M.ModelID
			LEFT JOIN CTEVariants MV ON V.ModelID = MV.ModelID
									AND V.ModelVariantID = MV.VariantID
		WHERE MV.VariantID IS NULL
		

		-----------------------------------------
		-- CHECK FOR INVALID ROLE TYPES -- V3.1 -- (Have hard coded here, rather than add a flag, as more complicated roletype functionality may follow)
		-----------------------------------------
		;WITH CTE_ValidRoleTypeIDs AS 
		(
			SELECT RT.VehicleRoleTypeID
			FROM Vehicle.VehicleRoleTypes RT
			WHERE RT.VehicleRoleType IN ('Purchaser',
										 'Registered Owner',
										 'Principle Driver',
										 'Other Driver')
		)
		UPDATE Selection.Base
		SET DeleteInvalidRoleType = 1
		WHERE VehicleRoleTypeID NOT IN (	SELECT VRT.VehicleRoleTypeID 
											FROM CTE_ValidRoleTypeIDs VRT)

		
		-----------------------------------------
		-- CHECK FOR Sale Types (if flagged on the QuestionnaireRequirement) -- V3.1
		-----------------------------------------
		IF ISNULL(@ValidateSaleTypes, 0) = 1
		BEGIN 
			-- Check values 
			;WITH CTE_ValidSaleTypes
			AS (
				SELECT VT.SalesType
				FROM Requirement.QuestionnaireValidSaleTypes VT
				WHERE VT.RequirementID = @QuestionnaireRequirementID
					AND VT.FromDate < GETDATE() 
					AND (VT.ThroughDate IS NULL OR VT.ThroughDate > GETDATE())
			),
			CTE_MaxLoadedDate							-- V3.42
			AS (
				SELECT B.EventID , MAX(SL.LoadedDate) AS MaxLoadedDate 
				FROM Selection.Base B 
					INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = B.EventID
				GROUP BY B.EventID
			)
			UPDATE SB
			SET SB.DeleteInvalidSaleType = 1
			FROM Selection.Base SB
				INNER JOIN Event.AdditionalInfoSales AI ON AI.EventID = SB.EventID
				INNER JOIN CTE_MaxLoadedDate MLD ON MLD.EventID = SB.EventID
			WHERE RTRIM(LTRIM(ISNULL(AI.TypeOfSaleOrig,''))) NOT IN (	SELECT VST.SalesType 
																		FROM CTE_ValidSaleTypes VST)
				AND (@CRMSaleTypeCheck = 0 		
						-- V3.23 -- If the CRM Sale Type Check is "TRUE" THEN we only do InvalidSalesType filtering for Events with a LoadedDate after CRMSaleTypeCheckSwitchDate, that way guaranteeing that the VISTA SaleTypeCode will have been loaded for those CRM records (CRM 4.0)
						OR @CRMSaleTypeCheckSwitchDate < MLD.MaxLoadedDate)	-- V3.42  - Modified to use CTE value instead of table lookup 
				AND @ValidateSaleTypeFromDate < MLD.MaxLoadedDate			-- V3.42 

		END


		-----------------------------------------
		-- CHECK FOR PDI Flag (if flagged on the QuestionnaireRequirement) -- V3.22
		-----------------------------------------
		IF ISNULL(@PDIFlagCheck, 0) = 1
		BEGIN 
			-- Check values 
			UPDATE SB
			SET SB.DeletePDIFlag = 1
			FROM Selection.Base SB
				INNER JOIN Event.AdditionalInfoSales AI ON AI.EventID = SB.EventID
			WHERE AI.PDI_Flag = 'Y'
		END


		----------------------------------------------------------------------------------
		-- Apply Customer Contact Preferences										-- V3.9
		----------------------------------------------------------------------------------
	
		DECLARE @ContactPreferencesModel  VARCHAR(50)
		SELECT @ContactPreferencesModel = ContactPreferencesModel 
		FROM dbo.Markets M 
		WHERE M.CountryID = @CountryID

		-- Check whether the Market exists for the CountryID and ERROR, if not.
		IF @ContactPreferencesModel IS NULL
		OR @ContactPreferencesModel NOT IN ('Global', 'By Survey')
			RAISERROR (N'Selection.uspRunSelection: ContactPreferencesModel value is not set or is invalid.', 16, 1) 		


		-----------------------------------------------------------------------------------------------------------------
		-- Set the ContactPreferences suppress values for each party based on the ContactPreferencesModel for the Market
		-----------------------------------------------------------------------------------------------------------------

		IF @ContactPreferencesModel = 'Global'		
		BEGIN 
			UPDATE B
			SET B.ContactPreferencesPartySuppress  = CP.PartySuppression,
				B.ContactPreferencesEmailSuppress  = CP.EmailSuppression,
				B.ContactPreferencesPhoneSuppress  = CP.PhoneSuppression,
				B.ContactPreferencesPostalSuppress = CP.PostalSuppression
			FROM Selection.Base B 
				INNER JOIN Party.ContactPreferences CP ON CP.PartyID = B.PartyID
		END

		IF @ContactPreferencesModel = 'By Survey'		-- Update using the latest preferences loaded
		BEGIN 
			UPDATE B
			SET B.ContactPreferencesPartySuppress  = CP.PartySuppression,
				B.ContactPreferencesEmailSuppress  = CP.EmailSuppression,
				B.ContactPreferencesPhoneSuppress  = CP.PhoneSuppression,
				B.ContactPreferencesPostalSuppress = CP.PostalSuppression
			FROM Selection.Base B 
				INNER JOIN Party.ContactPreferencesBySurvey CP ON CP.PartyID = B.PartyID 
																AND CP.EventCategoryID = B.EventCategoryID 
		END

 
		-- Set the Unsubscribe Flag (This should not actually be required to suppress the event as the Party Contact Pref flag is aleady set for unsubscribes
		-- ------------------------	 It has been added to for reporting purposes primarily but I will include in the filtering just in case the Contact 
		--							 Preferences were manually updated)	-- V3.27
		UPDATE B
			SET B.ContactPreferencesUnsubscribed = CP.PartyUnsubscribe
		FROM Selection.Base B
			INNER JOIN Party.ContactPreferences CP ON CP.PartyID = B.PartyID
		
 
		-------------------------------------------------------------------------------------------------------------------------
		-- Clear the contact mechanisms in the base table where the suppress flags have been set (to ensure we do not contact where suppressed)
		-------------------------------------------------------------------------------------------------------------------------

		-- Clear Email Contact Mechanisms
		UPDATE B 
		SET EmailContactMechanismID = NULL
		FROM Selection.Base B
		WHERE B.ContactPreferencesEmailSuppress = 1

				
		-- Clear Phone Contact Mechanisms
		UPDATE B 
		SET PhoneContactMechanismID = NULL,
			MobileContactMechanismID = NULL,
			LandlineContactMechanismID = NULL
		FROM Selection.Base B
		WHERE B.ContactPreferencesPhoneSuppress = 1


		-- Clear Postal Contact Mechanisms
		UPDATE B 
		SET PostalContactMechanismID = NULL
		FROM Selection.Base B
		WHERE B.ContactPreferencesPostalSuppress = 1


		-------------------------------------------------------------------------------------------------------------------------
		-- Set the DeleteContactPreferences flag based on what the required fields are and what suppress flags have been set
		-------------------------------------------------------------------------------------------------------------------------

		UPDATE B
		SET B.DeleteContactPreferences = CASE WHEN ( (@StreetRequired = 1 OR @PostcodeRequired = 1)        
															AND ISNULL(B.ContactPreferencesPostalSuppress, 0) = 1)
												OR  ( (@TelephoneRequired = 1 OR @MobilePhoneRequired = 1 ) 
																AND ISNULL(B.ContactPreferencesPhoneSuppress, 0) = 1)
												OR	(@EmailRequired = 1 
																AND ISNULL(B.ContactPreferencesEmailSuppress, 0) = 1)
												OR	(@StreetOrEmailRequired = 1 
																AND (ISNULL(B.ContactPreferencesPostalSuppress, 0) = 1 OR ISNULL(PostalContactMechanismID, 0) = 0)
																AND (ISNULL(B.ContactPreferencesEmailSuppress, 0) = 1 OR ISNULL(EmailContactMechanismID, 0) = 0)
																AND (ISNULL(B.ContactPreferencesPostalSuppress, 0) = 1 OR ISNULL(B.ContactPreferencesEmailSuppress, 0) = 1) )			-- V3.16
												OR	(@TelephoneOrEmailRequired = 1
																AND (ISNULL(B.ContactPreferencesEmailSuppress, 0) = 1 OR ISNULL(EmailContactMechanismID, 0) = 0)
																AND (ISNULL(B.ContactPreferencesPhoneSuppress, 0) = 1 OR ( ISNULL(PhoneContactMechanismID, 0) = 0 
																															AND ISNULL(LandlineContactMechanismID, 0) = 0
																															AND ISNULL(MobileContactMechanismID, 0) = 0)
																AND (ISNULL(B.ContactPreferencesPhoneSuppress, 0) = 1 OR ISNULL(B.ContactPreferencesEmailSuppress, 0) = 1) )			-- V3.16

												OR	(@MobilePhoneOrEmailRequired = 1 
																AND (ISNULL(B.ContactPreferencesEmailSuppress, 0) = 1 OR ISNULL(EmailContactMechanismID, 0) = 0)
																AND (ISNULL(B.ContactPreferencesPhoneSuppress, 0) = 1 OR ISNULL(MobileContactMechanismID, 0) = 0)
																AND (ISNULL(B.ContactPreferencesPhoneSuppress, 0) = 1 OR ISNULL(B.ContactPreferencesEmailSuppress, 0) = 1)) )		-- V3.16

												OR	ISNULL(B.ContactPreferencesPartySuppress, 0) = 1
												OR	ISNULL(B.ContactPreferencesUnsubscribed, 0) = 1		-- V3.27
											THEN 1 
											ELSE 0 END
		FROM Selection.Base B 


		----------------------------------------------------------------------------------------------------
		-- FILTER BY DealerPilotOutputCodes V3.10
		----------------------------------------------------------------------------------------------------
		IF ISNULL(@FilterOnDealerPilotOutputCodes,0) = 1
		
		BEGIN
			;WITH CTE_ValidPilotDealers (DealerCode) AS 
			(	
				SELECT DPOC.DealerCode
				FROM dbo.vwBrandMarketQuestionnaireSampleMetadata M 
					LEFT JOIN SelectionOutput.DealerPilotOutputCodes DPOC ON M.ISOAlpha3 = DPOC.Market 
																			AND M.Questionnaire = DPOC.EventCategory
				WHERE M.QuestionnaireRequirementID = @QuestionnaireRequirementID
			)
			UPDATE Selection.Base
			SET DeleteFilterOnDealerPilotOutputCodes = 1
			WHERE DealerCode NOT IN (SELECT DealerCode FROM CTE_ValidPilotDealers)
		END
		----------------------------------------------------------------------------------------------------

		
		----------------------------------------------------------
		-- Rockar Processing
		----------------------------------------------------------
                     
		-- Check for Roacker Dealers having Emails present
		UPDATE B
		SET DeleteEmail = 1
		FROM Selection.Base B
			INNER JOIN dbo.DW_JLRCSPDealers D ON D.OUtletPartyID = B.DealerPartyID
		WHERE D.RockarDealer = 1	
			AND ISNULL(EmailContactMechanismID, 0) = 0
  
		-- Remove all contact mechanisms other then Email for Rockar Dealers
        UPDATE	B
		SET	MobileContactMechanismID = 0,
			PhoneContactMechanismID = 0,
			LandlineContactMechanismID = 0,
			PostalContactMechanismID = 0
         FROM Selection.Base B
			INNER JOIN dbo.DW_JLRCSPDealers D ON D.OUtletPartyID = B.DealerPartyID
         WHERE D.RockarDealer = 1
 
 
 		----------------------------------------------------------
		-- Exclude from CQI selections records without Extra Vehicle Feed Info V3.15 V3.21 V3.33 V3.35
        ----------------------------------------------------------
        IF @CQISurvey = 1
        
        BEGIN
   
			UPDATE B
			SET B.DeleteCQIMissingExtraVehicleFeed = 1
			FROM Selection.Base B
				LEFT JOIN Vehicle.ExtraVehicleFeed EVF ON B.VIN = EVF.VIN
			WHERE EVF.VehicleLine IS NULL
				OR EVF.VehicleLine IN ('*','Not Known','Not Known (NA)')
				OR EVF.ModelYear IS NULL
				--OR EVF.ProductionDate IS NULL
				--OR EVF.ProductionMonth IS NULL
				--OR EVF.CountrySold IS NULL
				--OR EVF.CountrySold IN ('*','Not Known','Not Known (NA)')
				--OR EVF.Plant IS NULL
				--OR EVF.Plant IN ('*','Not Known','Not Known (NA)')
				--OR EVF.BodyStyle IS NULL
				--OR EVF.BodyStyle IN ('*','Not Known','Not Known (NA)')
				--OR EVF.Drive IS NULL
				--OR EVF.Drive IN ('*','Not Known','Not Known (NA)')
				--OR EVF.Transmission IS NULL
				--OR EVF.Transmission IN ('*','Not Known','Not Known (NA)')
				--OR EVF.Engine IS NULL
				--OR EVF.Engine IN ('*','Not Known','Not Known (NA)') 
        
        END     


 		----------------------------------------------------------
		-- Exclude from US/CA Lost Lead Selections records without Agency V3.17 V3.24 V3.30, V3.41, V3.50, V3.52
        ----------------------------------------------------------
		DECLARE @Market  VARCHAR(50)
		SELECT @Market = Market FROM dbo.Markets M WHERE M.CountryID = @CountryID

        /*		
		IF @Market IN ('Canada', 'United States of America') AND @EventCategory = 'LostLeads'						-- V3.2, V3.41, V3.50
        
        BEGIN
   
			UPDATE B
			SET B.DeleteMissingLostLeadAgency = CASE	WHEN LLA.Agency IS NULL THEN 1 
														ELSE 0 END													-- V3.30
			FROM Selection.Base B
				LEFT JOIN dbo.DW_JLRCSPDealers D ON B.DealerPartyID = D.OutletPartyID								-- V3.24
													AND D.OutletFunction = 'Sales'									-- V3.30
				LEFT JOIN ContactMechanism.DealerCountries DC ON D.OutletPartyID = DC.PartyIDFrom					-- V3.30
																AND D.OutletFunctionID = DC.RoleTypeIDFrom			-- V3.30
				LEFT JOIN ContactMechanism.Countries C ON DC.CountryID = C.CountryID								-- V3.30											
				LEFT JOIN [$(ETLDB)].Lookup.LostLeadsAgencyStatus LLR ON D.OutletCode = LLR.CICode					-- V3.24	-- V3.51
																		AND C.ISOAlpha2 = LLR.Market				-- V3.30
																		AND D.OutletFunction = 'Sales'				-- V3.30
				LEFT JOIN SelectionOutput.LostLeadAgencies LLA ON LLR.LostSalesProvider = LLA.Agency				-- V3.30 
			
        END     
		*/

   		----------------------------------------------------------
		-- Exclude from UK PreOwned LostLead Selections records without Agency V3.39	-- V3.50
        ----------------------------------------------------------
		/*
		IF @Market IN ('United Kingdom') AND @EventCategory = 'PreOwnedLostLeads'									-- V3.39
        
        BEGIN
   
			UPDATE B
			SET B.DeleteMissingLostLeadAgency = CASE	WHEN LLA.Agency IS NULL THEN 1 
														ELSE 0 END							
			FROM Selection.Base B
				LEFT JOIN dbo.DW_JLRCSPDealers D ON B.DealerPartyID = D.OutletPartyID										
													AND D.OutletFunction = 'PreOwned'							
				LEFT JOIN ContactMechanism.DealerCountries DC ON D.OutletPartyID = DC.PartyIDFrom							
																AND D.OutletFunctionID = DC.RoleTypeIDFrom		
				LEFT JOIN ContactMechanism.Countries C ON DC.CountryID = C.CountryID																				
				LEFT JOIN [$(ETLDB)].Lookup.LostLeadsAgencyStatus LLR ON D.OutletCode_GDD = LLR.CICode						
																		AND C.ISOAlpha2 = LLR.Market					
																		AND D.OutletFunction = 'PreOwned'				
				LEFT JOIN SelectionOutput.LostLeadAgencies LLA ON LLR.LostSalesProvider = LLA.Agency						
			
        END     
		*/


  		----------------------------------------------------------
		-- V3.48 Exclude EventDate <= VEH_REGISTRATION_DATE for UK Service 
        ----------------------------------------------------------
		IF @Market IN ('United Kingdom') AND @EventCategory = 'Service'
        
        BEGIN
			;WITH CTE_LatestDMSRepair_Service (EventID, AuditItemID) AS
			(
				SELECT B.EventID,
					MAX(SL.AuditItemID) AS AuditItemID
				FROM Selection.Base B
					INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = B.EventID
				GROUP BY B.EventID
			)
			UPDATE B 
			SET B.DeletePDIFlag = 1
			FROM Selection.Base B
				INNER JOIN CTE_LatestDMSRepair_Service CTE ON B.EventID = CTE.EventID
				INNER JOIN [Sample_ETL].CRM.DMS_Repair_Service DMS ON CTE.AuditItemID = DMS.AuditItemID
			WHERE B.EventDate <= ISNULL(DMS.Converted_VEH_REGISTRATION_DATE,'1900-01-01')
        END     


  		----------------------------------------------------------
		-- V3.53 Exclude Germany/Austria/Czech Republic Sales if existing Service event exists 
        ----------------------------------------------------------
		IF @Market IN ('Germany','Austria','Czech Republic') AND @EventCategory = 'Sales'
        
        BEGIN
			;WITH CTE_ExistingServiceEvent (EventID, EventDate) AS
			(
				SELECT B.EventID,
					MIN(VE.EventDate) AS EventDate
				FROM Selection.Base B
					INNER JOIN Sample.Meta.VehicleEvents VE ON B.VehicleID = VE.VehicleID
				WHERE VE.EventType = 'Service'
				GROUP BY B.EventID
			)
			UPDATE B 
			SET B.DeletePDIFlag = 1
			FROM Selection.Base B
				INNER JOIN CTE_ExistingServiceEvent ESE ON B.EventID = ESE.EventID
			WHERE ESE.EventDate < B.EventDate
        END     
		
		
		------------------------------------------------------------------------
		-- V3.31 Exclude warranty events from selection (specific DDW markets)
        -------------------------------------------------------------------------
		IF ISNULL(@IgnoreWarrantyEvents, 0) = 1
		BEGIN
			UPDATE Selection.Base	
			SET DeleteWarranty = 1
			WHERE EventType = 'Warranty'
		END
		

		-------------------------------------------------------------------------
		-- V3.32 LOST LEADS SELECTIONS
		-- POPULATE THE LL SUPPRESSION FIELDS
		-------------------------------------------------------------------------
		/*	V3.55 DISABLE LOST LEAD SUPPRESSIONS
		UPDATE B
		SET B.LLMarketingPermission = CASE	WHEN AI.LostLead_MarketingPermission = 'Yes' THEN 1
											ELSE 0 END,
			B.LLCompleteSuppressionJLR = CASE	WHEN AI.LostLead_CompleteSuppressionJLR = 'Yes' THEN 1
												ELSE 0 END,
			B.LLCompleteSuppressionRetailer = CASE	WHEN AI.LostLead_CompleteSuppressionRetailer = 'Yes' THEN 1
													ELSE 0 END,
			B.LLPermissionToEmailJLR = CASE	WHEN AI.LostLead_PermissionToEmailJLR = 'Yes' THEN 1
											ELSE 0 END,
			B.LLPermissionToEmailRetailer = CASE WHEN AI.LostLead_PermissionToEmailRetailer = 'Yes' THEN 1
												ELSE 0 END,
			B.LLPermissionToPhoneJLR = CASE	WHEN AI.LostLead_PermissionToPhoneJLR = 'Yes' THEN 1
											ELSE 0 END,
			B.LLPermissionToPhoneRetailer =	CASE	WHEN AI.LostLead_PermissionToPhoneRetailer = 'Yes' THEN 1
													ELSE 0 END,
			B.LLDateOfLastContact =	CASE	WHEN AI.LostLead_ConvertedDateOfLastContact IS NOT NULL THEN 1
											ELSE 0 END,
			B.LLConvertedDateOfLastContact = AI.LostLead_ConvertedDateOfLastContact 
		FROM Selection.Base B
			INNER JOIN Event.AdditionalInfoSales AI ON B.EventID = AI.EventID
		
		-- V3.32
		IF EXISTS (	SELECT * 
					FROM Selection.LostLeadsSelectionRules 
					WHERE RequirementID = @QuestionnaireRequirementID)
		BEGIN
		
			--CHECKING IF LLConvertedDateOfLastContact IS IN THE FUTURE (BASED ON EVENT LOAD DATE)
			IF @NumberOfDaysToExclude >= 0
			BEGIN
			
				;WITH InvalidContactDate_CTE (EventLastLoaded, EventID)	AS
				(	
					SELECT F.ActionDate, 
						EventID				
					FROM [$(AuditDB)].dbo.Files F
						INNER JOIN [$(AuditDB)].dbo.AuditItems  AU ON F.AuditID = AU.AuditID
						INNER JOIN (	SELECT MAX(AuditItemID) AS AuditItemID, 
											B.EventID
										FROM [$(AuditDB)].Audit.AdditionalInfoSales AIS
											INNER JOIN Selection.Base B ON AIS.EventID = B.EventID
										GROUP BY B.EventID
									) T ON AU.AuditItemID = T.AuditItemID
				)
				UPDATE B
				SET DeleteInvalidDateOfLastContact = 1
				FROM Selection.Base B
					INNER JOIN InvalidContactDate_CTE CTE ON B.EventID = CTE.EventID
				WHERE CONVERT(DATE, B.LLConvertedDateOfLastContact) > CONVERT (DATE, DATEADD(DD, @NumberOfDaysToExclude, CTE.EventLastLoaded))
				
			END 
			
		
			;WITH ExtraSelectionRulesEmail_CTE (PartyID) AS
			(
				SELECT B.PartyID 
				FROM Selection.Base B
					INNER JOIN Selection.LostLeadsSelectionRules LL ON B.QuestionnaireRequirementID = LL.RequirementID
					LEFT JOIN	Requirement.QuestionnaireRequirements QR ON LL.RequirementID = QR.RequirementID
				WHERE	LL.ContactMechanismTypeID = (	SELECT CAST(ContactMechanismTypeID AS INT) 
														FROM ContactMechanism.ContactMechanismTypes 
														WHERE ContactMechanismType ='E-mail address') 
					--AND LL.CompleteSuppressionJLR	= LLCompleteSuppressionJLR						-- IF PARTY SUPPRESSION SUPPLIED WITH EVENT DO NOT IGNORE IT 
					--AND LL.CompleteSuppressionRetailer = LLCompleteSuppressionRetailer			-- IF PARTY SUPPRESSION SUPPLIED WITH EVENT DO NOT IGNORE IT
					AND LL.CompleteSuppressionJLR =	CASE	WHEN LL.CompleteSuppressionJLR = 1 AND B.LLCompleteSuppressionJLR = 0 THEN 1		-- V3.36
															WHEN LL.CompleteSuppressionJLR = 1 AND B.LLCompleteSuppressionJLR = 1 THEN 0        -- PARTY HAS A COMPLETE SUPRRESSION AND IT'S SPECIFIED THAT PARTY SUPPRESSION MUST = NO
															ELSE LL.CompleteSuppressionJLR END 
					AND LL.CompleteSuppressionRetailer = CASE	WHEN LL.CompleteSuppressionRetailer = 1 AND B.LLCompleteSuppressionRetailer = 0 THEN 1		-- V3.36
																WHEN LL.CompleteSuppressionRetailer = 1 AND B.LLCompleteSuppressionRetailer = 1 THEN 0		-- PARTY HAS A COMPLETE SUPRRESSION AND IT'S SPECIFIED THAT PARTY SUPPRESSION MUST = NO
																ELSE LL.CompleteSuppressionRetailer	END 										-- V3.36
					AND LL.MarketingPermission = CASE	WHEN LL.MarketingPermission = 1 AND B.LLMarketingPermission = 1 THEN 1
														WHEN LL.MarketingPermission = 1 AND B.LLMarketingPermission = 0 THEN 0
														ELSE LL.MarketingPermission END 
					AND LL.PermissionToEmailJLR = CASE	WHEN LL.PermissionToEmailJLR = 1 AND B.LLPermissionToEmailJLR = 1 THEN 1
															WHEN LL.PermissionToEmailJLR = 1 AND B.LLPermissionToEmailJLR = 0 THEN 0
															ELSE LL.PermissionToEmailJLR END 
					AND LL.PermissionToEmailRetailer = CASE 	WHEN LL.PermissionToEmailRetailer = 1 AND B.LLPermissionToEmailRetailer = 1 THEN 1
																WHEN LL.PermissionToEmailRetailer = 1 AND B.LLPermissionToEmailRetailer = 0 THEN 0
																ELSE LL.PermissionToEmailRetailer END 
					AND	LL.DateOfLastContact = CASE	WHEN LL.DateOfLastContact = 1 AND B.LLDateOfLastContact = 1 AND DATEDIFF(DD,LLConvertedDateOfLastContact, @SelectionDate) <= ISNULL(QR.NumberOfDaysOfLastContact,0) AND DeleteInvalidDateOfLastContact = 0 THEN 1
													WHEN LL.DateOfLastContact = 1 AND B.LLDateOfLastContact = 1 AND DATEDIFF(DD,LLConvertedDateOfLastContact, @SelectionDate) > ISNULL(QR.NumberOfDaysOfLastContact,0) THEN 0
													ELSE LL.DateOfLastContact END 
			)			
			--UPDATE RECORDS THAT DON'T SATISFY THE EMAIL SELECTION RULES
			UPDATE B
			--SET DeleteEmail = 1
			SET	EmailContactMechanismID = 0		-- V3.36			
			FROM Selection.Base B
				LEFT JOIN ExtraSelectionRulesEmail_CTE CTE ON B.PartyID = CTE.PartyID
			WHERE (CTE.PartyID IS NULL)	
				AND (@EmailRequired = 1 OR @TelephoneOrEmailRequired =1) -- V3.36

			;WITH ExtraSelectionRulesPhone_CTE (PartyID) AS
			(	
				SELECT B.PartyID 
				FROM Selection.Base B
					INNER JOIN Selection.LostLeadsSelectionRules LL ON B.QuestionnaireRequirementID = LL.RequirementID
					LEFT JOIN Requirement.QuestionnaireRequirements QR ON LL.RequirementID = QR.RequirementID
				WHERE LL.ContactMechanismTypeID = (	SELECT CAST(ContactMechanismTypeID AS INT) 
													FROM ContactMechanism.ContactMechanismTypes 
													WHERE ContactMechanismType ='Phone')
					--AND LL.CompleteSuppressionJLR	= LLCompleteSuppressionJLR						-- IF PARTY SUPPRESSION SUPPLIED WITH EVENT DO NOT IGNORE IT 
					--AND LL.CompleteSuppressionRetailer = LLCompleteSuppressionRetailer			-- IF PARTY SUPPRESSION SUPPLIED WITH EVENT DO NOT IGNORE IT
					AND LL.CompleteSuppressionJLR =	CASE	WHEN LL.CompleteSuppressionJLR = 1 AND B.LLCompleteSuppressionJLR = 0 THEN 1	-- V3.36
															WHEN LL.CompleteSuppressionJLR = 1 AND B.LLCompleteSuppressionJLR = 1 THEN 0	-- PARTY HAS A COMPLETE SUPRRESSION AND IT'S SPECIFIED THAT PARTY SUPPRESSION MUST = NO
															ELSE LL.CompleteSuppressionJLR END 
					AND LL.CompleteSuppressionRetailer = CASE	WHEN LL.CompleteSuppressionRetailer = 1 AND B.LLCompleteSuppressionRetailer = 0 THEN 1  -- V3.36
																WHEN LL.CompleteSuppressionRetailer = 1 AND B.LLCompleteSuppressionRetailer = 1 THEN 0	--PARTY HAS A COMPLETE SUPRRESSION AND IT'S SPECIFIED THAT PARTY SUPPRESSION MUST = NO
																ELSE LL.CompleteSuppressionRetailer END
					AND LL.MarketingPermission = CASE	WHEN LL.MarketingPermission = 1 AND B.LLMarketingPermission = 1 THEN 1
														WHEN LL.MarketingPermission = 1 AND B.LLMarketingPermission = 0 THEN 0
														ELSE LL.MarketingPermission END 
					AND LL.PermissionToPhoneJLR = CASE	WHEN LL.PermissionToPhoneJLR = 1 AND B.LLPermissionToPhoneJLR = 1 THEN 1
															WHEN LL.PermissionToPhoneJLR = 1 AND B.LLPermissionToPhoneJLR = 0 THEN 0
															ELSE LL.PermissionToPhoneJLR END 
					AND LL.PermissionToPhoneRetailer = CASE	WHEN LL.PermissionToPhoneRetailer = 1 AND B.LLPermissionToPhoneRetailer = 1 THEN 1
																WHEN LL.PermissionToPhoneRetailer = 1 AND B.LLPermissionToPhoneRetailer = 0 THEN 0
																ELSE LL.PermissionToPhoneRetailer END 
					AND LL.DateOfLastContact = CASE	WHEN LL.DateOfLastContact = 1 AND B.LLDateOfLastContact = 1 AND DATEDIFF(DD,LLConvertedDateOfLastContact, @SelectionDate) <= ISNULL(QR.NumberOfDaysOfLastContact,0) AND DeleteInvalidDateOfLastContact =0 THEN 1
													WHEN LL.DateOfLastContact = 1 AND B.LLDateOfLastContact = 1 AND DATEDIFF(DD,LLConvertedDateOfLastContact, @SelectionDate) > ISNULL(QR.NumberOfDaysOfLastContact,0) THEN 0
													ELSE LL.DateOfLastContact END 
			)			
			--UPDATE RECORDS THAT DON'T SATISFY THE TELEPHONE SELECTION RULES
			UPDATE B
			--SET DeleteTelephone = 1
			SET PhoneContactMechanismID = 0,		-- V3.36
				LandlineContactMechanismID = 0,		-- V3.36
				MobileContactMechanismID = 0		-- V3.36
			FROM Selection.Base B
				LEFT JOIN ExtraSelectionRulesPhone_CTE CTE ON B.PartyID = CTE.PartyID
			WHERE (CTE.PartyID IS NULL)	
				AND (@TelephoneRequired = 1 OR @TelephoneOrEmailRequired =1)  -- V3.36

			-- V3.36					
			--REMOVED EMAIL/TELEPHONE NUMBERS FOR INELIGIBLE RECORDS, 
			--NEED TO SET DELETION FLAGS ACORDINGLY
			IF @EmailRequired = 1
			BEGIN
				UPDATE Selection.Base
				SET DeleteEmail = 1
				WHERE ISNULL(EmailContactMechanismID, 0) = 0
			END

			IF @TelephoneRequired = 1
			BEGIN
				UPDATE Selection.Base
				SET DeleteTelephone = 1
				WHERE ISNULL(PhoneContactMechanismID, 0) = 0
					AND ISNULL(LandlineContactMechanismID, 0) = 0
					AND ISNULL(MobileContactMechanismID, 0) = 0
			END	

			IF @TelephoneOrEmailRequired = 1
			BEGIN
				UPDATE Selection.Base
				SET DeleteTelephoneOrEmail = 1
				WHERE ISNULL(EmailContactMechanismID, 0) = 0
					AND ISNULL(PhoneContactMechanismID, 0) = 0
					AND ISNULL(LandlineContactMechanismID, 0) = 0
					AND ISNULL(MobileContactMechanismID, 0) = 0
			END
		END 
		*/


		--V3.61
		--------------------------------------------------
		-- DO CommonSaleType CHECK
		--------------------------------------------------
		;WITH CTE_MaxLoadedDate
		AS (
				SELECT		B.EventID , MAX(SL.LoadedDate) AS MaxLoadedDate 
				FROM		Selection.Base B 
				INNER JOIN	[WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = B.EventID
				GROUP BY	B.EventID
			)
		UPDATE		SB
		SET			SB.DeleteInvalidSaleType = 1
		FROM		Selection.Base SB
		INNER JOIN	Event.AdditionalInfoSales AI ON AI.EventID = SB.EventID
		INNER JOIN	CTE_MaxLoadedDate MLD ON MLD.EventID = SB.EventID
		WHERE		RTRIM(LTRIM(ISNULL(AI.CommonSaleType,''))) IN ('Fleet of 25-99 Vehicles','Fleet of 100+ Vehicles')	AND 
					ISNULL(@ValidateCommonSaleType,0) = 1





		----------------------------------------------------------------------------------------------------
		-- APPLY QUOTAS (IF APPLICABLE) 
		-- QUOTAS:  For CQI quotas are applied as % of totals by model
		--			Any cases surplus to quotas are simply removed from selection.Base.
		----------------------------------------------------------------------------------------------------

		IF 	ISNULL(@UseQuotas,0) = 1
		
		BEGIN	
					
			----------------------------------------------------------------------------------------------------
			-- GET ALL EVENTS NOT FLAGGED FOR DELETION
			----------------------------------------------------------------------------------------------------
			SELECT ManufacturerPartyID, 
				ModelID, 
				EventDate, 
				EventID 
			INTO #EventsPoolForQuotas
			FROM Selection.Base B
			WHERE DeleteBarredEmail = 0
				AND DeleteEmail = 0
				AND DeleteEventNonSolicitation = 0
				AND DeleteEventType = 0
				AND DeleteInvalidModel = 0
				AND DeleteInvalidVariant = 0											-- V3.37
				AND DeletePartyTypes = 0
				AND DeletePostcode = 0
				AND DeleteRecontactPeriod = 0
				AND DeleteRelativeRecontactPeriod = 0
				AND DeleteSelected = 0
				AND DeleteStreet = 0
				AND DeleteStreetOrEmail = 0
				AND DeleteTelephone = 0
				AND DeleteTelephoneOrEmail = 0
				AND DeleteMobilePhone = 0												-- V1.5
				AND DeleteMobilePhoneOrEmail = 0										-- V1.5
				AND DeletePersonRequired = 0
				AND DeleteOrganisationRequired = 0
				AND DeletePartyName = 0
				AND DeleteLanguage = 0													-- V1.8
				AND DeleteInternalDealer = 0											-- V2.0		
				AND DeleteInvalidOwnershipCycle = 0										-- V2.0		
				AND DeleteInvalidRoleType = 0											-- V3.1
				AND DeleteInvalidSaleType = 0											-- V3.1
				AND DeleteAFRLCode = 0													-- V3.2
				AND DeleteDealerExclusion = 0											-- V3.2
				AND DeleteContactPreferences = 0										-- V3.9
				AND DeleteFilterOnDealerPilotOutputCodes = 0							-- V3.10
				AND DeleteCRMSaleType = 0												-- V3.11
				AND DeleteCQIMissingExtraVehicleFeed = 0								-- V3.15
				AND DeleteMissingLostLeadAgency = 0										-- V3.17
				AND DeletePDIFlag = 0													-- V3.22
				AND DeleteWarranty = 0													-- V3.31
				AND DeleteInvalidDateOfLastContact = 0									-- V3.32
			
			----------------------------------------------------------------------------------------------------
			-- GET QUOTA EVENTS
			----------------------------------------------------------------------------------------------------
			;WITH CTE_Events_Ranked (RowNumber, TotalAvailable, ModelID, EventDate, EventID) AS 
			(	
				SELECT ROW_NUMBER() OVER (PARTITION BY ModelID ORDER BY NEWID()) AS RowNumber,
					COUNT(*) OVER (PARTITION BY ModelID) AS Total,
					ModelID, 
					EventDate, 
					EventID
				FROM #EventsPoolForQuotas P
				WHERE P.ModelID IS NOT NULL
			)
			SELECT CTE.*, 
				QMR.TotalQuotaPercentage, 
				QMR.TotalQuota						-- V3.19
			INTO #TotalQuotaEvents	   
			FROM CTE_Events_Ranked CTE
				INNER JOIN Requirement.ModelRequirements MR ON CTE.ModelID = MR.ModelID
				INNER JOIN Requirement.QuestionnaireModelRequirements QMR ON MR.RequirementID = QMR.RequirementIDMadeUpOf
																AND	QMR.RequirementIDPartOf = @QuestionnaireRequirementID  
																AND GETDATE() BETWEEN ISNULL(QMR.FromDate, GETDATE()) 
																AND ISNULL(QMR.ThroughDate, CAST('01-01-2999' AS DATETIME))
			WHERE CTE.RowNumber * 10000 / CTE.TotalAvailable <= QMR.TotalQuotaPercentage * 100	-- V3.12 Fix Bug with Zero Target Rounding
				AND CTE.RowNumber <= ISNULL(QMR.TotalQuota, CTE.RowNumber)			-- V3.19
			----------------------------------------------------------------------------------------------------


			----------------------------------------------------------------------------------------------------
			-- FLAG ALL THOSE RECORDS NOT SELECTED IN THE QUOTAS (NotInQuota FLAG)
			----------------------------------------------------------------------------------------------------
			UPDATE B
			SET B.DeleteNotInQuota = 1
			FROM Selection.Base B
			WHERE NOT EXISTS (	SELECT * 
								FROM #TotalQuotaEvents
								WHERE EventID = B.EventID)
				AND EXISTS (	SELECT *						-- V3.46
								FROM #EventsPoolForQuotas
								WHERE EventID = B.EventID)
			----------------------------------------------------------------------------------------------------


			----------------------------------------------------------------------------------------------------
			-- UPDATE SELECTIONALLOCATIONS TABLE (THIS STORES INFORMATION ABOUT QUOTA SELECTION)
			----------------------------------------------------------------------------------------------------
			;WITH CTE_TotalQuota (QuestionnaireRequirementID, SelectionRequirementID, ModelRequirementID, TotalQuota, TotalQuotaPercentage, TotalAvailable, TotalActual) AS		-- V3.19
			(
				SELECT @QuestionnaireRequirementID AS QuestionnaireRequirementID,  
					@SelectionRequirementID AS SelectionRequirementID, 
					MR.RequirementID AS ModelRequirementID,
					TQE.TotalQuota,												-- V3.19
					TQE.TotalQuotaPercentage, 
					TQE.TotalAvailable,
					MAX(TQE.RowNumber) AS Allocated
				FROM #TotalQuotaEvents TQE
					INNER JOIN Requirement.ModelRequirements MR ON TQE.ModelID = MR.ModelID 
				GROUP BY MR.RequirementID, 
					TotalQuota, 
					TotalQuotaPercentage, 
					TotalAvailable												-- V3.19
			)
			UPDATE SA
			SET SA.TotalTargetPercentage = CTE.TotalQuotaPercentage,
				SA.TotalAvailable = CTE.TotalAvailable,
				SA.TotalActual = CTE.TotalActual,
				SA.TotalTarget = CTE.TotalQuota
			FROM CTE_TotalQuota CTE
				INNER JOIN Requirement.SelectionAllocations SA ON CTE.SelectionRequirementID = SA.RequirementIDPartOf
																AND CTE.ModelRequirementID = SA.RequirementIDMadeUpOf;	
			----------------------------------------------------------------------------------------------------

			----------------------------------------------------------------------------------------------------
			-- UPDATE QUESTIONNAREMODELREQUIREMENTS TABLE (THIS STORES QUOTA TARGET) V3.19
			----------------------------------------------------------------------------------------------------
			;WITH CTE_TotalQuota (QuestionnaireRequirementID, SelectionRequirementID, ModelRequirementID, TotalQuota, TotalQuotaPercentage, TotalAvailable, TotalActual) AS		-- V3.19 
			(	
				SELECT @QuestionnaireRequirementID AS QuestionnaireRequirementID,  
					@SelectionRequirementID AS SelectionRequirementID, 
					MR.RequirementID AS ModelRequirementID,
					TQE.TotalQuota,												-- V3.19
					TQE.TotalQuotaPercentage, 
					TQE.TotalAvailable,
					MAX(TQE.RowNumber) AS Allocated
				FROM #TotalQuotaEvents TQE
					INNER JOIN Requirement.ModelRequirements MR ON TQE.ModelID = MR.ModelID 
				GROUP BY MR.RequirementID, 
					TotalQuota, 
					TotalQuotaPercentage, 
					TotalAvailable
			)
			UPDATE QMR
			SET QMR.TotalQuota = QMR.TotalQuota - CTE.TotalActual
			FROM CTE_TotalQuota CTE
				INNER JOIN Requirement.QuestionnaireModelRequirements QMR ON CTE.ModelRequirementID = QMR.RequirementIDMadeUpOf
																	AND	QMR.RequirementIDPartOf = @QuestionnaireRequirementID  
																	AND GETDATE() BETWEEN ISNULL(QMR.FromDate, GETDATE()) 
																	AND ISNULL(QMR.ThroughDate, CAST('01-01-2999' AS DATETIME))										  								  
			----------------------------------------------------------------------------------------------------
			
		END

		--V3.59
		--BUILD A TABLE THAT WILL CONTAIN ONLY RECORDS THAT HAVE BEEN SELECTED
		CREATE TABLE #SelectedEvents	
		(
			ID								INT NOT NULL,
			AuditItemID						BIGINT NOT NULL,
			EventID							BIGINT NOT NULL,
			PartyID							INT NOT NULL,
			NonLatestEvent					BIT NULL
		)

		INSERT #SelectedEvents (ID, AuditItemID, EventID, PartyID)
		SELECT 	
					SB.ID,
					SL.AuditItemID,
					EventID,
					PartyID
		FROM		Selection.Base SB
		INNER JOIN	[WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = SB.EventID
																						AND SL.QuestionnaireRequirementID = CASE	WHEN SL.Market = 'United Kingdom' AND SL.Questionnaire = 'Sales' AND SL.Brand = 'Land Rover' THEN SB.QuestionnaireRequirementid	-- V3.58
																																	ELSE SL.QuestionnaireRequirementID END																							-- V3.58				
		WHERE		SB.VehicleID		= SL.MatchedODSVehicleID AND
					SB.EventID			= SL.MatchedODSEventID AND
					SB.DeleteSelected	<> 1 AND
					DeleteBarredEmail	= 0 AND 
					DeleteEmail			= 0 AND 
					DeleteEventNonSolicitation = 0 AND 
					DeleteEventType		= 0 AND 
					DeleteInvalidModel	= 0 AND 
					DeleteInvalidVariant = 0 AND 
					DeletePartyTypes	= 0 AND 
					DeletePostcode		= 0 AND 
					DeleteRecontactPeriod = 0 AND 
					DeleteRelativeRecontactPeriod = 0 AND 
					DeleteSelected		= 0 AND 
					DeleteStreet		= 0 AND 
					DeleteStreetOrEmail = 0 AND 
					DeleteTelephone		= 0 AND 
					DeleteTelephoneOrEmail = 0 AND 
					DeleteMobilePhone	= 0 AND 
					DeleteMobilePhoneOrEmail = 0 AND 
					DeletePersonRequired = 0 AND 
					DeleteOrganisationRequired = 0 AND 
					DeletePartyName		= 0 AND 
					DeleteLanguage		= 0 AND 
					DeleteInternalDealer = 0 AND 
					DeleteInvalidOwnershipCycle = 0 AND 
					DeleteInvalidRoleType = 0 AND 
					DeleteInvalidSaleType = 0 AND 
					DeleteAFRLCode		= 0 AND 
					DeleteDealerExclusion = 0 AND
					DeleteNotInQuota	= 0 AND 
					DeleteContactPreferences = 0 AND 
					DeleteFilterOnDealerPilotOutputCodes = 0 AND
					DeleteCRMSaleType	= 0 AND 
					DeleteCQIMissingExtraVehicleFeed = 0 AND 
					DeleteMissingLostLeadAgency = 0 AND 
					DeletePDIFlag		= 0 AND
					DeleteWarranty		= 0 AND 
					DeleteInvalidDateOfLastContact = 0

		
		--INITIALISE FLAG
		UPDATE	#SelectedEvents 
		SET		NonLatestEvent = 0 
		
		
		--KEEP THE EVENT WITH THE LARGEST(ASSUMING MOST RECENT) EVENTID PER PARTYID
		;WITH NonLatesteEvents_CTE (ID)
		AS
		(	SELECT SB.ID 
			FROM	Selection.Base SB
			INNER JOIN 
			(
				--DE-DUPPING  BASED ON EVENTID
				SELECT		MAX(SB.EventID) AS EventID, SB.PartyID
				FROM		#SelectedEvents SB
				GROUP BY	SB.PartyID
			)	SL ON	SB.EventID = SL.EventID AND
						SB.PartyID = SL.PartyID
		)
		--IF THERE ARE MULTIPLE EVENTS FOR A PARTY SET THE NON LATEST FLAG, IF THE EVENTID DIFFERS FROM THE MAX EVENTID FOR THAT PARTY
		UPDATE		SL
		SET			SL.NonLatestEvent = 1
		FROM		#SelectedEvents SL
		LEFT JOIN	NonLatesteEvents_CTE NE ON SL.ID = NE.ID
		WHERE		NE.ID IS NULL

		--COPY BACK TO THE MAIN Selection.base table
		UPDATE		SB
		SET			DeleteNonLatestEvent = 1
		FROM		Selection.Base SB
		INNER JOIN	#SelectedEvents SL ON SB.ID = SL.ID
		WHERE		SL.NonLatestEvent = 1




		---

		-----------------------------------------------------------------
		-- NOW LOG THE EVENTS IN THE SELECTION POOL
		-----------------------------------------------------------------
		IF @UpdateSelectionLogging = 1	--DO THE LOGGING
		  BEGIN

		  	--- Save logging values to a table rather than updating the logging table.  We then write everything at the same time.   -- V3.28
			--- This is so we do not create multiple entries for a single selection in the Logging Audit table. 
			DROP TABLE IF EXISTS #LoggingValues
		
			CREATE TABLE #LoggingValues	
			(
				AuditItemID						BIGINT NOT NULL,
				RecontactPeriod					BIT NULL,
				RelativeRecontactPeriod 		BIT NULL,
				CaseIDPrevious					INT NULL,			-- V3.57
				EventAlreadySelected 			BIT NULL,
				ExclusionListMatch 				BIT NULL,
				EventNonSolicitation			BIT NULL,
				BarredEmailAddress				BIT NULL,
				WrongEventType					BIT NULL,
				MissingStreet 					BIT NULL,
				MissingPostcode 				BIT NULL,
				MissingEmail 					BIT NULL,
				MissingTelephone 				BIT NULL,
				MissingStreetAndEmail 			BIT NULL,
				MissingTelephoneAndEmail 		BIT NULL,
				MissingMobilePhone 				BIT NULL,
				MissingMobilePhoneAndEmail 		BIT NULL,
				InvalidModel					BIT NULL,
				InvalidVariant					BIT NULL,			-- V3.37
				MissingPartyName 				BIT NULL,
				MissingLanguage 				BIT NULL,
				InternalDealer 					BIT NULL,
				InvalidOwnershipCycle 			BIT NULL,
				InvalidRoleType 				BIT NULL,
				InvalidSaleType 				BIT NULL,
				InvalidAFRLCode 				BIT NULL,
				SuppliedAFRLCode 				BIT NULL,
				DealerExclusionListMatch 		BIT NULL,
				NotInQuota 						BIT NULL,
				ContactPreferencesSuppression 	BIT NULL,
				ContactPreferencesPartySuppress BIT NULL,
				ContactPreferencesEmailSuppress BIT NULL,
				ContactPreferencesPhoneSuppress	BIT NULL,
				ContactPreferencesPostalSuppress BIT NULL,
				ContactPreferencesUnsubscribed 	BIT NULL,
				DealerPilotOutputFiltered 		BIT NULL,
				InvalidCRMSaleType 				BIT NULL,
				MissingLostLeadAgency 			BIT NULL,
				PDIFlagSet 						BIT NULL,

				SelectionOrganisationID			INT NULL,
				SelectionPostalID				INT NULL,
				SelectionEmailID				INT NULL,
				SelectionPhoneID				INT NULL,
				SelectionLandlineID				INT NULL,
				SelectionMobileID				INT NULL,

				EventDateOutOfDate				BIT NULL,
				EventDateTooYoung				BIT NULL,

				CaseID							INT NULL,
				NonSelectableWarrantyEvent		BIT NULL,	-- V3.31
				InvalidDateOfLastContact		BIT	NULL,   -- V3.32
				CQIMissingExtraVehicleFeed		BIT NULL,	-- V3.40
				MissingPerson					BIT NULL,	-- V3.47
				MissingOrganisation				BIT NULL,	-- V3.47
				NonLatestEvent					BIT NULL,	-- V3.61
			)

			INSERT INTO #LoggingValues 
			SELECT 	
				SL.AuditItemID,
				SB.DeleteRecontactPeriod AS RecontactPeriod,						-- V3.56
				SB.DeleteRelativeRecontactPeriod AS RelativeRecontactPeriod,		-- V3.56
				SB.CaseIDPrevious,			
				SB.DeleteSelected AS EventAlreadySelected,							-- V3.56
				SB.DeletePartyTypes AS ExclusionListMatch,							-- V3.56
				SB.DeleteEventNonSolicitation AS EventNonSolicitation,				-- V3.56
				SB.DeleteBarredEmail AS BarredEmailAddress,							-- V3.56
				SB.DeleteEventType AS WrongEventType,								-- V3.56
				SB.DeleteStreet AS MissingStreet,									-- V3.56
				SB.DeletePostcode AS MissingPostcode,								-- V3.56
				SB.DeleteEmail AS MissingEmail,										-- V3.56
				SB.DeleteTelephone AS MissingTelephone,								-- V3.56
				SB.DeleteStreetOrEmail AS MissingStreetAndEmail,					-- V3.56
				SB.DeleteTelephoneOrEmail AS MissingTelephoneAndEmail,				-- V3.56
				SB.DeleteMobilePhone AS MissingMobilePhone,							-- V3.56		
				SB.DeleteMobilePhoneOrEmail AS MissingMobilePhoneAndEmail,			-- V3.56		
				SB.DeleteInvalidModel AS InvalidModel,								-- V3.56
				SB.DeleteInvalidVariant AS InvalidVariant,							-- V3.37 V3.56
				SB.DeletePartyName AS MissingPartyName,								-- V3.56			
				SB.DeleteLanguage AS MissingLanguage,								-- V3.56
				SB.DeleteInternalDealer AS InternalDealer,							-- V3.56		
				SB.DeleteInvalidOwnershipCycle AS InvalidOwnershipCycle,			-- V3.56		
				SB.DeleteInvalidRoleType AS InvalidRoleType,						-- V3.56			
				SB.DeleteInvalidSaleType AS InvalidSaleType,						-- V3.56			
				SB.DeleteAFRLCode AS InvalidAFRLCode,								-- V3.56			
				SB.AFRLCode AS SuppliedAFRLCode,									-- V3.56			
				SB.DeleteDealerExclusion AS DealerExclusionListMatch,				-- V3.56			
				SB.DeleteNotInQuota AS NotInQuota,									-- V3.56
				SB.DeleteContactPreferences AS ContactPreferencesSuppression,		-- V3.56		
				SB.ContactPreferencesPartySuppress,	
				SB.ContactPreferencesEmailSuppress,	
				SB.ContactPreferencesPhoneSuppress,	
				SB.ContactPreferencesPostalSuppress,
				SB.ContactPreferencesUnsubscribed,	
				SB.DeleteFilterOnDealerPilotOutputCodes AS DealerPilotOutputFiltered,	-- V3.56		
				SB.DeleteCRMSaleType AS InvalidCRMSaleType,							-- V3.56					
				SB.DeleteMissingLostLeadAgency AS MissingLostLeadAgency,			-- V3.56					
				SB.DeletePDIFlag AS PDIFlagSet,										-- V3.56		
				SB.SelectionOrganisationID,
				SB.SelectionPostalID,	
				SB.SelectionEmailID,	
				SB.SelectionPhoneID,	
				SB.SelectionLandlineID,	
				SB.SelectionMobileID,	
				SL.EventDateOutOfDate,					-- Copy in existing value as this may or may not be overwritten.
				SL.EventDateTooYoung,					-- Copy in existing value as this may or may not be overwritten.
				SL.CaseID,
				SB.DeleteWarranty AS NonSelectableWarrantyEvent,					-- V3.31 V3.56
				SB.DeleteInvalidDateOfLastContact AS InvalidDateOfLastContact,		-- V3.32 V3.56
				SB.DeleteCQIMissingExtraVehicleFeed AS CQIMissingExtraVehicleFeed,	-- V3.40 V3.56
				SB.DeletePersonRequired AS MissingPerson,							-- V3.47 V3.56
				SB.DeleteOrganisationRequired AS MissingOrganisation,				-- V3.47 V3.56
				SB.DeleteNonLatestEvent												-- V3.61
			FROM Selection.Base SB
				INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = SB.EventID
																							AND SL.QuestionnaireRequirementID = CASE	WHEN SL.Market = 'United Kingdom' AND SL.Questionnaire = 'Sales' AND SL.Brand = 'Land Rover' THEN SB.QuestionnaireRequirementid	-- V3.58
																																		ELSE SL.QuestionnaireRequirementID END																							-- V3.58				
			WHERE SB.VehicleID = SL.MatchedODSVehicleID
				AND SB.EventID = SL.MatchedODSEventID
				AND SB.DeleteSelected <> 1														-- V3.56 Log event already selected separately
		
			-- V3.56 Log already selected
			INSERT INTO #LoggingValues
			SELECT SL.AuditItemID,
				0 AS RecontactPeriod,
				0 AS RelativeRecontactPeriod,
				0 AS CaseIDPrevious,
				SB.DeleteSelected AS EventAlreadySelected,
				0 AS ExclusionListMatch,
				0 AS EventNonSolicitation,
				0 AS BarredEmailAddress,
				0 AS WrongEventType,
				0 AS MissingStreet,
				0 AS MissingPostcode,
				0 AS MissingEmail,
				0 AS MissingTelephone,
				0 AS MissingStreetAndEmail,
				0 AS MissingTelephoneAndEmail,
				0 AS MissingMobilePhone,		
				0 AS MissingMobilePhoneAndEmail,	
				0 AS InvalidModel,
				0 AS InvalidVariant,
				0 AS MissingPartyName,		
				0 AS MissingLanguage,
				0 AS InternalDealer,		
				0 AS InvalidOwnershipCycle,		
				0 AS InvalidRoleType,		
				0 AS InvalidSaleType,			
				0 AS InvalidAFRLCode,			
				0 AS SuppliedAFRLCode,			
				0 AS DealerExclusionListMatch,		
				0 AS NotInQuota,
				SB.DeleteContactPreferences AS ContactPreferencesSuppression,		
				SB.ContactPreferencesPartySuppress,	
				SB.ContactPreferencesEmailSuppress,	
				SB.ContactPreferencesPhoneSuppress,	
				SB.ContactPreferencesPostalSuppress,
				SB.ContactPreferencesUnsubscribed,	
				0 AS DealerPilotOutputFiltered,	
				0 AS InvalidCRMSaleType,				
				0 AS MissingLostLeadAgency,					
				0 AS PDIFlagSet,		
				SB.SelectionOrganisationID,
				SB.SelectionPostalID,	
				SB.SelectionEmailID,	
				SB.SelectionPhoneID,	
				SB.SelectionLandlineID,	
				SB.SelectionMobileID,	
				SL.EventDateOutOfDate,
				SL.EventDateTooYoung,
				NULL AS CaseID,
				0 AS NonSelectableWarrantyEvent,
				0 AS InvalidDateOfLastContact,
				0 AS CQIMissingExtraVehicleFeed,
				0 AS MissingPerson,
				0 AS MissingOrganisation,
				0 AS NonLatestEvent				--V3.61

			FROM Selection.Base SB
				INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = SB.EventID
																							AND SL.QuestionnaireRequirementID = CASE	WHEN SL.Market = 'United Kingdom' AND SL.Questionnaire = 'Sales' AND SL.Brand = 'Land Rover' THEN SB.QuestionnaireRequirementid	-- V3.58
																																		ELSE SL.QuestionnaireRequirementID END																							-- V3.58				
			WHERE SB.VehicleID = SL.MatchedODSVehicleID
				AND SB.EventID = SL.MatchedODSEventID
				AND SB.DeleteSelected = 1							-- V3.56 Log already selected separately
				AND ISNULL(SL.CaseID,0) = 0							-- V3.56 Do not update existing logging for original case				

		END
		

		-- NOW DELETE THE UNSELECTABLE RECORDS
		DELETE
		FROM Selection.Base
		WHERE DeleteBarredEmail = 1
			OR DeleteEmail = 1
			OR DeleteEventNonSolicitation = 1
			OR DeleteEventType = 1
			OR DeleteInvalidModel = 1
			OR DeleteInvalidVariant = 1												-- V3.37
			OR DeletePartyTypes = 1
			OR DeletePostcode = 1
			OR DeleteRecontactPeriod = 1
			OR DeleteRelativeRecontactPeriod = 1
			OR DeleteSelected = 1
			OR DeleteStreet = 1
			OR DeleteStreetOrEmail = 1
			OR DeleteTelephone = 1
			OR DeleteTelephoneOrEmail = 1
			OR DeleteMobilePhone = 1												-- V1.5
			OR DeleteMobilePhoneOrEmail = 1											-- V1.5
			OR DeletePersonRequired = 1
			OR DeleteOrganisationRequired = 1
			OR DeletePartyName = 1
			OR DeleteLanguage = 1													-- V1.8
			OR DeleteInternalDealer = 1												-- V2.0		
			OR DeleteInvalidOwnershipCycle = 1										-- V2.0		
			OR DeleteInvalidRoleType = 1											-- V3.1
			OR DeleteInvalidSaleType = 1											-- V3.1
			OR DeleteAFRLCode = 1													-- V3.2
			OR DeleteDealerExclusion = 1											-- V3.2
			OR DeleteNotInQuota = 1													-- V3.8
			OR DeleteContactPreferences = 1											-- V3.9
			OR DeleteFilterOnDealerPilotOutputCodes = 1								-- V3.10
			OR DeleteCRMSaleType = 1												-- V3.11
			OR DeleteCQIMissingExtraVehicleFeed = 1									-- V3.15
			OR DeleteMissingLostLeadAgency = 1										-- V3.17
			OR DeletePDIFlag = 1													-- V3.22
			OR DeleteWarranty = 1													-- V3.31
			OR DeleteInvalidDateOfLastContact =1									-- V3.32
			OR DeleteNonLatestEvent = 1												-- V3.61
		
		-- NOW SELECT THE REMAINING EVENTS
		INSERT INTO Event.vwDA_AutomotiveEventBasedInterviews
		(	 
			CaseStatusTypeID,
			EventID,
			PartyID,
			VehicleRoleTypeID,
			VehicleID,
			ModelRequirementID,
			SelectionRequirementID
		)
		SELECT
			1 AS CaseStatusTypeID,
			SB.EventID,
			SB.PartyID,
			SB.VehicleRoleTypeID,
			SB.VehicleID,
			MR.RequirementID AS ModelRequirementID,
			SR.RequirementID AS SelectionRequirementID
		FROM Selection.Base SB
			INNER JOIN Requirement.ModelRequirements MR ON MR.ModelID = SB.ModelID
			INNER JOIN Requirement.RequirementRollups MS ON MS.RequirementIDMadeUpOf = MR.RequirementID
			INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = MS.RequirementIDPartOf
		WHERE SR.RequirementID = @SelectionRequirementID


		-- NOW SET THE CaseContactMechanisms
		INSERT INTO Event.CaseContactMechanisms (CaseID, ContactMechanismID, ContactMechanismTypeID)
		SELECT X.CaseID, 
			X.ContactMechanismID, 
			X.ContactMechanismTypeID
		FROM (	SELECT AEBI.CaseID, 
					SB.PostalContactMechanismID AS ContactMechanismID, 
					1 AS ContactMechanismTypeID
				FROM Requirement.SelectionCases SC
					INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
					INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
				WHERE SC.RequirementIDPartOf = @SelectionRequirementID
					AND ISNULL(SB.PostalContactMechanismID, 0) > 0

				UNION

				SELECT AEBI.CaseID, 
					SB.PhoneContactMechanismID AS ContactMechanismID, 
					2 AS ContactMechanismTypeID
				FROM Requirement.SelectionCases SC
					INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
					INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
				WHERE SC.RequirementIDPartOf = @SelectionRequirementID
					AND ISNULL(SB.PhoneContactMechanismID, 0) > 0

				UNION

				SELECT AEBI.CaseID, 
					SB.LandlineContactMechanismID AS ContactMechanismID, 3 AS ContactMechanismTypeID
				FROM Requirement.SelectionCases SC
					INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
					INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
				WHERE SC.RequirementIDPartOf = @SelectionRequirementID
					AND ISNULL(SB.LandlineContactMechanismID, 0) > 0

				UNION

				SELECT AEBI.CaseID, 
					SB.MobileContactMechanismID AS ContactMechanismID, 
					4 AS ContactMechanismTypeID
				FROM Requirement.SelectionCases SC
					INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
					INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
				WHERE SC.RequirementIDPartOf = @SelectionRequirementID
					AND ISNULL(SB.MobileContactMechanismID, 0) > 0

				UNION
			
				SELECT AEBI.CaseID, 
					SB.EmailContactMechanismID, 
					6 AS ContactMechanismTypeID
				FROM Requirement.SelectionCases SC
					INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
					INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
				WHERE SC.RequirementIDPartOf = @SelectionRequirementID
					AND ISNULL(SB.EmailContactMechanismID, 0) > 0
				) X
			LEFT JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = X.CaseID
												AND CCM.ContactMechanismID = X.ContactMechanismID
												AND CCM.ContactMechanismTypeID = X.ContactMechanismTypeID
		WHERE CCM.CaseID IS NULL


		-- UPDATE THE DATA IN SelectionRequirements
		UPDATE Requirement.SelectionRequirements
		SET	SelectionStatusTypeID = (	SELECT SelectionStatusTypeID 
										FROM Requirement.SelectionStatusTypes 
										WHERE SelectionStatusType = 'Selected'),
			DateLastRun = GETDATE(),
			RecordsSelected = (	SELECT COUNT(CaseID) 
								FROM Requirement.SelectionCases 
								WHERE RequirementIDPartOf = @SelectionRequirementID)
		WHERE RequirementID = @SelectionRequirementID


		-- FINALLY MARK THE CASES IN THE SELECTION LOGGING TABLE
		IF @UpdateSelectionLogging = 1	--DO THE LOGGING
			BEGIN
				-- Update the saved "logging values" table with the CaseID				-- V3.28
				UPDATE LV						
				SET LV.CaseID = AEBI.CaseID,
					LV.EventDateOutOfDate = 0,
					LV.EventDateTooYoung = 0
				FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
					INNER JOIN #LoggingValues LV ON LV.AuditItemID = SL.AuditItemID
					INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.EventID = SL.MatchedODSEventID
					INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = AEBI.CaseID
				WHERE SC.RequirementIDPartOf = @SelectionRequirementID
				-- V3.28 -- REMOVE -- AND SL.SampleRowProcessed = 0

				-- Write all the values to the logging table								-- V3.28
				UPDATE SL
				SET
					SL.RecontactPeriod						= LV.RecontactPeriod,
					SL.RelativeRecontactPeriod				= LV.RelativeRecontactPeriod,
					SL.CaseIDPrevious						= LV.CaseIDPrevious,
					SL.EventAlreadySelected					= LV.EventAlreadySelected,
					SL.ExclusionListMatch					= LV.ExclusionListMatch,
					SL.EventNonSolicitation					= LV.EventNonSolicitation,
					SL.BarredEmailAddress 					= LV.BarredEmailAddress,
					SL.WrongEventType						= LV.WrongEventType,
					SL.MissingStreet 						= LV.MissingStreet,
					SL.MissingPostcode						= LV.MissingPostcode,
					SL.MissingEmail 						= LV.MissingEmail,
					SL.MissingTelephone 					= LV.MissingTelephone,
					SL.MissingStreetAndEmail 				= LV.MissingStreetAndEmail,
					SL.MissingTelephoneAndEmail 			= LV.MissingTelephoneAndEmail,
					SL.MissingMobilePhone 					= LV.MissingMobilePhone,
					SL.MissingMobilePhoneAndEmail 			= LV.MissingMobilePhoneAndEmail,
					SL.InvalidModel 						= LV.InvalidModel,
					SL.InvalidVariant						= LV.InvalidVariant,					-- V3.37
					SL.MissingPartyName 					= LV.MissingPartyName,
					SL.MissingLanguage 						= LV.MissingLanguage,
					SL.InternalDealer 						= LV.InternalDealer,
					SL.InvalidOwnershipCycle				= LV.InvalidOwnershipCycle,
					SL.InvalidRoleType 						= LV.InvalidRoleType,
					SL.InvalidSaleType 						= LV.InvalidSaleType,
					SL.InvalidAFRLCode						= LV.InvalidAFRLCode,
					SL.SuppliedAFRLCode 					= LV.SuppliedAFRLCode,
					SL.DealerExclusionListMatch 			= LV.DealerExclusionListMatch,
					SL.NotInQuota 							= LV.NotInQuota,
					SL.ContactPreferencesSuppression 		= LV.ContactPreferencesSuppression,
					SL.ContactPreferencesPartySuppress 		= LV.ContactPreferencesPartySuppress,
					SL.ContactPreferencesEmailSuppress 		= LV.ContactPreferencesEmailSuppress,
					SL.ContactPreferencesPhoneSuppress 		= LV.ContactPreferencesPhoneSuppress,
					SL.ContactPreferencesPostalSuppress 	= LV.ContactPreferencesPostalSuppress,
					SL.ContactPreferencesUnsubscribed 		= LV.ContactPreferencesUnsubscribed,
					SL.DealerPilotOutputFiltered			= LV.DealerPilotOutputFiltered,
					SL.InvalidCRMSaleType 					= LV.InvalidCRMSaleType,
					SL.MissingLostLeadAgency 				= LV.MissingLostLeadAgency,
					SL.PDIFlagSet							= LV.PDIFlagSet,
					SL.SelectionOrganisationID				= LV.SelectionOrganisationID,			-- V3.28
					SL.SelectionPostalID					= LV.SelectionPostalID,					-- V3.28	
					SL.SelectionEmailID						= LV.SelectionEmailID,					-- V3.28
					SL.SelectionPhoneID						= LV.SelectionPhoneID,					-- V3.28
					SL.SelectionLandlineID					= LV.SelectionLandlineID,				-- V3.28
					SL.SelectionMobileID					= LV.SelectionMobileID,					-- V3.28
					SL.EventDateOutOfDate					= LV.EventDateOutOfDate,
					SL.EventDateTooYoung					= LV.EventDateTooYoung,
					SL.CaseID								= LV.CaseID,
					SL.SampleRowProcessed					= 1,
					SL.SampleRowProcessedDate				= GETDATE(),
					SL.NonSelectableWarrantyEvent			= LV.NonSelectableWarrantyEvent,		-- V3.31
					SL.InvalidDateOfLastContact				= LV.InvalidDateOfLastContact,			-- V3.32
					SL.CQIMissingExtraVehicleFeed			= LV.CQIMissingExtraVehicleFeed,		-- V3.40
					SL.MissingPerson						= LV.MissingPerson,						-- V3.47
					SL.MissingOrganisation					= LV.MissingOrganisation,				-- V3.47
					SL.NonLatestEvent						= LV.NonLatestEvent						-- V3.61
				FROM #LoggingValues LV
					INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LV.AuditItemID

			END

		/*
		DROP TABLE #MAXEVENTS

		-- REJECT ANY DUPLICATE CASES
		-- TODO: ADD THIS
		EXEC dbo.uspSELECTIONS_RejectDuplicateCases @SelectionRequirementID
		
		
		-- V3.28 -- Remove this step as we actually update all the associated logging entries for each event in this procedure.
		-----------------------------------------------------------------------------------------------------------------------
		-- RECORD THE SELECTION IN THE WEBSITE REPORTING DATABASE
		IF @UpdateSelectionLogging = 1	--DO THE LOGGING
			BEGIN
				EXEC [$(WebsiteReporting)].dbo.uspRecordSelection @SelectionRequirementID
				
			END
		*/
		
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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
