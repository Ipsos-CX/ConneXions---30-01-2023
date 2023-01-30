CREATE PROCEDURE InternalUpdate.uspReissueInvite_Insert
AS

/*
	Purpose:	To create new invites (CaseIDs) from the original Case data. Also requires 
				that a new pre-authorised selection is created for it to output automatically 
				as part of the selection output routines.
	
	Version			Date			Developer			Comment
	1.0				15/05/2013		ChrisRoss			Original version
	1.1				28/06/2013		Chris Ross			BUG 9134: Add in Reoutput Y/N functionality
	1.2				16/12/2013		Chris Ross			BUG 9814: Fixed issue with primary key violation on previously rejected cases being processed.
	1.3				12/10/2017		Eddie Thomas		BUG 14337 : Updated re-invite file processing
	1.4				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
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
	

		-- V1.3 BUG 14337 : ADD THE EVENT CATEGORY
		UPDATE		RI
		SET			EventCategoryID										= ET.EventCategoryID
		FROM		InternalUpdate.ReissueInvite						RI
		INNER JOIN [$(SampleDB)].[Event].[AutomotiveEventBasedInterviews]	AEBI	ON RI.CaseID = AEBI.CaseID
		INNER JOIN [$(SampleDB)].[Event].[Events]							EV		ON AEBI.EventID = EV.EventID
		INNER JOIN [$(SampleDB)].[Event].[vwEventTypes]						ET		ON EV.EventTypeID = ET.EventTypeID

	
		-- Check the CaseID and PartyID combination is valid
		UPDATE RI
		SET RI.CasePartyCombinationValid = 1
		FROM InternalUpdate.ReissueInvite RI
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI 
						ON AEBI.CaseID = RI.CaseID
						AND AEBI.PartyID = RI.PartyID


		------------------------------------------------------------------------------------------------------------
		-- First get the relevant information for the original cases to create the selections and new cases
		------------------------------------------------------------------------------------------------------------

		-- drop table #NewInvites 
		create table #NewInvites 
			(
				ID	INT IDENTITY(1,1) NOT NULL,
				AuditItemID					bigint, 
				PartyID						bigint,
				Reoutput					varchar(10),
				OrigCaseID					bigint,
				NewCaseID					bigint,
				ManufacturerPartyID			bigint,
				QuestionnaireRequirementID	bigint,
				SelectionName				VARCHAR(255),
				NewSelectionRequirementID	bigint
			)

		;WITH CTE_ReqSelName (QuestionnaireRequirementID, SelectionName) AS 
		(
			select distinct QuestionnaireRequirementID, SelectionName  
			from [$(SampleDB)].dbo.BrandMarketQuestionnaireSampleMetadata
			WHERE CreateSelection = 1
		)
		INSERT INTO #NewInvites (AuditItemID, PartyID, Reoutput, OrigCaseID, NewCaseID, ManufacturerPartyID, QuestionnaireRequirementID,
								SelectionName, NewSelectionRequirementID)
		SELECT  RI.AuditItemID, 
				RI.PartyID,
				Reoutput,
				RI.CaseID	as OrigCaseID,
				NULL		as NewCaseID, 
				QR.ManufacturerPartyID,
				QR.RequirementID,
				SelectionName + 
					(CASE WHEN SUBSTRING(LTRIM(Reoutput),1,1) = 'Y'
						  THEN '_InviteReissues' 
						  ELSE '_InviteReissues_NON_OUTPUT' END)
					as SelectionName ,
				NULL		as NewSelectionRequirement
		from InternalUpdate.ReissueInvite  RI
		INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC on SC.CaseID = RI.CaseID
		INNER JOIN [$(SampleDB)].Requirement.RequirementRollups rr on rr.RequirementIDMadeUpOf = SC.RequirementIDPartOf 
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR on QR.RequirementID = rr.RequirementIDPartOf 
		INNER JOIN CTE_ReqSelName rqs on rqs.QuestionnaireRequirementID = rr.RequirementIDPartOf 

		--
		LEFT JOIN [$(SampleDB)].META.PartyBestPostalAddresses			PBPA ON RI.PartyID = PBPA.PartyID
		LEFT JOIN [$(SampleDB)].Meta.PartyBestEmailAddresses				PBEA ON RI.PartyID = PBEA.PartyID
		LEFT JOIN [$(SampleDB)].Meta.PartyBestTelephoneNumbers			PBTN ON RI.PartyID = PBTN.PartyID
		
		LEFT JOIN [$(SampleDB)].Meta.PartyBestEmailAddressesAFRL			AFRL ON RI.PartyID = AFRL.PartyID AND RI.EventCategoryID = AFRL.EventCategoryID
		LEFT JOIN [$(SampleDB)].Meta.PartyBestEmailAddressesLatestOnly	PBEL ON RI.PartyID = PBEL.PartyID AND RI.EventCategoryID = PBEL.EventCategoryID
		

		WHERE	(RI.AuditItemID = RI.ParentAuditItemID ) AND 
				(RI.CasePartyCombinationValid = 1) AND
				---- V1.3 BUG 14337 : WE'RE USING THE LASTEST INFORMATION FOR THE PARTY; ONLY RE-OUTPUT IF THE PARTY HAS USABLE CONTACT DETAILS
				COALESCE (NULLIF(PBPA.ContactMechanismID,0), NULLIF(PBEA.ContactMechanismID,0), NULLIF(PBTN.PhoneID,0),  NULLIF(PBTN.LandlineID,0) , NULLIF(PBTN.MobileID,0) , NULLIF(AFRL.ContactMechanismID,0),  NULLIF(PBEL.ContactMechanismID,0),0) >0 






		------------------------------------------------------------------------------------------------------------
		-- Create the new selection requirements 
		------------------------------------------------------------------------------------------------------------

		-- GENERATE A DATE STAMP STRING
			DECLARE @DateStamp VARCHAR(8)
			DECLARE @Today DATETIME2

			SELECT @Today = GETDATE()

			SELECT @DateStamp = CAST(YEAR(@Today) AS CHAR(4))

			SELECT @DateStamp = @DateStamp + CASE WHEN LEN(CAST(MONTH(@Today) AS VARCHAR(2))) = 1 THEN '0' + CAST(MONTH(@Today) AS CHAR(1)) ELSE CAST(MONTH(@Today) AS CHAR(2)) END

			SELECT @DateStamp = @DateStamp + CASE WHEN LEN(CAST(DAY(@Today) AS VARCHAR(2))) = 1 THEN '0' + CAST(DAY(@Today) AS CHAR(1)) ELSE CAST(DAY(@Today) AS CHAR(2)) END

			
			-- CREATE A TABLE TO HOLD ALL THE SELECTIONS WE NEED TO GENERATE
			CREATE TABLE #Selections
			(
				ID INT IDENTITY(1,1) NOT NULL,
				ManufacturerPartyID INT,
				QuestionnaireRequirementID INT,
				SelectionName VARCHAR(255),
				NewSelectionRequirenmentID BIGINT,
				Reoutput varchar(10)
			)

			-- GET THE SELECTIONS WE NEED TO GENERATE
			INSERT INTO #Selections (ManufacturerPartyID, QuestionnaireRequirementID, SelectionName, Reoutput)
			SELECT DISTINCT 
					ManufacturerPartyID, 
					QuestionnaireRequirementID, 
					SelectionName,
					Reoutput
			FROM #NewInvites 
			
			-- LOOP THROUGH EACH OF THE SELECTIONS AND GENERATE IT
			DECLARE @ManufacturerPartyID INT
			DECLARE @QuestionnaireRequirementID INT
			DECLARE @SelectionName VARCHAR(255)
			DECLARE @SelectionRequirementID BIGINT

			DECLARE @MAXID INT
			SELECT @MAXID = MAX(ID) FROM #Selections

			DECLARE @Counter INT
			SET @Counter = 1

			WHILE @Counter <= @MAXID
			BEGIN

				-- GET THE VALUES FROM #Selections
				SELECT  @ManufacturerPartyID = ManufacturerPartyID,
						@QuestionnaireRequirementID = QuestionnaireRequirementID,
						@SelectionName = @DateStamp + '_' + SelectionName
				FROM #Selections WHERE ID = @Counter
				
				-- GENERATE THE SELECTION
				EXEC [$(SampleDB)].Selection.uspCreateSelectionRequirement @ManufacturerPartyID, @QuestionnaireRequirementID, @SelectionName, @DateStamp, 1

				-- Get the Selection RequirementID just created and populate #Selections table
				UPDATE S
				SET NewSelectionRequirenmentID = R.RequirementID 
				from #Selections S
				INNER JOIN [$(SampleDB)].Requirement.RequirementRollups RR ON RR.RequirementIDPartOf = S.QuestionnaireRequirementID 
				inner join [$(SampleDB)].Requirement.Requirements R on R.RequirementID = RR.RequirementIDMadeUpOf 
				WHERE R.Requirement = (@DateStamp + '_' + SelectionName)

				-- INCREMENT THE COUNTER
				SET @Counter += 1
						
			END


		-- Put the new SelectionRequirementIDs into the #NewInvites table ---------

		UPDATE NI 
		SET NI.NewSelectionRequirementID = S.NewSelectionRequirenmentID 
		from #Selections S 
		inner join #NewInvites NI on NI.QuestionnaireRequirementID = S.QuestionnaireRequirementID 
								and NI.Reoutput = S.Reoutput 



		------------------------------------------------------------------------------------------------------------
		-- Update the new selection requirements with the counts and correct status,etc for outputting
		------------------------------------------------------------------------------------------------------------

		;WITH CTE_CaseCounts (NewSelectionRequirementID, Reoutput, CaseCount)  AS 
		(
			select S.NewSelectionRequirenmentID, s.Reoutput , COUNT(*) AS CaseCount
			from #Selections S 
			inner join #NewInvites NI on NI.QuestionnaireRequirementID = S.QuestionnaireRequirementID 
									 and NI.Reoutput = S.Reoutput
			group by S.NewSelectionRequirenmentID , s.Reoutput
		)
		UPDATE sr
		SET sr.DateOutputAuthorised = GETDATE(),
			sr.DateLastRun			= GETDATE(),
			sr.SelectionStatusTypeID = (select SelectionStatusTypeID from [$(SampleDB)].Requirement.SelectionStatusTypes 
											where SelectionStatusType = CASE WHEN SUBSTRING(LTRIM(Reoutput),1,1) = 'Y' 
																			THEN 'Authorised'
																			ELSE 'Outputted' END),
			sr.RecordsSelected = CaseCount 
		from CTE_CaseCounts CC
		INNER JOIN [$(SampleDB)].Requirement.SelectionRequirements sr 
							ON sr.RequirementID = cc.NewSelectionRequirementID 



		------------------------------------------------------------------------------------------------------------
		-- Create the new cases 
		------------------------------------------------------------------------------------------------------------

		INSERT INTO [$(SampleDB)].Event.vwDA_AutomotiveEventBasedInterviews
			(
				 CaseStatusTypeID
				,EventID
				,PartyID
				,VehicleRoleTypeID
				,VehicleID
				,ModelRequirementID
				,SelectionRequirementID
			)
		SELECT	 1 AS CaseStatusTypeID
				,aebi.EventID
				,aebi.PartyID
				,aebi.VehicleRoleTypeID
				,aebi.VehicleID
				,SC.RequirementIDMadeUpOf AS ModelRequirementID
				,ni.NewSelectionRequirementID AS SelectionRequirementID	
		from #NewInvites ni 
		inner join [$(SampleDB)].event.AutomotiveEventBasedInterviews aebi on aebi.CaseID = ni.OrigCaseID 
		inner join [$(SampleDB)].Requirement.SelectionCases sc on sc.CaseID = aebi.CaseID   -- For ModelRequirementID


		-- Get the IDs of the Cases just created -----------------

		UPDATE ni
		SET ni.NewCaseID = aebi2.CaseID 
		from #NewInvites ni
		inner join [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi on aebi.CaseID = ni.OrigCaseID 
		inner join [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi2 on aebi2.EventID = aebi.EventID 
																	and aebi2.PartyID = aebi.PartyID 
																	and aebi2.VehicleID = aebi.VehicleID 
																	and aebi2.CaseID <> aebi.CaseID 
		inner join [$(SampleDB)].Requirement.SelectionCases sc on sc.CaseID = aebi2.CaseID   -- For SelectionRequirementID
														and sc.RequirementIDPartOf = ni.NewSelectionRequirementID 


		
		-- V1.37 BUG 14337 : USING THE MOST RECENT CONTACT MECHANISM'S <--- THIS WILL ONLY WORK IF META TABLES BEEN REBUILT SINCE CUSTOMER UPDATES HAVE BEEN APPLIED
		--INSERT EMAIL 
		INSERT INTO [$(SampleDB)].Event.CaseContactMechanisms (CaseID, ContactMechanismID, ContactMechanismTypeID)
		SELECT		DISTINCT ni.NewCaseID, 
					COALESCE (NULLIF(PBEA.ContactMechanismID,0),  NULLIF(PBEL.ContactMechanismID,0),  NULLIF(AFRL.ContactMechanismID,0),0) AS ContactMechanismID, 
					(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID
		FROM		#NewInvites										ni
		INNER JOIN	InternalUpdate.ReissueInvite					ri ON ni.PartyID = ri.PartyID
		LEFT JOIN	[$(SampleDB)].Meta.PartyBestEmailAddresses			PBEA ON ni.PartyID = PBEA.PartyID		
		LEFT JOIN	[$(SampleDB)].Meta.PartyBestEmailAddressesAFRL		AFRL ON ni.PartyID = AFRL.PartyID				AND ri.EventCategoryID = AFRL.EventCategoryID
		LEFT JOIN	[$(SampleDB)].Meta.PartyBestEmailAddressesLatestOnly	PBEL ON ni.PartyID = PBEL.PartyID 	AND ri.EventCategoryID = PBEL.EventCategoryID 
		WHERE		COALESCE (NULLIF(PBEA.ContactMechanismID,0),  NULLIF(PBEL.ContactMechanismID,0),  NULLIF(AFRL.ContactMechanismID,0),0) >0  

		
		--INSERT POSTAL
		INSERT INTO [$(SampleDB)].Event.CaseContactMechanisms (CaseID, ContactMechanismID, ContactMechanismTypeID)
		SELECT		DISTINCT ni.NewCaseID, 
					PBEA.ContactMechanismID, 
					(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Postal Address') AS ContactMechanismTypeID
		FROM		#NewInvites										ni
		INNER JOIN	[$(SampleDB)].META.PartyBestPostalAddresses			PBEA ON ni.PartyID = PBEA.PartyID		



		--INSERT TELEPHONE NUMBERS
		;WITH Party_TelNoCTE (partyid, ContactMechanismID, TelephoneType, ContactMechanismTypeID)
		AS
		(

			SELECT unpvt.partyid, ContactMechanismID, TelephoneType, CMT.ContactMechanismTypeID
			FROM [$(SampleDB)].Meta.PartyBestTelephoneNumbers
			UNPIVOT (
				ContactMechanismID FOR TelephoneType IN (
					PhoneID, LandlineID, MobileID
				)
			) unpvt
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CASE unpvt.TelephoneType 
																				WHEN 'PhoneID' THEN 'Phone'
																				WHEN 'LandlineID' THEN 'Phone (landline)'
																				WHEN 'MobileID' THEN 'Phone (mobile)'
																			END = CMT.ContactMechanismType
																			
			INNER JOIN #NewInvites ni		ON 	unpvt.partyid = ni.PartyID												
		)
		INSERT INTO [$(SampleDB)].Event.CaseContactMechanisms (CaseID, ContactMechanismID, ContactMechanismTypeID)
		
		SELECT		DISTINCT ni.NewCaseID, 
					PBTN.ContactMechanismID,
					PBTN.ContactMechanismTypeID
		FROM		#NewInvites				ni
		INNER JOIN	Party_TelNoCTE			PBTN ON ni.PartyID = PBTN.PartyID
		





		--------------------------------------------------------------------------------------------------
		---- Cancel the Orginal Case
		--------------------------------------------------------------------------------------------------

		-- Add to the case rejections table
		INSERT INTO [$(SampleDB)].Event.CaseRejections
		(
			 CaseID
			,FromDate
		)
		SELECT
			OrigCaseID,
			getdate()
		FROM #NewInvites
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].Event.CaseRejections WHERE CaseID = OrigCaseID)  -- v1.2

		-- Update Case records with rejection 
		UPDATE CD
		SET CD.CaseStatusTypeID = (SELECT CaseStatusTypeID FROM [$(SampleDB)].Event.CaseStatusTypes WHERE CaseStatusType = 'Invite Reissued')
		FROM #NewInvites NI
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CaseID = NI.OrigCaseID 
		
		-- Update the case meta data table
		UPDATE	CD
		SET		 CaseRejection = 1
				,CaseStatusTypeID = ( SELECT CaseStatusTypeID from [$(SampleDB)].Event.CaseStatusTypes WHERE CaseStatusType = 'Invite Reissued' )
		FROM	#NewInvites NI
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CaseID = NI.OrigCaseID 
	
		-- NOW WRITE THE VALUES INTO THE CASE REJECTION AUDIT TABLE
		INSERT INTO [$(AuditDB)].Audit.CaseRejections
		(
			 AuditItemID
			,CaseID
			,FromDate
			,Rejection
		)
		SELECT
			 AuditItemID
			,OrigCaseID
			,getdate() as FromDate
			,1 AS Rejection
		FROM #NewInvites



		--------------------------------------------------------------------------------------------------
		---- UPDATE the Sample Logging with the new CaseID
		--------------------------------------------------------------------------------------------------
		
		UPDATE SL
		SET SL.CaseID = NI.NewCaseID,
			SL.SampleRowProcessedDate = GETDATE()
		-- select * 
		FROM #NewInvites NI
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = NI.NewCaseID 
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = AEBI.EventID 
		



		--------------------------------------------------------------------------------------------------
		---- UPDATE the Internal Updates table for transfer to Audit 
		--------------------------------------------------------------------------------------------------


		UPDATE RI
		SET RI.NewCaseID = NI.NewCaseID,
			RI.NewSelectionRequirementID = NI.NewSelectionRequirementID
		from #NewInvites NI 
		inner join InternalUpdate.ReissueInvite RI on RI.AuditItemID = NI.AuditItemID 


	
	

	COMMIT TRAN

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












