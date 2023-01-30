CREATE PROCEDURE [SelectionOutput].[uspReOutputTelephone]
@Brand [dbo].[OrganisationName], @Market [dbo].[Country], @Questionnaire [dbo].[Requirement]

AS

/*
	Purpose:	Populates the various selection output tables for use in the Selection Output package.  
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	???					Created
	1.1				20/01/2014		Chris Ross			(BUG 9500) Fix bug where even if there are no available telephone numbers the case is still reoutput
	1.2				26/01/2106		Chris Ross			BUG 12038 - Replace hardcoded OutletFuntionID statement with Event.EventTypes table lookup.
	1.3				05/09/2016		Chris Ross			BUG 12859 - Modfiy Dealer lookup to use Sales dealers for LostLeads.
	1.4				22/10/2016		Chris Ledger		BUG 13098 - Only reoutput cases since change in ContactMethodology
	1.5				23/10/2016		Chris Ledger		BUG 13098 - Update ContactMethodologyTypeID when SelectionOutputActive = 1
	1.6				09/01/2018		Eddie Thomas		BUG 14362 - Online files Re-output records to be output once a week 
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

		-- CREATE A TEMPORARY TABLE TO HOLD THE CASES WE NEED TO REOUTPUT
		CREATE TABLE #CasesToReOutput
		(
			CaseID BIGINT,
			OutcomeCode INT,
			ActionDate DATETIME2
		)


		-- GET THE CASES WE NEED TO REOUTPUT
		INSERT INTO #CasesToReOutput
		(
			CaseID,
			OutcomeCode,
			ActionDate
		)
		SELECT DISTINCT
			CCMO.CaseID,
			CCMO.OutcomeCode,
			CCMO.ActionDate
		FROM Event.CaseContactMechanismOutcomes		CCMO
		INNER JOIN SelectionOutput.ReoutputCases	REOU ON CCMO.CaseID = REOU.CaseID
		
		--INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
		--INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = CCMO.CaseID
		--LEFT JOIN Event.CaseRejections CR ON CR.CaseID = CCMO.CaseID
		--INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CCMO.CaseID
		--INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
		--INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID
		--inner join ContactMechanism.DealerCountries dc on dc.PartyIDFrom = epr.PartyID 
													  --and dc.RoleTypeIDFrom = epr.RoleTypeID -- Get Dealer country code for BMQ
		--inner join ContactMechanism.Countries c on c.CountryID = dc.CountryID -- Get the country ISO for filtering on
		--INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = CCMO.CaseID 
		--INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = SC.RequirementIDPartOf 
		--INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ 
							--ON BMQ.CountryID = dc.CountryID
							--AND BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf 
							--AND BMQ.ContactMethodologyTypeID = (SELECT ContactMethodologyTypeID FROM SelectionOutput.ContactMethodologyTypes WHERE ContactMethodologyType = 'Mixed (email & CATI)')
							--AND CCMO.ActionDate >= ISNULL(BMQ.ContactMethodologyFromDate,'2000-01-01')	-- V1.4 
		--WHERE OC.CausesReOutput = 1
		--AND CCMO.ReOutputProcessed = 0
		--AND CR.CaseID IS NULL
		--AND D.Manufacturer = @Brand
		--AND (   REPLACE(D.OutletFunction, 'Aftersales', 'Service') = @Questionnaire		-- v1.3
			 --OR (D.OutletFunction = 'Sales' AND @Questionnaire = 'LostLeads')			-- v1.3
			--)
		--AND CASE
			--WHEN C.ISOAlpha3 = 'LUX' THEN 'BEL'
			--ELSE C.ISOAlpha3
		--END = @Market
		WHERE	REOU.Brand = @Brand 
				AND REOU.Market = @Market
				AND REOU.Questionnaire = @Questionnaire
				AND REOU.ContactMethodology = 'CATI'

		-- GET THE OUTPUT INFORMATION FOR THE CASES WE NEED TO REOUTPUT
		; WITH PostalAddresses AS (
			SELECT DISTINCT
				CCM.CaseID,
				PA.Street, 
				PA.SubLocality, 
				PA.Locality, 
				PA.Town, 
				PA.PostCode,
				CT.ISOAlpha3
			FROM #CasesToReOutput C
			INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = C.CaseID
			INNER JOIN ContactMechanism.vwPostalAddresses PA ON CCM.ContactMechanismID = PA.ContactMechanismID
			INNER JOIN ContactMechanism.Countries CT ON CT.CountryID = PA.CountryID
			LEFT JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.ContactMechanismID = CCM.ContactMechanismID
			WHERE CMNS.ContactMechanismID IS NULL
		),
		Phone AS (
			SELECT DISTINCT
				CCM.CaseID,
				TN.ContactNumber
			FROM Event.CaseContactMechanisms CCM
			INNER JOIN ContactMechanism.vwTelephoneNumbers TN ON CCM.ContactMechanismID = TN.ContactMechanismID
			LEFT JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.ContactMechanismID = CCM.ContactMechanismID
			WHERE CMNS.ContactMechanismID IS NULL
			AND TN.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone')
		),
		LandLine AS (
			SELECT DISTINCT
				CCM.CaseID,
				TN.ContactNumber
			FROM Event.CaseContactMechanisms CCM
			INNER JOIN ContactMechanism.vwTelephoneNumbers TN ON CCM.ContactMechanismID = TN.ContactMechanismID
			LEFT JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.ContactMechanismID = CCM.ContactMechanismID
			WHERE CMNS.ContactMechanismID IS NULL
			AND TN.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
		),
		Mobile AS (
			SELECT DISTINCT
				CCM.CaseID,
				TN.ContactNumber
			FROM Event.CaseContactMechanisms CCM
			INNER JOIN ContactMechanism.vwTelephoneNumbers TN ON CCM.ContactMechanismID = TN.ContactMechanismID
			LEFT JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.ContactMechanismID = CCM.ContactMechanismID
			WHERE CMNS.ContactMechanismID IS NULL
			AND TN.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)')
		)
		INSERT INTO SelectionOutput.ReOutputTelephone
		(
			 VIN
			,DealerCode
			,ModelDesc
			,CoName
			,Add1
			,Add2
			,Add3
			,Add4
			,Add5
			,LandPhone
			,WorkPhone
			,MobilePhone
			,PartyID
			,CaseID
			,DateOutput
			,JLR
			,EventTypeID
			,RegNumber
			,RegDate
			,LocalName
			,BMQID
			,EventDate
			,SelectionOutputPassword
			, VariantID
			, ModelVariant

		)
		SELECT DISTINCT
			CD.VIN,
			CD.DealerCode,
			CD.ModelDescription AS ModelDesc,
			CD.OrganisationName AS CoName,
			ISNULL(PA.Street, '') AS Add1, 
			ISNULL(PA.SubLocality, '') AS Add2, 
			ISNULL(PA.Locality, '') AS Add3, 
			ISNULL(PA.Town, '') AS Add4, 
			ISNULL(PA.PostCode, '') AS Add5,
			LANDLINE.ContactNumber AS LandPhone,
			PHONE.ContactNumber AS WorkPhone,
			MOBILE.ContactNumber AS MobilePhone,
			CD.PartyID AS PartyID,
			CD.CaseID AS CaseID,
			CURRENT_TIMESTAMP AS DateOutput,
			CD.ManufacturerPartyID AS JLR,
			CD.EventTypeID AS EventTypeID,
			CD.RegistrationNumber AS RegNumber, 
			CASE
				WHEN CD.EventTypeID = 1 THEN
					CASE LEN(DAY(CD.RegistrationDate))
							WHEN 1 THEN '0' + CAST(DAY(CD.RegistrationDate) AS CHAR(1))
							ELSE CAST(DAY(CD.RegistrationDate) AS CHAR(2))
					END + '/' + 
					CASE LEN(MONTH(CD.RegistrationDate))
							WHEN 1 THEN '0' + CAST(MONTH(CD.RegistrationDate) AS CHAR(1))
							ELSE CAST(MONTH(CD.RegistrationDate) AS CHAR(2))
					END + '/' + 
					CAST(YEAR(CD.RegistrationDate) AS CHAR(4))
				ELSE
					CASE LEN(DAY(CD.EventDate))
							WHEN 1 THEN '0' + CAST(DAY(CD.EventDate) AS CHAR(1))
							ELSE CAST(DAY(CD.EventDate) AS CHAR(2))
					END + '/' + 
					CASE LEN(MONTH(CD.EventDate))
							WHEN 1 THEN '0' + CAST(MONTH(CD.EventDate) AS CHAR(1))
							ELSE CAST(MONTH(CD.EventDate) AS CHAR(2))
					END + '/' + 
					CAST(YEAR(CD.EventDate) AS CHAR(4))
			END AS RegDate,
			CD.LastName + ' ' + CD.FirstName + ' ' + CD.SecondLastName AS LocalName,
			BMQ.BMQID,
			CD.EventDate,
			EC.SelectionOutputPassword
			, CD.VariantID
			, CD.ModelVariant

		FROM #CasesToReOutput CO
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = CO.CaseID
		INNER JOIN Event.Cases EC ON EC.CaseID = CO.CaseID
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = CD.EventTypeID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.ManufacturerPartyID = CD.ManufacturerPartyID
																		AND BMQ.ISOAlpha3 = CD.CountryISOAlpha3
																		AND BMQ.Questionnaire = ET.EventCategory
		LEFT JOIN PostalAddresses PA ON PA.CaseID = CO.CaseID
		LEFT JOIN Phone ON Phone.CaseID = CO.CaseID
		LEFT JOIN LandLine ON LandLine.CaseID = CO.CaseID
		LEFT JOIN Mobile ON Mobile.CaseID = CO.CaseID
		WHERE COALESCE(Phone.CaseID, LandLine.CaseID, Mobile.CaseID) IS NOT NULL  -- v1.1



		-- write new dealer code and transferpartyid to the reoutput details table

		UPDATE ROT
			SET GDDDealerCode = D.OutletCode_GDD
			, ReportingDealerPartyID = D.TransferPartyID
		FROM SelectionOutput.ReOutputTelephone ROT
		INNER JOIN Meta.CaseDetails CD ON ROT.CaseID = CD.CaseID
		INNER JOIN Event.EventTypes et ON et.EventTypeID = CD.EventTypeID				--v1.2
									  AND et.RelatedOutletFunctionID IS NOT NULL
		INNER JOIN 
			(
				SELECT DISTINCT
					OutletPartyID
					, OutletFunctionID
					, ISNULL(OutletCode_GDD, '') OutletCode_GDD
					, TransferPartyID
				FROM dbo.DW_JLRCSPDealers
			) D
		ON CD.DealerPartyID = D.OutletPartyID
		AND et.RelatedOutletFunctionID = D.OutletFunctionID								--v1.2
		
		
		
		
		-- SET THE CASE RE-OUTPUT AS PROCESSED AND DETERMINE IF WE HAVE BEEN ABLE TO RE-OUTPUT, I.E. THE PARTY HAD A VALID POSTAL ADDRESS
		UPDATE CCMO
		SET	CCMO.ReOutputProcessed = 1,
			CCMO.ReOutputProcessDate = GETDATE(),
			CCMO.ReOutputSuccess = CASE
						WHEN ISNULL(O.CaseID, 0) <> 0 THEN 1
						ELSE 0
			END
		FROM #CasesToReOutput C
		INNER JOIN Event.CaseContactMechanismOutcomes CCMO ON CCMO.CaseID = C.CaseID
														AND C.OutcomeCode = CCMO.OutcomeCode
														AND C.ActionDate = CCMO.ActionDate
		LEFT JOIN SelectionOutput.ReOutputTelephone O ON O.CaseID = C.CaseID

		DROP TABLE #CasesToReOutput


		-- GET THE ContactMethodologyTypeID FOR THE MARKET
		DECLARE @ContactMethodologyTypeID INT

		SELECT @ContactMethodologyTypeID = BMQ.ContactMethodologyTypeID
		FROM dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ
		INNER JOIN ContactMechanism.Countries C ON C.CountryID = BMQ.CountryID
		WHERE BMQ.Brand = @Brand
		AND C.ISOAlpha3 = @Market
		AND BMQ.Questionnaire = @Questionnaire
		AND SelectionOutputActive = 1	-- V1.5
		
			
		-- SET THE ContactMethodologyTypeID VALUE IN SelectionOutput_JLR_Output SO WE CAN USE IT WHEN GENERATING THE OUTPUT FILES
		UPDATE SelectionOutput.SelectionsToOutput
		SET ContactMethodologyTypeID = @ContactMethodologyTypeID
		WHERE Brand = @Brand
		AND Market = @Market
		AND Questionnaire = @Questionnaire


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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH