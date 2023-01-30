CREATE PROCEDURE [Selection].[uspRunSelectionChinaPreLoaded]
AS
/*
	Purpose: Creates cases and Selection Requirements for China sample data supplied with responses.
		
	Version			Date			Developer			Comment
	1.0				27-07-2015		Chris Ross			Created
	1.1				28-09-2016		Chris Ross			13072 - Pre-authorise the Selection on creation
	1.2				22-03-2016		Chris Ledger		Bug 13657 - Fix bug in COALESCE of MatchedODSPersonID and MatchedOrganisationID 
	1.3				16-05-2017		Eddie Thomas		Bug 13682 - China Roadside with responses
	1.4				16-03-2018		Eddie Thomas		Bug 14557 - Adding CRC with responses support
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

		------------------------------------------------------------------------------------
		-- Create table to hold all records we are going to create cases for
		------------------------------------------------------------------------------------
		-- DROP TABLE #SelectionBase
		CREATE TABLE #SelectionBase	
			(
				AuditItemID				bigint,
				CaseID					bigint,
				EventID					bigint,
				PartyID					bigint,
				VehicleID				bigint,
				VehicleRoleTypeID			int,
				ManufacturerPartyID			int,
				PostalContactMechanismID	bigint,
				EmailContactMechanismID		bigint,
				PhoneContactMechanismID		bigint,
				LandlineContactMechanismID	bigint,
				MobileContactMechanismID	bigint,
				QuestionnaireRequirementID  bigint
			)

		------------------------------------------------------------------------------------
		-- NOW GET THE EVENT DETAILS FOR THE CASES
		------------------------------------------------------------------------------------
		INSERT INTO #SelectionBase	
		(
			AuditItemID	,
			CaseID		,
			EventID		,
			PartyID		,
			VehicleID,
			VehicleRoleTypeID,
			ManufacturerPartyID,
			PostalContactMechanismID	,
			EmailContactMechanismID		,
			PhoneContactMechanismID		,	
			LandlineContactMechanismID	,
			MobileContactMechanismID,
			QuestionnaireRequirementID
		)
		SELECT 
			L.AuditItemID,
			NULL AS CaseID,
			L.MatchedODSEventID,
			COALESCE(NULLIF(L.MatchedODSPersonID,0), NULLIF(L.MatchedODSOrganisationID,0), L.MatchedODSPartyID) AS PartyID,		-- V1.2
			L.MatchedODSVehicleID,
			0 AS VehicleRoleType,
			L.ManufacturerID,
			L.MatchedODSAddressID,
			L.MatchedODSEmailAddressID,
			L.MatchedODSPrivTelID ,	
			COALESCE(L.MatchedODSTelID, L.[MatchedODSBusTelID] ) AS LandlineContactMechanismID	,
			COALESCE(L.MatchedODSMobileTelID, L.MatchedODSPrivMobileTelID) AS MobileContactMechanismID,
			L.QuestionnaireRequirementID
		FROM Sample_ETL.China.Sales_WithResponses R
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging L ON L.AuditItemID = R.AuditItemID 
		WHERE R.CaseID IS NULL
		UNION 
		SELECT 
			L.AuditItemID,
			NULL AS CaseID,
			L.MatchedODSEventID,
			COALESCE(NULLIF(L.MatchedODSPersonID,0), NULLIF(L.MatchedODSOrganisationID,0), L.MatchedODSPartyID) AS PartyID,		-- V1.2
			L.MatchedODSVehicleID,
			0 AS VehicleRoleType,
			L.ManufacturerID,
			L.MatchedODSAddressID,
			L.MatchedODSEmailAddressID,
			L.MatchedODSPrivTelID ,	
			COALESCE(L.MatchedODSTelID, L.[MatchedODSBusTelID] ) AS LandlineContactMechanismID	,
			COALESCE(L.MatchedODSMobileTelID, L.MatchedODSPrivMobileTelID) AS MobileContactMechanismID,
			L.QuestionnaireRequirementID
		FROM Sample_ETL.China.Service_WithResponses R
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging L ON L.AuditItemID = R.AuditItemID 
		WHERE R.CaseID IS NULL
		--ROADSIDE
		UNION 
		SELECT 
			L.AuditItemID,
			NULL AS CaseID,
			L.MatchedODSEventID,
			COALESCE(NULLIF(L.MatchedODSPersonID,0), NULLIF(L.MatchedODSOrganisationID,0), L.MatchedODSPartyID) AS PartyID,
			L.MatchedODSVehicleID,
			0 AS VehicleRoleType,
			L.ManufacturerID,
			L.MatchedODSAddressID,
			L.MatchedODSEmailAddressID,
			L.MatchedODSPrivTelID ,	
			COALESCE(L.MatchedODSTelID, L.[MatchedODSBusTelID] ) AS LandlineContactMechanismID	,
			COALESCE(L.MatchedODSMobileTelID, L.MatchedODSPrivMobileTelID) AS MobileContactMechanismID,
			L.QuestionnaireRequirementID
		FROM Sample_ETL.China.Roadside_WithResponses R
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging L ON L.AuditItemID = R.AuditItemID 
		WHERE R.CaseID IS NULL
		--CRC
		UNION 
		SELECT 
			L.AuditItemID,
			NULL AS CaseID,
			L.MatchedODSEventID,
			COALESCE(NULLIF(L.MatchedODSPersonID,0), NULLIF(L.MatchedODSOrganisationID,0), L.MatchedODSPartyID) AS PartyID,
			L.MatchedODSVehicleID,
			0 AS VehicleRoleType,
			L.ManufacturerID,
			L.MatchedODSAddressID,
			L.MatchedODSEmailAddressID,
			L.MatchedODSPrivTelID ,	
			COALESCE(L.MatchedODSTelID, L.[MatchedODSBusTelID] ) AS LandlineContactMechanismID	,
			COALESCE(L.MatchedODSMobileTelID, L.MatchedODSPrivMobileTelID) AS MobileContactMechanismID,
			L.QuestionnaireRequirementID
		FROM Sample_ETL.China.CRC_WithResponses R
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging L ON L.AuditItemID = R.AuditItemID 
		WHERE R.CaseID IS NULL


		------------------------------------------------------------------------------------
		-- UPDATE THE VehicleRoleTypeID
		------------------------------------------------------------------------------------
		;WITH CTE_VehicleRoleTypes
		AS (
			SELECT sb.EventID, MIN(v.VehicleRoleTypeID) AS VehicleRoleTypeID
			from #SelectionBase sb
			INNER JOIN vehicle.VehiclePartyRoleEvents v ON v.EventID = sb.EventID
			GROUP BY sb.EventID
		)
		UPDATE sb 
		SET sb.VehicleRoleTypeId = v.VehicleRoleTypeID
		from #SelectionBase sb
		INNER JOIN CTE_VehicleRoleTypes v ON v.EventID = sb.EventID
			
		

		------------------------------------------------------------------------------------
		-- ADD IN EMAIL ContactMechanismID if one is not present
		------------------------------------------------------------------------------------
		
		DECLARE @DummyEmail bigint
		SELECT @DummyEmail = ContactMechanismID FROM contactmechanism.emailaddresses
		WHERE emailaddress = 'Unknown Email Address'

		
		UPDATE SB
		SET SB.EmailContactMechanismID = @DummyEmail
		FROM #SelectionBase SB
		WHERE SB.EmailContactMechanismID IS NULL

	

		------------------------------------------------------------------------------------
		-- Create selection requirements to add the cases to
		------------------------------------------------------------------------------------
		
		-- CREATE A TABLE TO HOLD ALL THE SELECTIONS WE NEED TO GENERATE
		CREATE TABLE #Selections
		(
			ManufacturerPartyID INT,
			QuestionnaireRequirementID INT,
			SelectionName VARCHAR(255),
			SelectionRequirementID INT
		)

	
		-- GENERATE A DATE STAMP STRING (INCLUDING TIME - In case the process is run more than once on the same day)
		DECLARE @DateStamp VARCHAR(20)
		DECLARE @TimeStr VARCHAR(10)

		SELECT @TimeStr = CONVERT(VARCHAR(8), GETDATE(),  108)
		SELECT @DateStamp = CONVERT(VARCHAR(8), GETDATE(),  112) + '_' + SUBSTRING(@TimeStr, 1, 2) + SUBSTRING(@TimeStr, 4, 2) 

		
		-- GET THE SELECTIONS WE NEED TO GENERATE
		;WITH CTE_Requirements
		AS (
			SELECT DISTINCT sb.ManufacturerPartyID, 
							sb.QuestionnaireRequirementID
			FROM #SelectionBase sb 
		)		
		INSERT INTO #Selections (ManufacturerPartyID, QuestionnaireRequirementID, SelectionName)
		SELECT  r.ManufacturerPartyID, 
				r.QuestionnaireRequirementID,
				bmq.SelectionName + '_' + @DateStamp
		FROM CTE_Requirements r
		INNER JOIN [dbo].[vwBrandMarketQuestionnaireSampleMetadata] bmq ON bmq.QuestionnaireRequirementID = r.QuestionnaireRequirementID
		

		-- GENERATE THE SelectionRequirement records  
        INSERT  INTO Requirement.Requirements
                ( Requirement ,
                    RequirementTypeID
                )
        SELECT  SelectionName ,
                3 AS RequirementTypeID
        FROM    #Selections
     
		
		-- UPDATE Selections tmp table with RequirementIDs
		UPDATE s
		SET s.SelectionRequirementID = r.RequirementID
		FROM #Selections s
		INNER JOIN Requirement.Requirements r ON r.Requirement = s.SelectionName


		-- ADD A NEW ROW TO SelectionRequirements
        DECLARE @Date DATE
		SELECT @Date = CONVERT(DATE, GETDATE()) 
		INSERT  INTO Requirement.SelectionRequirements
                ( RequirementID ,
                    SelectionDate ,
                    SelectionStatusTypeID ,
                    SelectionTypeID ,
                    ScheduledRunDate,
					DateLastRun,
					DateOutputAuthorised
                )
        SELECT  SelectionRequirementID,
                @Date AS SelectionDate ,
                ( SELECT    SelectionStatusTypeID
           			FROM      Requirement.SelectionStatusTypes
                    WHERE     SelectionStatusType = 'Authorised'		-- v1.1
                ) AS SelectionStatusTypeID ,
                1 AS SelectionTypeID ,
                @Date AS ScheduledRunDate,
				@Date AS DateLastRun,
				GETDATE() AS DateOutputAuthorised						-- v1.1
		FROM #Selections
				
				

		-- ADD THE ROLLUP FROM THE QUESTIONNAIRE TO THE SELECTION
        INSERT  INTO Requirement.RequirementRollups
                ( RequirementIDMadeUpOf ,
                    RequirementIDPartOf ,
                    FromDate
                )
        SELECT  SelectionRequirementID ,
                QuestionnaireRequirementID ,
                @Date
		FROM #Selections

		
		---------------------------------------------
		-- UPDATE Totals in The SelectionRequirements
		---------------------------------------------
		;WITH CTE_SelReqCases
		AS (
			SELECT s.SelectionRequirementID, COUNT(*) AS TotalCases
			FROM #SelectionBase sb 
			INNER JOIN #Selections s ON s.QuestionnaireRequirementID = sb.QuestionnaireRequirementID
			GROUP BY s.SelectionRequirementID
		)
		UPDATE sr
		SET sr.RecordsSelected = TotalCases,
			sr.RecordsRejected = 0 
		FROM CTE_SelReqCases rc
		INNER JOIN Requirement.SelectionRequirements sr ON sr.RequirementID = rc.SelectionRequirementID 



		------------------------------------------------------------------------------------
		-- NOW CREATE THE CASES
		------------------------------------------------------------------------------------
	
		;WITH CTE_ModelRequirements		--- Get the first instance of each vehicle in the model requirements table
		AS (
			select ModelID, MIN(mr.RequirementID) AS RequirementID 
			from Requirement.ModelRequirements mr 
			GROUP BY ModelID
		)
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
			,S.SelectionRequirementID 
			FROM #SelectionBase SB
			INNER JOIN #Selections S ON S.QuestionnaireRequirementID = SB.QuestionnaireRequirementID
			INNER JOIN Vehicle.Vehicles v On v.VehicleID = sb.VehicleID
			INNER JOIN CTE_ModelRequirements mr ON mr.modelID = v.ModelID


		-- UPDATE THE Selection Base table with the CASE IDs just generated
		UPDATE sb
		SET sb.CaseID = sc.CaseID
		FROM #SelectionBase sb 
		INNER JOIN #Selections s ON s.QuestionnaireRequirementID = sb.QuestionnaireRequirementID
		INNER JOIN Event.AutomotiveEventBasedinterviews AEBI ON AEBI.EventID = sb.EventID
		INNER JOIN Requirement.SelectionCases sc ON sc.CaseID = AEBI.CaseID 
												AND sc.RequirementIDPartOf = s.SelectionRequirementID

		
		-- Check that a CaseID has been created for every single Event we are processing - IF NOT RAISE ERROR and roll everything back
		IF  EXISTS (SELECT * FROM #SelectionBase  WHERE CaseID IS NULL)
			RAISERROR ('Not all Cases generated for Events', -- Message text.
               16, -- Severity.
               1 -- State.
               );


		-- NOW SET THE CaseContactMechanisms
		INSERT INTO Event.CaseContactMechanisms (CaseID, ContactMechanismID, ContactMechanismTypeID)
		SELECT X.CaseID, X.ContactMechanismID, X.ContactMechanismTypeID
		FROM (
			SELECT SB.CaseID, SB.PostalContactMechanismID AS ContactMechanismID, 1 AS ContactMechanismTypeID
			FROM #SelectionBase SB
			WHERE SB.PostalContactMechanismID IS NOT NULL

			UNION

			SELECT SB.CaseID, SB.PhoneContactMechanismID AS ContactMechanismID, 2 AS ContactMechanismTypeID
			FROM #SelectionBase SB
			WHERE SB.PhoneContactMechanismID IS NOT NULL

			UNION

			SELECT SB.CaseID, SB.LandlineContactMechanismID AS ContactMechanismID, 3 AS ContactMechanismTypeID
			FROM #SelectionBase SB
			WHERE SB.LandlineContactMechanismID IS NOT NULL

			UNION

			SELECT SB.CaseID, SB.MobileContactMechanismID AS ContactMechanismID, 4 AS ContactMechanismTypeID
			FROM #SelectionBase SB
			WHERE SB.MobileContactMechanismID IS NOT NULL

			UNION
			
			SELECT SB.CaseID, SB.EmailContactMechanismID, 6 AS ContactMechanismTypeID
			FROM #SelectionBase SB
			WHERE SB.EmailContactMechanismID IS NOT NULL
		) X
		LEFT JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = X.CaseID
											AND CCM.ContactMechanismID = X.ContactMechanismID
											AND CCM.ContactMechanismTypeID = X.ContactMechanismTypeID
		WHERE CCM.CaseID IS NULL



		------------------------------------------------------------------------------------
		-- Update the CASEID, ProcessedDate and ensure none of the non-selection values are set
		------------------------------------------------------------------------------------
		UPDATE SL
		SET
			SL.RecontactPeriod = 0,
			SL.RelativeRecontactPeriod = 0,
			SL.CaseIDPrevious = NULL,
			SL.EventAlreadySelected = 0,
			SL.ExclusionListMatch = 0,
			SL.EventNonSolicitation = 0,
			SL.BarredEmailAddress = 0,
			SL.WrongEventType = 0,
			SL.MissingStreet = 0,
			SL.MissingPostcode = 0,
			SL.MissingEmail = 0,
			SL.MissingTelephone = 0,
			SL.MissingStreetAndEmail = 0,
			SL.MissingTelephoneAndEmail =0,
			SL.MissingMobilePhone = 0,
			SL.MissingMobilePhoneAndEmail = 0,
			SL.InvalidModel = 0,
			SL.MissingPartyName = 0,
			SL.MissingLanguage = 0,
			SL.InternalDealer =0,
			SL.InvalidOwnershipCycle = 0,
			SL.CaseID = SB.CaseID,
			SL.SampleRowProcessed = 1,
			SL.SampleRowProcessedDate = GETDATE()
		--SELECT * 
		FROM #SelectionBase SB
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = SB.AuditItemID



		------------------------------------------------------------------------------------
		-- UPDATE THE CaseID DATA IN China With Response Permanent Staging tables
		------------------------------------------------------------------------------------
		
		-- Sales --		
		UPDATE R 
		SET R.CaseID = SB.CaseID
		FROM #SelectionBase SB
		INNER JOIN Sample_ETL.China.Sales_WithResponses R ON R.AuditItemID = SB.AuditItemID

		-- Service --
		UPDATE R 
		SET R.CaseID = SB.CaseID
		FROM #SelectionBase SB
		INNER JOIN Sample_ETL.China.Service_WithResponses R ON R.AuditItemID = SB.AuditItemID

		-- Roadside -- 1.3
		UPDATE R 
		SET R.CaseID = SB.CaseID
		FROM #SelectionBase SB
		INNER JOIN Sample_ETL.China.Roadside_WithResponses R ON R.AuditItemID = SB.AuditItemID

		-- CRC -- 1.4
		UPDATE R 
		SET R.CaseID		= SB.CaseID,
			R.ODSEventID	= SB.EventID
		FROM #SelectionBase SB
		INNER JOIN Sample_ETL.China.CRC_WithResponses R ON R.AuditItemID = SB.AuditItemID
	
		
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

