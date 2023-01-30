CREATE PROCEDURE [Selection].[uspRunSelectAll]
	@QuestionnaireRequirementID [dbo].[RequirementID], 
	@SelectionRequirementID [dbo].[RequirementID]
AS
/*
	Purpose: Select all historic sample, for NEW markets. 
		
	Version			Date			Developer			Comment
	1.0				25/11/2014		Eddie Thomas		Created
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
		DECLARE @EventCategory VARCHAR(10)
		DECLARE @ManufacturerPartyID dbo.PartyID
		DECLARE @OwnershipCycle dbo.OwnershipCycle
		DECLARE @CountryID dbo.CountryID
		DECLARE @SelectSales BIT
		DECLARE @SelectService BIT
		DECLARE @SelectWarranty BIT
		DECLARE @SelectRoadside BIT
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

		
		SELECT
			 @StartDays = QR.StartDays
			,@EndDays = QR.EndDays
			,@SelectionDate = SR.SelectionDate
			,@EventCategory = B.Questionnaire
			,@ManufacturerPartyID = B.ManufacturerPartyID
			,@OwnershipCycle = QR.OwnershipCycle
			,@CountryID = B.CountryID
			,@SelectSales = B.SelectSales
			,@SelectService = B.SelectService
			,@SelectWarranty = B.SelectWarranty
			,@SelectRoadside = B.SelectRoadside
			,@PersonRequired = B.PersonRequired
			,@OrganisationRequired = B.OrganisationRequired
			,@StreetRequired = B.StreetRequired
			,@PostcodeRequired = B.PostcodeRequired
			,@EmailRequired = B.EmailRequired
			,@TelephoneRequired = B.TelephoneRequired
			,@StreetOrEmailRequired = B.StreetOrEmailRequired
			,@TelephoneOrEmailRequired = B.TelephoneOrEmailRequired
			,@MobilePhoneRequired = B.MobilePhoneRequired					-- v1.5
			,@MobilePhoneOrEmailRequired = B.MobilePhoneOrEmailRequired		-- v1.5
			,@LanguageRequired = B.LanguageRequired
			,@QuestionnaireIncompatibilityDays = QR.QuestionnaireIncompatibilityDays
			,@UpdateSelectionLogging = B.UpdateSelectionLogging
			,@RelativeRecontactDays = QR.RelativeRecontactDays
		FROM dbo.vwBrandMarketQuestionnaireSampleMetadata B
		INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = B.QuestionnaireRequirementID
		INNER JOIN Requirement.RequirementRollups QS ON QS.RequirementIDPartOf = QR.RequirementID
		INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = QS.RequirementIDMadeUpOf
		WHERE QR.RequirementID = @QuestionnaireRequirementID
		AND SR.RequirementID = @SelectionRequirementID


		-- GET THE LATEST EVENTS WITH IN THE DATE RANGE FOR EACH PARTY
		SELECT
			VPRE.VehicleID, 
			ET.EventCategoryID, 
			EPR.PartyID AS DealerID, 
			VPRE.PartyID, 
			VPRE.VehicleRoleTypeID, 
			COALESCE(MAX(E.EventDate), MAX(REG.RegistrationDate)) AS MaxEventDate
		INTO #MAXEVENTS
		FROM Vehicle.VehiclePartyRoleEvents VPRE
		INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
		INNER JOIN Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
		LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
			INNER JOIN Vehicle.Registrations REG ON REG.RegistrationID = VRE.RegistrationID
							--Dealing with historic data, very likely that event date will fall outside date window
							--AND RegistrationDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)
		ON VRE.EventID = E.EventID AND VRE.VehicleID = VPRE.VehicleID
		WHERE ET.EventCategory = @EventCategory
		
		--Dealing with historic data, very likely that event date will fall outside date window
		--AND COALESCE(E.EventDate, REG.RegistrationDate) BETWEEN DATEADD(DAY, @EndDays, @SelectionDate) AND DATEADD(DAY, @StartDays, @SelectionDate)
		GROUP BY
			VPRE.VehicleID, 
			ET.EventCategoryID, 
			EPR.PartyID, 
			VPRE.PartyID, 
			VPRE.VehicleRoleTypeID


		-- CHECK IF WE'VE GOT ANY EVENTS FOR ANY OF THESE PARTIES THAT ARE NOT THE LATEST EVENTS BUT HAVE NOT YET BEEN MARKED IN THE SELECTION LOGGING TABLE
	
	IF @UpdateSelectionLogging = 1--DO THE LOGGING
		 BEGIN
		 
			-- SALES - PERSONS
			UPDATE SL
			SET  SL.NonLatestEvent = 1
				,SL.SampleRowProcessed = 1
				,SL.SampleRowProcessedDate = GETDATE()
			FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
			INNER JOIN #MAXEVENTS ME ON ME.PartyID = SL.MatchedODSPersonID
			WHERE ME.EventCategoryID = (SELECT EventCategoryID FROM Event.EventCategories WHERE EventCategory = 'Sales')
			AND ME.MaxEventDate > SL.SaleDate
			AND ME.VehicleID = SL.MatchedODSVehicleID
			AND ME.DealerID = SL.SalesDealerID
			
			-- SERVICE - PERSONS
			UPDATE SL
			SET  SL.NonLatestEvent = 1
				,SL.SampleRowProcessed = 1
				,SL.SampleRowProcessedDate = GETDATE()
			FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
			INNER JOIN #MAXEVENTS ME ON ME.PartyID = SL.MatchedODSPersonID
			WHERE ME.EventCategoryID = (SELECT EventCategoryID FROM Event.EventCategories WHERE EventCategory = 'Service')
			AND ME.MaxEventDate > SL.ServiceDate
			AND ME.VehicleID = SL.MatchedODSVehicleID
			AND ME.DealerID = SL.ServiceDealerID

			-- SALES - ORGANISATIONS
			UPDATE SL
			SET  SL.NonLatestEvent = 1
				,SL.SampleRowProcessed = 1
				,SL.SampleRowProcessedDate = GETDATE()
			FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
			INNER JOIN #MAXEVENTS ME ON ME.PartyID = SL.MatchedODSOrganisationID
			WHERE ME.EventCategoryID = (SELECT EventCategoryID FROM Event.EventCategories WHERE EventCategory = 'Sales')
			AND ME.MaxEventDate > SL.SaleDate
			AND ME.VehicleID = SL.MatchedODSVehicleID
			AND ME.DealerID = SL.SalesDealerID

			-- SERVICE - ORGANISATIONS
			UPDATE SL
			SET  SL.NonLatestEvent = 1
				,SL.SampleRowProcessed = 1
				,SL.SampleRowProcessedDate = GETDATE()
			FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
			INNER JOIN #MAXEVENTS ME ON ME.PartyID = SL.MatchedODSOrganisationID
			WHERE ME.EventCategoryID = (SELECT EventCategoryID FROM Event.EventCategories WHERE EventCategory = 'Service')
			AND ME.MaxEventDate > SL.ServiceDate
			AND ME.VehicleID = SL.MatchedODSVehicleID
			AND ME.DealerID = SL.ServiceDealerID

			-- SALES - PARTIES
			UPDATE SL
			SET  SL.NonLatestEvent = 1
				,SL.SampleRowProcessed = 1
				,SL.SampleRowProcessedDate = GETDATE()
			FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
			INNER JOIN #MAXEVENTS ME ON ME.PartyID = SL.MatchedODSPartyID
			WHERE ME.EventCategoryID = (SELECT EventCategoryID FROM Event.EventCategories WHERE EventCategory = 'Sales')
			AND ME.MaxEventDate > SL.SaleDate
			AND ME.VehicleID = SL.MatchedODSVehicleID
			AND ME.DealerID = SL.SalesDealerID

			-- SERVICE - PARTIES
			UPDATE SL
			SET  SL.NonLatestEvent = 1
				,SL.SampleRowProcessed = 1
				,SL.SampleRowProcessedDate = GETDATE()
			FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
			INNER JOIN #MAXEVENTS ME ON ME.PartyID = SL.MatchedODSPartyID
			WHERE ME.EventCategoryID = (SELECT EventCategoryID FROM Event.EventCategories WHERE EventCategory = 'Service')
			AND ME.MaxEventDate > SL.ServiceDate
			AND ME.VehicleID = SL.MatchedODSVehicleID
			AND ME.DealerID = SL.ServiceDealerID
				
		END



		-- TRUNCATE THE BASE TABLE TO HOLD THE FINAL DATA
		TRUNCATE TABLE Selection.Base								-- v1.5


		-- NOW GET THE EVENT DETAILS FOR THE LATEST EVENTS FOR EACH PARTY FOR THE CORRECT BRAND, OWNERSHIP CYCLE, FOR NON INTERNAL DEALERS AND WHERE WE HAVE PEOPLE OR ORGANISATION INFORMATION
		INSERT INTO Selection.Base
		(
			 EventID
			,VehicleID
			,VehicleRoleTypeID
			,VIN
			,EventCategory
			,EventCategoryID
			,EventType
			,EventTypeID
			,EventDate
			,ManufacturerPartyID
			,ModelID
			,PartyID
			,RegistrationNumber
			,RegistrationDate
			,OwnershipCycle
			,DealerPartyID
			,DealerCode
			,OrganisationPartyID
		)
		SELECT DISTINCT
			 VE.EventID
			,VE.VehicleID
			,VE.VehicleRoleTypeID
			,VE.VIN
			,VE.EventCategory
			,VE.EventCategoryID
			,VE.EventType
			,VE.EventTypeID
			,VE.EventDate
			,VE.ManufacturerPartyID
			,VE.ModelID
			,VE.PartyID
			,VE.RegistrationNumber
			,VE.RegistrationDate
			,VE.OwnershipCycle
			,VE.DealerPartyID
			,VE.DealerCode
			,COALESCE(O.PartyID, BE.PartyID) AS OrganisationPartyID
		FROM #MAXEVENTS M
		INNER JOIN Meta.VehicleEvents VE ON VE.VehicleID = M.VehicleID
										AND VE.EventCategoryID = M.EventCategoryID
										AND VE.PartyID = M.PartyID
										AND VE.VehicleRoleTypeID = M.VehicleRoleTypeID
										AND VE.EventDate = M.MaxEventDate
										AND VE.ManufacturerPartyID = @ManufacturerPartyID
		LEFT JOIN Meta.BusinessEvents BE ON BE.EventID = VE.EventID		
		LEFT JOIN Party.Organisations O ON O.PartyID = VE.PartyID
		
		
		--v1.8 -- EXCLUDE PARTIES WITH NO NAME
		--UPDATE SB
		--SET DeletePartyName = 1
		--FROM Selection.Base SB
		--LEFT JOIN Party.People PP ON PP.PartyID = SB.PartyID
		--LEFT JOIN Party.Organisations O ON O.PartyID = SB.PartyID		
		--WHERE COALESCE(PP.PartyID, O.PartyID) IS NULL 
		
		
		
		--v2.0 -- EXCLUDE INTERNAL DEALERS
		--UPDATE SB
		--SET DeleteInternalDealer = 1
		--FROM Selection.Base SB
		--LEFT JOIN Party.DealershipClassifications DC ON DC.PartyID = SB.DealerPartyID 
					--AND DC.PartyTypeID = (SELECT PartyTypeID FROM Party.PartyTypes WHERE PartyType = 'Manufacturer Internal Dealership')		
		--WHERE DC.PartyID IS NOT NULL 
		
		
		--v2.0 -- Mark InvalidOwnershipCycle
		--UPDATE SB
		--SET DeleteInvalidOwnershipCycle = 1
		--FROM Selection.Base SB
		--JOIN Event.OwnershipCycle OC ON OC.EventID = SB.EventID
		--WHERE ISNULL(OC.OwnershipCycle, 1) <> COALESCE(@OwnershipCycle, OC.OwnershipCycle, 1)
		
		
		
		-- v1.17  - Exclude South Africa Records from this update as the address data not populated/reliable.
		IF @CountryID <> (select CountryID from ContactMechanism.Countries c where Country = 'South Africa')
		BEGIN 
			-- GET THE ORGANISATION PARTYID IF WE'VE NOT ALREADY GOT IT BY CHECKING FOR ORGANISATIONS AT THE SAME ADDRESS
			UPDATE SB
			SET SB.OrganisationPartyID = O.PartyID
			FROM Selection.Base SB
			INNER JOIN ContactMechanism.PartyContactMechanisms PCM_P ON PCM_P.PartyID = SB.PartyID
			INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PCM_P.ContactMechanismID
			INNER JOIN ContactMechanism.PartyContactMechanisms PCM_O ON PCM_O.ContactMechanismID = PA.ContactMechanismID
			INNER JOIN Party.Organisations O ON O.PartyID = PCM_O.PartyID
			WHERE SB.OrganisationPartyID IS NULL
		END


		-- NOW GET THE COUNTRY DETAILS: FIRSTLY USE THE POSTAL ADDRESS OF THE CUSOMTER, SECONDLY USE THE MARKET OF THE DEALER
		-- WHILE WE'RE HERE GET THE ADDRESS DETAILS AS WELL
		UPDATE SB
		SET SB.CountryID = PA.CountryID,
			SB.PostalContactMechanismID = PA.ContactMechanismID,
			SB.Street = PA.Street,
			SB.Postcode = PA.Postcode
		FROM Selection.Base SB
		INNER JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = SB.PartyID
		INNER JOIN ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID

		; WITH DealerCountries (DealerPartyID, CountryID) AS (
			SELECT DISTINCT
				PartyIDFrom, CountryID
			FROM ContactMechanism.DealerCountries
		)
		UPDATE SB
		SET SB.CountryID = DC.CountryID
		FROM Selection.Base SB
		INNER JOIN DealerCountries DC ON DC.DealerPartyID = SB.DealerPartyID
		WHERE SB.CountryID IS NULL

		-- NOW DELETE ALL THE RECORDS THAT DON'T BELONG TO THE REQUIRED CountryID
		DELETE FROM Selection.Base
		WHERE ISNULL(CountryID,0) <> @CountryID -- eliminating all records with no countryid / dont belong to required countryid bug 7569


		-- NOW CHECK IF WE ARE SELECTION THE EVENT TYPES
		IF ISNULL(@SelectSales, 0) = 0
		BEGIN
			UPDATE Selection.Base
			SET DeleteEventType = 1
			WHERE EventType = 'Sales'
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


		-- ADD IN EMAIL ContactMechanismID
		UPDATE SB
		SET SB.EmailContactMechanismID = PBEA.ContactMechanismID
		FROM Selection.Base SB
		INNER JOIN Meta.PartyBestEmailAddresses PBEA ON PBEA.PartyID = SB.PartyID

		-- ADD IN TELEPHONE ContactMechanismIDs
		UPDATE SB
		SET  SB.PhoneContactMechanismID = TN.PhoneID
			,SB.LandlineContactMechanismID = TN.LandlineID
			,SB.MobileContactMechanismID = TN.MobileID
		FROM Selection.Base SB
		INNER JOIN Meta.PartyBestTelephoneNumbers TN ON TN.PartyID = SB.PartyID

		
		--------------------------------------------------------------------		
		-- Checks based on Required field flags
		--------------------------------------------------------------------		
		--IF @PersonRequired = 1 AND @OrganisationRequired = 0
		--BEGIN
			--UPDATE SB
			--SET DeletePersonRequired = 1
			--FROM Selection.Base SB
			--INNER JOIN Party.Organisations O ON O.PartyID = SB.PartyID
		--END
		--IF @PersonRequired = 0 AND @OrganisationRequired = 1
		--BEGIN
			--UPDATE SB
			--SET DeleteOrganisationRequired = 1
			--FROM Selection.Base SB
			--INNER JOIN Party.People PP ON PP.PartyID = SB.PartyID
		--END
		--IF @PersonRequired = 1 AND @OrganisationRequired = 1
		--BEGIN
			--UPDATE Selection.Base
			--SET DeleteOrganisationRequired = 0, DeletePersonRequired = 0
		--END 
		--IF @StreetRequired = 1
		--BEGIN
			--UPDATE Selection.Base
			--SET DeleteStreet = 1
			--WHERE ISNULL(Street, '') = ''
		--END
		--IF @PostcodeRequired = 1
		--BEGIN
			--UPDATE Selection.Base
			--SET DeletePostcode = 1
			--WHERE ISNULL(Postcode, '') = ''
		--END
		--IF @EmailRequired = 1
		--BEGIN
			--UPDATE Selection.Base
			--SET DeleteEmail = 1
			--WHERE ISNULL(EmailContactMechanismID, 0) = 0
		--END
		--IF @TelephoneRequired = 1
		--BEGIN
			--UPDATE Selection.Base
			--SET DeleteTelephone = 1
			--WHERE ISNULL(PhoneContactMechanismID, 0) = 0
			--AND ISNULL(LandlineContactMechanismID, 0) = 0
			--AND ISNULL(MobileContactMechanismID, 0) = 0
		--END	
		--IF @MobilePhoneRequired = 1							-- v1.5
		--BEGIN
			--UPDATE Selection.Base
			--SET DeleteMobilePhone = 1
			--WHERE ISNULL(MobileContactMechanismID, 0) = 0
		--END
		
		--IF @LanguageRequired = 1
		--BEGIN
		
			--; WITH PreferredLanguage (PartyID)
			--AS 
				--(
					--SELECT PartyID
					--FROM Party.PartyLanguages
					--WHERE PreferredFlag = 1
				--)
				
				--UPDATE SB
					--SET DeleteLanguage = 1
				--FROM Selection.Base SB
				--WHERE NOT EXISTS (SELECT 1 FROM PreferredLanguage PL WHERE PL.PartyID = SB.PartyID)
		--END
		
		----- Now check "OR" filters -------
		--IF @StreetRequired = 0 
		--AND @PostcodeRequired = 0 
		--AND @EmailRequired = 0 
		--AND @MobilePhoneRequired = 0
		--BEGIN 
			--IF @StreetOrEmailRequired = 1
			--BEGIN
				--UPDATE Selection.Base
				--SET DeleteStreetOrEmail = 1
				--WHERE ISNULL(EmailContactMechanismID, 0) = 0
				--AND ISNULL(Street, '') = ''
			--END
			--IF @TelephoneOrEmailRequired = 1
			--BEGIN
				--UPDATE Selection.Base
				--SET DeleteTelephoneOrEmail = 1
				--WHERE ISNULL(EmailContactMechanismID, 0) = 0
				--AND ISNULL(PhoneContactMechanismID, 0) = 0
				--AND ISNULL(LandlineContactMechanismID, 0) = 0
				--AND ISNULL(MobileContactMechanismID, 0) = 0
			--END
			--IF @MobilePhoneOrEmailRequired = 1								-- v1.5
			--BEGIN
				--UPDATE Selection.Base
				--SET DeleteMobilePhoneOrEmail = 1
				--WHERE ISNULL(EmailContactMechanismID, 0) = 0
				--AND ISNULL(MobileContactMechanismID, 0) = 0
			--END
		--END ------------------------------

		
		--------------------------------------------------------------------		
		-- Further general checks 
		--------------------------------------------------------------------		
					
		-- NOW CHECK FOR ANY EVENTS ALREADY SELECTED
		--; WITH EXSELS (PartyID, VehicleRoleTypeID, VehicleID, EventID) AS (
			--SELECT
				--AEBI.PartyID,
				--AEBI.VehicleRoleTypeID,
				--AEBI.VehicleID,
				--AEBI.EventID
			--FROM Event.AutomotiveEventBasedInterviews AEBI
			--INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = AEBI.CaseID
			--INNER JOIN Requirement.SelectionRequirements SR ON SC.RequirementIDPartOf = SR.RequirementID AND SelectionTypeID = (SELECT SelectionTypeID FROM Requirement.SelectionRequirements WHERE RequirementID = @SelectionRequirementID)
			--INNER JOIN Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = SR.RequirementID
			--WHERE SQ.RequirementIDPartOf = @QuestionnaireRequirementID
		--)
		--UPDATE SB
		--SET SB.DeleteSelected = 1
		--FROM Selection.Base SB
		--INNER JOIN EXSELS ON EXSELS.EventID = SB.EventID
		--AND EXSELS.PartyID = SB.PartyID
		--AND EXSELS.VehicleRoleTypeID = SB.VehicleRoleTypeID
		--AND EXSELS.VehicleID = SB.VehicleID

		-- NOW EXCLUDE PARTIES THAT HAVE BEEN CATEGORISED BY ONE OF THE PARTY TYPES WHICH HAS BEEN SET AS AN EXCLUSION
		-- PARTY TYPE CATEGORY FOR THIS QUESTIONNAIRE
		--; WITH EXPARTYTYPES (PartyID) AS (
			--SELECT PC.PartyID
			--FROM Party.PartyClassifications PC
			--INNER JOIN Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
												--AND PC.PartyTypeID = IC.PartyTypeID
			--INNER JOIN Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
			--INNER JOIN Requirement.QuestionnairePartyTypeRelationships QPTR ON PT.PartyTypeID = QPTR.PartyTypeID
			--INNER JOIN Requirement.QuestionnairePartyTypeExclusions QPTE ON QPTR.RequirementID = QPTE.RequirementID
															--AND QPTR.PartyTypeID = QPTE.PartyTypeID
															--AND QPTR.FromDate = QPTE.FromDate
			--WHERE QPTR.RequirementID = @QuestionnaireRequirementID 
		--)
		--UPDATE SB
		--SET SB.DeletePartyTypes = 1
		--FROM Selection.Base SB
		--INNER JOIN EXPARTYTYPES ON EXPARTYTYPES.PartyID = COALESCE(NULLIF(SB.OrganisationPartyID, 0), NULLIF(SB.PartyID, 0)) -- v1.4

		---- NOW CHECK EVENT NON SOLICITATIONS
		--; WITH EVENTNONSOL (EventID) AS (
			--SELECT DISTINCT EventID
			--FROM dbo.NonSolicitations ns
			--INNER JOIN Event.NonSolicitations ENS ON NS.NonSolicitationID = ENS.NonSolicitationID
		--)
		--UPDATE SB
		--SET SB.DeleteEventNonSolicitation = 1
		--FROM Selection.Base SB
		--INNER JOIN EVENTNONSOL ON EVENTNONSOL.EventID = SB.EventID
			

		---- NOW CHECK PARTIES WITH BARRED EMAILS
		--; WITH BarredEmails (PartyID) AS (
			--SELECT PCM.PartyID
			--FROM ContactMechanism.vwBlacklistedEmail BCM
			--INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
			--WHERE BCM.PreventsSelection = 1
		--)
		--UPDATE SB
		--SET SB.DeleteBarredEmail = 1
		--FROM Selection.Base SB
		--INNER JOIN BarredEmails BE ON BE.PartyID = SB.PartyID


		---- NOW CHECK FOR INVALID MODELS
		--; WITH Models (ModelID) AS (
			--SELECT DISTINCT MR.ModelID
			--FROM Requirement.RequirementRollups SM
			--INNER JOIN Requirement.ModelRequirements MR ON MR.RequirementID = SM.RequirementIDMadeUpOf
			--WHERE SM.RequirementIDPartOf = @SelectionRequirementID
		--)
		--UPDATE Selection.Base
		--SET DeleteInvalidModel = 1
		--WHERE ModelID NOT IN (SELECT ModelID FROM Models)


		-- NOW LOG THE EVENTS THAT ARE NOT ELIGIBLE FOR SELECTION
		
		IF @UpdateSelectionLogging = 1	--DO THE LOGGING
		  BEGIN
			
			UPDATE SL
			SET
				SL.RecontactPeriod = SB.DeleteRecontactPeriod,
				SL.RelativeRecontactPeriod = SB.DeleteRelativeRecontactPeriod,
				SL.CaseIDPrevious = SB.CaseIDPrevious,			
				SL.EventAlreadySelected = SB.DeleteSelected,
				SL.ExclusionListMatch = SB.DeletePartyTypes,
				SL.EventNonSolicitation = SB.DeleteEventNonSolicitation,
				SL.BarredEmailAddress = SB.DeleteBarredEmail,
				SL.WrongEventType = SB.DeleteEventType,
				SL.MissingStreet = SB.DeleteStreet,
				SL.MissingPostcode = SB.DeletePostcode,
				SL.MissingEmail = SB.DeleteEmail,
				SL.MissingTelephone = SB.DeleteTelephone,
				SL.MissingStreetAndEmail = SB.DeleteStreetOrEmail,
				SL.MissingTelephoneAndEmail = SB.DeleteTelephoneOrEmail,
				SL.MissingMobilePhone = SB.DeleteMobilePhone,					--v1.5
				SL.MissingMobilePhoneAndEmail = SB.DeleteMobilePhoneOrEmail,	--v1.5
				SL.InvalidModel = SB.DeleteInvalidModel,
				SL.MissingPartyName = SB.DeletePartyName,						--v1.8
				SL.MissingLanguage = SB.DeleteLanguage,
				SL.InternalDealer = SB.DeleteInternalDealer,					--v2.0
				SL.InvalidOwnershipCycle = SB.DeleteInvalidOwnershipCycle,		--v2.0
				SL.SampleRowProcessed = 1,
				SL.SampleRowProcessedDate = GETDATE()
			FROM Selection.Base SB
			INNER JOIN [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = SB.EventID
			WHERE SB.VehicleID = SL.MatchedODSVehicleID
			AND SB.EventID = SL.MatchedODSEventID
		END

		-- NOW DELETE THE UNSELECTABLE RECORDS
		--DELETE
		--FROM Selection.Base
		--WHERE DeleteBarredEmail = 1
		--OR DeleteEmail = 1
		--OR DeleteEventNonSolicitation = 1
		--OR DeleteEventType = 1
		--OR DeleteInvalidModel = 1
		--OR DeletePartyTypes = 1
		--OR DeletePostcode = 1
		--OR DeleteRecontactPeriod = 1
		--OR DeleteRelativeRecontactPeriod = 1
		--OR DeleteSelected = 1
		--OR DeleteStreet = 1
		--OR DeleteStreetOrEmail = 1
		--OR DeleteTelephone = 1
		--OR DeleteTelephoneOrEmail = 1
		--OR DeleteMobilePhone = 1												-- v1.5
		--OR DeleteMobilePhoneOrEmail = 1											-- v1.5
		--OR DeletePersonRequired = 1
		--OR DeleteOrganisationRequired = 1
		--OR DeletePartyName = 1
		--OR DeleteLanguage = 1													-- v1.8
		--OR DeleteInternalDealer = 1												-- v2.0		
		--OR DeleteInvalidOwnershipCycle = 1										-- v2.0		


		-- NOW SELECT THE REMAINING EVENTS
		INSERT INTO Event.vwDA_AutomotiveEventBasedInterviews
		(
			 CaseStatusTypeID
			,EventID
			,PartyID
			,VehicleRoleTypeID
			,VehicleID
			,ModelRequirementID
			,SelectionRequirementID
		)
		SELECT
			 1 AS CaseStatusTypeID
			,SB.EventID
			,SB.PartyID
			,SB.VehicleRoleTypeID
			,SB.VehicleID
			,MR.RequirementID AS ModelRequirementID
			,SR.RequirementID AS SelectionRequirementID
		FROM Selection.Base SB
		INNER JOIN Requirement.ModelRequirements MR ON MR.ModelID = SB.ModelID
		INNER JOIN Requirement.RequirementRollups MS ON MS.RequirementIDMadeUpOf = MR.RequirementID
		INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = MS.RequirementIDPartOf
		WHERE SR.RequirementID = @SelectionRequirementID


		-- NOW SET THE CaseContactMechanisms
		INSERT INTO Event.CaseContactMechanisms (CaseID, ContactMechanismID, ContactMechanismTypeID)
		SELECT X.CaseID, X.ContactMechanismID, X.ContactMechanismTypeID
		FROM (
			SELECT AEBI.CaseID, SB.PostalContactMechanismID AS ContactMechanismID, 1 AS ContactMechanismTypeID
			FROM Requirement.SelectionCases SC
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
			INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
			WHERE SC.RequirementIDPartOf = @SelectionRequirementID
			AND ISNULL(SB.PostalContactMechanismID, 0) > 0

			UNION

			SELECT AEBI.CaseID, SB.PhoneContactMechanismID AS ContactMechanismID, 2 AS ContactMechanismTypeID
			FROM Requirement.SelectionCases SC
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
			INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
			WHERE SC.RequirementIDPartOf = @SelectionRequirementID
			AND ISNULL(SB.PhoneContactMechanismID, 0) > 0

			UNION

			SELECT AEBI.CaseID, SB.LandlineContactMechanismID AS ContactMechanismID, 3 AS ContactMechanismTypeID
			FROM Requirement.SelectionCases SC
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
			INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
			WHERE SC.RequirementIDPartOf = @SelectionRequirementID
			AND ISNULL(SB.LandlineContactMechanismID, 0) > 0

			UNION

			SELECT AEBI.CaseID, SB.MobileContactMechanismID AS ContactMechanismID, 4 AS ContactMechanismTypeID
			FROM Requirement.SelectionCases SC
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
			INNER JOIN Selection.Base SB ON SB.EventID = AEBI.EventID
			WHERE SC.RequirementIDPartOf = @SelectionRequirementID
			AND ISNULL(SB.MobileContactMechanismID, 0) > 0

			UNION
			
			SELECT AEBI.CaseID, SB.EmailContactMechanismID, 6 AS ContactMechanismTypeID
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
		SET	SelectionStatusTypeID = (SELECT SelectionStatusTypeID FROM Requirement.SelectionStatusTypes WHERE SelectionStatusType = 'Selected'),
			DateLastRun = GETDATE(),
			RecordsSelected = (SELECT COUNT(CaseID) FROM Requirement.SelectionCases WHERE RequirementIDPartOf = @SelectionRequirementID)
		WHERE RequirementID = @SelectionRequirementID

		-- FINALLY MARK THE CASES IN THE SELECTION LOGGING TABLE
		
		IF @UpdateSelectionLogging = 1	--DO THE LOGGING
			BEGIN
				UPDATE SL
				SET SL.CaseID = AEBI.CaseID,
					SL.SampleRowProcessed = 1,
					SL.SampleRowProcessedDate = GETDATE(),
					SL.EventDateOutOfDate = 0    --Bug 10008
				FROM [WebsiteReporting].dbo.SampleQualityAndSelectionLogging SL
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.EventID = SL.MatchedODSEventID
				INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = AEBI.CaseID
				WHERE SC.RequirementIDPartOf = @SelectionRequirementID
				AND SL.SampleRowProcessed = 0

			END

		DROP TABLE #MAXEVENTS


		-- REJECT ANY DUPLICATE CASES
		-- TODO: ADD THIS
		--EXEC dbo.uspSELECTIONS_RejectDuplicateCases @SelectionRequirementID
		
		-- RECORD THE SELECTION IN THE WEBSITE REPORTING DATABASE
		IF @UpdateSelectionLogging = 1	--DO THE LOGGING
			BEGIN
				EXEC [WebsiteReporting].dbo.uspRecordSelection @SelectionRequirementID
				
			END
		
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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH	

