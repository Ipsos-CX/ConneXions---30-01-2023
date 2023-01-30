CREATE PROCEDURE [SelectionOutput].[uspReOutputProcessing]
	@ReoutputRequested  BIT = 'false'

AS
SET NOCOUNT ON

/*
	Purpose:	Populates the various selection output tables for use in the Selection Output package.  
		
	Version			Date			Developer			Comment
	1.0				04/01/2018		Eddie Thomas		Created for BUG 14362 - Online files – Re-output records to be output once a week
	1.1				26/03/2018		Eddie Thomas		Exclude postal from new re-output process
	1.2				16/08/2018		Eddie Thomas		BUG 14797 Portugal Roadside - Contact Methodology Change request - Re-output weren't supported properly (Roadside & CRC)
	1.3				20/11/2018		Chris Ledger		Changes to speed up running
	1.4				05/02/2020		Eddie Thomas		Now using a predefined temporary table
*/



DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)




BEGIN TRY
		--PRE-DEFINED DAY FOR  RE-OUTPUTS
		DECLARE @ReoutputDay VARCHAR(10)

		SELECT		@ReoutputDay = [ReoutputDay_SelectionOutput]
		FROM		[Meta].[System]


		CREATE TABLE #BMQSampleMetadata	--1.4
		(
			ISOAlpha3					CHAR(3),
			Brand						NVARCHAR(510),
			Questionnaire				VARCHAR(255),
			CountryID					SMALLINT,
			QuestionnaireRequirementID	INT,
			ContactMethodologyTypeID	TINYINT,
			ContactMethodologyFromDate	DATETIME2(7)
		)
		INSERT #BMQSampleMetadata		--1.4
		SELECT	DISTINCT	ISOAlpha3,
							Brand,
							Questionnaire,
							CountryID,
							QuestionnaireRequirementID,
							ContactMethodologyTypeID,
							ContactMethodologyFromDate
		FROM	dbo.vwBrandMarketQuestionnaireSampleMetadata		
		WHERE	SampleFileID != 52 --< NEED TO IGNORE ADHOC STUDIES NCBS, CQI etc


		-- Set MethodologyTypeIDs
		DECLARE @CMT_MixedEmailPostal_ID INT,
				@CMT_MixedEmailSMS_ID INT,
				@CMT_MixedEmailCATI INT

		SELECT @CMT_MixedEmailPostal_ID  = ContactMethodologyTypeID FROM SelectionOutput.ContactMethodologyTypes WHERE ContactMethodologyType = 'Mixed (Email & Postal)'
		SELECT @CMT_MixedEmailSMS_ID = ContactMethodologyTypeID FROM SelectionOutput.ContactMethodologyTypes WHERE ContactMethodologyType = 'Mixed (Email & SMS)'
		SELECT @CMT_MixedEmailCATI = ContactMethodologyTypeID FROM SelectionOutput.ContactMethodologyTypes WHERE ContactMethodologyType = 'Mixed (email & CATI)'

		--CLEAR DOWN THE RE-OUTPUT
		TRUNCATE TABLE [SelectionOutput].[ReoutputCases]

		--RE-OUTPUT'S WILL ONLY HAPPEN ON A DESIGNATED DAY
		IF (DATENAME(weekday, GETDATE()) = @ReoutputDay  AND @ReoutputRequested='true')
		BEGIN
				--v1.2
				CREATE TABLE #Dealers
				(	OutletPartyID INT NOT NULL,
					OutletFunctionID INT NOT NULL,
					CountryID INT NOT NULL
				)
				
				INSERT #Dealers
				SELECT	OutletPartyID, OutletFunctionID, CountryID
				FROM	Sample.dbo.DW_JLRCSPDealers d
				INNER JOIN ContactMechanism.DealerCountries dc ON D.OutletPartyID = dc.PartyIDFrom

				UNION

				SELECT	PartyIDFrom, (SELECT RoleTypeID FROM [dbo].[RoleTypes] WHERE RoleType = 'CRC Centre') AS OutletFunctionID, CountryID
				FROM	[Party].[CRCNetworks]

				UNION

				SELECT	PartyIDFrom, (SELECT RoleTypeID FROM [dbo].[RoleTypes] WHERE RoleType = 'Roadside Assistance Network') AS OutletFunctionID, CountryID
				FROM	[Party].[RoadsideNetworks]
				--v1.2

		 
				-- GET THE CASES WE NEED TO REOUTPUT
				INSERT INTO [SelectionOutput].[ReoutputCases]
				(
					CaseID,
					Brand,
					Market,
					Questionnaire,
					ContactMethodology
				)
		
				--EMAIL RE-OUTPUT
				SELECT DISTINCT
					CCMO.CaseID,
					--CCMO.OutcomeCode,
					--CCMO.ActionDate
					BMQ.Brand,
					BMQ.ISOAlpha3,
					BMQ.Questionnaire,
					'Email' AS ContactMethodology
				FROM Event.CaseContactMechanismOutcomes CCMO
				INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
														  AND  OC.CausesReOutput = 1
				INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = CCMO.CaseID
				LEFT JOIN Event.CaseRejections CR ON CR.CaseID = CCMO.CaseID
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CCMO.CaseID

				INNER JOIN Event.CaseOutput CO ON AEBI.CaseID = CO.CaseID
				INNER JOIN Event.CaseOutputTypes T ON CO.CaseOutputTypeID = T.CaseOutputTypeID
															AND T.CaseOutputType IN ('CATI', 'SMS')
													
				INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
				--INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID
				INNER JOIN #Dealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID		--v1.2
				--INNER JOIN ContactMechanism.DealerCountries dc on dc.PartyIDFrom = epr.PartyID 
				--											  and dc.RoleTypeIDFrom = epr.RoleTypeID -- Get Dealer country code for BMQ
				--INNER JOIN ContactMechanism.Countries c on c.CountryID = dc.CountryID -- Get the country ISO for filtering on
				INNER JOIN ContactMechanism.Countries c on c.CountryID = d.CountryID -- Get the country ISO for filtering on --v1.2
				INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = CCMO.CaseID 
				INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = SC.RequirementIDPartOf 
				INNER JOIN #BMQSampleMetadata BMQ 
								    --ON BMQ.CountryID = dc.CountryID
									ON BMQ.CountryID = d.CountryID		--v1.2
									AND BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf 
									AND BMQ.ContactMethodologyTypeID IN (SELECT CAST(ContactMethodologyTypeID AS INT)	-- V1.3 
																		 FROM SelectionOutput.ContactMethodologyTypes 
																		 WHERE ContactMethodologyType IN ('Mixed (SMS & Email)', 'Mixed (CATI & Email)'))
									AND CCMO.ActionDate >= ISNULL(BMQ.ContactMethodologyFromDate,'2000-01-01')
				WHERE	CCMO.ReOutputProcessed = 0	
						AND CR.CaseID IS NULL		
		
				--UNION
				----POSTAL RE-OUTPUT
				--SELECT DISTINCT
				--	CCMO.CaseID,
				--	BMQ.Brand,
				--	BMQ.ISOAlpha3,
				--	BMQ.Questionnaire,
				--	'Postal' AS ContactMethodology
				--FROM Event.CaseContactMechanismOutcomes CCMO
				--INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
				--											AND OC.CausesReOutput = 1
				--INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = CCMO.CaseID
				--LEFT JOIN Event.CaseRejections CR ON CR.CaseID = CCMO.CaseID
				--INNER JOIN ContactMechanism.PostalAddresses PA ON  CCM.ContactMechanismID = PA.ContactMechanismID
				--INNER JOIN Requirement.SelectionCases sc on sc.CaseID = CCMO.CaseID 
				--INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = SC.RequirementIDPartOf 
				--INNER JOIN #BMQSampleMetadata BMQ 
				--					ON BMQ.CountryID = PA.CountryID
				--					AND BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf
				--					AND BMQ.ContactMethodologyTypeID = @CMT_MixedEmailPostal_ID 
				--					AND CCMO.ActionDate >= ISNULL(BMQ.ContactMethodologyFromDate,'2000-01-01')
				--INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CCMO.CaseID
				--WHERE CCMO.ReOutputProcessed = 0
				--AND CR.CaseID IS NULL

				UNION

				--SMS RE-OUTPUT
				SELECT DISTINCT
					CCMO.CaseID,
					BMQ.Brand,
					BMQ.ISOAlpha3,
					BMQ.Questionnaire,
					'SMS' AS ContactMethodology
				FROM Event.CaseContactMechanismOutcomes CCMO
				INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
				INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = CCMO.CaseID
				LEFT JOIN Event.CaseRejections CR ON CR.CaseID = CCMO.CaseID
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CCMO.CaseID
				INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
				INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID
				inner join ContactMechanism.DealerCountries dc on dc.PartyIDFrom = epr.PartyID 
															  and dc.RoleTypeIDFrom = epr.RoleTypeID -- Get Dealer country code for BMQ
				inner join ContactMechanism.Countries c on c.CountryID = dc.CountryID -- Get the country ISO for filtering on
				INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = CCMO.CaseID 
				INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = SC.RequirementIDPartOf 
				INNER JOIN #BMQSampleMetadata BMQ 
									ON BMQ.CountryID = dc.CountryID
									AND BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf 
									AND BMQ.ContactMethodologyTypeID = @CMT_MixedEmailSMS_ID	 -- V1.3
									AND CCMO.ActionDate >= ISNULL(BMQ.ContactMethodologyFromDate,'2000-01-01')
						
				WHERE	OC.CausesReOutput = 1
						AND CCMO.ReOutputProcessed = 0
						AND CR.CaseID IS NULL

				UNION 
		
				--TELEPHONE RE-OUTPUT
				SELECT DISTINCT
					CCMO.CaseID,
					BMQ.Brand,
					BMQ.ISOAlpha3,
					BMQ.Questionnaire,
					'CATI' AS ContactMethodology
				FROM Event.CaseContactMechanismOutcomes CCMO
				INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
				INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = CCMO.CaseID
				LEFT JOIN Event.CaseRejections CR ON CR.CaseID = CCMO.CaseID
				INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CCMO.CaseID
				INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
				INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID
				inner join ContactMechanism.DealerCountries dc on dc.PartyIDFrom = epr.PartyID 
															  and dc.RoleTypeIDFrom = epr.RoleTypeID -- Get Dealer country code for BMQ
				inner join ContactMechanism.Countries c on c.CountryID = dc.CountryID -- Get the country ISO for filtering on
				INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = CCMO.CaseID 
				INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = SC.RequirementIDPartOf 
				INNER JOIN #BMQSampleMetadata BMQ 
									ON BMQ.CountryID = dc.CountryID
									AND BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf 
									AND BMQ.ContactMethodologyTypeID = @CMT_MixedEmailCATI  -- V1.3
									AND CCMO.ActionDate >= ISNULL(BMQ.ContactMethodologyFromDate,'2000-01-01')
				WHERE OC.CausesReOutput = 1
				AND CCMO.ReOutputProcessed = 0
				AND CR.CaseID IS NULL
		END
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