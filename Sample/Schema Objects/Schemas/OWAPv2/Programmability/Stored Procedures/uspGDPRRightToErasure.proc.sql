
CREATE PROCEDURE OWAPv2.uspGDPRRightToErasure

	@PartyID				 BIGINT, 
	@FullErase				 CHAR(1), 
	@RequestedBy			 VARCHAR(100), 
	@ErasureValidated		 BIT OUTPUT,  
	@ValidationFailureReason VARCHAR(255) OUTPUT

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
	Purpose:	Sets the GDPR "Right of Erasure" non-solicitation on the PartyID and blanks 
				all the customer related information in line with GDPR requirements.  
				Where the customer does not want to be contacted in future we must retain 
				a certain amount of the information to ensure that we can match against the 
				customer again to determine they are not to be contacted.  This is what the 
				"FullErase" parameter is for.
		
	Version			Date			Developer			Comment
	1.0				16-04-2018		Chris Ross			BUG 14399 - Original version.
	1.1				01-04-2019		Chris Ledger		Change reference to [LostLeads].[ModelVehicleMatchStrings] 
	1.2				21-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
	1.3				21-06-2021		Ben King			TASK 510 - Update GDPR to incorporate new survey, General Enquiries.
*/


	------------------------------------------------------------------------
	-- Check params populated correctly
	------------------------------------------------------------------------

	SET @ErasureValidated = 0
	
		
	IF	@PartyID		IS NULL
	BEGIN
		SET @ValidationFailureReason = '@PartyID parameter has not been supplied'
		RETURN 0
	END 

	IF	@FullErase		IS NULL
	BEGIN
		SET @ValidationFailureReason = '@FullErase parameter has not been supplied'
		RETURN 0
	END 

	IF	@RequestedBy	IS NULL
	BEGIN
		SET @ValidationFailureReason = '@RequestedBy parameter has not been supplied'
		RETURN 0
	END 


	IF	0 = (SELECT COUNT(*) FROM Party.People WHERE PartyID = @PartyID)
	BEGIN
		SET @ValidationFailureReason = 'The supplied PartyID is not found in the People table.'
		RETURN 0
	END 


	IF @FullErase NOT IN ('Y', 'N')
	BEGIN
		SET @ValidationFailureReason = '@FullErase must be a value of "Y" or "N".'
		RETURN 0
	END 




	------------------------------------------------------------------------
	-- Check PartyID not part of a merge.
	------------------------------------------------------------------------


	IF 1 = (SELECT CASE WHEN MergedDate IS NULL THEN 0 ELSE 1 END AS Merged FROM Party.People WHERE PartyID = @PartyID)
	BEGIN
		SET @ValidationFailureReason = 'This party is part of a merge.  Please unmerge first and address underlying PartyIDs individually.'
		RETURN 0
	END 


	

	------------------------------------------------------------------------
	-- Check PartyID not already erased (or fully erased)
	------------------------------------------------------------------------


	IF 0 < (SELECT COUNT(*) FROM [$(AuditDB)].GDPR.ErasureRequests WHERE PartyID = @PartyID AND FullErasure = 'Y')
	BEGIN
		SET @ValidationFailureReason = 'This party has already been fully erased.'
		RETURN 0
	END 


	IF 0 < (SELECT COUNT(*) FROM [$(AuditDB)].GDPR.ErasureRequests WHERE PartyID = @PartyID AND FullErasure = 'N' AND @FullErase = 'N')
	BEGIN
		SET @ValidationFailureReason = 'This party has already been partially erased.'
		RETURN 0
	END 



	------------------------------------------------------------------------
	-- Set then check system variables
	------------------------------------------------------------------------

		DECLARE @DummyEmailID BIGINT, 
				@DummyPhoneID BIGINT, 
				@DummyPostalID BIGINT, 
				@DummyJagVehicleID BIGINT,
				@DummyLRVehicleID BIGINT,
				@DummyJagModelID INT,
				@DummyLRModelID INT,
				@DummyOrganisationID BIGINT,
				@DummyCountryID INT
	
		SELECT	@DummyEmailID = sv.DummyEmailID ,
				@DummyPhoneID = sv.DummyPhoneID ,
				@DummyPostalID = sv.DummyPostalID ,
				@DummyJagVehicleID = sv.DummyJagVehicleID,
				@DummyLRVehicleID = sv.DummyLRVehicleID,
				@DummyJagModelID = m1.ModelID,
				@DummyLRModelID = m2.ModelID,
				@DummyOrganisationID = sv.DummyOrganisationID
		FROM GDPR.SystemValues sv
		LEFT JOIN Vehicle.Vehicles v1 ON v1.VehicleID = sv.DummyJagVehicleID
		LEFT JOIN Vehicle.Models m1 ON m1.ModelID = v1.ModelID
		LEFT JOIN Vehicle.Vehicles v2 ON v2.VehicleID = sv.DummyLRVehicleID
		LEFT JOIN Vehicle.Models m2 ON m2.ModelID = v2.ModelID

		SELECT @DummyCountryID = CountryID FROM ContactMechanism.Countries WHERE Country = 'GDPR Erased' 

		DECLARE @RemovalText  VARCHAR(20)
		SET @RemovalText = '[GDPR - Erased]'

		-- Check all present 
		IF  @DummyEmailID IS NULL OR
			@DummyPhoneID IS NULL OR
			@DummyPostalID IS NULL OR
			@DummyJagVehicleID Is NULL OR
			@DummyLRVehicleID Is NULL OR
			@DummyJagModelID Is NULL OR
			@DummyLRModelID Is NULL OR
			@DummyCountryID IS NULL 
	BEGIN
		SET @ValidationFailureReason = 'System variables not configuring correctly.  Please contact the Connexions team.'
		RETURN 0
	END 		


	SET @ErasureValidated = 1



	------------------------------------------------------------------------
	-- Create temp table to hold counts of tables that have been blanked
	------------------------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#ErasedRecordCounts') IS NOT NULL
	DROP TABLE #ErasedRecordCounts

	CREATE TABLE #ErasedRecordCounts
		(
			ID				INT IDENTITY(1,1) NOT NULL,
			TableName		VARCHAR(255),
			UpdateType		VARCHAR(50),
			RecordCount		INT
		)




	------------------------------------------------------------------------
	------------------------------------------------------------------------
	-- Save the file names and row numbers that are associated with this 
	-- PartyID  (including Selection Output files) so that the users can 
	-- replace the originating file rows with "[GDPR - Erased]" 
	-- 
	-- Note: we will also use the auditItemIDs saved here to remove many 
	--       of the file entries later on.
	------------------------------------------------------------------------
	------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#OriginatingDataRows') IS NOT NULL
	DROP TABLE #OriginatingDataRows

	CREATE TABLE #OriginatingDataRows
	(
		ID							INT IDENTITY(1,1) NOT NULL,
		OriginatingAuditID			BIGINT			NOT NULL,
		FileName					VARCHAR(100)	NOT NULL, 
		ActionDate					DATETIME2		NULL, 
		PhysicalRow					INT				NOT NULL, 
		OriginatingAuditItemID		BIGINT			NOT NULL,
		FileType					VARCHAR(50)		NOT NULL
	)


	INSERT INTO #OriginatingDataRows (OriginatingAuditID		,
									FileName				,
									ActionDate			,
									PhysicalRow			,
									OriginatingAuditItemID	,
									FileType			
									)
	
	-- NOTE: getting from both Audit.People AND Audit.VehiclePartyRoleEvents ensures all Sample originated AuditItemIDs are found.
	SELECT  f.AuditID,
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'Sample' AS FileType
	FROM [$(AuditDB)].Audit.People ap
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = ap.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = ap.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE ap.PartyID = @PartyID

	UNION
	
	SELECT  f.AuditID,
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'Sample' AS FileType
	FROM [$(AuditDB)].Audit.vehiclePartyRoleEvents avpre				
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = avpre.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = avpre.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE avpre.PartyID = @PartyID

	UNION
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'Customer Update - Email' AS FileType
	FROM [$(AuditDB)].Audit.CustomerUpdate_EmailAddress cea
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = cea.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = cea.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE cea.PartyID = @PartyID

	UNION
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'Customer Update - PostalAddress' AS FileType 
	FROM [$(AuditDB)].Audit.CustomerUpdate_PostalAddress cpa
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = cpa.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = cpa.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE cpa.PartyId = @PartyID
	
	UNION
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID, 
			'Customer Update - TelephoneNumber' AS FileType 
	FROM [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber ctn
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = ctn.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = ctn.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE ctn.PartyID = @PartyID

	UNION
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'Customer Update - Organisation' AS FileType 
	FROM [$(AuditDB)].Audit.CustomerUpdate_Organisation co
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = co.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = co.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE co.PartyID = @PartyID

	UNION
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'Customer Update - Person' AS FileType 
	FROM [$(AuditDB)].Audit.CustomerUpdate_Person cpu
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = cpu.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = cpu.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE cpu.PartyID = @PartyID

	UNION
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'Customer Update - RegistrationNumber' AS FileType
	FROM [$(AuditDB)].Audit.CustomerUpdate_RegistrationNumber crn
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = crn.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = crn.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE crn.PartyID = @PartyID

	UNION	
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			fr.PhysicalRow, 
			ai.AuditItemID,
			'AFRL Update File' AS FileType
	FROM [$(AuditDB)].Audit.VehiclePartyRoleEventsAFRL crn
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = crn.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = crn.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE crn.PartyID = @PartyID

	UNION
	
	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			0 AS PhysicalRow, 
			ai.AuditItemID,
			'Selection Output' AS FileType
	FROM [$(AuditDB)].Audit.SelectionOutput so
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = so.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.FileRows fr ON fr.AuditItemID = so.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE so.PartyID = @PartyID

	UNION

	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			0 AS PhysicalRow,		--- There are no associated dbo.Filerow entries for these records
			ai.AuditItemID,
			'LandRover Brazil Sales Customer - Legacy' AS FileType
	FROM [$(AuditDB)].Audit.People ap
	INNER JOIN [$(AuditDB)].Audit.CustomerRelationships acr on acr.AuditItemID = ap.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.LandRover_Brazil_Sales_Customer lbc ON lbc.CustomerID = acr.CustomerIdentifier
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai_p ON ai_p.AuditItemID = ap.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f_p ON f_p.AuditID = ai_p.AuditID  and f_p.Filename like 'LandRover_Brazil_Sales%'
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = lbc.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID
	WHERE ap.partyid = @PartyID	

	UNION

	SELECT  f.AuditID, 
			f.FileName, 
			f.ActionDate, 
			0 AS PhysicalRow,		--- There are no associated dbo.Filerow entries for these records
			bcon.AuditItemID,
			'LandRover Brazil Sales Contract - Legacy' AS FileType
	FROM [$(AuditDB)].Audit.People ap
	INNER JOIN [$(AuditDB)].Audit.CustomerRelationships acr on acr.AuditItemID = ap.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.LandRover_Brazil_Sales_Customer lbc ON lbc.CustomerID = acr.CustomerIdentifier
	INNER JOIN [$(AuditDB)].Audit.Landrover_Brazil_Sales_Matching bm ON bm.CustomerAuditItemID = lbc.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.LandRover_Brazil_Sales_Contract bcon ON bcon.AuditItemId = bm.ContractAuditItemId 
	INNER JOIN [$(AuditDB)].dbo.AuditItems ai_p ON ai_p.AuditItemID = ap.AuditItemID
	INNER JOIN [$(AuditDB)].dbo.Files f_p ON f_p.AuditID = ai_p.AuditID  and f_p.filename like 'LandRover_Brazil_Sales%'
	INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = bm.ContractAuditID
	WHERE ap.partyid = @PartyID


	


	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-- Find associated EventIDs and determine whether they have more than one party
	-- linked to them and whether the Org has been provided independently.
	-- This table is used to determine what records to remove or update further on.
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	
		-- Find all associated Events for the PartyID
		IF OBJECT_ID('tempdb..#Events') IS NOT NULL
		DROP TABLE #Events

		CREATE TABLE #Events
			(
				PartyID					BIGINT,
				EventID					BIGINT,
				MultiPersonEvent		BIT,
				PrimaryVehiclePartyRoleEventID	BIGINT			-- used to ensure a single vehicle record still linked to the Event
			)

		INSERT INTO #Events (PartyID, EventID, MultiPersonEvent)
		SELECT	DISTINCT
				vpre.PartyID, 
				vpre.EventID,
				0 AS MultiPersonEvent
		FROM Vehicle.VehiclePartyRoleEvents vpre 
		WHERE vpre.PartyID = @PartyID


		-- Determine the primary VehiclePartyRoleEventID
		;WITH CTE_PrimaryVehiclePartyRoleEventID
		AS (
			SELECT e.EventID, e.PartyID, vpre.VehiclePartyRoleEventID, 
					ROW_NUMBER() OVER(PARTITION BY e.EventID, e.PartyID ORDER BY VehicleRoleTypeID) AS RowID
			FROM #Events e
			INNER JOIN Vehicle.VehiclePartyRoleEvents vpre ON vpre.EventID = e.EventID 
														  AND vpre.PartyID = e.PartyID
		)
		UPDATE e
		SET e.PrimaryVehiclePartyRoleEventID = cte.VehiclePartyRoleEventID
		FROM CTE_PrimaryVehiclePartyRoleEventID cte
		INNER JOIN #Events e ON e.EventID = cte.EventID 
							AND e.PartyID = cte.PartyID
		WHERE cte.RowID = 1
		
		
		
		-- Find any linked Organisations for the events -------------------------------
		IF OBJECT_ID('tempdb..#LinkedOrgs') IS NOT NULL
		DROP TABLE #LinkedOrgs

		CREATE TABLE #LinkedOrgs
			(
				PartyID			BIGINT, 
				EventID			BIGINT, 
				OrgPartyID		BIGINT,
				ReceivedIndependently BIT
			)

		INSERT INTO #LinkedOrgs (PartyID, EventID, OrgPartyID, ReceivedIndependently)
		SELECT e.PartyID, 
				e.EventID, 
				ao.PartyID AS OrgPartyID, 
				0 AS ReceivedIndependently
		FROM #Events e
		INNER JOIN [$(AuditDB)].Audit.Events ae ON ae.EventID = e.EventID
		INNER JOIN [$(AuditDB)].Audit.Organisations ao ON ao.AuditItemID = ae.AuditItemID
		UNION
		SELECT e.PartyID, e.EventID, cuo.OrganisationPartyID AS OrgPartyID, 0 AS ReceivedIndependently
		FROM #Events e
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Organisation cuo ON cuo.PartyID = e.PartyID


		-- Now check if the Org's PartyId was received independently of the Party/Events we are removing
		UPDATE lo
		SET  ReceivedIndependently = CASE WHEN ap.AuditItemID IS NULL THEN 1 ELSE 0 END
		FROM #LinkedOrgs lo
		INNER JOIN [$(AuditDB)].Audit.Organisations ao ON ao.PartyID = lo.OrgPartyID
		INNER JOIN [$(AuditDB)].Audit.Events ae ON ae.AuditItemID = ao.AuditItemID AND ae.EventID <> lo.EventID
		LEFT JOIN [$(AuditDB)].Audit.People ap ON ap.AuditItemID = ae.AuditItemID 
												AND ap.PartyID = lo.PartyID
  

		-- Determine if Event has other partyIDs linked to it (which are NOT linked orgs)
		UPDATE e
		SET MultiPersonEvent = 1
		FROM #Events e
		WHERE EXISTS (SELECT vpre.VehicleID 
						FROM Vehicle.VehiclePartyRoleEvents vpre 
						WHERE vpre.EventID = e.EventID 
							AND vpre.PartyID <> e.PartyID 
							AND vpre.PartyID NOT IN (SELECT OrgPartyID FROM #LinkedOrgs)
						)




	BEGIN TRAN ----------------------------------------------------------------------------------------------------------------------------------


	IF @FullErase = 'Y'		-- If fully erasing then no requirement to keep contact details for matching purposes
	BEGIN 


		------------------------------------------------------------------------
		--
		-- Erase the person details
		--
		------------------------------------------------------------------------
		
		UPDATE p
		SET p.TitleID = 0,
			p.Initials = @RemovalText, 
			p.FirstName = @RemovalText, 
			p.MiddleName = @RemovalText, 
			p.LastName = @RemovalText, 
			p.SecondLastName = @RemovalText, 
			p.GenderID = 0, 
			p.BirthDate = '1900-01-01', 
			p.MonthAndYearOfBirth = NULL
		FROM Party.People p 
		WHERE p.PartyID = @PartyID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Party.People', 'Erase details', @@RowCount)




		------------------------------------------------------------------------------------------------------------
		-- Blank Usable Customer Identifiers (Non-usable are removed outside of this conditional section)
		------------------------------------------------------------------------------------------------------------

		-- First get the primary usable customer identifiers	
		IF OBJECT_ID('tempdb..#PrimaryCustomerIdentifiers') IS NOT NULL
		DROP TABLE #PrimaryCustomerIdentifiers

		CREATE TABLE #PrimaryCustomerIdentifiers
			(
				PartyIDFrom			BIGINT, 
				PartyIDTo			BIGINT, 
				RoleTypeIDFrom		BIGINT, 
				RoleTypeIDTo		BIGINT, 
				CustomerIdentifier	NVARCHAR(60)
			)

		;WITH CTE_CustomerIDsOrdered
		AS (
			SELECT	Row_Number() OVER(PARTITION BY PartyIDFrom, PartyIDTo, RoleTypeIDFrom, RoleTypeIDTo ORDER BY CustomerIdentifier) AS RowID,
					PartyIDFrom, PartyIDTo, RoleTypeIDFrom, RoleTypeIDTo, CustomerIdentifier
			FROM Party.CustomerRelationships cr
			WHERE cr.PartyIDFrom = @PartyID
			AND CustomerIdentifierUsable = 1
			)
		INSERT INTO #PrimaryCustomerIdentifiers (PartyIDFrom, PartyIDTo, RoleTypeIDFrom, RoleTypeIDTo, CustomerIdentifier)
		SELECT PartyIDFrom, PartyIDTo, RoleTypeIDFrom, RoleTypeIDTo, CustomerIdentifier 
		FROM CTE_CustomerIDsOrdered
		WHERE RowID = 1


		--- Then blank the Primary Usable CustomerIdentifiers 
		-----------------------------------------------------
		UPDATE cr
		SET CustomerIdentifier = @RemovalText, 
			CustomerIdentifierUsable = 0 -- set unusable
		FROM #PrimaryCustomerIdentifiers ci
		INNER JOIN Party.CustomerRelationships cr ON cr.PartyIDFrom		   = ci.PartyIDFrom
												 AND cr.PartyIDTo		   = ci.PartyIDTo
												 AND cr.RoleTypeIDFrom	   = ci.RoleTypeIDFrom
												 AND cr.RoleTypeIDTo	   = ci.RoleTypeIDTo
												 AND cr.CustomerIdentifier = ci.CustomerIdentifier
		
		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Party.CustomerRelationships', 'Erase Primary Usable Customer IDs', @@RowCount)


		--- Now remove the NON-primary Usable CustomerIdentifiers 
		---------------------------------------------------------
		DELETE cr
		FROM Party.CustomerRelationships cr 
		WHERE cr.PartyIDFrom = @PartyID
		AND cr.CustomerIdentifierUsable = 1
		AND  NOT EXISTS (SELECT ci.PartyIDFrom FROM #PrimaryCustomerIdentifiers ci
			 			  WHERE cr.PartyIDFrom			= ci.PartyIDFrom
						    AND cr.PartyIDTo			= ci.PartyIDTo
						    AND cr.RoleTypeIDFrom		= ci.RoleTypeIDFrom
						    AND cr.RoleTypeIDTo			= ci.RoleTypeIDTo
						    AND cr.CustomerIdentifier	= ci.CustomerIdentifier)

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Party.CustomerRelationships', 'Delete NON-Primary Usable CustomerID Records', @@RowCount)





		------------------------------------------------------------------------
		-- Erase or Unlink the following tables...
		--
		-- ContactMechanism.EmailAddresses
		-- ContactMechanism.PostalAddresses
		-- ContactMechanism.TelephoneNumbers
		------------------------------------------------------------------------


			-- Find all associated ContactMechanisms for PartyID
			IF OBJECT_ID('tempdb..#ContactMechanisms') IS NOT NULL
			DROP TABLE #ContactMechanisms

			CREATE TABLE #ContactMechanisms
				(
					PartyID					BIGINT,
					ContactMechanismID		BIGINT,
					ContactMechanismType	VARCHAR(10),
					MultiLinked				BIT,
					MultiLinkRowID			INT
				)

			INSERT INTO #ContactMechanisms (PartyID, ContactMechanismID, ContactMechanismType, MultiLinked)
			SELECT	pcm.PartyID, 
					pcm.ContactMechanismID,
					CASE WHEN ea.ContactMechanismID IS NOT NULL THEN 'Email' 
						 WHEN pa.ContactMechanismID IS NOT NULL THEN 'Postal'
						 WHEN tn.ContactMechanismID IS NOT NULL THEN 'Phone'
						 END AS ContactMechanismType,
					0 AS MultiLinked
			FROM ContactMechanism.PartyContactMechanisms pcm 
			LEFT JOIN ContactMechanism.EmailAddresses ea ON ea.ContactMechanismId = pcm.contactmechanismID 
			LEFT JOIN ContactMechanism.PostalAddresses pa ON pa.ContactMechanismId = pcm.contactmechanismID 
			LEFT JOIN ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismId = pcm.contactmechanismID 
			WHERE pcm.PartyID = @PartyID


			-- Now set variable to indicate whether other parties linked to the same contact mechanisms
			UPDATE cmt
			SET MultiLinked = 1
			FROM #ContactMechanisms cmt
			WHERE EXISTS (SELECT pcm.ContactMechanismID 
							FROM ContactMechanism.PartyContactMechanisms pcm 
							WHERE pcm.ContactMechanismID = cmt.ContactMechanismID 
							  AND pcm.PartyID <> cmt.PartyID )



			-- Set the primary row ID for later processing
			;WITH CTE_MultiRowIDs
			AS (
				SELECT	ROW_NUMBER() OVER(PARTITION BY ContactMechanismType ORDER BY ContactMechanismID DESC) AS RowID,
						PartyID,
						ContactMechanismID,
						ContactMechanismType
				FROM #ContactMechanisms cmt
				WHERE cmt.MultiLinked = 1
		
			)
			UPDATE cmt
			SET MultiLinkRowID = mri.RowID
			FROM CTE_MultiRowIDs mri
			INNER JOIN #ContactMechanisms cmt ON mri.ContactMechanismID = cmt.ContactMechanismID 
											 AND mri.PartyID = cmt.PartyID


			
			------------------------------------------------------
			-- Update the NON-multi-linked ContactMechanisms
			------------------------------------------------------

			-- Erase Email Address 
			---------------------------------
			UPDATE ea
			SET EmailAddress = @RemovalText
			FROM #ContactMechanisms cmt
			INNER JOIN ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = cmt.ContactMechanismID 
			WHERE cmt.MultiLinked = 0
			AND cmt.ContactMechanismType = 'Email'
	
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('ContactMechanism.EmailAddresses', 'Erase details', @@RowCount)



			-- Erase Telephone Numbers
			---------------------------------
			UPDATE tn
			SET ContactNumber = @RemovalText
			FROM #ContactMechanisms cmt
			INNER JOIN ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismID = cmt.ContactMechanismID 
			WHERE cmt.MultiLinked = 0
			AND cmt.ContactMechanismType = 'Phone'

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('ContactMechanism.TelephoneNumbers', 'Erase details', @@RowCount)

	
			
			-- Erase Postal Addresses
			---------------------------------
			UPDATE pa 
			SET BuildingName = @RemovalText, 
				SubStreetNumber = @RemovalText, 
				SubStreet = @RemovalText, 
				StreetNumber = @RemovalText, 
				Street = @RemovalText, 
				SubLocality = @RemovalText, 
				Locality = @RemovalText, 
				Town = @RemovalText, 
				Region = @RemovalText, 
				PostCode = @RemovalText, 
				CountryID = @DummyCountryID
			FROM #ContactMechanisms cmt
			INNER JOIN ContactMechanism.PostalAddresses pa ON pa.ContactMechanismID = cmt.ContactMechanismID 
			WHERE cmt.MultiLinked = 0
			AND cmt.ContactMechanismType = 'Postal'

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('ContactMechanism.PostalAddresses', 'Erase details', @@RowCount)

	

			-----------------------------------------------------------------------
			-- Update MULTI-LINKED ContactMechanisms with Dummy ContactMechanismIDs
			-----------------------------------------------------------------------
	
			-- First delete the purposes records as not required
			DELETE pcm
			FROM #ContactMechanisms cmt
			INNER JOIN ContactMechanism.PartyContactMechanismPurposes pcm 
							ON  pcm.ContactMechanismID = cmt.ContactMechanismID 
							AND pcm.PartyID = cmt.PartyID
			WHERE cmt.MultiLinked = 1
	
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('ContactMechanism.PartyContactMechanismPurposes', 'Delete Record', @@RowCount)

	
			-- Then update the primary row of each type of the mutli-linnked PartyContactMechanism 
			-- as we cannot update more than one of each type due to constraints on dupe
			-- Email/Phone/Address being attached to a single partyID in this table.
			----------------------------------------------------------------------------------------
			UPDATE pcm
			SET ContactMechanismID =   CASE WHEN cmt.ContactMechanismType = 'Email'  THEN @DummyEmailID
											WHEN cmt.ContactMechanismType = 'Phone'  THEN @DummyPhoneID
											WHEN cmt.ContactMechanismType = 'Postal' THEN @DummyPostalID
											ELSE 0
										END 
			FROM #ContactMechanisms cmt
			INNER JOIN ContactMechanism.PartyContactMechanisms pcm 
							ON  pcm.ContactMechanismID = cmt.ContactMechanismID 
							AND pcm.PartyID = cmt.PartyID
			WHERE cmt.MultiLinked = 1
			AND cmt.MultiLinkRowID = 1
	
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('ContactMechanism.PartyContactMechanisms', 'Unlink', @@RowCount)

	
			-- Delete the remaining Multi-linked PartyContactMechanisms
			----------------------------------------------------------------------------------------
			DELETE pcm 
			FROM #ContactMechanisms cmt
			INNER JOIN ContactMechanism.PartyContactMechanisms pcm 
							ON  pcm.ContactMechanismID = cmt.ContactMechanismID 
							AND pcm.PartyID = cmt.PartyID
			WHERE cmt.MultiLinked = 1
			AND cmt.MultiLinkRowID <> 1

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('ContactMechanism.PartyContactMechanisms', 'Delete records', @@RowCount)



			------------------------------------------------------
			-- Update the ContactMechanismIDs on the Audit Records
			------------------------------------------------------
			
			-- Get the primary audit record per contact mechanism type
			----------------------------------------------------------
			
			-- Find all associated ContactMechanisms for PartyID
			IF OBJECT_ID('tempdb..#AuditPrimaryPartyContactMechanisms') IS NOT NULL
			DROP TABLE #AuditPrimaryPartyContactMechanisms

			CREATE TABLE #AuditPrimaryPartyContactMechanisms
				(
					AuditItemID				BIGINT,
					PartyID					BIGINT,
					ContactMechanismID		BIGINT,
					ContactMechanismType	VARCHAR(10)
				)

			;WITH CTE_AllAuditsWithType
			AS (
				SELECT	apcm.AuditItemID,
						apcm.PartyID, 
						apcm.ContactMechanismID,
						CASE WHEN ea.ContactMechanismID IS NOT NULL THEN 'Email' 
							 WHEN pa.ContactMechanismID IS NOT NULL THEN 'Postal'
							 WHEN tn.ContactMechanismID IS NOT NULL THEN 'Phone'
							 END AS ContactMechanismType
				FROM [$(AuditDB)].Audit.PartyContactMechanisms apcm 
				LEFT JOIN ContactMechanism.EmailAddresses ea ON ea.ContactMechanismId = apcm.contactmechanismID 
				LEFT JOIN ContactMechanism.PostalAddresses pa ON pa.ContactMechanismId = apcm.contactmechanismID 
				LEFT JOIN ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismId = apcm.contactmechanismID 
				WHERE apcm.PartyID = @PartyID
			)
			, 
			CTE_AuditsWithRowIDs
			AS (
				SELECT ROW_NUMBER() OVER(PARTITION BY AuditItemID, PartyID, ContactMechanismType ORDER BY ContactMechanismID) AS RowID,
						AuditItemID, PartyID, ContactMechanismID, ContactMechanismType
				FROM CTE_AllAuditsWithType
			)
			INSERT INTO #AuditPrimaryPartyContactMechanisms (AuditItemID, PartyID, ContactMechanismID, ContactMechanismType)
			SELECT AuditItemID, PartyID, ContactMechanismID, ContactMechanismType
			FROM CTE_AuditsWithRowIDs
			WHERE RowID = 1
			

			-- Delete the non-primary records
			---------------------------------
			DELETE apcm 
			FROM [$(AuditDB)].Audit.PartyContactMechanisms apcm 
			WHERE apcm.AuditItemID IN (SELECT DISTINCT AuditItemID FROM #AuditPrimaryPartyContactMechanisms)
			AND NOT EXISTS (SELECT ppcm.PartyID FROM #AuditPrimaryPartyContactMechanisms ppcm
												WHERE ppcm.AuditItemID			= apcm.AuditItemID 
												  AND ppcm.PartyID				= apcm.PartyID
												  AND ppcm.ContactMechanismID	= apcm.ContactMechanismID )

			
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Audit.PartyContactMechanisms', 'Delete non-primary records', @@RowCount)

			
			-- Update the primary Audit records
			-----------------------------------
			UPDATE apcm
			SET ContactMechanismID =   CASE WHEN ppcm.ContactMechanismType = 'Email'  THEN @DummyEmailID
											WHEN ppcm.ContactMechanismType = 'Phone'  THEN @DummyPhoneID
											WHEN ppcm.ContactMechanismType = 'Postal' THEN @DummyPostalID
											ELSE 0
										END 
			FROM #AuditPrimaryPartyContactMechanisms ppcm
			INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms apcm 
							ON  apcm.AuditItemID = ppcm.AuditItemID 
							AND apcm.PartyID = ppcm.PartyID
							AND apcm.ContactMechanismID = ppcm.ContactMechanismID 

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Audit.PartyContactMechanisms', 'Erase details', @@RowCount)



			-- A simple update of the Audit.PartyContactMechanismPurposes table will suffice 
			-- as there are no primary key constraints
			--------------------------------------------------------------------------------
			UPDATE apcmp
			SET ContactMechanismID =   CASE WHEN ea.ContactMechanismID IS NOT NULL THEN @DummyEmailID
											WHEN tn.ContactMechanismID IS NOT NULL THEN @DummyPhoneID
											WHEN pa.ContactMechanismID IS NOT NULL THEN @DummyPostalID
										END 
			FROM [$(AuditDB)].Audit.PartyContactMechanismPurposes apcmp
			LEFT JOIN ContactMechanism.EmailAddresses ea ON ea.ContactMechanismId = apcmp.contactmechanismID 
			LEFT JOIN ContactMechanism.PostalAddresses pa ON pa.ContactMechanismId = apcmp.contactmechanismID 
			LEFT JOIN ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismId = apcmp.contactmechanismID 
			WHERE apcmp.PartyID = @PartyID
			
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Audit.PartyContactMechanismPurposes', 'Erase details', @@RowCount)

	

		---------------------------------------------------------------------------
		-- Erase VINS and Registrations and Unlink People from Events and Vehicles
		---------------------------------------------------------------------------

			-- Find all associated Vehicles for PartyID that are not multi-linked
			IF OBJECT_ID('tempdb..#Vehicles') IS NOT NULL
			DROP TABLE #Vehicles

			CREATE TABLE #Vehicles
				(
					PartyID					BIGINT,
					VehicleID				BIGINT,
					Manufacturer			VARCHAR(20)
				)

			INSERT INTO #Vehicles (PartyID, VehicleID, Manufacturer)
			SELECT	DISTINCT
					vpre.PartyID, 
					vpre.VehicleID,
					o.OrganisationName AS Manufacturer
			FROM #Events e
			INNER JOIN Vehicle.VehiclePartyRoleEvents vpre ON vpre.EventID = e.EventID
			INNER JOIN Vehicle.Vehicles v ON v.VehicleID = vpre.VehicleID
										 AND v.VehicleID NOT IN (SELECT VehicleID FROM Vehicle.Vehicles WHERE SUBSTRING(VIN,1,6) IN ('SAL_LL','SAJ_LL'))	-- V1.1 Ignore LostLeads dummy vehicles
										 AND v.VIN NOT LIKE 'SA%_CRC_Unknown_V' -- Ignore CRC dummy vehicles
			INNER JOIN Vehicle.Models m ON m.ModelID = v.ModelID
			INNER JOIN Party.Organisations o ON o.PartyID = m.ManufacturerPartyID
			WHERE e.MultiPersonEvent = 0
			AND NOT EXISTS (SELECT EventID FROM #LinkedOrgs lo WHERE lo.EventID = e.EventID AND lo.ReceivedIndependently = 1) -- NOT the known multi-linked events
			AND NOT EXISTS (SELECT vpre2.VehicleID FROM Vehicle.VehiclePartyRoleEvents vpre2 WHERE vpre2.VehicleID = v.VehicleID				
																							  AND vpre2.PartyID <> e.PartyID					
																							  AND vpre2.PartyID NOT IN (SELECT PartyID FROM #LinkedOrgs lo2 
																														WHERE lo2.ReceivedIndependently = 0) 
							) ---> Where the vehicle is not linked to a different party that is not one of the already identified linked organisations.	

			-- Update the NON-multi-linked Vehicles
			UPDATE v
			SET v.VIN = @RemovalText,
				v.ModelID = CASE WHEN vt.Manufacturer = 'Jaguar' THEN @DummyJagModelID ELSE @DummyLRModelID END, 
				v.VehicleIdentificationNumberUsable = 0,
				v.VINPrefix = @RemovalText,
				v.ChassisNumber = NULL,
				v.BuildDate = NULL, 
				v.BuildYear = NULL,
				ThroughDate = NULL,
				ModelVariantID = NULL,
				SVOTypeID = NULL,
				FOBCode = NULL
			FROM #Vehicles vt
			INNER JOIN Vehicle.Vehicles v ON v.VehicleID = vt.VehicleID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Vehicle.Vehicles', 'Erase details', @@RowCount)



			-----------------------------------------------------------------------------------
			-- Now remove the links from the PartyID (and associated Orgs) to Event and Vehicle
			-----------------------------------------------------------------------------------

			-- Add in the new Vehicle.VehiclePartyRoles record for the
			-- primary VPRE so there are no Foreign Key complaints
			-----------------------------------------------------------
			INSERT INTO Vehicle.VehiclePartyRoles (PartyID, VehicleRoleTypeID, VehicleID, FromDate, ThroughDate)
			SELECT DISTINCT 
					vpre.PartyID, 
					vpre.VehicleRoleTypeID, 
					CASE WHEN o.OrganisationName = 'Jaguar' THEN @DummyJagVehicleID ELSE @DummyLRVehicleID END AS VehicleID, 
					CAST('1900-01-01' As DATE) AS FromDate, 
					NULL AS ThroughDate
			FROM #Events e
			INNER JOIN Vehicle.VehiclePartyRoleEvents vpre ON vpre.VehiclePartyRoleEventID = e.PrimaryVehiclePartyRoleEventID
			INNER JOIN Vehicle.Vehicles v ON v.VehicleID = vpre.VehicleID
			INNER JOIN Vehicle.Models m ON m.ModelID = v.ModelID
			INNER JOIN Party.Organisations o ON o.PartyID = m.ManufacturerPartyID
			WHERE v.VIN <> @RemovalText  -- Only update where we have not already overwritten the vehicle details

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Vehicle.VehiclePartyRoles', 'Add dummy vehicle role', @@RowCount)
			
			
			
			
			-- Update primary VPRE record to dummy Vehicle, if not already GDPR erased (to maintain data coherency) 
			-- before removing the remaining recs
			-------------------------------------------------------------------------------------------------------
					
			-- Link primary VPRE record to a dummy vehicle 
			UPDATE vpre
			SET vpre.VehicleID = CASE WHEN o.OrganisationName = 'Jaguar' THEN @DummyJagVehicleID ELSE @DummyLRVehicleID END
			FROM #Events e
			INNER JOIN Vehicle.VehiclePartyRoleEvents vpre ON vpre.VehiclePartyRoleEventID = e.PrimaryVehiclePartyRoleEventID
			INNER JOIN Vehicle.Vehicles v ON v.VehicleID = vpre.VehicleID
			INNER JOIN Vehicle.Models m ON m.ModelID = v.ModelID
			INNER JOIN Party.Organisations o ON o.PartyID = m.ManufacturerPartyID
			WHERE v.VIN <> @RemovalText  -- Only update where we have not already overwritten the vehicle details
			
			
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Vehicle.VehiclePartyRoleEvents', 'Unlink vehicle', @@RowCount)

					

			-- Remove main Party links
			-----------------------------
			DELETE vpre
			FROM #Events e
			INNER JOIN Vehicle.VehiclePartyRoleEvents vpre ON vpre.EventID = e.EventID 
														  AND vpre.PartyID = e.PartyID
														  AND vpre.VehiclePartyRoleEventID <> e.PrimaryVehiclePartyRoleEventID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Vehicle.VehiclePartyRoleEvents', 'Delete non-primary record (Person)', @@RowCount)
			


			-- Now remove uneeded Vehicle.VehiclePartyRoles records
			-------------------------------------------------------
			DELETE vpr
			FROM Vehicle.VehiclePartyRoles vpr 
			INNER JOIN Vehicle.Vehicles v ON v.VehicleID = vpr.VehicleID
										AND v.VIN <> @RemovalText										-- Only remove non-GDPR vehicles
										AND v.VehicleID NOT IN (@DummyLRVehicleID, @DummyJagVehicleID)	-- Only remove non-GDPR vehicles
			WHERE vpr.PartyID = @PartyID
			
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Vehicle.VehiclePartyRoles', 'Delete record', @@RowCount)
			
	


			-- Remove asscoiated Orgs links
			-------------------------------
			DELETE vpre
			FROM #LinkedOrgs lo
			INNER JOIN Vehicle.VehiclePartyRoleEvents vpre ON vpre.EventID = lo.EventID
														  AND vpre.PartyID = lo.OrgPartyID
														  
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Vehicle.VehiclePartyRoleEvents', 'Delete record (Organisation)', @@RowCount)




			------------------------------------------------------------
			-- Erase AUDIT TABLE values used in matching
			------------------------------------------------------------



			-- Audit.PostalAddresses
			UPDATE aud
			SET aud.ContactMechanismID = @DummyPostalID, 
				aud.BuildingName = @RemovalText, 
				aud.SubStreetAndNumberOrig = @RemovalText, 
				aud.SubStreetOrig = @RemovalText, 
				aud.SubStreetNumber = @RemovalText, 
				aud.SubStreet = @RemovalText, 
				aud.StreetAndNumberOrig = @RemovalText, 
				aud.StreetOrig = @RemovalText, 
				aud.StreetNumber = @RemovalText, 
				aud.Street = @RemovalText, 
				aud.SubLocality = @RemovalText, 
				aud.Locality = @RemovalText, 
				aud.Town = @RemovalText, 
				aud.Region = @RemovalText, 
				aud.PostCode = @RemovalText, 
				aud.CountryID = @DummyCountryID
			FROM #OriginatingDataRows odr
			INNER JOIN [$(AuditDB)].Audit.PostalAddresses aud ON aud.AuditItemID = odr.OriginatingAuditItemID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Audit.PostalAddresses', 'Erase details', @@RowCount)



			-- Audit.TelephoneNumbers
			UPDATE aud
			SET aud.ContactMechanismID = @DummyPhoneID,
				aud.ContactNumber = @RemovalText
			FROM #OriginatingDataRows odr
			INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers aud ON aud.AuditItemID = odr.OriginatingAuditItemID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Audit.TelephoneNumbers', 'Erase details', @@RowCount)





	END --- end of Full erasure section ----------------------------------------------------------------------------------------------------


	--- CGR Note: I am allowing a full erasure after a "partial" erasure to run this part (below) again because +new+ data rows may have 
	---           been loaded and matched in the meantime and we would want these to be blanked as well.



			-- Remove Non-Usable Customer Identifiers  (Usable IDs are blanked inside the conditional section above)
			----------------------------------------
			DELETE cr
			FROM Party.CustomerRelationships cr
			WHERE cr.PartyIDFrom = @PartyID
			AND CustomerIdentifierUsable = 0
			AND CustomerIdentifier <> @RemovalText	-- ignore those blanked in the section above

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Party.CustomerRelationships', 'Delete Non-Usable CustomerID Records', @@RowCount)




			-----------------------------------
			-- Update the vehicle registrations 
			-----------------------------------
			UPDATE r
			SET RegistrationNumber = @RemovalText,
				RegistrationDate = NULL,
				ThroughDate = '1900-01-01'
			FROM #Events e
			INNER JOIN Vehicle.VehicleRegistrationEvents vre ON vre.EventID = e.EventID
			INNER JOIN Vehicle.Registrations r ON r.RegistrationID = vre.RegistrationID 
			WHERE MultiPersonEvent = 0
			
			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Vehicle.VehicleRegistrations', 'Erase details', @@RowCount)

			
			--------------------------------------------------------------------
			-- Update the CaseContactMechanisms
			--------------------------------------------------------------------

			-- Find all associated ContactMechanisms for CaseIDs
			IF OBJECT_ID('tempdb..#CaseContactMechanisms') IS NOT NULL
			DROP TABLE #CaseContactMechanisms

			CREATE TABLE #CaseContactMechanisms
				(
					CaseID					BIGINT,
					ContactMechanismID		BIGINT,
					ContactMechanismType	VARCHAR(10)
				)

			INSERT INTO #CaseContactMechanisms (CaseID, ContactMechanismID, ContactMechanismType)
			SELECT DISTINCT
					ccm.CaseID, 
					ccm.ContactMechanismID,
					CASE WHEN ea.ContactMechanismID IS NOT NULL THEN 'Email' 
						 WHEN pa.ContactMechanismID IS NOT NULL THEN 'Postal'
						 WHEN tn.ContactMechanismID IS NOT NULL THEN 'Phone'
						 END AS ContactMechanismType
			FROM Event.AutomotiveEventBasedInterviews aebi 
			INNER JOIN Event.CaseContactMechanisms ccm ON ccm.CaseID = aebi.CaseID
			LEFT JOIN ContactMechanism.EmailAddresses ea ON ea.ContactMechanismId = ccm.contactmechanismID 
			LEFT JOIN ContactMechanism.PostalAddresses pa ON pa.ContactMechanismId = ccm.contactmechanismID 
			LEFT JOIN ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismId = ccm.contactmechanismID 
			WHERE aebi.PartyID = @PartyID
	
	
			-- Reset ContactMechanismsIDs to GDPR dummy records
			------------------------------------------------------------

			-- Unlink CaseContactMechanisms
			UPDATE ccm
			SET ContactMechanismID =   CASE WHEN cmt.ContactMechanismType = 'Email'  THEN @DummyEmailID
											WHEN cmt.ContactMechanismType = 'Phone'  THEN @DummyPhoneID
											WHEN cmt.ContactMechanismType = 'Postal' THEN @DummyPostalID
											ELSE 0
										END 
			FROM #CaseContactMechanisms cmt
			INNER JOIN Event.CaseContactMechanisms ccm 
							ON  ccm.ContactMechanismID = cmt.ContactMechanismID 
							AND ccm.CaseID = cmt.CaseID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Event.CaseContactMechanisms', 'Unlink', @@RowCount)


			
			-- Unlink CaseContactMechanismOutcomes
			UPDATE ccmo
			SET ContactMechanismID =   CASE WHEN cmt.ContactMechanismType = 'Email'  THEN @DummyEmailID
											WHEN cmt.ContactMechanismType = 'Phone'  THEN @DummyPhoneID
											WHEN cmt.ContactMechanismType = 'Postal' THEN @DummyPostalID
											ELSE 0
										END 
			FROM #CaseContactMechanisms cmt
			INNER JOIN Event.CaseContactMechanismOutcomes ccmo 
							ON  ccmo.ContactMechanismID = cmt.ContactMechanismID 
							AND ccmo.CaseID = cmt.CaseID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Event.CaseContactMechanismOutcomes', 'Unlink', @@RowCount)



			-- Unlink Audit.CaseContactMechanismOutcomes
			UPDATE accmo
			SET ContactMechanismID =   CASE WHEN cmt.ContactMechanismType = 'Email'  THEN @DummyEmailID
											WHEN cmt.ContactMechanismType = 'Phone'  THEN @DummyPhoneID
											WHEN cmt.ContactMechanismType = 'Postal' THEN @DummyPostalID
											ELSE 0
										END 
			FROM #CaseContactMechanisms cmt
			INNER JOIN [$(AuditDB)].Audit.CaseContactMechanismOutcomes accmo 
							ON  accmo.ContactMechanismID = cmt.ContactMechanismID 
							AND accmo.CaseID = cmt.CaseID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Audit.CaseContactMechanismOutcomes', 'Unlink', @@RowCount)

			


		----------------------------------------------------------------
		-- Clear Party.LegalOrganisations and Party.Organisations where
		-- not supplied independently
		----------------------------------------------------------------

			-- Party.LegalOrganisations
			-------------------------------------------------------
			UPDATE la
			SET LegalName = @RemovalText
			FROM #linkedorgs lo
			INNER JOIN Party.LegalOrganisations la ON la.PartyID = lo.OrgPartyId 
			WHERE lo.ReceivedIndependently = 0

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Party.LegalOrganisations', 'Erase details', @@RowCount)



			-- Party.LegalOrganisationsByLanguage
			-------------------------------------------------------
			UPDATE la
			SET LegalName = @RemovalText
			FROM #linkedorgs lo
			INNER JOIN Party.LegalOrganisationsByLanguage la ON la.PartyID = lo.OrgPartyId 
			WHERE lo.ReceivedIndependently = 0

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Party.LegalOrganisationsByLanguage', 'Erase details', @@RowCount)



			-- Party.Organisations
			-------------------------------------------------------
			UPDATE o
			SET OrganisationName = @RemovalText
			FROM #linkedorgs lo
			INNER JOIN Party.Organisations o ON o.PartyID = lo.OrgPartyId 
			WHERE lo.ReceivedIndependently = 0

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Party.Organisations', 'Erase details', @@RowCount)





		----------------------------------------------------------------
		-- Delete any EmployeeRelationships records
		----------------------------------------------------------------

			DELETE er
			FROM #Events e
			INNER JOIN Party.EmployeeRelationships er ON er.PartyIDFrom = e.PartyID

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Party.EmployeeRelationships', 'Delete record', @@RowCount)




		----------------------------------------------------------------
		-- Reset Event dates and erase any Event.AdditionalInfoSales
		----------------------------------------------------------------

			-- Reset EventDate
			-----------------------------------------
			UPDATE e
			SET e.EventDate = '1900-01-01'
			FROM #Events t
			INNER JOIN Event.Events e ON e.EventID = t.EventID
			WHERE t.MultiPersonEvent = 0

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Event.Events', 'Erase details', @@RowCount)




			--Clear down AddtionalInfo values
			------------------------------------------
			UPDATE ais
			SET		SalesOrderNumber = @RemovalText, 
					SalesCustomerType = @RemovalText, 
					SalesPaymentType = @RemovalText, 
					Salesman = @RemovalText, 
					ContractRelationship = @RemovalText, 
					ContractCustomer = @RemovalText, 
					SalesmanCode = @RemovalText, 
					InvoiceNumber = @RemovalText, 
					InvoiceValue = @RemovalText, 
					PrivateOwner = @RemovalText, 
					OwningCompany = @RemovalText, 
					UserChooserDriver = @RemovalText, 
					EmployerCompany = @RemovalText, 
					AdditionalCountry = @RemovalText, 
					State = @RemovalText, 
					VehiclePurchaseDate = @RemovalText, 
					VehicleDeliveryDate = @RemovalText, 
					TypeOfSaleOrig = @RemovalText ,
					Approved = '', 
					LostLead_DateOfLeadCreation = @RemovalText, 
					ServiceAdvisorID = @RemovalText, 
					ServiceAdvisorName = @RemovalText, 
					TechnicianID = @RemovalText, 
					TechnicianName = @RemovalText, 
					VehicleSalePrice = @RemovalText, 
					SalesAdvisorID = @RemovalText, 
					SalesAdvisorName = @RemovalText, 
					PDI_Flag = NULL 
				-- 	ParentAuditItemID = NULL						-- Part of BUG 14413
			FROM #Events t
			INNER JOIN Event.AdditionalInfoSales ais ON ais.EventID = t.EventID
			WHERE t.MultiPersonEvent = 0

			-- Save the update count
			INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
			VALUES ('Event.AdditionalInfoSales', 'Erase details', @@RowCount)






		--------------------------------------------------------------------------------
		-- China.Sales_WithResponses
		-- China.Service_WithResponses
		-- China.Roadside_WithResponses
		-- China.CRC_WithResponses 
		--------------------------------------------------------------------------------

		-- China.Sales_WithResponses
		UPDATE csr
		SET csr.Manufacturer = @RemovalText, 
			csr.VehiclePurchaseDate = '01/01/1900', 
			csr.VehicleRegistrationDate = '01/01/1900', 
			csr.VehicleDeliveryDate = '01/01/1900', 
			csr.ServiceEventDate = '01/01/1900', 
			csr.DealerCode = @RemovalText, 
			csr.CustomerUniqueID = @RemovalText, 
			csr.CompanyName = @RemovalText, 
			csr.Title = @RemovalText, 
			csr.FirstName = @RemovalText, 
			csr.SurnameField1 = @RemovalText, 
			csr.SurnameField2 = @RemovalText, 
			csr.Salutation = @RemovalText, 
			csr.Address1 = @RemovalText, 
			csr.Address2 = @RemovalText, 
			csr.Address3 = @RemovalText, 
			csr.Address4 = @RemovalText, 
			csr.Address5 = @RemovalText, 
			csr.Address6 = @RemovalText, 
			csr.Address7 = @RemovalText, 
			csr.Address8 = @RemovalText, 
			csr.HomeTelephoneNumber = @RemovalText, 
			csr.BusinessTelephoneNumber = @RemovalText, 
			csr.MobileTelephoneNumber = @RemovalText, 
			csr.ModelName = @RemovalText, 
			csr.ModelYear = @RemovalText, 
			csr.VIN = @RemovalText, 
			csr.RegistrationNumber = @RemovalText, 
			csr.EmailAddress1 = @RemovalText, 
			csr.EmailAddress2 = @RemovalText, 
			csr.PreferredLanguage = @RemovalText, 
			csr.CompleteSuppression = @RemovalText, 
			csr.SuppressionEmail = @RemovalText, 
			csr.SuppressionPhone = @RemovalText, 
			csr.SuppressionMail = @RemovalText, 
			csr.InvoiceNumber = @RemovalText, 
			csr.InvoiceValue = @RemovalText, 
			csr.ServiceEmployeeCode = @RemovalText, 
			csr.EmployeeName = @RemovalText, 
			csr.OwnershipCycle = @RemovalText, 
			csr.Gender = @RemovalText, 
			csr.PrivateOwner = @RemovalText, 
			csr.OwningCompany = @RemovalText, 
			csr.UserChooserDriver = @RemovalText, 
			csr.EmployerCompany = @RemovalText, 
			csr.MonthAndYearOfBirth = @RemovalText, 
			csr.PreferrredMethodOfContact = @RemovalText, 
			csr.PermissionsForContact = @RemovalText, 
			csr.ConvertedVehicleDeliveryDate = '1900-01-01', 
			csr.ConvertedServiceEventDate = '1900-01-01', 
			csr.ConvertedVehiclePurchaseDate = '1900-01-01', 
			csr.ConvertedVehicleRegistrationDate = '1900-01-01', 
			csr.CustomerIdentifier = @RemovalText, 
			csr.ResponseID = @RemovalText, 
			csr.InterviewerNumber = @RemovalText, 
			csr.ResponseDate = '01/01/1900', 
			csr.DateTransferredToVWT = '01/01/1900'
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].China.Sales_WithResponses csr ON csr.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('China.Sales_WithResponses', 'Erase details', @@RowCount)


		-- China.Service_WithResponses
		UPDATE csr
		SET csr.Manufacturer = @RemovalText, 
			csr.VehiclePurchaseDate = '01/01/1900', 
			csr.VehicleRegistrationDate = '01/01/1900', 
			csr.VehicleDeliveryDate = '01/01/1900', 
			csr.ServiceEventDate = '01/01/1900', 
			csr.DealerCode = @RemovalText, 
			csr.CustomerUniqueID = @RemovalText, 
			csr.CompanyName = @RemovalText, 
			csr.Title = @RemovalText, 
			csr.FirstName = @RemovalText, 
			csr.SurnameField1 = @RemovalText, 
			csr.SurnameField2 = @RemovalText, 
			csr.Salutation = @RemovalText, 
			csr.Address1 = @RemovalText, 
			csr.Address2 = @RemovalText, 
			csr.Address3 = @RemovalText, 
			csr.Address4 = @RemovalText, 
			csr.Address5 = @RemovalText, 
			csr.Address6 = @RemovalText, 
			csr.Address7 = @RemovalText, 
			csr.Address8 = @RemovalText, 
			csr.HomeTelephoneNumber = @RemovalText, 
			csr.BusinessTelephoneNumber = @RemovalText, 
			csr.MobileTelephoneNumber = @RemovalText, 
			csr.ModelName = @RemovalText, 
			csr.ModelYear = @RemovalText, 
			csr.VIN = @RemovalText, 
			csr.RegistrationNumber = @RemovalText, 
			csr.EmailAddress1 = @RemovalText, 
			csr.EmailAddress2 = @RemovalText, 
			csr.PreferredLanguage = @RemovalText, 
			csr.CompleteSuppression = @RemovalText, 
			csr.SuppressionEmail = @RemovalText, 
			csr.SuppressionPhone = @RemovalText, 
			csr.SuppressionMail = @RemovalText, 
			csr.InvoiceNumber = @RemovalText, 
			csr.InvoiceValue = @RemovalText, 
			csr.ServiceEmployeeCode = @RemovalText, 
			csr.EmployeeName = @RemovalText, 
			csr.OwnershipCycle = @RemovalText, 
			csr.Gender = @RemovalText, 
			csr.PrivateOwner = @RemovalText, 
			csr.OwningCompany = @RemovalText, 
			csr.UserChooserDriver = @RemovalText, 
			csr.EmployerCompany = @RemovalText, 
			csr.MonthAndYearOfBirth = @RemovalText, 
			csr.PreferrredMethodOfContact = @RemovalText, 
			csr.PermissionsForContact = @RemovalText, 
			csr.ConvertedVehicleDeliveryDate = '1900-01-01', 
			csr.ConvertedServiceEventDate = '1900-01-01', 
			csr.ConvertedVehiclePurchaseDate = '1900-01-01', 
			csr.ConvertedVehicleRegistrationDate = '1900-01-01', 
			csr.CustomerIdentifier = @RemovalText, 
			csr.ResponseID = @RemovalText, 
			csr.InterviewerNumber = @RemovalText, 
			csr.ResponseDate = '01/01/1900', 
			csr.DateTransferredToVWT = '01/01/1900'
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].China.Service_WithResponses csr ON csr.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('China.Service_WithResponses', 'Erase details', @@RowCount)


		-- China.Roadside_WithResponses
		UPDATE csr
		SET csr.Manufacturer = @RemovalText, 
			csr.VehiclePurchaseDate = '01/01/1900', 
			csr.VehicleRegistrationDate = '01/01/1900', 
			csr.VehicleDeliveryDate = '01/01/1900', 
			csr.ServiceEventDate = '01/01/1900', 
			csr.DealerCode = @RemovalText, 
			csr.CustomerUniqueID = @RemovalText, 
			csr.CompanyName = @RemovalText, 
			csr.Title = @RemovalText, 
			csr.FirstName = @RemovalText, 
			csr.SurnameField1 = @RemovalText, 
			csr.SurnameField2 = @RemovalText, 
			csr.Salutation = @RemovalText, 
			csr.Address1 = @RemovalText, 
			csr.Address2 = @RemovalText, 
			csr.Address3 = @RemovalText, 
			csr.Address4 = @RemovalText, 
			csr.Address5 = @RemovalText, 
			csr.Address6 = @RemovalText, 
			csr.Address7 = @RemovalText, 
			csr.Address8 = @RemovalText, 
			csr.HomeTelephoneNumber = @RemovalText, 
			csr.BusinessTelephoneNumber = @RemovalText, 
			csr.MobileTelephoneNumber = @RemovalText, 
			csr.ModelName = @RemovalText, 
			csr.ModelYear = @RemovalText, 
			csr.VIN = @RemovalText, 
			csr.RegistrationNumber = @RemovalText, 
			csr.EmailAddress1 = @RemovalText, 
			csr.EmailAddress2 = @RemovalText, 
			csr.PreferredLanguage = @RemovalText, 
			csr.CompleteSuppression = @RemovalText, 
			csr.SuppressionEmail = @RemovalText, 
			csr.SuppressionPhone = @RemovalText, 
			csr.SuppressionMail = @RemovalText, 
			csr.InvoiceNumber = @RemovalText, 
			csr.InvoiceValue = @RemovalText, 
			csr.ServiceEmployeeCode = @RemovalText, 
			csr.EmployeeName = @RemovalText, 
			csr.OwnershipCycle = @RemovalText, 
			csr.Gender = @RemovalText, 
			csr.PrivateOwner = @RemovalText, 
			csr.OwningCompany = @RemovalText, 
			csr.UserChooserDriver = @RemovalText, 
			csr.EmployerCompany = @RemovalText, 
			csr.MonthAndYearOfBirth = @RemovalText, 
			csr.PreferrredMethodOfContact = @RemovalText, 
			csr.PermissionsForContact = @RemovalText, 
			csr.BreakdownAttendingResource = @RemovalText, 
			csr.BreakdownCaseID = @RemovalText, 
			csr.BreakdownCountry = @RemovalText, 
			csr.BreakdownDate = '01/01/1900', 
			csr.CarHireGroupBranch = @RemovalText, 
			csr.CarHireJobNumber = @RemovalText, 
			csr.carHireMake = @RemovalText, 
			csr.CarHireModel = @RemovalText, 
			csr.CarHireProvider = @RemovalText, 
			csr.CarHireStartDate = '01/01/1900', 
			csr.CarHireStartTime = '', 
			csr.CarHireTicketNumber  = @RemovalText, 
			csr.DataSource = @RemovalText, 
			csr.ReasonForHire = @RemovalText, 
			csr.RepairingDealerCode = @RemovalText, 
			csr.RepairingDealerCountry = @RemovalText, 
			csr.RoadsideAssistanceProvider = @RemovalText, 
			csr.ConvertedBreakdownDate = '1900-01-01', 
			csr.ConvertedCarHireStartDate = '1900-01-01', 
			csr.ConvertedCarHireStartTime = '1900-01-01', 
			csr.ConvertedVehicleDeliveryDate = '1900-01-01', 
			csr.ConvertedServiceEventDate = '1900-01-01', 
			csr.ConvertedVehiclePurchaseDate = '1900-01-01', 
			csr.ConvertedVehicleRegistrationDate = '1900-01-01', 
			csr.CustomerIdentifier = @RemovalText, 
			csr.ResponseID = @RemovalText, 
			csr.InterviewerNumber = @RemovalText, 
			csr.ResponseDate = '01/01/1900', 
			csr.DateTransferredToVWT = '01/01/1900'
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].China.Roadside_WithResponses csr ON csr.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('China.Roadside_WithResponses', 'Erase details', @@RowCount)



	
		-- China.CRC_WithResponses
		UPDATE ccr
		SET ccr.Respondent_Serial = @RemovalText, 
			ccr.GfKPartyID = @RemovalText, 
			ccr.ID_init = @RemovalText, 
			ccr.INTERNAME = @RemovalText, 
			ccr.FSTARTTIME = @RemovalText, 
			ccr.STARTTIME = @RemovalText, 
			ccr.ENDDate = @RemovalText, 
			ccr.ENDTIME = @RemovalText, 
			ccr.Telephone = @RemovalText, 
			ccr.DealerCode = @RemovalText, 
			ccr.fullModel = @RemovalText, 
			ccr.Model = @RemovalText, 
			ccr.SType = @RemovalText, 
			ccr.Carreg = @RemovalText, 
			ccr.Title = @RemovalText, 
			ccr.Initial = @RemovalText, 
			ccr.Surname = @RemovalText, 
			ccr.CoName = @RemovalText, 
			ccr.add1 = @RemovalText, 
			ccr.add2 = @RemovalText, 
			ccr.add3 = @RemovalText, 
			ccr.add4 = @RemovalText, 
			ccr.add5 = @RemovalText, 
			ccr.add6 = @RemovalText, 
			ccr.add7 = @RemovalText, 
			ccr.add8 = @RemovalText, 
			ccr.add9 = @RemovalText, 
			ccr.CTRY = @RemovalText, 
			ccr.sno = @RemovalText, 
			ccr.ccode = @RemovalText, 
			ccr.modelcode = @RemovalText, 
			ccr.lang = @RemovalText, 
			ccr.manuf = @RemovalText, 
			ccr.gender_init = @RemovalText, 
			ccr.qver = @RemovalText, 
			ccr.etype = @RemovalText, 
			ccr.week = @RemovalText, 
			ccr.test = @RemovalText, 
			ccr.EmailAddress = @RemovalText, 
			ccr.eventDate = @RemovalText, 
			ccr.VIN = @RemovalText, 
			ccr.Tel_1 = @RemovalText, 
			ccr.Tel_2 = @RemovalText, 
			ccr.CustomerUniqueId = @RemovalText, 
			ccr.OwnerName = @RemovalText, 
			ccr.DealerCode_GDD = @RemovalText, 
			ccr.dealer = @RemovalText,
			ccr.DealerName = @RemovalText, 
			ccr.surveyscale = @RemovalText, 
			ccr.reminder = @RemovalText, 
			ccr.CRCsurveyfile = @RemovalText, 
			ccr.Password = @RemovalText, 
			ccr.SRNumber = @RemovalText, 
			ccr.ContactId = @RemovalText, 
			ccr.AssetId = @RemovalText, 
			ccr.VehicleMileage = @RemovalText, 
			ccr.VehicleDerivative = @RemovalText, 
			ccr.VehicleMonthsinService = @RemovalText, 
			ccr.CustomerFirstName = @RemovalText, 
			ccr.ResponseDate = '1900-01-01', 
			ccr.ConvertedeventDate = '1900-01-01', 
			ccr.ConvertedResponseDate = '1900-01-01', 
			ccr.CustomerIdentifier = @RemovalText, 
			ccr.DateTransferredToVWT = '1900-01-01'
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].China.CRC_WithResponses ccr ON ccr.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('China.CRC_WithResponses', 'Erase details', @@RowCount)






	------------------------------------------------------------------------------------------
	-- CRM.CRCCall_Call
	-- CRM.DMS_Repair_Service
	-- CRM.PreOwned						(This is commented out as CRM.PreOwned is not yet ready for release to Live)
	-- CRM.RoadsideIncident_Roadside	(This is commented out as CRM.RoadsideIncident_Roadside is not yet ready for release to Live)
	-- CRM.Vista_Contract_Sales
	------------------------------------------------------------------------------------------


		-- CRM.CRCCall_Call
		UPDATE crm
		SET crm.Converted_ACCT_DATE_OF_BIRTH = '1900-01-01', 
		crm.Converted_ACCT_DATE_ADVISED_OF_DEATH = '1900-01-01', 
		crm.Converted_VEH_REGISTRATION_DATE = '1900-01-01', 
		crm.Converted_VEH_BUILD_DATE = '1900-01-01', 
		crm.Converted_DMS_REPAIR_ORDER_CLOSED_DATE = '1900-01-01', 
		crm.Converted_ROADSIDE_DATE_JOB_COMPLETED = '1900-01-01', 
		crm.Converted_CASE_CASE_SOLVED_DATE = '1900-01-01', 
		crm.Converted_VISTACONTRACT_HANDOVER_DATE = '1900-01-01', 
		crm.DateTransferredToVWT = '1900-01-01', 
		crm.ACCT_ACADEMIC_TITLE = '', 
		crm.ACCT_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_ACCT_ID = '', 
		crm.ACCT_ADDITIONAL_LAST_NAME = @RemovalText, 
		crm.ACCT_BP_ROLE = '', 
		crm.ACCT_BUILDING = '', 
		crm.ACCT_CITY_CODE = '', 
		crm.ACCT_CITY_CODE2 = '', 
		crm.ACCT_CITY_TOWN = '', 
		crm.ACCT_CITYH_CODE = '', 
		crm.ACCT_COUNTRY = '', 
		crm.ACCT_COUNTRY_CODE = '', 
		crm.ACCT_COUNTY = '', 
		crm.ACCT_COUNTY_CODE = '', 
		crm.ACCT_DATE_ADVISED_OF_DEATH = '', 
		crm.ACCT_DATE_OF_BIRTH = '', 
		crm.ACCT_DEAL_FULNAME_OF_CREAT_DEA = '', 
		crm.ACCT_DISTRICT = '', 
		crm.ACCT_EMPLOYER_NAME = '', 
		crm.ACCT_EXTERN_FINANC_COMP_ACCTID = '', 
		crm.ACCT_FIRST_NAME = @RemovalText, 
		crm.ACCT_FLOOR = '', 
		crm.ACCT_FULL_NAME = @RemovalText, 
		crm.ACCT_GENDER_FEMALE = '', 
		crm.ACCT_GENDER_MALE = '', 
		crm.ACCT_GENDER_UNKNOWN = '', 
		crm.ACCT_GENERATION = '', 
		--crm.ACCT_GERMAN_ONLY_NON_ACAD_CODE = '', -- REMOVED AS REMOVED BUG 16755
		--crm.ACCT_GERMAN_ONLY_NON_ACADEMIC = '', 
		crm.ACCT_HOME_CITY = '', 
		crm.ACCT_HOME_EMAIL_ADDR_PRIMARY = '', 
		crm.ACCT_HOME_PHONE_NUMBER = '', 
		crm.ACCT_HOUSE_NO = '', 
		crm.ACCT_HOUSE_NUM2 = '', 
		crm.ACCT_HOUSE_NUM3 = '', 
		crm.ACCT_INDUSTRY_SECTOR = '', 
		crm.ACCT_INDUSTRY_SECTOR_CODE = '', 
		crm.ACCT_INITIALS = '', 
		crm.ACCT_JAGUAR_IN_MARKET_DATE = '', 
		crm.ACCT_JAGUAR_LOYALTY_STATUS = '', 
		crm.ACCT_KNOWN_AS = '', 
		crm.ACCT_LAND_ROVER_MARKET_DATE = '', 
		crm.ACCT_LAST_NAME = @RemovalText, 
		crm.ACCT_LOCATION = '', 
		crm.ACCT_MIDDLE_NAME = @RemovalText, 
		crm.ACCT_MOBILE_NUMBER = '', 
		crm.ACCT_NAME_1 = '', 
		crm.ACCT_NAME_2 = '', 
		crm.ACCT_NAME_3 = '', 
		crm.ACCT_NAME_4 = '', 
		crm.ACCT_NAME_CO = '', 
		crm.ACCT_NON_ACADEMIC_TITLE = '', 
		crm.ACCT_NON_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_PCODE1_EXT = '', 
		crm.ACCT_PCODE2_EXT = '', 
		crm.ACCT_PCODE3_EXT = '', 
		crm.ACCT_PO_BOX = '', 
		crm.ACCT_PO_BOX_CTY = '', 
		crm.ACCT_PO_BOX_LOBBY = '', 
		crm.ACCT_PO_BOX_LOC = '', 
		crm.ACCT_PO_BOX_NUM = '', 
		crm.ACCT_PO_BOX_REG = '', 
		crm.ACCT_POST_CODE2 = '', 
		crm.ACCT_POST_CODE3 = '', 
		crm.ACCT_POSTALAREA = '', 
		crm.ACCT_POSTCODE_ZIP = '', 
		crm.ACCT_PREF_LANGUAGE = '', 
		crm.ACCT_PREF_LANGUAGE_CODE = '', 
		crm.ACCT_REGION_STATE = '', 
		crm.ACCT_REGION_STATE_CODE = '', 
		crm.ACCT_ROOM_NUMBER = '', 
		crm.ACCT_STREET = @RemovalText, 
		crm.ACCT_STREETABBR = '', 
		crm.ACCT_STREETCODE = '', 
		crm.ACCT_SUPPLEMENT_1 = '', 
		crm.ACCT_SUPPLEMENT_2 = '', 
		crm.ACCT_SUPPLEMENT_3 = '', 
		crm.ACCT_TITLE = '', 
		crm.ACCT_TITLE_CODE = '', 
		crm.ACCT_TOWNSHIP = '', 
		crm.ACCT_TOWNSHIP_CODE = '', 
		crm.ACCT_WORK_PHONE_EXTENSION = '', 
		crm.ACCT_WORK_PHONE_PRIMARY = '', 
		crm.ACTIVITY_ID = '', 
		crm.CASE_CASE_CREATION_DATE = '', 
		crm.CASE_CASE_DESC = '', 
		crm.CASE_CASE_EMPL_RESPONSIBLE_NAM = '', 
		crm.CASE_CASE_ID = '', 
		crm.CASE_CASE_SOLVED_DATE = '', 
		crm.CASE_EMPL_RESPONSIBLE_ID = '', 
		crm.CASE_SECON_DEALER_CODE_OF_DEAL = '', 
		crm.CASE_VEH_REG_PLATE = '', 
		crm.CASE_VEH_VIN_NUMBER = @RemovalText, 
		crm.CASE_VEHMODEL_DERIVED_FROM_VIN = '', 
		crm.DMS_LICENSE_PLATE_REGISTRATION = '', 
		crm.DMS_REPAIR_ORDER_CLOSED_DATE = '', 
		crm.DMS_REPAIR_ORDER_NUMBER = '', 
		crm.DMS_REPAIR_ORDER_OPEN_DATE = '', 
	--	crm.DMS_TOTAL_CUSTOMER_PRICE = '', 
		crm.DMS_VIN = @RemovalText, 
		crm.LEAD_IN_MARKET_DATE = '', 
		crm.ROADSIDE_CUSTOMER_SUMMARY_INC = '', 
		crm.ROADSIDE_DATE_CALL_ANSWERED = '', 
		crm.ROADSIDE_DATE_CALL_RECEIVED = '', 
		crm.ROADSIDE_DATE_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_DRIVER_EMAIL = '', 
		crm.ROADSIDE_DRIVER_FIRST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_LAST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_MOBILE = '', 
		crm.ROADSIDE_DRIVER_TITLE = '',  
		crm.ROADSIDE_INCIDENT_DATE = '', 
		crm.ROADSIDE_INCIDENT_ID = '', 
		crm.ROADSIDE_INCIDENT_SUMMARY = '', 
		crm.ROADSIDE_INCIDENT_TIME = '', 
		crm.ROADSIDE_LICENSE_PLATE_REG_NO = '', 
		crm.ROADSIDE_RESOLUTION_TIME = '', 
		crm.ROADSIDE_TIME_CALL_ANSWERED = '', 
		crm.ROADSIDE_TIME_CALL_RECEIVED = '', 
		crm.ROADSIDE_TIME_JOB_COMPLETED = '', 
		crm.ROADSIDE_TIME_RESOURCE_ALL = '', 
		crm.ROADSIDE_TIME_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_TIME_SECON_RES_ALL = '', 
		crm.ROADSIDE_TIME_SECON_RES_ARR = '', 
		crm.ROADSIDE_VIN = @RemovalText, 
		crm.VEH_VIN = @RemovalText,
		crm.VEH_DERIVATIVE = '',
		crm.VEH_BUILD_DATE = '', 
		crm.VEH_CHASSIS_NUMBER = '', 
		crm.VEH_COMMON_ORDER_NUMBER = '',
		crm.VEH_CURR_PLANNED_DELIVERY_DATE = '', 
		crm.VEH_DELIVERED_DATE = '', 
		crm.VEH_DRIVER_FULL_NAME = '', 
		crm.VEH_FEATURE_CODE = '', 
		crm.VEH_MODEL	 = '', 
		crm.VEH_MODEL_DESC = '', 
		crm.VEH_PREDICTED_REPLACEMENT_DATE = '', 
		crm.VEH_REGISTRAT_LICENC_PLATE_NUM = '', 
		crm.VEH_REGISTRATION_DATE = '', 
		crm.VEH_VISTA_CONTRACT_NUMBER = '', 
		crm.VISTACONTRACT_HANDOVER_DATE = '', 
		crm.VISTACONTRACT_SALES_MAN_CD_DES = '',
		crm.VISTACONTRACT_SALES_MAN_FULNAM = '', 
		crm.VISTACONTRACT_SALESMAN_CODE = '', 
		crm.RESPONSE_ID = '', 
		crm.DMS_OTHER_RELATED_SERVICES = ''
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].CRM.CRCCall_Call crm ON crm.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('CRM.CRCCall_Call', 'Erase details', @@RowCount)


		-- CRM.DMS_Repair_Service
		UPDATE crm
		SET crm.Converted_ACCT_DATE_OF_BIRTH = '1900-01-01', 
		crm.Converted_ACCT_DATE_ADVISED_OF_DEATH = '1900-01-01', 
		crm.Converted_VEH_REGISTRATION_DATE = '1900-01-01', 
		crm.Converted_VEH_BUILD_DATE = '1900-01-01', 
		crm.Converted_DMS_REPAIR_ORDER_CLOSED_DATE = '1900-01-01', 
		crm.Converted_ROADSIDE_DATE_JOB_COMPLETED = '1900-01-01', 
		crm.Converted_CASE_CASE_SOLVED_DATE = '1900-01-01', 
		crm.Converted_VISTACONTRACT_HANDOVER_DATE = '1900-01-01', 
		crm.DateTransferredToVWT = '1900-01-01', 
		crm.ACCT_ACADEMIC_TITLE = '', 
		crm.ACCT_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_ACCT_ID = '', 
		crm.ACCT_ADDITIONAL_LAST_NAME = @RemovalText, 
		crm.ACCT_BP_ROLE = '', 
		crm.ACCT_BUILDING = '', 
		crm.ACCT_CITY_CODE = '', 
		crm.ACCT_CITY_CODE2 = '', 
		crm.ACCT_CITY_TOWN = '', 
		crm.ACCT_CITYH_CODE = '', 
		crm.ACCT_COUNTRY = '', 
		crm.ACCT_COUNTRY_CODE = '', 
		crm.ACCT_COUNTY = '', 
		crm.ACCT_COUNTY_CODE = '', 
		crm.ACCT_DATE_ADVISED_OF_DEATH = '', 
		crm.ACCT_DATE_OF_BIRTH = '', 
		crm.ACCT_DEAL_FULNAME_OF_CREAT_DEA = '', 
		crm.ACCT_DISTRICT = '', 
		crm.ACCT_EMPLOYER_NAME = '', 
		crm.ACCT_EXTERN_FINANC_COMP_ACCTID = '', 
		crm.ACCT_FIRST_NAME = @RemovalText, 
		crm.ACCT_FLOOR = '', 
		crm.ACCT_FULL_NAME = @RemovalText, 
		crm.ACCT_GENDER_FEMALE = '', 
		crm.ACCT_GENDER_MALE = '', 
		crm.ACCT_GENDER_UNKNOWN = '', 
		crm.ACCT_GENERATION = '', 
		--crm.ACCT_GERMAN_ONLY_NON_ACAD_CODE = '', -- REMOVED AS REMOVED BUG 16755
		--crm.ACCT_GERMAN_ONLY_NON_ACADEMIC = '', 
		crm.ACCT_HOME_CITY = '', 
		crm.ACCT_HOME_EMAIL_ADDR_PRIMARY = '', 
		crm.ACCT_HOME_PHONE_NUMBER = '', 
		crm.ACCT_HOUSE_NO = '', 
		crm.ACCT_HOUSE_NUM2 = '', 
		crm.ACCT_HOUSE_NUM3 = '', 
		crm.ACCT_INDUSTRY_SECTOR = '', 
		crm.ACCT_INDUSTRY_SECTOR_CODE = '', 
		crm.ACCT_INITIALS = '', 
		crm.ACCT_JAGUAR_IN_MARKET_DATE = '', 
		crm.ACCT_JAGUAR_LOYALTY_STATUS = '', 
		crm.ACCT_KNOWN_AS = '', 
		crm.ACCT_LAND_ROVER_MARKET_DATE = '', 
		crm.ACCT_LAST_NAME = @RemovalText, 
		crm.ACCT_LOCATION = '', 
		crm.ACCT_MIDDLE_NAME = @RemovalText, 
		crm.ACCT_MOBILE_NUMBER = '', 
		crm.ACCT_NAME_1 = '', 
		crm.ACCT_NAME_2 = '', 
		crm.ACCT_NAME_3 = '', 
		crm.ACCT_NAME_4 = '', 
		crm.ACCT_NAME_CO = '', 
		crm.ACCT_NON_ACADEMIC_TITLE = '', 
		crm.ACCT_NON_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_PCODE1_EXT = '', 
		crm.ACCT_PCODE2_EXT = '', 
		crm.ACCT_PCODE3_EXT = '', 
		crm.ACCT_PO_BOX = '', 
		crm.ACCT_PO_BOX_CTY = '', 
		crm.ACCT_PO_BOX_LOBBY = '', 
		crm.ACCT_PO_BOX_LOC = '', 
		crm.ACCT_PO_BOX_NUM = '', 
		crm.ACCT_PO_BOX_REG = '', 
		crm.ACCT_POST_CODE2 = '', 
		crm.ACCT_POST_CODE3 = '', 
		crm.ACCT_POSTALAREA = '', 
		crm.ACCT_POSTCODE_ZIP = '', 
		crm.ACCT_PREF_LANGUAGE = '', 
		crm.ACCT_PREF_LANGUAGE_CODE = '', 
		crm.ACCT_REGION_STATE = '', 
		crm.ACCT_REGION_STATE_CODE = '', 
		crm.ACCT_ROOM_NUMBER = '', 
		crm.ACCT_STREET = @RemovalText, 
		crm.ACCT_STREETABBR = '', 
		crm.ACCT_STREETCODE = '', 
		crm.ACCT_SUPPLEMENT_1 = '', 
		crm.ACCT_SUPPLEMENT_2 = '', 
		crm.ACCT_SUPPLEMENT_3 = '', 
		crm.ACCT_TITLE = '', 
		crm.ACCT_TITLE_CODE = '', 
		crm.ACCT_TOWNSHIP = '', 
		crm.ACCT_TOWNSHIP_CODE = '', 
		crm.ACCT_WORK_PHONE_EXTENSION = '', 
		crm.ACCT_WORK_PHONE_PRIMARY = '', 
		crm.ACTIVITY_ID = '', 
		crm.CASE_CASE_CREATION_DATE = '', 
		crm.CASE_CASE_DESC = '', 
		crm.CASE_CASE_EMPL_RESPONSIBLE_NAM = '', 
		crm.CASE_CASE_ID = '', 
		crm.CASE_CASE_SOLVED_DATE = '', 
		crm.CASE_EMPL_RESPONSIBLE_ID = '', 
		crm.CASE_SECON_DEALER_CODE_OF_DEAL = '', 
		crm.CASE_VEH_REG_PLATE = '', 
		crm.CASE_VEH_VIN_NUMBER = @RemovalText, 
		crm.CASE_VEHMODEL_DERIVED_FROM_VIN = '', 
		crm.DMS_LICENSE_PLATE_REGISTRATION = '', 
		crm.DMS_REPAIR_ORDER_CLOSED_DATE = '', 
		crm.DMS_REPAIR_ORDER_NUMBER = '', 
		crm.DMS_REPAIR_ORDER_OPEN_DATE = '', 
		crm.DMS_TOTAL_CUSTOMER_PRICE = NULL, 
		crm.DMS_VIN = @RemovalText, 
		crm.LEAD_IN_MARKET_DATE = '', 
		crm.ROADSIDE_CUSTOMER_SUMMARY_INC = '', 
		crm.ROADSIDE_DATE_CALL_ANSWERED = '', 
		crm.ROADSIDE_DATE_CALL_RECEIVED = '', 
		crm.ROADSIDE_DATE_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_DRIVER_EMAIL = '', 
		crm.ROADSIDE_DRIVER_FIRST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_LAST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_MOBILE = '', 
		crm.ROADSIDE_DRIVER_TITLE = '',  
		crm.ROADSIDE_INCIDENT_DATE = '', 
		crm.ROADSIDE_INCIDENT_ID = '', 
		crm.ROADSIDE_INCIDENT_SUMMARY = '', 
		crm.ROADSIDE_INCIDENT_TIME = '', 
		crm.ROADSIDE_LICENSE_PLATE_REG_NO = '', 
		crm.ROADSIDE_RESOLUTION_TIME = '', 
		crm.ROADSIDE_TIME_CALL_ANSWERED = '', 
		crm.ROADSIDE_TIME_CALL_RECEIVED = '', 
		crm.ROADSIDE_TIME_JOB_COMPLETED = '', 
		crm.ROADSIDE_TIME_RESOURCE_ALL = '', 
		crm.ROADSIDE_TIME_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_TIME_SECON_RES_ALL = '', 
		crm.ROADSIDE_TIME_SECON_RES_ARR = '', 
		crm.ROADSIDE_VIN = @RemovalText, 
		crm.VEH_VIN = @RemovalText,
		crm.VEH_DERIVATIVE = '',
		crm.VEH_BUILD_DATE = '', 
		crm.VEH_CHASSIS_NUMBER = '', 
		crm.VEH_COMMON_ORDER_NUMBER = '',
		crm.VEH_CURR_PLANNED_DELIVERY_DATE = '', 
		crm.VEH_DELIVERED_DATE = '', 
		crm.VEH_DRIVER_FULL_NAME = '', 
		crm.VEH_FEATURE_CODE = '', 
		crm.VEH_MODEL	 = '', 
		crm.VEH_MODEL_DESC = '', 
		crm.VEH_PREDICTED_REPLACEMENT_DATE = '', 
		crm.VEH_REGISTRAT_LICENC_PLATE_NUM = '', 
		crm.VEH_REGISTRATION_DATE = '', 
		crm.VEH_VISTA_CONTRACT_NUMBER = '', 
		crm.VISTACONTRACT_HANDOVER_DATE = '', 
		crm.VISTACONTRACT_SALES_MAN_CD_DES = '',
		crm.VISTACONTRACT_SALES_MAN_FULNAM = '', 
		crm.VISTACONTRACT_SALESMAN_CODE = '', 
		crm.RESPONSE_ID = '', 
		crm.DMS_REPAIR_ORDER_NUMBER_UNIQUE = '', 
		crm.DMS_OTHER_RELATED_SERVICES = ''
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].CRM.DMS_Repair_Service crm ON crm.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('CRM.DMS_Repair_Service', 'Erase details', @@RowCount)


	


		-- CRM.PreOwned
		UPDATE crm
		SET crm.Converted_ACCT_DATE_OF_BIRTH = '1900-01-01', 
		crm.Converted_ACCT_DATE_ADVISED_OF_DEATH = '1900-01-01', 
		crm.Converted_VEH_REGISTRATION_DATE = '1900-01-01', 
		crm.Converted_VEH_BUILD_DATE = '1900-01-01', 
		crm.Converted_DMS_REPAIR_ORDER_CLOSED_DATE = '1900-01-01', 
		crm.Converted_ROADSIDE_DATE_JOB_COMPLETED = '1900-01-01', 
		crm.Converted_CASE_CASE_SOLVED_DATE = '1900-01-01', 
		crm.Converted_VISTACONTRACT_HANDOVER_DATE = '1900-01-01', 
		crm.DateTransferredToVWT = '1900-01-01', 
		crm.ACCT_ACADEMIC_TITLE = '', 
		crm.ACCT_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_ACCT_ID = '', 
		crm.ACCT_ADDITIONAL_LAST_NAME = @RemovalText, 
		crm.ACCT_BP_ROLE = '', 
		crm.ACCT_BUILDING = '', 
		crm.ACCT_CITY_CODE = '', 
		crm.ACCT_CITY_CODE2 = '', 
		crm.ACCT_CITY_TOWN = '', 
		crm.ACCT_CITYH_CODE = '', 
		crm.ACCT_COUNTRY = '', 
		crm.ACCT_COUNTRY_CODE = '', 
		crm.ACCT_COUNTY = '', 
		crm.ACCT_COUNTY_CODE = '', 
		crm.ACCT_DATE_ADVISED_OF_DEATH = '', 
		crm.ACCT_DATE_OF_BIRTH = '', 
		crm.ACCT_DEAL_FULNAME_OF_CREAT_DEA = '', 
		crm.ACCT_DISTRICT = '', 
		crm.ACCT_EMPLOYER_NAME = '', 
		crm.ACCT_EXTERN_FINANC_COMP_ACCTID = '', 
		crm.ACCT_FIRST_NAME = @RemovalText, 
		crm.ACCT_FLOOR = '', 
		crm.ACCT_FULL_NAME = @RemovalText, 
		crm.ACCT_GENDER_FEMALE = '', 
		crm.ACCT_GENDER_MALE = '', 
		crm.ACCT_GENDER_UNKNOWN = '', 
		crm.ACCT_GENERATION = '', 
		--crm.ACCT_GERMAN_ONLY_NON_ACAD_CODE = '', -- REMOVED AS REMOVED BUG 16755
		--crm.ACCT_GERMAN_ONLY_NON_ACADEMIC = '', 
		crm.ACCT_HOME_CITY = '', 
		crm.ACCT_HOME_EMAIL_ADDR_PRIMARY = '', 
		crm.ACCT_HOME_PHONE_NUMBER = '', 
		crm.ACCT_HOUSE_NO = '', 
		crm.ACCT_HOUSE_NUM2 = '', 
		crm.ACCT_HOUSE_NUM3 = '', 
		crm.ACCT_INDUSTRY_SECTOR = '', 
		crm.ACCT_INDUSTRY_SECTOR_CODE = '', 
		crm.ACCT_INITIALS = '', 
		crm.ACCT_JAGUAR_IN_MARKET_DATE = '', 
		crm.ACCT_JAGUAR_LOYALTY_STATUS = '', 
		crm.ACCT_KNOWN_AS = '', 
		crm.ACCT_LAND_ROVER_MARKET_DATE = '', 
		crm.ACCT_LAST_NAME = @RemovalText, 
		crm.ACCT_LOCATION = '', 
		crm.ACCT_MIDDLE_NAME = @RemovalText, 
		crm.ACCT_MOBILE_NUMBER = '', 
		crm.ACCT_NAME_1 = '', 
		crm.ACCT_NAME_2 = '', 
		crm.ACCT_NAME_3 = '', 
		crm.ACCT_NAME_4 = '', 
		crm.ACCT_NAME_CO = '', 
		crm.ACCT_NON_ACADEMIC_TITLE = '', 
		crm.ACCT_NON_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_PCODE1_EXT = '', 
		crm.ACCT_PCODE2_EXT = '', 
		crm.ACCT_PCODE3_EXT = '', 
		crm.ACCT_PO_BOX = '', 
		crm.ACCT_PO_BOX_CTY = '', 
		crm.ACCT_PO_BOX_LOBBY = '', 
		crm.ACCT_PO_BOX_LOC = '', 
		crm.ACCT_PO_BOX_NUM = '', 
		crm.ACCT_PO_BOX_REG = '', 
		crm.ACCT_POST_CODE2 = '', 
		crm.ACCT_POST_CODE3 = '', 
		crm.ACCT_POSTALAREA = '', 
		crm.ACCT_POSTCODE_ZIP = '', 
		crm.ACCT_PREF_LANGUAGE = '', 
		crm.ACCT_PREF_LANGUAGE_CODE = '', 
		crm.ACCT_REGION_STATE = '', 
		crm.ACCT_REGION_STATE_CODE = '', 
		crm.ACCT_ROOM_NUMBER = '', 
		crm.ACCT_STREET = @RemovalText, 
		crm.ACCT_STREETABBR = '', 
		crm.ACCT_STREETCODE = '', 
		crm.ACCT_SUPPLEMENT_1 = '', 
		crm.ACCT_SUPPLEMENT_2 = '', 
		crm.ACCT_SUPPLEMENT_3 = '', 
		crm.ACCT_TITLE = '', 
		crm.ACCT_TITLE_CODE = '', 
		crm.ACCT_TOWNSHIP = '', 
		crm.ACCT_TOWNSHIP_CODE = '', 
		crm.ACCT_WORK_PHONE_EXTENSION = '', 
		crm.ACCT_WORK_PHONE_PRIMARY = '', 
		crm.ACTIVITY_ID = '', 
		crm.CASE_CASE_CREATION_DATE = '', 
		crm.CASE_CASE_DESC = '', 
		crm.CASE_CASE_EMPL_RESPONSIBLE_NAM = '', 
		crm.CASE_CASE_ID = '', 
		crm.CASE_CASE_SOLVED_DATE = '', 
		crm.CASE_EMPL_RESPONSIBLE_ID = '', 
		crm.CASE_SECON_DEALER_CODE_OF_DEAL = '', 
		crm.CASE_VEH_REG_PLATE = '', 
		crm.CASE_VEH_VIN_NUMBER = @RemovalText, 
		crm.CASE_VEHMODEL_DERIVED_FROM_VIN = '', 
		crm.DMS_LICENSE_PLATE_REGISTRATION = '', 
		crm.DMS_REPAIR_ORDER_CLOSED_DATE = '', 
		crm.DMS_REPAIR_ORDER_NUMBER = '', 
		crm.DMS_REPAIR_ORDER_OPEN_DATE = '', 
		crm.DMS_TOTAL_CUSTOMER_PRICE = NULL, 
		crm.DMS_VIN = @RemovalText, 
		crm.LEAD_IN_MARKET_DATE = '', 
		crm.ROADSIDE_CUSTOMER_SUMMARY_INC = '', 
		crm.ROADSIDE_DATE_CALL_ANSWERED = '', 
		crm.ROADSIDE_DATE_CALL_RECEIVED = '', 
		crm.ROADSIDE_DATE_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_DRIVER_EMAIL = '', 
		crm.ROADSIDE_DRIVER_FIRST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_LAST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_MOBILE = '', 
		crm.ROADSIDE_DRIVER_TITLE = '',  
		crm.ROADSIDE_INCIDENT_DATE = '', 
		crm.ROADSIDE_INCIDENT_ID = '', 
		crm.ROADSIDE_INCIDENT_SUMMARY = '', 
		crm.ROADSIDE_INCIDENT_TIME = '', 
		crm.ROADSIDE_LICENSE_PLATE_REG_NO = '', 
		crm.ROADSIDE_RESOLUTION_TIME = '', 
		crm.ROADSIDE_TIME_CALL_ANSWERED = '', 
		crm.ROADSIDE_TIME_CALL_RECEIVED = '', 
		crm.ROADSIDE_TIME_JOB_COMPLETED = '', 
		crm.ROADSIDE_TIME_RESOURCE_ALL = '', 
		crm.ROADSIDE_TIME_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_TIME_SECON_RES_ALL = '', 
		crm.ROADSIDE_TIME_SECON_RES_ARR = '', 
		crm.ROADSIDE_VIN = @RemovalText, 
		crm.VEH_VIN = @RemovalText,
		crm.VEH_DERIVATIVE = '',
		crm.VEH_BUILD_DATE = '', 
		crm.VEH_CHASSIS_NUMBER = '', 
		crm.VEH_COMMON_ORDER_NUMBER = '',
		crm.VEH_CURR_PLANNED_DELIVERY_DATE = '', 
		crm.VEH_DELIVERED_DATE = '', 
		crm.VEH_DRIVER_FULL_NAME = '', 
		crm.VEH_FEATURE_CODE = '', 
		crm.VEH_MODEL	 = '', 
		crm.VEH_MODEL_DESC = '', 
		crm.VEH_PREDICTED_REPLACEMENT_DATE = '', 
		crm.VEH_REGISTRAT_LICENC_PLATE_NUM = '', 
		crm.VEH_REGISTRATION_DATE = '', 
		crm.VEH_VISTA_CONTRACT_NUMBER = '', 
		crm.VISTACONTRACT_HANDOVER_DATE = '', 
		crm.VISTACONTRACT_SALES_MAN_CD_DES = '',
		crm.VISTACONTRACT_SALES_MAN_FULNAM = '', 
		crm.VISTACONTRACT_SALESMAN_CODE = '', 
		crm.RESPONSE_ID = '', 
		crm.DMS_OTHER_RELATED_SERVICES = ''
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].CRM.PreOwned crm ON crm.AuditItemID = odr.OriginatingAuditItemID


	

	


		-- CRM.RoadsideIncident_Roadside
		UPDATE crm
		SET crm.Converted_ACCT_DATE_OF_BIRTH = '1900-01-01', 
		crm.Converted_ACCT_DATE_ADVISED_OF_DEATH = '1900-01-01', 
		crm.Converted_VEH_REGISTRATION_DATE = '1900-01-01', 
		crm.Converted_VEH_BUILD_DATE = '1900-01-01', 
		crm.Converted_DMS_REPAIR_ORDER_CLOSED_DATE = '1900-01-01', 
		crm.Converted_ROADSIDE_DATE_JOB_COMPLETED = '1900-01-01', 
		crm.Converted_CASE_CASE_SOLVED_DATE = '1900-01-01', 
		crm.Converted_VISTACONTRACT_HANDOVER_DATE = '1900-01-01', 
		crm.DateTransferredToVWT = '1900-01-01', 
		crm.ACCT_ACADEMIC_TITLE = '', 
		crm.ACCT_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_ACCT_ID = '', 
		crm.ACCT_ADDITIONAL_LAST_NAME = @RemovalText, 
		crm.ACCT_BP_ROLE = '', 
		crm.ACCT_BUILDING = '', 
		crm.ACCT_CITY_CODE = '', 
		crm.ACCT_CITY_CODE2 = '', 
		crm.ACCT_CITY_TOWN = '', 
		crm.ACCT_CITYH_CODE = '', 
		crm.ACCT_COUNTRY = '', 
		crm.ACCT_COUNTRY_CODE = '', 
		crm.ACCT_COUNTY = '', 
		crm.ACCT_COUNTY_CODE = '', 
		crm.ACCT_DATE_ADVISED_OF_DEATH = '', 
		crm.ACCT_DATE_OF_BIRTH = '', 
		crm.ACCT_DEAL_FULNAME_OF_CREAT_DEA = '', 
		crm.ACCT_DISTRICT = '', 
		crm.ACCT_EMPLOYER_NAME = '', 
		crm.ACCT_EXTERN_FINANC_COMP_ACCTID = '', 
		crm.ACCT_FIRST_NAME = @RemovalText, 
		crm.ACCT_FLOOR = '', 
		crm.ACCT_FULL_NAME = @RemovalText, 
		crm.ACCT_GENDER_FEMALE = '', 
		crm.ACCT_GENDER_MALE = '', 
		crm.ACCT_GENDER_UNKNOWN = '', 
		crm.ACCT_GENERATION = '', 
		--crm.ACCT_GERMAN_ONLY_NON_ACAD_CODE = '', -- REMOVED AS REMOVED BUG 16755
		--crm.ACCT_GERMAN_ONLY_NON_ACADEMIC = '', 
		crm.ACCT_HOME_CITY = '', 
		crm.ACCT_HOME_EMAIL_ADDR_PRIMARY = '', 
		crm.ACCT_HOME_PHONE_NUMBER = '', 
		crm.ACCT_HOUSE_NO = '', 
		crm.ACCT_HOUSE_NUM2 = '', 
		crm.ACCT_HOUSE_NUM3 = '', 
		crm.ACCT_INDUSTRY_SECTOR = '', 
		crm.ACCT_INDUSTRY_SECTOR_CODE = '', 
		crm.ACCT_INITIALS = '', 
		crm.ACCT_JAGUAR_IN_MARKET_DATE = '', 
		crm.ACCT_JAGUAR_LOYALTY_STATUS = '', 
		crm.ACCT_KNOWN_AS = '', 
		crm.ACCT_LAND_ROVER_MARKET_DATE = '', 
		crm.ACCT_LAST_NAME = @RemovalText, 
		crm.ACCT_LOCATION = '', 
		crm.ACCT_MIDDLE_NAME = @RemovalText, 
		crm.ACCT_MOBILE_NUMBER = '', 
		crm.ACCT_NAME_1 = '', 
		crm.ACCT_NAME_2 = '', 
		crm.ACCT_NAME_3 = '', 
		crm.ACCT_NAME_4 = '', 
		crm.ACCT_NAME_CO = '', 
		crm.ACCT_NON_ACADEMIC_TITLE = '', 
		crm.ACCT_NON_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_PCODE1_EXT = '', 
		crm.ACCT_PCODE2_EXT = '', 
		crm.ACCT_PCODE3_EXT = '', 
		crm.ACCT_PO_BOX = '', 
		crm.ACCT_PO_BOX_CTY = '', 
		crm.ACCT_PO_BOX_LOBBY = '', 
		crm.ACCT_PO_BOX_LOC = '', 
		crm.ACCT_PO_BOX_NUM = '', 
		crm.ACCT_PO_BOX_REG = '', 
		crm.ACCT_POST_CODE2 = '', 
		crm.ACCT_POST_CODE3 = '', 
		crm.ACCT_POSTALAREA = '', 
		crm.ACCT_POSTCODE_ZIP = '', 
		crm.ACCT_PREF_LANGUAGE = '', 
		crm.ACCT_PREF_LANGUAGE_CODE = '', 
		crm.ACCT_REGION_STATE = '', 
		crm.ACCT_REGION_STATE_CODE = '', 
		crm.ACCT_ROOM_NUMBER = '', 
		crm.ACCT_STREET = @RemovalText, 
		crm.ACCT_STREETABBR = '', 
		crm.ACCT_STREETCODE = '', 
		crm.ACCT_SUPPLEMENT_1 = '', 
		crm.ACCT_SUPPLEMENT_2 = '', 
		crm.ACCT_SUPPLEMENT_3 = '', 
		crm.ACCT_TITLE = '', 
		crm.ACCT_TITLE_CODE = '', 
		crm.ACCT_TOWNSHIP = '', 
		crm.ACCT_TOWNSHIP_CODE = '', 
		crm.ACCT_WORK_PHONE_EXTENSION = '', 
		crm.ACCT_WORK_PHONE_PRIMARY = '', 
		crm.ACTIVITY_ID = '', 
		crm.CASE_CASE_CREATION_DATE = '', 
		crm.CASE_CASE_DESC = '', 
		crm.CASE_CASE_EMPL_RESPONSIBLE_NAM = '', 
		crm.CASE_CASE_ID = '', 
		crm.CASE_CASE_SOLVED_DATE = '', 
		crm.CASE_EMPL_RESPONSIBLE_ID = '', 
		crm.CASE_SECON_DEALER_CODE_OF_DEAL = '', 
		crm.CASE_VEH_REG_PLATE = '', 
		crm.CASE_VEH_VIN_NUMBER = @RemovalText, 
		crm.CASE_VEHMODEL_DERIVED_FROM_VIN = '', 
		crm.DMS_LICENSE_PLATE_REGISTRATION = '', 
		crm.DMS_REPAIR_ORDER_CLOSED_DATE = '', 
		crm.DMS_REPAIR_ORDER_NUMBER = '', 
		crm.DMS_REPAIR_ORDER_OPEN_DATE = '', 
		crm.DMS_TOTAL_CUSTOMER_PRICE = NULL, 
		crm.DMS_VIN = @RemovalText, 
		crm.LEAD_IN_MARKET_DATE = '', 
		crm.ROADSIDE_CUSTOMER_SUMMARY_INC = '', 
		crm.ROADSIDE_DATE_CALL_ANSWERED = '', 
		crm.ROADSIDE_DATE_CALL_RECEIVED = '', 
		crm.ROADSIDE_DATE_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_DRIVER_EMAIL = '', 
		crm.ROADSIDE_DRIVER_FIRST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_LAST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_MOBILE = '', 
		crm.ROADSIDE_DRIVER_TITLE = '',  
		crm.ROADSIDE_INCIDENT_DATE = '', 
		crm.ROADSIDE_INCIDENT_ID = '', 
		crm.ROADSIDE_INCIDENT_SUMMARY = '', 
		crm.ROADSIDE_INCIDENT_TIME = '', 
		crm.ROADSIDE_LICENSE_PLATE_REG_NO = '', 
		crm.ROADSIDE_RESOLUTION_TIME = '', 
		crm.ROADSIDE_TIME_CALL_ANSWERED = '', 
		crm.ROADSIDE_TIME_CALL_RECEIVED = '', 
		crm.ROADSIDE_TIME_JOB_COMPLETED = '', 
		crm.ROADSIDE_TIME_RESOURCE_ALL = '', 
		crm.ROADSIDE_TIME_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_TIME_SECON_RES_ALL = '', 
		crm.ROADSIDE_TIME_SECON_RES_ARR = '', 
		crm.ROADSIDE_VIN = @RemovalText, 
		crm.VEH_VIN = @RemovalText,
		crm.VEH_DERIVATIVE = '',
		crm.VEH_BUILD_DATE = '', 
		crm.VEH_CHASSIS_NUMBER = '', 
		crm.VEH_COMMON_ORDER_NUMBER = '',
		crm.VEH_CURR_PLANNED_DELIVERY_DATE = '', 
		crm.VEH_DELIVERED_DATE = '', 
		crm.VEH_DRIVER_FULL_NAME = '', 
		crm.VEH_FEATURE_CODE = '', 
		crm.VEH_MODEL	 = '', 
		crm.VEH_MODEL_DESC = '', 
		crm.VEH_PREDICTED_REPLACEMENT_DATE = '', 
		crm.VEH_REGISTRAT_LICENC_PLATE_NUM = '', 
		crm.VEH_REGISTRATION_DATE = '', 
		crm.VEH_VISTA_CONTRACT_NUMBER = '', 
		crm.VISTACONTRACT_HANDOVER_DATE = '', 
		crm.VISTACONTRACT_SALES_MAN_CD_DES = '',
		crm.VISTACONTRACT_SALES_MAN_FULNAM = '', 
		crm.VISTACONTRACT_SALESMAN_CODE = '', 
		crm.RESPONSE_ID = '', 
		crm.DMS_OTHER_RELATED_SERVICES = ''
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].CRM.RoadsideIncident_Roadside crm ON crm.AuditItemID = odr.OriginatingAuditItemID


	


		-- CRM.Vista_Contract_Sales
		UPDATE crm
		SET crm.Converted_ACCT_DATE_OF_BIRTH = '1900-01-01', 
		crm.Converted_ACCT_DATE_ADVISED_OF_DEATH = '1900-01-01', 
		crm.Converted_VEH_REGISTRATION_DATE = '1900-01-01', 
		crm.Converted_VEH_BUILD_DATE = '1900-01-01', 
		crm.Converted_DMS_REPAIR_ORDER_CLOSED_DATE = '1900-01-01', 
		crm.Converted_ROADSIDE_DATE_JOB_COMPLETED = '1900-01-01', 
		crm.Converted_CASE_CASE_SOLVED_DATE = '1900-01-01', 
		crm.Converted_VISTACONTRACT_HANDOVER_DATE = '1900-01-01', 
		crm.DateTransferredToVWT = '1900-01-01', 
		crm.ACCT_ACADEMIC_TITLE = '', 
		crm.ACCT_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_ACCT_ID = '', 
		crm.ACCT_ADDITIONAL_LAST_NAME = @RemovalText, 
		crm.ACCT_BP_ROLE = '', 
		crm.ACCT_BUILDING = '', 
		crm.ACCT_CITY_CODE = '', 
		crm.ACCT_CITY_CODE2 = '', 
		crm.ACCT_CITY_TOWN = '', 
		crm.ACCT_CITYH_CODE = '', 
		crm.ACCT_COUNTRY = '', 
		crm.ACCT_COUNTRY_CODE = '', 
		crm.ACCT_COUNTY = '', 
		crm.ACCT_COUNTY_CODE = '', 
		crm.ACCT_DATE_ADVISED_OF_DEATH = '', 
		crm.ACCT_DATE_OF_BIRTH = '', 
		crm.ACCT_DEAL_FULNAME_OF_CREAT_DEA = '', 
		crm.ACCT_DISTRICT = '', 
		crm.ACCT_EMPLOYER_NAME = '', 
		crm.ACCT_EXTERN_FINANC_COMP_ACCTID = '', 
		crm.ACCT_FIRST_NAME = @RemovalText, 
		crm.ACCT_FLOOR = '', 
		crm.ACCT_FULL_NAME = @RemovalText, 
		crm.ACCT_GENDER_FEMALE = '', 
		crm.ACCT_GENDER_MALE = '', 
		crm.ACCT_GENDER_UNKNOWN = '', 
		crm.ACCT_GENERATION = '', 
		--crm.ACCT_GERMAN_ONLY_NON_ACAD_CODE = '', -- REMOVED AS REMOVED BUG 16755
		--crm.ACCT_GERMAN_ONLY_NON_ACADEMIC = '', 
		crm.ACCT_HOME_CITY = '', 
		crm.ACCT_HOME_EMAIL_ADDR_PRIMARY = '', 
		crm.ACCT_HOME_PHONE_NUMBER = '', 
		crm.ACCT_HOUSE_NO = '', 
		crm.ACCT_HOUSE_NUM2 = '', 
		crm.ACCT_HOUSE_NUM3 = '', 
		crm.ACCT_INDUSTRY_SECTOR = '', 
		crm.ACCT_INDUSTRY_SECTOR_CODE = '', 
		crm.ACCT_INITIALS = '', 
		crm.ACCT_JAGUAR_IN_MARKET_DATE = '', 
		crm.ACCT_JAGUAR_LOYALTY_STATUS = '', 
		crm.ACCT_KNOWN_AS = '', 
		crm.ACCT_LAND_ROVER_MARKET_DATE = '', 
		crm.ACCT_LAST_NAME = @RemovalText, 
		crm.ACCT_LOCATION = '', 
		crm.ACCT_MIDDLE_NAME = @RemovalText, 
		crm.ACCT_MOBILE_NUMBER = '', 
		crm.ACCT_NAME_1 = '', 
		crm.ACCT_NAME_2 = '', 
		crm.ACCT_NAME_3 = '', 
		crm.ACCT_NAME_4 = '', 
		crm.ACCT_NAME_CO = '', 
		crm.ACCT_NON_ACADEMIC_TITLE = '', 
		crm.ACCT_NON_ACADEMIC_TITLE_CODE = '', 
		crm.ACCT_PCODE1_EXT = '', 
		crm.ACCT_PCODE2_EXT = '', 
		crm.ACCT_PCODE3_EXT = '', 
		crm.ACCT_PO_BOX = '', 
		crm.ACCT_PO_BOX_CTY = '', 
		crm.ACCT_PO_BOX_LOBBY = '', 
		crm.ACCT_PO_BOX_LOC = '', 
		crm.ACCT_PO_BOX_NUM = '', 
		crm.ACCT_PO_BOX_REG = '', 
		crm.ACCT_POST_CODE2 = '', 
		crm.ACCT_POST_CODE3 = '', 
		crm.ACCT_POSTALAREA = '', 
		crm.ACCT_POSTCODE_ZIP = '', 
		crm.ACCT_PREF_LANGUAGE = '', 
		crm.ACCT_PREF_LANGUAGE_CODE = '', 
		crm.ACCT_REGION_STATE = '', 
		crm.ACCT_REGION_STATE_CODE = '', 
		crm.ACCT_ROOM_NUMBER = '', 
		crm.ACCT_STREET = @RemovalText, 
		crm.ACCT_STREETABBR = '', 
		crm.ACCT_STREETCODE = '', 
		crm.ACCT_SUPPLEMENT_1 = '', 
		crm.ACCT_SUPPLEMENT_2 = '', 
		crm.ACCT_SUPPLEMENT_3 = '', 
		crm.ACCT_TITLE = '', 
		crm.ACCT_TITLE_CODE = '', 
		crm.ACCT_TOWNSHIP = '', 
		crm.ACCT_TOWNSHIP_CODE = '', 
		crm.ACCT_WORK_PHONE_EXTENSION = '', 
		crm.ACCT_WORK_PHONE_PRIMARY = '', 
		crm.ACTIVITY_ID = '', 
		crm.CASE_CASE_CREATION_DATE = '', 
		crm.CASE_CASE_DESC = '', 
		crm.CASE_CASE_EMPL_RESPONSIBLE_NAM = '', 
		crm.CASE_CASE_ID = '', 
		crm.CASE_CASE_SOLVED_DATE = '', 
		crm.CASE_EMPL_RESPONSIBLE_ID = '', 
		crm.CASE_SECON_DEALER_CODE_OF_DEAL = '', 
		crm.CASE_VEH_REG_PLATE = '', 
		crm.CASE_VEH_VIN_NUMBER = @RemovalText, 
		crm.CASE_VEHMODEL_DERIVED_FROM_VIN = '', 
		crm.DMS_LICENSE_PLATE_REGISTRATION = '', 
		crm.DMS_REPAIR_ORDER_CLOSED_DATE = '', 
		crm.DMS_REPAIR_ORDER_NUMBER = '', 
		crm.DMS_REPAIR_ORDER_OPEN_DATE = '', 
		crm.DMS_TOTAL_CUSTOMER_PRICE = NULL, 
		crm.DMS_VIN = @RemovalText, 
		crm.LEAD_IN_MARKET_DATE = '', 
		crm.ROADSIDE_CUSTOMER_SUMMARY_INC = '', 
		crm.ROADSIDE_DATE_CALL_ANSWERED = '', 
		crm.ROADSIDE_DATE_CALL_RECEIVED = '', 
		crm.ROADSIDE_DATE_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_DRIVER_EMAIL = '', 
		crm.ROADSIDE_DRIVER_FIRST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_LAST_NAME = @RemovalText, 
		crm.ROADSIDE_DRIVER_MOBILE = '', 
		crm.ROADSIDE_DRIVER_TITLE = '',  
		crm.ROADSIDE_INCIDENT_DATE = '', 
		crm.ROADSIDE_INCIDENT_ID = '', 
		crm.ROADSIDE_INCIDENT_SUMMARY = '', 
		crm.ROADSIDE_INCIDENT_TIME = '', 
		crm.ROADSIDE_LICENSE_PLATE_REG_NO = '', 
		crm.ROADSIDE_RESOLUTION_TIME = '', 
		crm.ROADSIDE_TIME_CALL_ANSWERED = '', 
		crm.ROADSIDE_TIME_CALL_RECEIVED = '', 
		crm.ROADSIDE_TIME_JOB_COMPLETED = '', 
		crm.ROADSIDE_TIME_RESOURCE_ALL = '', 
		crm.ROADSIDE_TIME_RESOURCE_ARRIVED = '', 
		crm.ROADSIDE_TIME_SECON_RES_ALL = '', 
		crm.ROADSIDE_TIME_SECON_RES_ARR = '', 
		crm.ROADSIDE_VIN = @RemovalText, 
		crm.VEH_VIN = @RemovalText,
		crm.VEH_DERIVATIVE = '',
		crm.VEH_BUILD_DATE = '', 
		crm.VEH_CHASSIS_NUMBER = '', 
		crm.VEH_COMMON_ORDER_NUMBER = '',
		crm.VEH_CURR_PLANNED_DELIVERY_DATE = '', 
		crm.VEH_DELIVERED_DATE = '', 
		crm.VEH_DRIVER_FULL_NAME = '', 
		crm.VEH_FEATURE_CODE = '', 
		crm.VEH_MODEL	 = '', 
		crm.VEH_MODEL_DESC = '', 
		crm.VEH_PREDICTED_REPLACEMENT_DATE = '', 
		crm.VEH_REGISTRAT_LICENC_PLATE_NUM = '', 
		crm.VEH_REGISTRATION_DATE = '', 
		crm.VEH_VISTA_CONTRACT_NUMBER = '', 
		crm.VISTACONTRACT_HANDOVER_DATE = '', 
		crm.VISTACONTRACT_SALES_MAN_CD_DES = '',
		crm.VISTACONTRACT_SALES_MAN_FULNAM = '', 
		crm.VISTACONTRACT_SALESMAN_CODE = '', 
		crm.RESPONSE_ID = '', 
		crm.DMS_OTHER_RELATED_SERVICES = ''
		FROM #OriginatingDataRows odr 
		INNER JOIN [$(ETLDB)].CRM.Vista_Contract_Sales crm ON crm.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('CRM.Vista_Contract_Sales', 'Erase details', @@RowCount)





	---------------------------------------------------------------------------------------------------
	-- CRC.CRCEvents
	-- CRC.HistoricalLoadData
	---------------------------------------------------------------------------------------------------


		-- CRC.CRCEvents
		UPDATE crc
		SET crc.DateTransferredToVWT = '1900-01-01',
			crc.ContactId = @RemovalText, 
			crc.AssetId = @RemovalText, 
			crc.UniqueCustomerId = @RemovalText, 
			crc.VehicleRegNumber = @RemovalText, 
			crc.VIN = @RemovalText, 
			crc.VehicleModel = @RemovalText, 
			crc.VehicleDerivative = @RemovalText, 
			crc.VehicleMileage = @RemovalText, 
			crc.VehicleMonthsinService = @RemovalText, 
			crc.CustomerTitle = @RemovalText, 
			crc.CustomerInitial = @RemovalText, 
			crc.CustomerFirstName = @RemovalText, 
			crc.CustomerLastName = @RemovalText, 
			crc.AddressLine1 = @RemovalText, 
			crc.AddressLine2 = @RemovalText, 
			crc.AddressLine3 = @RemovalText, 
			crc.AddressLine4 = @RemovalText, 
			crc.City = @RemovalText, 
			crc.County = @RemovalText, 
			crc.Country = @RemovalText, 
			crc.PostalCode = @RemovalText, 
			crc.PhoneMobile = @RemovalText, 
			crc.PhoneHome = @RemovalText, 
			crc.EmailAddress = @RemovalText, 
			crc.CompanyName = @RemovalText, 
			crc.CaseNumber = @RemovalText, 
			crc.SRCreatedDate = @RemovalText, 
			crc.SRClosedDate = @RemovalText, 
			crc.Owner = @RemovalText, 
			crc.ClosedBy = @RemovalText, 
			crc.Type = @RemovalText, 
			crc.ConvertedSRCreatedDate = '1900-01-01', 
			crc.ConvertedSRClosedDate = '1900-01-01'
		FROM #OriginatingDataRows odr 
		INNER JOIN  [$(ETLDB)].CRC.CRCEvents crc ON crc.AuditItemID = odr.OriginatingAuditItemID
	
		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('CRC.CRCEvents', 'Erase details', @@RowCount)




		-- CRC.HistoricalLoadData
		UPDATE crc
		SET crc.UniqueID = @RemovalText, 
			crc.SampleID = @RemovalText, 
			crc.SampleDate = @RemovalText, 
			crc.samplefile = @RemovalText, 
			crc.RunDateofExtract = @RemovalText, 
			crc.ContactId = @RemovalText, 
			crc.AssetId = @RemovalText, 
			crc.UniqueCustomerId = @RemovalText, 
			crc.VehicleRegNumber = @RemovalText, 
			crc.VIN = @RemovalText, 
			crc.VehicleMileage = @RemovalText, 
			crc.VehicleMonthsinService = @RemovalText, 
			crc.CustomerTitle = @RemovalText, 
			crc.CustomerInitial = @RemovalText, 
			crc.CustomerFirstName = @RemovalText, 
			crc.CustomerLastName = @RemovalText, 
			crc.AddressLine1 = @RemovalText, 
			crc.AddressLine2 = @RemovalText, 
			crc.AddressLine3 = @RemovalText, 
			crc.AddressLine4 = @RemovalText, 
			crc.City = @RemovalText, 
			crc.County = @RemovalText, 
			crc.Country = @RemovalText, 
			crc.PostalCode = @RemovalText, 
			crc.DaytimeTelephoneNumber = @RemovalText, 
			crc.EveningTelephoneNumber = @RemovalText, 
			crc.recEmailAddress = @RemovalText, 
			crc.CompanyName = @RemovalText, 
			crc.RowId = @RemovalText, 
			crc.SRNumber = @RemovalText, 
			crc.SRCreatedDate = @RemovalText, 
			crc.SRClosedDate = @RemovalText, 
			crc.Owner = @RemovalText, 
			crc.ClosedBy = @RemovalText, 
			crc.emailcontact = @RemovalText, 
			crc.vehiclecontact = @RemovalText, 
			crc.customercontact = @RemovalText, 
			crc.surnameaddress = @RemovalText, 
			crc.salutation = @RemovalText, 
			crc.GfkVehicleDescription = @RemovalText, 
			crc.GfKVehicleCode = @RemovalText, 
			crc.RandomID = @RemovalText, 
			crc.GFKCustomerId = @RemovalText, 
			crc.GFKVehicleID = @RemovalText, 
			crc.GfKSalutation = @RemovalText, 
			crc.Salutation_2 = @RemovalText, 
			crc.GfKCaseID = @RemovalText, 
			crc.GfKPassword = @RemovalText, 
			crc.GfKUserID = @RemovalText, 
			crc.GfKContactID = @RemovalText, 
			crc.BL_Postalnonsolicitations_email = @RemovalText, 
			crc.BL_EmailBlacklist_EMAIL = @RemovalText, 
			crc.BL_EmailNonsolicitation_email = @RemovalText, 
			crc.BL_EmailNonsolicitation_Postcode_surname = @RemovalText, 
			crc.BL_EmailNonsolicitation_VIN_email_Surname = @RemovalText, 
			crc.BL_Nonsolicitation_email_surname = @RemovalText, 
			crc.BL_nonsolicitation_postcode_surname = @RemovalText, 
			crc.BL_nonsolicitation_vin_surname = @RemovalText, 
			crc.BL_postalnonsolicitation_Postcode_surname = @RemovalText, 
			crc.BL_Postalnonsolicitation_VIN_Surname = @RemovalText, 
			crc.BL_email_Internal = @RemovalText, 
			crc.surname_email_postcode_vin = @RemovalText, 
			crc.Selection_Month = @RemovalText, 
			crc.Selection_Year = @RemovalText, 
			crc.Reminder = @RemovalText, 
			crc.Reminder_Date = @RemovalText, 
			crc.Reminder_Notes = @RemovalText, 
			crc.Notes_Non_Selection = @RemovalText, 
			crc.OwnerName = @RemovalText
		FROM [$(ETLDB)].CRC.HistoricalLoadData crc 
		WHERE GfKPartyID = @PartyID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('CRC.HistoricalLoadData', 'Erase details', @@RowCount)



	------------------------------------------------------------------------------------------------------------
	-- Roadside.RoadsideEventsProcessed
	--
	--(Roadside.RoadsideEvents				-- manual search required as no links on PartyID available)
	------------------------------------------------------------------------------------------------------------


		-- Roadside.RoadsideEventsProcessed
		UPDATE rep
		SET	rep.VehiclePurchaseDateOrig = @RemovalText, 
			rep.VehicleRegistrationDateOrig = @RemovalText, 
			rep.VehicleDeliveryDateOrig = @RemovalText, 
			rep.ServiceEventDateOrig = @RemovalText, 
			rep.CustomerUniqueId = @RemovalText, 
			rep.CompanyName = @RemovalText, 
			rep.Title = @RemovalText, 
			rep.Firstname = @RemovalText, 
			rep.SurnameField1 = @RemovalText, 
			rep.SurnameField2 = @RemovalText, 
			rep.Salutation = @RemovalText, 
			rep.Address1 = @RemovalText, 
			rep.Address2 = @RemovalText, 
			rep.Address3 = @RemovalText, 
			rep.Address4 = @RemovalText, 
			rep.[Address5(City)] = @RemovalText, 
			rep.[Address6(County)] = @RemovalText, 
			rep.[Address7(Postcode/Zipcode)] = @RemovalText, 
			rep.[Address8(Country)] = @RemovalText, 
			rep.HomeTelephoneNumber = @RemovalText, 
			rep.BusinessTelephoneNumber = @RemovalText, 
			rep.MobileTelephoneNumber = @RemovalText, 
			rep.ModelName = @RemovalText, 
			rep.ModelYear = @RemovalText, 
			rep.Vin = @RemovalText, 
			rep.RegistrationNumber = @RemovalText, 
			rep.EmailAddress1 = @RemovalText, 
			rep.EmailAddress2 = @RemovalText, 
			rep.InvoiceNumber = @RemovalText, 
			rep.InvoiceValue = @RemovalText, 
			rep.ServiceEmployeeCode = @RemovalText, 
			rep.EmployeeName = @RemovalText, 
			rep.OwningCompany = @RemovalText, 
			rep.EmployerCompany = @RemovalText, 
			rep.MonthAndYearOfBirth = @RemovalText, 
			rep.BreakdownDate = '1900-01-01', 
			rep.BreakdownDateOrig = @RemovalText, 
			rep.BreakdownCaseId = @RemovalText, 
			rep.CarHireStartDate = '1900-01-01', 
			rep.CarHireStartDateOrig = @RemovalText, 
			rep.ReasonForHire = @RemovalText, 
			rep.HireGroupBranch = @RemovalText, 
			rep.CarHireTicketNumber = @RemovalText, 
			rep.HireJobNumber = @RemovalText, 
			rep.RepairingDealer = @RemovalText, 
			rep.VehicleReplacementTime = NULL, 
			rep.CarHireStartTime = NULL, 
			rep.ConvertedCarHireStartTime = '1900-01-01', 
			rep.MatchedODSVehicleID = NULL, 
			rep.MatchedODSOrganisationID = NULL, 
			rep.MatchedODSEmailAddress1ID = NULL, 
			rep.MatchedODSEmailAddress2ID = NULL, 
			rep.DateTransferredToVWT = '1900-01-01'
		FROM [$(ETLDB)].Roadside.RoadsideEventsProcessed rep WHERE rep.MatchedODSPersonID = @PartyID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Roadside.RoadsideEventsProcessed', 'Erase details', @@RowCount)

	

	------------------------------------------------------------------------------------------------------
	-- Warranty.WarrantyEventsProcessed
	--
	--(Warranty.WarrantyEvents				-- manual search required as no links on PartyID available)
	------------------------------------------------------------------------------------------------------	

		-- Warranty.WarrantyEventsProcessed
		UPDATE war
		SET war.CICode = NULL, 
			war.ClaimNumber = NULL, 
			war.OverseasDealerCode = NULL, 
			war.VINPrefix = SUBSTRING(@RemovalText, 1, 11), 
			war.ChassisNumber = SUBSTRING(@RemovalText, 12, 6), 
			war.OdometerDistance = NULL, 
			war.ClaimType = NULL, 
			war.DateOfRepairOrig = @RemovalText, 
			war.DateOfRepair = '1900-01-01', 
			war.DateOfSaleOrig = NULL, 
			war.DateOfSale = '1900-01-01', 
			war.MatchedODSVehicleID = 0, 
			war.MatchedODSPersonID = 0, 
			war.MatchedODSOrganisationID = 0, 
			war.DateTransferredToVWT = '1900-01-01', 
			war.RONumber = NULL, 
			war.ROSeqNumber = NULL
		FROM [$(ETLDB)].Warranty.WarrantyEventsProcessed war WHERE war.MatchedODSPersonID = @PartyID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Warranty.WarrantyEventsProcessed', 'Erase details', @@RowCount)


		------------------------------------------------------------------------------------------------------
	-- [GeneralEnquiry].[GeneralEnquiryEvents]
	-- V1.3
	------------------------------------------------------------------------------------------------------	

	UPDATE gg
	SET		gg.ODSEventID = 0,
			gg.DateTransferredToVWT = '1900-01-01',
			gg.CRCCentreCode = @RemovalText,
			gg.MarketCode = @RemovalText,
			gg.BrandCode = @RemovalText,
			gg.GeneralEnquiryDateOrig = @RemovalText,
			gg.UniqueCustomerID = @RemovalText,
			gg.VehicleRegNumber = @RemovalText,
			gg.VIN = @RemovalText,
			gg.VehicleModel = @RemovalText,
			gg.CustomerTitle = @RemovalText,
			gg.CustomerInitial = @RemovalText,
			gg.CustomerFirstName = @RemovalText,
			gg.CustomerLastName = @RemovalText,
			gg.AddressLine1 = @RemovalText,
			gg.AddressLine2 = @RemovalText,
			gg.AddressLine3 = @RemovalText,
			gg.AddressLine4 = @RemovalText,
			gg.City = @RemovalText,
			gg.County = @RemovalText,
			gg.Country = @RemovalText,
			gg.PostalCode = @RemovalText,
			gg.PhoneMobile = @RemovalText,
			gg.PhoneHome = @RemovalText,
			gg.EmailAddress = @RemovalText,
			gg.CompanyName = @RemovalText,
			--gg.RowID dbo.LoadText NULL,
			gg.CommunicationType = @RemovalText,
			gg.EmployeeResponsibleName = @RemovalText,
			gg.GeneralEnquiryDate = '1900-01-01',
			gg.PreferredLanguageID = 0,
			gg.SampleTriggeredSelectionReqID = 0,
			gg.COMPLETE_SUPPRESSION = @RemovalText,
			gg.SUPPRESSION_EMAIL = @RemovalText,
			gg.SUPPRESSION_PHONE = @RemovalText,
			gg.SUPPRESSION_MAIL = @RemovalText,
			gg.CaseNumber = @RemovalText
	FROM #OriginatingDataRows odr 
	INNER JOIN  [$(ETLDB)].[GeneralEnquiry].[GeneralEnquiryEvents] gg ON gg.AuditItemID = odr.OriginatingAuditItemID
	

	-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('GeneralEnquiry.GeneralEnquiryEvents', 'Erase details', @@RowCount)

	

	UPDATE	ge
	SET		ge.PhysicalRowID = 0,
			ge.Converted_ACCT_DATE_OF_BIRTH =  '1901-01-01',
			ge.Converted_ACCT_DATE_ADVISED_OF_DEATH =  '1901-01-01',
			ge.Converted_VEH_REGISTRATION_DATE =  '1901-01-01',
			ge.Converted_VEH_BUILD_DATE =  '1901-01-01',
			ge.Converted_DMS_REPAIR_ORDER_CLOSED_DATE =  '1901-01-01',
			ge.Converted_ROADSIDE_DATE_JOB_COMPLETED =  '1901-01-01',
			ge.Converted_CASE_CASE_SOLVED_DATE =  '1901-01-01',
			ge.Converted_VISTACONTRACT_HANDOVER_DATE =  '1901-01-01',
			ge.Converted_GENERAL_ENQRY_INTERACTION_DATE =  '1901-01-01',
			ge.DateTransferredToVWT =  '1901-01-01',
			ge.SampleTriggeredSelectionReqID = 0,
			ge.Calculated_Salutation = @RemovalText,
			ge.Calculated_Title = @RemovalText,
			ge.ACCT_ACADEMIC_TITLE = @RemovalText,
			ge.ACCT_ACADEMIC_TITLE_CODE = '-',
			ge.ACCT_ACCT_ID = '-',
			ge.ACCT_ACCT_TYPE = @RemovalText,
			ge.ACCT_ACCT_TYPE_CODE = '-',
			ge.ACCT_ADDITIONAL_LAST_NAME = @RemovalText,
			ge.ACCT_BP_ROLE = @RemovalText,
			ge.ACCT_BUILDING = @RemovalText,
			ge.ACCT_CITY_CODE = '-',
			ge.ACCT_CITY_CODE2 = '-',
			ge.ACCT_CITY_TOWN = @RemovalText,
			ge.ACCT_CITYH_CODE = '-',
			ge.ACCT_CORRESPONDENCE_LANG_CODE = '-',
			ge.ACCT_CORRESPONDENCE_LANGUAGE = '-',
			ge.ACCT_COUNTRY = @RemovalText,
			ge.ACCT_COUNTRY_CODE = '-',
			ge.ACCT_COUNTY = @RemovalText,
			ge.ACCT_COUNTY_CODE = '-',
			ge.ACCT_DATE_ADVISED_OF_DEATH = '-',
			ge.ACCT_DATE_DECL_TO_GIVE_EMAIL = '-',
			ge.ACCT_DATE_OF_BIRTH = '-',
			ge.ACCT_DEAL_FULNAME_OF_CREAT_DEA = @RemovalText,
			ge.ACCT_DISTRICT = '-',
			ge.ACCT_EMAIL_VALIDATION_STATUS = @RemovalText,
			ge.ACCT_EMPLOYER_NAME = @RemovalText,
			ge.ACCT_EXTERN_FINANC_COMP_ACCTID = @RemovalText,
			ge.ACCT_FIRST_NAME = @RemovalText,
			ge.ACCT_FLOOR = '-',
			ge.ACCT_FULL_NAME = @RemovalText,
			ge.ACCT_GENDER_FEMALE = '-',
			ge.ACCT_GENDER_MALE = '-',
			ge.ACCT_GENDER_UNKNOWN = '-',
			ge.ACCT_GENERATION = '-',
			ge.ACCT_HOME_CITY = @RemovalText,
			ge.ACCT_HOME_EMAIL_ADDR_PRIMARY = @RemovalText,
			ge.ACCT_HOME_PHONE_NUMBER = @RemovalText,
			ge.ACCT_HOUSE_NO = '-',
			ge.ACCT_HOUSE_NUM2 = '-',
			ge.ACCT_HOUSE_NUM3 = '-',
			ge.ACCT_INDUSTRY_SECTOR = @RemovalText,
			ge.ACCT_INDUSTRY_SECTOR_CODE = '-',
			ge.ACCT_INITIALS = '-',
			ge.ACCT_JAGUAR_IN_MARKET_DATE = '-',
			ge.ACCT_JAGUAR_LOYALTY_STATUS = @RemovalText,
			ge.ACCT_KNOWN_AS = @RemovalText,
			ge.ACCT_LAND_ROVER_LOYALTY_STATUS = @RemovalText,
			ge.ACCT_LAND_ROVER_MARKET_DATE = '-',
			ge.ACCT_LAST_NAME = @RemovalText,
			ge.ACCT_LOCATION = @RemovalText,
			ge.ACCT_MIDDLE_NAME = @RemovalText,
			ge.ACCT_MOBILE_NUMBER = @RemovalText,
			ge.ACCT_NAME_1 = @RemovalText,
			ge.ACCT_NAME_2 = @RemovalText,
			ge.ACCT_NAME_3 = @RemovalText,
			ge.ACCT_NAME_4 = @RemovalText,
			ge.ACCT_NAME_CO = @RemovalText,
			ge.ACCT_NON_ACADEMIC_TITLE = @RemovalText,
			ge.ACCT_NON_ACADEMIC_TITLE_CODE = '-',
			ge.ACCT_ORG_TYPE = @RemovalText,
			ge.ACCT_ORG_TYPE_CODE = '-',
			ge.ACCT_PCODE1_EXT = '-',
			ge.ACCT_PCODE2_EXT = '-',
			ge.ACCT_PCODE3_EXT = '-',
			ge.ACCT_PO_BOX = '-',
			ge.ACCT_PO_BOX_CTY = '-',
			ge.ACCT_PO_BOX_LOBBY = @RemovalText,
			ge.ACCT_PO_BOX_LOC = @RemovalText,
			ge.ACCT_PO_BOX_NUM = '-',
			ge.ACCT_PO_BOX_REG = '-',
			ge.ACCT_POST_CODE2 = '-',
			ge.ACCT_POST_CODE3 = '-',
			ge.ACCT_POSTALAREA = '-',
			ge.ACCT_POSTCODE_ZIP = '-',
			ge.ACCT_PREF_CONTACT_METHOD = @RemovalText,
			ge.ACCT_PREF_CONTACT_METHOD_CODE = '-',
			ge.ACCT_PREF_CONTACT_TIME = @RemovalText,
			ge.ACCT_PREF_LANGUAGE = '-',
			ge.ACCT_PREF_LANGUAGE_CODE = '-',
			ge.ACCT_REGION_STATE = @RemovalText,
			ge.ACCT_REGION_STATE_CODE = '-',
			ge.ACCT_ROOM_NUMBER = '-',
			ge.ACCT_STREET = @RemovalText,
			ge.ACCT_STREETABBR = '-',
			ge.ACCT_STREETCODE = '-',
			ge.ACCT_SUPPLEMENT_1 = @RemovalText,
			ge.ACCT_SUPPLEMENT_2 = @RemovalText,
			ge.ACCT_SUPPLEMENT_3 = @RemovalText,
			ge.ACCT_TITLE = @RemovalText,
			ge.ACCT_TITLE_CODE = '-',
			ge.ACCT_TOWNSHIP = @RemovalText,
			ge.ACCT_TOWNSHIP_CODE = '-',
			ge.ACCT_VIP_FLAG = '-',
			ge.ACCT_WORK_PHONE_EXTENSION = '-',
			ge.ACCT_WORK_PHONE_PRIMARY = @RemovalText,
			ge.CAMPAIGN_CAMPAIGN_CHANNEL = @RemovalText,
			ge.CAMPAIGN_CAMPAIGN_DESC = @RemovalText,
			ge.CAMPAIGN_CAMPAIGN_ID = @RemovalText,
			ge.CAMPAIGN_CATEGORY_1 = @RemovalText,
			ge.CAMPAIGN_CATEGORY_2 = @RemovalText,
			ge.CAMPAIGN_CATEGORY_3 = @RemovalText,
			ge.CAMPAIGN_DEALERFULNAME_DEALER1 = @RemovalText,
			ge.CAMPAIGN_DEALERFULNAME_DEALER2 = @RemovalText,
			ge.CAMPAIGN_DEALERFULNAME_DEALER3 = @RemovalText,
			ge.CAMPAIGN_DEALERFULNAME_DEALER4 = @RemovalText,
			ge.CAMPAIGN_DEALERFULNAME_DEALER5 = @RemovalText,
			ge.CAMPAIGN_SECDEALERCODE_DEALER1 = @RemovalText,
			ge.CAMPAIGN_SECDEALERCODE_DEALER2 = @RemovalText,
			ge.CAMPAIGN_SECDEALERCODE_DEALER3 = @RemovalText,
			ge.CAMPAIGN_SECDEALERCODE_DEALER4 = @RemovalText,
			ge.CAMPAIGN_SECDEALERCODE_DEALER5 = @RemovalText,
			ge.CAMPAIGN_TARGET_GROUP_DESC = @RemovalText,
			ge.CAMPAIGN_TARGET_GROUP_ID = '-',
			ge.CASE_BRAND = @RemovalText,
			ge.CASE_BRAND_CODE = @RemovalText,
			ge.CASE_CASE_CREATION_DATE = '-',
			ge.CASE_CASE_DESC = @RemovalText,
			ge.CASE_CASE_EMPL_RESPONSIBLE_NAM = @RemovalText,
			ge.CASE_CASE_ID = '-',
			ge.CASE_CASE_SOLVED_DATE = '-',
			ge.CASE_EMPL_RESPONSIBLE_ID = '-',
			ge.CASE_GOODWILL_INDICATOR = '-',
			ge.CASE_REASON_FOR_STATUS = @RemovalText,
			ge.CASE_SECON_DEALER_CODE_OF_DEAL = @RemovalText,
			ge.CASE_VEH_REG_PLATE = @RemovalText,
			ge.CASE_VEH_VIN_NUMBER = @RemovalText,
			ge.CASE_VEHMODEL_DERIVED_FROM_VIN = @RemovalText,
			ge.CRH_DEALER_ROA_CITY_TOWN = @RemovalText,
			ge.CRH_DEALER_ROA_COUNTRY = @RemovalText,
			ge.CRH_DEALER_ROA_HOUSE_NO = '-',
			ge.CRH_DEALER_ROA_ID = '-',
			ge.CRH_DEALER_ROA_NAME_1 = @RemovalText,
			ge.CRH_DEALER_ROA_NAME_2 = @RemovalText,
			ge.CRH_DEALER_ROA_PO_BOX = '-',
			ge.CRH_DEALER_ROA_POSTCODE_ZIP = '-',
			ge.CRH_DEALER_ROA_PREFIX_1 = @RemovalText,
			ge.CRH_DEALER_ROA_PREFIX_2 = @RemovalText,
			ge.CRH_DEALER_ROA_REGION_STATE = @RemovalText,
			ge.CRH_DEALER_ROA_STREET = @RemovalText,
			ge.CRH_DEALER_ROA_SUPPLEMENT_1 = @RemovalText,
			ge.CRH_DEALER_ROA_SUPPLEMENT_2 = @RemovalText,
			ge.CRH_DEALER_ROA_SUPPLEMENT_3 = @RemovalText,
			ge.CRH_END_DATE = '-',
			ge.CRH_START_DATE = '-',
			ge.DMS_ACTIVITY_DESC = @RemovalText,
			ge.DMS_DAYS_OPEN = '-',
			ge.DMS_EVENT_TYPE = '-',
			ge.DMS_LICENSE_PLATE_REGISTRATION = '-',
			ge.DMS_POTENTIAL_CHANGE_OF_OWNERS = '-',
			ge.DMS_REPAIR_ORDER_CLOSED_DATE = '-',
			ge.DMS_REPAIR_ORDER_NUMBER = @RemovalText,
			ge.DMS_REPAIR_ORDER_OPEN_DATE = '-',
			ge.DMS_SECON_DEALER_CODE = @RemovalText,
			ge.DMS_SERVICE_ADVISOR = @RemovalText,
			ge.DMS_SERVICE_ADVISOR_ID = '-',
			ge.DMS_TECHNICIAN_ID = '-',
			ge.DMS_TECHNICIAN = @RemovalText,
			ge.DMS_USER_STATUS = @RemovalText,
			ge.DMS_USER_STATUS_CODE = '-',
			ge.DMS_VIN = @RemovalText,
			ge.LEAD_BRAND_CODE = '-',
			ge.LEAD_EMP_RESPONSIBLE_DEAL_NAME = @RemovalText,
			ge.LEAD_ENQUIRY_TYPE_CODE = '-',
			ge.LEAD_FUEL_TYPE_CODE = '-',
			ge.LEAD_IN_MARKET_DATE = '-',
			ge.LEAD_LEAD_CATEGORY_CODE = '-',
			ge.LEAD_LEAD_STATUS_CODE = @RemovalText,
			ge.LEAD_MODEL_OF_INTEREST_CODE = '-',
			ge.LEAD_MODEL_YEAR = '-',
			ge.LEAD_NEW_USED_INDICATOR = '-',
			ge.LEAD_ORIGIN_CODE = '-',
			ge.LEAD_PRE_LAUNCH_MODEL = '-',
			ge.LEAD_PREF_CONTACT_METHOD = '-',
			ge.LEAD_SECON_DEALER_CODE = @RemovalText,
			ge.LEAD_VEH_SALE_TYPE_CODE = '-',
			ge.ROADSIDE_ACTIVE_STATUS_CODE = '-',
			ge.ROADSIDE_ACTIVITY_DESC = @RemovalText,
			ge.ROADSIDE_COUNTRY_ISO_CODE = '-',
			ge.ROADSIDE_CUSTOMER_SUMMARY_INC = '-',
			ge.ROADSIDE_DATA_SOURCE = @RemovalText,
			ge.ROADSIDE_DATE_CALL_ANSWERED = '-',
			ge.ROADSIDE_DATE_CALL_RECEIVED = '-',
			ge.ROADSIDE_DATE_JOB_COMPLETED = '-',
			ge.ROADSIDE_DATE_RESOURCE_ALL = '-',
			ge.ROADSIDE_DATE_RESOURCE_ARRIVED = '-',
			ge.ROADSIDE_DATE_SECON_RES_ALL = '-',
			ge.ROADSIDE_DATE_SECON_RES_ARR = '-',
			ge.ROADSIDE_DRIVER_EMAIL = @RemovalText,
			ge.ROADSIDE_DRIVER_FIRST_NAME = @RemovalText,
			ge.ROADSIDE_DRIVER_LAST_NAME = @RemovalText,
			ge.ROADSIDE_DRIVER_MOBILE = @RemovalText,
			ge.ROADSIDE_DRIVER_TITLE = @RemovalText,
			ge.ROADSIDE_INCIDENT_CATEGORY = @RemovalText,
			ge.ROADSIDE_INCIDENT_COUNTRY = '-',
			ge.ROADSIDE_INCIDENT_DATE = '-',
			ge.ROADSIDE_INCIDENT_ID = @RemovalText,
			ge.ROADSIDE_INCIDENT_SUMMARY = '-',
			ge.ROADSIDE_INCIDENT_TIME = @RemovalText,
			ge.ROADSIDE_LICENSE_PLATE_REG_NO = '-',
			ge.ROADSIDE_PROVIDER = @RemovalText,
			ge.ROADSIDE_REPAIRING_SEC_DEAL_CD = @RemovalText,
			ge.ROADSIDE_RESOLUTION_TIME = @RemovalText,
			ge.ROADSIDE_TIME_CALL_ANSWERED = @RemovalText,
			ge.ROADSIDE_TIME_CALL_RECEIVED = @RemovalText,
			ge.ROADSIDE_TIME_JOB_COMPLETED = @RemovalText,
			ge.ROADSIDE_TIME_RESOURCE_ALL = @RemovalText,
			ge.ROADSIDE_TIME_RESOURCE_ARRIVED = @RemovalText,
			ge.ROADSIDE_TIME_SECON_RES_ALL = @RemovalText,
			ge.ROADSIDE_TIME_SECON_RES_ARR = @RemovalText,
			ge.ROADSIDE_VIN = @RemovalText,
			ge.ROADSIDE_WAIT_TIME = @RemovalText,
			ge.VEH_BRAND = '-',
			ge.VEH_BUILD_DATE = '-',
			ge.VEH_CHASSIS_NUMBER = @RemovalText,
			ge.VEH_COMMON_ORDER_NUMBER = @RemovalText,
			ge.VEH_COUNTRY_EQUIPMENT_CODE = @RemovalText,
			ge.VEH_CREATING_DEALER = @RemovalText,
			ge.VEH_CURR_PLANNED_DELIVERY_DATE = '-',
			ge.VEH_CURRENT_PLANNED_BUILD_DATE = '-',
			ge.VEH_DEA_NAME_LAST_SELLING_DEAL = @RemovalText,
			ge.VEH_DEALER_NAME_OF_SELLING_DEA = @RemovalText,
			ge.VEH_DELIVERED_DATE = '-',
			ge.VEH_DERIVATIVE = @RemovalText,
			ge.VEH_DRIVER_FULL_NAME = @RemovalText,
			ge.VEH_ENGINE_SIZE = @RemovalText,
			ge.VEH_EXTERIOR_COLOUR_CODE = '-',
			ge.VEH_EXTERIOR_COLOUR_DESC = @RemovalText,
			ge.VEH_EXTERIOR_COLOUR_SUPPL_CODE = '-',
			ge.VEH_EXTERIOR_COLOUR_SUPPL_DESC = @RemovalText,
			ge.VEH_FEATURE_CODE = '-',
			ge.VEH_FINANCE_PROD = @RemovalText,
			ge.VEH_FIRST_RETAIL_SALE = '-',
			ge.VEH_FUEL_TYPE_CODE = '-',
			ge.VEH_MODEL = @RemovalText,
			ge.VEH_MODEL_DESC = @RemovalText,
			ge.VEH_MODEL_YEAR = '-',
			ge.VEH_NUM_OF_OWNERS_RELATIONSHIP = 0,
			ge.VEH_ORIGIN = @RemovalText,
			ge.VEH_OWNERSHIP_STATUS = '-',
			ge.VEH_OWNERSHIP_STATUS_CODE = '-',
			ge.VEH_PAYMENT_TYPE = @RemovalText,
			ge.VEH_PREDICTED_REPLACEMENT_DATE = '-',
			ge.VEH_REACQUIRED_INDICATOR = '-',
			ge.VEH_REGISTRAT_LICENC_PLATE_NUM = '-',
			ge.VEH_REGISTRATION_DATE = '-',
			ge.VEH_SALE_TYPE_DESC = @RemovalText,
			ge.VEH_VIN = @RemovalText,
			ge.VEH_VISTA_CONTRACT_NUMBER = @RemovalText,
			ge.VISTACONTRACT_COMM_TY_SALE_DS = @RemovalText,
			ge.VISTACONTRACT_HANDOVER_DATE = '-',
			ge.VISTACONTRACT_PREV_VEH_BRAND = @RemovalText,
			ge.VISTACONTRACT_PREV_VEH_MODEL = @RemovalText,
			ge.VISTACONTRACT_SALES_MAN_FULNAM = @RemovalText,
			ge.VISTACONTRACT_SALESMAN_CODE = @RemovalText,
			ge.VISTACONTRACT_SECON_DEALER_CD = @RemovalText,
			ge.VISTACONTRACT_TRADE_IN_MANUFAC = @RemovalText,
			ge.VISTACONTRACT_TRADE_IN_MODEL = @RemovalText,
			ge.VISTACONTRACT_ACTIVITY_CATEGRY = '-',
			ge.VISTACONTRACT_RETAIL_PRICE = 0,
			ge.VEH_APPR_WARNTY_TYPE = @RemovalText,
			ge.VEH_APPR_WARNTY_TYPE_DESC = @RemovalText,
			ge.VISTACONTRACTNAPPRO_RETAIL_WAR = '-',
			ge.VISTACONTRACTNAPPRO_RETAIL_DES = @RemovalText,
			ge.VISTACONTRACT_EXT_WARR = '-',
			ge.VISTACONTRACT_EXT_WARR_DESC = @RemovalText,
			ge.RESPONSE_ID = '-',
			ge.DMS_OTHER_RELATED_SERVICES = '-',
			ge.VEH_SALE_TYPE_CODE = '-',
			ge.VISTACONTRACT_COMM_TY_SALE_CD = '-',
			ge.LEAD_STATUS_REASON_LEV1_DESC = @RemovalText,
			ge.LEAD_STATUS_REASON_LEV1_COD = @RemovalText,
			ge.LEAD_STATUS_REASON_LEV2_DESC = @RemovalText,
			ge.LEAD_STATUS_REASON_LEV2_COD = @RemovalText,
			ge.LEAD_STATUS_REASON_LEV3_DESC = @RemovalText,
			ge.LEAD_STATUS_REASON_LEV3_COD = @RemovalText,
			ge.JAGDIGITALEVENTSEXP = '-',
			ge.JAGDIGITALINCONTROL = '-',
			ge.JAGDIGITALOWNERVEHCOMM = '-',
			ge.JAGDIGITALPARTNERSSPONSORS = '-',
			ge.JAGDIGITALPRODSERV = '-',
			ge.JAGDIGITALPROMOTIONSOFFERS = '-',
			ge.JAGDIGITALSURVEYSRESEARCH = '-',
			ge.JAGEMAILEVENTSEXP = '-',
			ge.JAGEMAILINCONTROL = '-',
			ge.JAGEMAILOWNERVEHCOMM = '-',
			ge.JAGEMAILPARTNERSSPONSORS = '-',
			ge.JAGEMAILPRODSERV = '-',
			ge.JAGEMAILPROMOTIONSOFFERS = '-',
			ge.JAGEMAILSURVEYSRESEARCH = '-',
			ge.JAGPHONEEVENTSEXP = '-',
			ge.JAGPHONEINCONTROL = '-',
			ge.JAGPHONEOWNERVEHCOMM = '-',
			ge.JAGPHONEPARTNERSSPONSORS = '-',
			ge.JAGPHONEPRODSERV = '-',
			ge.JAGPHONEPROMOTIONSOFFERS = '-',
			ge.JAGPHONESURVEYSRESEARCH = '-',
			ge.JAGPOSTEVENTSEXP = '-',
			ge.JAGPOSTINCONTROL = '-',
			ge.JAGPOSTOWNERVEHCOMM = '-',
			ge.JAGPOSTPARTNERSSPONSORS = '-',
			ge.JAGPOSTPRODSERV = '-',
			ge.JAGPOSTPROMOTIONSOFFERS = '-',
			ge.JAGPOSTSURVEYSRESEARCH = '-',
			ge.JAGSMSEVENTSEXP = '-',
			ge.JAGSMSINCONTROL = '-',
			ge.JAGSMSOWNERVEHCOMM = '-',
			ge.JAGSMSPARTNERSSPONSORS = '-',
			ge.JAGSMSPRODSERV = '-',
			ge.JAGSMSPROMOTIONSOFFERS = '-',
			ge.JAGSMSSURVEYSRESEARCH = '-',
			ge.LRDIGITALEVENTSEXP = '-',
			ge.LRDIGITALINCONTROL = '-',
			ge.LRDIGITALOWNERVEHCOMM = '-',
			ge.LRDIGITALPARTNERSSPONSORS = '-',
			ge.LRDIGITALPRODSERV = '-',
			ge.LRDIGITALPROMOTIONSOFFERS = '-',
			ge.LRDIGITALSURVEYSRESEARCH = '-',
			ge.LREMAILEVENTSEXP = '-',
			ge.LREMAILINCONTROL = '-',
			ge.LREMAILOWNERVEHCOMM = '-',
			ge.LREMAILPARTNERSSPONSORS = '-',
			ge.LREMAILPRODSERV = '-',
			ge.LREMAILPROMOTIONSOFFERS = '-',
			ge.LREMAILSURVEYSRESEARCH = '-',
			ge.LRPHONEEVENTSEXP = '-',
			ge.LRPHONEINCONTROL = '-',
			ge.LRPHONEOWNERVEHCOMM = '-',
			ge.LRPHONEPARTNERSSPONSORS = '-',
			ge.LRPHONEPRODSERV = '-',
			ge.LRPHONEPROMOTIONSOFFERS = '-',
			ge.LRPHONESURVEYSRESEARCH = '-',
			ge.LRPOSTEVENTSEXP = '-',
			ge.LRPOSTINCONTROL = '-',
			ge.LRPOSTOWNERVEHCOMM = '-',
			ge.LRPOSTPARTNERSSPONSORS = '-',
			ge.LRPOSTPRODSERV = '-',
			ge.LRPOSTPROMOTIONSOFFERS = '-',
			ge.LRPOSTSURVEYSRESEARCH = '-',
			ge.LRSMSEVENTSEXP = '-',
			ge.LRSMSINCONTROL = '-',
			ge.LRSMSOWNERVEHCOMM = '-',
			ge.LRSMSPARTNERSSPONSORS = '-',
			ge.LRSMSPRODSERV = '-',
			ge.LRSMSPROMOTIONSOFFERS = '-',
			ge.LRSMSSURVEYSRESEARCH = '-',
			ge.ACCT_NAME_PREFIX_CODE = '-',
			ge.ACCT_NAME_PREFIX = @RemovalText,
			ge.DMS_REPAIR_ORDER_NUMBER_UNIQUE = @RemovalText,
			ge.DMS_TOTAL_CUSTOMER_PRICE = 0,
			ge.VISTACONTRACT_COMMON_ORDER_NUM = @RemovalText,
			ge.VEH_FUEL_TYPE = @RemovalText,
			ge.CNT_ABTNR = '-',
			ge.CNT_ADDRESS = @RemovalText,
			ge.CNT_DPRTMNT = @RemovalText,
			ge.CNT_FIRST_NAME = @RemovalText,
			ge.CNT_FNCTN = @RemovalText,
			ge.CNT_LAST_NAME = @RemovalText,
			ge.CNT_PAFKT = '-',
			ge.CNT_RELTYP = '-',
			ge.CNT_TEL_NUMBER = @RemovalText,
			ge.CONTACT_PER_ID = '-',
			ge.ACCT_NAME_CREATING_DEA = @RemovalText,
			ge.CNT_MOBILE_PHONE = @RemovalText,
			ge.CNT_ACADEMIC_TITLE = @RemovalText,
			ge.CNT_ACADEMIC_TITLE_CODE = '-',
			ge.CNT_NAME_PREFIX_CODE = '-',
			ge.CNT_NAME_PREFIX = @RemovalText,
			ge.CNT_JAGDIGITALEVENTSEXP = '-',
			ge.CNT_JAGDIGITALINCONTROL = '-',
			ge.CNT_JAGDIGITALOWNERVEHCOMM = '-',
			ge.CNT_JAGDIGITALPARTNERSSPONSORS = '-',
			ge.CNT_JAGDIGITALPRODSERV = '-',
			ge.CNT_JAGDIGITALPROMOTIONSOFFERS = '-',
			ge.CNT_JAGDIGITALSURVEYSRESEARCH = '-',
			ge.CNT_JAGEMAILEVENTSEXP = '-',
			ge.CNT_JAGEMAILINCONTROL = '-',
			ge.CNT_JAGEMAILOWNERVEHCOMM = '-',
			ge.CNT_JAGEMAILPARTNERSSPONSORS = '-',
			ge.CNT_JAGEMAILPRODSERV = '-',
			ge.CNT_JAGEMAILPROMOTIONSOFFERS = '-',
			ge.CNT_JAGEMAILSURVEYSRESEARCH = '-',
			ge.CNT_JAGPHONEEVENTSEXP = '-',
			ge.CNT_JAGPHONEINCONTROL = '-',
			ge.CNT_JAGPHONEOWNERVEHCOMM = '-',
			ge.CNT_JAGPHONEPARTNERSSPONSORS = '-',
			ge.CNT_JAGPHONEPRODSERV = '-',
			ge.CNT_JAGPHONEPROMOTIONSOFFERS = '-',
			ge.CNT_JAGPHONESURVEYSRESEARCH = '-',
			ge.CNT_JAGPOSTEVENTSEXP = '-',
			ge.CNT_JAGPOSTINCONTROL = '-',
			ge.CNT_JAGPOSTOWNERVEHCOMM = '-',
			ge.CNT_JAGPOSTPARTNERSSPONSORS = '-',
			ge.CNT_JAGPOSTPRODSERV = '-',
			ge.CNT_JAGPOSTPROMOTIONSOFFERS = '-',
			ge.CNT_JAGPOSTSURVEYSRESEARCH = '-',
			ge.CNT_JAGSMSEVENTSEXP = '-',
			ge.CNT_JAGSMSINCONTROL = '-',
			ge.CNT_JAGSMSOWNERVEHCOMM = '-',
			ge.CNT_JAGSMSPARTNERSSPONSORS = '-',
			ge.CNT_JAGSMSPRODSERV = '-',
			ge.CNT_JAGSMSPROMOTIONSOFFERS = '-',
			ge.CNT_JAGSMSSURVEYSRESEARCH = '-',
			ge.CNT_LRDIGITALEVENTSEXP = '-',
			ge.CNT_LRDIGITALINCONTROL = '-',
			ge.CNT_LRDIGITALOWNERVEHCOMM = '-',
			ge.CNT_LRDIGITALPARTNERSSPONSORS = '-',
			ge.CNT_LRDIGITALPRODSERV = '-',
			ge.CNT_LRDIGITALPROMOTIONSOFFERS = '-',
			ge.CNT_LRDIGITALSURVEYSRESEARCH = '-',
			ge.CNT_LREMAILEVENTSEXP = '-',
			ge.CNT_LREMAILINCONTROL = '-',
			ge.CNT_LREMAILOWNERVEHCOMM = '-',
			ge.CNT_LREMAILPARTNERSSPONSORS = '-',
			ge.CNT_LREMAILPRODSERV = '-',
			ge.CNT_LREMAILPROMOTIONSOFFERS = '-',
			ge.CNT_LREMAILSURVEYSRESEARCH = '-',
			ge.CNT_LRPHONEEVENTSEXP = '-',
			ge.CNT_LRPHONEINCONTROL = '-',
			ge.CNT_LRPHONEOWNERVEHCOMM = '-',
			ge.CNT_LRPHONEPARTNERSSPONSORS = '-',
			ge.CNT_LRPHONEPRODSERV = '-',
			ge.CNT_LRPHONEPROMOTIONSOFFERS = '-',
			ge.CNT_LRPHONESURVEYSRESEARCH = '-',
			ge.CNT_LRPOSTEVENTSEXP = '-',
			ge.CNT_LRPOSTINCONTROL = '-',
			ge.CNT_LRPOSTOWNERVEHCOMM = '-',
			ge.CNT_LRPOSTPARTNERSSPONSORS = '-',
			ge.CNT_LRPOSTPRODSERV = '-',
			ge.CNT_LRPOSTPROMOTIONSOFFERS = '-',
			ge.CNT_LRPOSTSURVEYSRESEARCH = '-',
			ge.CNT_LRSMSEVENTSEXP = '-',
			ge.CNT_LRSMSINCONTROL = '-',
			ge.CNT_LRSMSOWNERVEHCOMM = '-',
			ge.CNT_LRSMSPARTNERSSPONSORS = '-',
			ge.CNT_LRSMSPRODSERV = '-',
			ge.CNT_LRSMSPROMOTIONSOFFERS = '-',
			ge.CNT_LRSMSSURVEYSRESEARCH = '-',
			ge.CNT_TITLE = @RemovalText,
			ge.CNT_TITLE_CODE = '-',
			ge.CNT_PREF_LANGUAGE = '-',
			ge.CNT_PREF_LANGUAGE_CODE = '-',
			ge.CNT_NON_ACADEMIC_TITLE_CODE = '-',
			ge.CNT_NON_ACADEMIC_TITLE = @RemovalText,
			ge.CNT_PREF_LAST_NAME = @RemovalText,
			ge.ACCT_PREF_LAST_NAME = @RemovalText,
			ge.GENERAL_ENQUIRY_BRAND = @RemovalText,
			ge.GENERAL_ENQUIRY_COMM_TYPE = @RemovalText,
			ge.GENERAL_ENQRY_INTERACTION_DATE = '-',
			ge.GENERAL_ENQUIRY_EMP_RES_NAME = @RemovalText,
			ge.GENERAL_ENQUIRYY_VEH_REG_NO = '-',
			ge.GENERAL_ENQUIRY_VIN_NO = @RemovalText
	FROM #OriginatingDataRows odr 
	INNER JOIN  [$(ETLDB)].CRM.General_Enquiry ge ON ge.AuditItemID = odr.OriginatingAuditItemID
	

	-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('CRM.General_Enquiry', 'Erase details', @@RowCount)
	
	------------------------------------------------------------------------------------------------------
	--
	-- Erase AUDIT TABLES (not used in matching)
	--
	------------------------------------------------------------------------------------------------------


		-- Audit.CustomerUpdate_EmailAddress
		UPDATE aud
		SET aud.EmailAddress = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_EmailAddress aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.CustomerUpdate_EmailAddress', 'Erase details', @@RowCount)





	
		-- Audit.CustomerUpdate_PostalAddress
		UPDATE aud
		SET aud.Address1 = @RemovalText, 
			aud.Address2 = @RemovalText, 
			aud.Address3 = @RemovalText, 
			aud.Address4 = @RemovalText, 
			aud.Address5 = @RemovalText, 
			aud.Address6 = @RemovalText, 
			aud.Address7 = @RemovalText, 
			aud.BuildingName = @RemovalText, 
			aud.SubStreetNumber = @RemovalText, 
			aud.SubStreet = @RemovalText, 
			aud.SubStreetAndNumber = @RemovalText, 
			aud.StreetNumber = @RemovalText, 
			aud.Street = @RemovalText, 
			aud.StreetAndNumber = @RemovalText, 
			aud.SubLocality = @RemovalText, 
			aud.Locality = @RemovalText, 
			aud.Town = @RemovalText, 
			aud.Region = @RemovalText, 
			aud.PostCode = @RemovalText, 
			aud.ContactMechanismID = 0, 
			aud.DateProcessed = '1900-01-01'
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_PostalAddress aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.CustomerUpdate_PostalAddress', 'Erase details', @@RowCount)




		-- Audit.CustomerUpdate_TelephoneNumber
		UPDATE aud
		SET aud.HomeTelephoneNumberContactMechanismID = 0,	
			aud.WorkTelephoneContactMechanismID	= 0,
			aud.MobileNumberContactMechanismID = 0 ,
			aud.HomeTelephoneNumber = @RemovalText, 
			aud.WorkTelephoneNumber = @RemovalText, 	
			aud.MobileNumber = @RemovalText, 
			aud.DateProcessed = '1900-01-01'
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.CustomerUpdate_TelephoneNumber', 'Erase details', @@RowCount)





		-- Audit.CustomerUpdate_Organisation
		UPDATE aud
		SET aud.OrganisationName = @RemovalText, 
			aud.OrganisationPartyID = @DummyOrganisationID,
			aud.DateProcessed = '1900-01-01'
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Organisation aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.CustomerUpdate_Organisation', 'Erase details', @@RowCount)





		-- Audit.CustomerUpdate_Person
		UPDATE aud
		SET aud.Title = @RemovalText, 
			aud.FirstName = @RemovalText, 
			aud.LastName = @RemovalText, 
			aud.SecondLastName = @RemovalText, 
			aud.TitleID = 0, 
			aud.DateProcessed = '1900-01-01'
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Person aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.CustomerUpdate_Person', 'Erase details', @@RowCount)








		--Audit.CustomerUpdate_RegistrationNumber
		UPDATE aud
		SET aud.RegNumber = @RemovalText, 
			aud.DateProcessed = '1900-01-01'
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_RegistrationNumber aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.CustomerUpdate_RegistrationNumber', 'Erase details', @@RowCount)





		-- Audit.AdditionalInfoSales
		UPDATE aud
		SET SalesOrderNumber = @RemovalText, 
			Salesman = @RemovalText, 
			ContractCustomer = @RemovalText, 
			SalesmanCode = @RemovalText, 
			InvoiceNumber = @RemovalText, 
			InvoiceValue = @RemovalText, 
			OwningCompany = @RemovalText, 
			EmployerCompany = @RemovalText, 
			VehiclePurchaseDate = @RemovalText, 
			VehicleDeliveryDate = @RemovalText, 
			LostLead_DateOfLeadCreation = @RemovalText, 
			ServiceAdvisorID = @RemovalText, 
			ServiceAdvisorName = @RemovalText, 
			TechnicianID = @RemovalText, 
			TechnicianName = @RemovalText, 
			VehicleSalePrice = @RemovalText, 
			SalesAdvisorID = @RemovalText, 
			SalesAdvisorName = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.AdditionalInfoSales aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.AdditionalInfoSales', 'Erase details', @@RowCount)






		-- Audit.Events
		UPDATE aud
		SET aud.EventDate = '1900-01-01',
			aud.InvoiceDate = '1900-01-01',
			aud.EventDateOrig = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.Events aud ON aud.AuditItemID = odr.OriginatingAuditItemID

	
		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.Events', 'Erase details', @@RowCount)





		-- Audit.CustomerRelationships
		UPDATE aud
		SET aud.CustomerIdentifier = @RemovalText,
			aud.CustomerIdentifierUsable = 0
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.CustomerRelationships aud ON aud.AuditItemID = odr.OriginatingAuditItemID

	
		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.CustomerRelationships', 'Erase details', @@RowCount)






		-- Audit.LandRover_Brazil_Sales_Contract
		UPDATE aud
		SET PartnerUniqueID    = @RemovalText,
			CommonOrderNumber  = @RemovalText,
			VIN                = @RemovalText,
			ContractNo         = @RemovalText,
			ContractVersion    = @RemovalText,
			CustomerID         = @RemovalText,
			CancelDate         = @RemovalText,
			ContractDate       = @RemovalText,
			HandoverDate       = @RemovalText,
			DealerReference    = @RemovalText,
			DateCreated        = @RemovalText,
			CreatedBy          = @RemovalText,
			LastUpdatedBy      = @RemovalText,
			LastUpdated        = @RemovalText,
			Customers          = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.LandRover_Brazil_Sales_Contract aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.LandRover_Brazil_Sales_Contract', 'Erase details', @@RowCount)






		-- Audit.LandRover_Brazil_Sales_Customer
		UPDATE aud
		SET PartnerUniqueID   = @RemovalText,
			CustomerID        = @RemovalText,
			Surname           = @RemovalText,
			Forename          = @RemovalText,
			Title             = @RemovalText,
			DateOfBirth       = @RemovalText,
			Occupation        = @RemovalText,
			Email             = @RemovalText,
			MobileTelephone   = @RemovalText,
			HomeTelephone     = @RemovalText,
			WorkTelephone     = @RemovalText,
			Address1          = @RemovalText,
			Address2          = @RemovalText,
			PostCode          = @RemovalText,
			Town              = @RemovalText,
			Country           = @RemovalText,
			CompanyName       = @RemovalText,
			State             = @RemovalText,
			PersonalTaxNumber = @RemovalText,
			CompanyTaxNumber  = @RemovalText,
			MaritalStatus     = @RemovalText,
			DateCreated       = @RemovalText,
			CreatedBy         = @RemovalText,
			LastUpdatedBy     = @RemovalText,
			LastUpdated       = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.LandRover_Brazil_Sales_Customer aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.LandRover_Brazil_Sales_Customer', 'Erase details', @@RowCount)







		-- Audit.LegalOrganisations
		DELETE aud
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.LegalOrganisations aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.LegalOrganisations', 'Delete record', @@RowCount)






		-- Audit.LegalOrganisationsByLanguage
		DELETE aud
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.LegalOrganisationsByLanguage aud ON aud.AuditItemID = odr.OriginatingAuditItemID
	
		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.LegalOrganisationsByLanguage', 'Delete record', @@RowCount)






		-- Audit.Organisations
		UPDATE aud
		SET aud.PartyID = @DummyOrganisationID,
			aud.OrganisationName = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.Organisations aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.Organisations', 'Erase details', @@RowCount)





		
		-- Audit.PartySalutations
		UPDATE aud
		SET Salutation = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.PartySalutations aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.PartySalutations', 'Erase details', @@RowCount)





	
		-- Audit.People
		UPDATE aud
		SET TitleID = 0, 
			Title = @RemovalText, 
			Initials = @RemovalText, 
			FirstName = @RemovalText, 
			FirstNameOrig = @RemovalText, 
			MiddleName = @RemovalText, 
			LastName = @RemovalText, 
			LastNameOrig = @RemovalText, 
			SecondLastName = @RemovalText, 
			SecondLastNameOrig = @RemovalText, 
			BirthDate = '1900-01-01',
			GenderID = NULL
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.People aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.People', 'Erase details', @@RowCount)






		-- Audit.EmailAddresses
		UPDATE aud
		SET aud.ContactMechanismID = @DummyEmailID,
			aud.EmailAddress = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.EmailAddresses aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.EmailAddresses', 'Erase details', @@RowCount)





		-- Audit.SelectionOutput
		UPDATE aud
		SET FullModel = @RemovalText, 
			Model = @RemovalText, 
			CarReg = @RemovalText, 
			RegistrationDate = '1900-01-01', 
			VIN = @RemovalText, 
			Title = @RemovalText, 
			Initial = @RemovalText, 
			Surname = @RemovalText, 
			Fullname = @RemovalText, 
			DearName = @RemovalText, 
			CoName = @RemovalText, 
			Add1 = @RemovalText, 
			Add2 = @RemovalText, 
			Add3 = @RemovalText, 
			Add4 = @RemovalText, 
			Add5 = @RemovalText, 
			Add6 = @RemovalText, 
			Add7 = @RemovalText, 
			Add8 = @RemovalText, 
			Add9 = @RemovalText, 
			CTRY = @RemovalText, 
			EmailAddress = @RemovalText, 
			Dealer = @RemovalText, 
			sno = @RemovalText, 
			ccode = NULL, 
			modelcode = NULL, 
			lang = NULL, 
			manuf = NULL, 
			gender = NULL, 
			reminder = NULL, 
			week = NULL, 
			SalesServiceFile = NULL, 
			LandPhone = @RemovalText, 
			WorkPhone = @RemovalText, 
			MobilePhone = @RemovalText, 
			DateOutput = '1900-01-01' ,
			Expired = NULL, 
			EmployeeCode = NULL, 
			EmployeeName = NULL, 
			URL = NULL, 
			PilotCode = NULL, 
			CallRecordingsCount = NULL, 
			TimeZone = NULL, 
			CallOutcome = NULL, 
			PhoneNumber = @RemovalText, 
			PhoneSource = NULL, 
			Language = NULL, 
			ExpirationTime = NULL, 
			HomePhoneNumber = @RemovalText, 
			WorkPhoneNumber = @RemovalText, 
			MobilePhoneNumber = @RemovalText, 
			Owner = @RemovalText, 
			OwnerCode = @RemovalText, 
			CRCCode = NULL, 
			MarketCode = NULL, 
			SampleYear = NULL, 
			VehicleMileage = NULL, 
			VehicleMonthsinService = NULL, 
			ModelSummary = NULL, 
			IntervalPeriod = NULL, 
			VistaContractOrderNumber = NULL, 
			DealNo = NULL, 
			RepairOrderNumber = NULL, 
			FOBCode = NULL, 
			SVOvehicle = NULL, 
			SRNumber = @RemovalText, 
			DearNameBilingual = @RemovalText,
			CustomerIdentifier = @RemovalText,		
			EventDate = '1900-01-01', 
			FileDate = NULL, 
			GDDDealerCode = NULL, 
			ManufacturerDealerCode = NULL, 
			Market = NULL, 
			ModelVariant = NULL, 
			ModelYear = NULL, 
			OutletPartyID = NULL, 
			OwnershipCycle = NULL, 
			Password = NULL, 
			ReportingDealerPartyID = NULL, 
			Telephone = NULL
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.SelectionOutput aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.SelectionOutput', 'Erase details', @@RowCount)






		-- Audit.Titles
		UPDATE aud
		SET aud.TitleID = 0,
			aud.Title =  @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.Titles aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.Titles', 'Erase details', @@RowCount)






		-- Audit.TitleVariations
		UPDATE aud
		SET aud.TitleVariationID = 0,
			aud.TitleID = 0,
			aud.TitleVariation =  @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.TitleVariations aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.TitleVariations', 'Erase details', @@RowCount)






		-- Audit.Vehicles
		UPDATE aud
		SET aud.VIN = @RemovalText,
			aud.VehicleIdentificationNumberUsable = 0, 
			ModelDescription = @RemovalText, 
			BodyStyleDescription = NULL, 
			EngineDescription = NULL, 
			TransmissionDescription = NULL, 
			BuildDateOrig = NULL, 
			BuildDate = NULL, 
			BuildYear = NULL, 
			ThroughDate = NULL, 
			SVOTypeID = NULL
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.Vehicles aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.Vehicles', 'Erase details', @@RowCount)





		-- Audit.VehiclePartyRoleEvents
		UPDATE aud
		SET aud.PartyID = 0,
			aud.VehicleID = 0
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.VehiclePartyRoleEvents aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.VehiclePartyRoleEvents', 'Erase details', @@RowCount)





		-- Audit.VehiclePartyRoleEventsAFRL
		UPDATE aud
		SET aud.PartyID = 0,
			aud.VehicleID = 0
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.VehiclePartyRoleEventsAFRL aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.VehiclePartyRoleEventsAFRL', 'Erase details', @@RowCount)





		-- Audit.VehiclePartyRoles
		UPDATE aud
		SET aud.PartyID = 0,
			aud.VehicleID = 0
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].Audit.VehiclePartyRoles aud ON aud.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Audit.VehiclePartyRoles', 'Erase details', @@RowCount)



/*  -- Awaiting BUG 14196 - Rollback Proc to be released

	---------------------------------------------------------------------------------------------------------
	--
	-- "ROLLBACK" AUDIT TABLES
	-- 
	---------------------------------------------------------------------------------------------------------


		-- RollbackSample.Events
		UPDATE aud2
		SET aud2.EventDate = '1900-01-01'
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].RollbackSample.Audit_Events aud ON aud.AuditItemID = odr.OriginatingAuditItemID
		INNER JOIN [$(AuditDB)].RollbackSample.Events aud2 ON aud2.AuditID = aud.AuditID
														  AND aud2.EventID = aud.EventID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('RollbackSample.Events', 'Erase details', @@RowCount)





		-- RollbackSample.Audit_Events
		UPDATE aud
		SET aud.EventDate = '1900-01-01' ,
			aud.TypeOfSaleOrig = @RemovalText,
			aud.EventDateOrig = @RemovalText,
			aud.InvoiceDate = NULL
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].RollbackSample.Audit_Events aud ON aud.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('RollbackSample.Audit_Events', 'Erase details', @@RowCount)





		-- RollbackSample.Audit_Organisations
		UPDATE aud
		SET aud.OrganisationName = @RemovalText, 
			aud.FromDate = NULL
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].RollbackSample.Audit_Organisations aud ON aud.AuditItemID = odr.OriginatingAuditItemID
	

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('RollbackSample.Audit_Organisations', 'Erase details', @@RowCount)





		-- RollbackSample.Audit_LegalOrganisations
		UPDATE aud
		SET aud.LegalName = @RemovalText
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].RollbackSample.Audit_LegalOrganisations aud ON aud.AuditItemID = odr.OriginatingAuditItemID
	

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('RollbackSample.Audit_LegalOrganisations', 'Erase details', @@RowCount)





		-- RollbackSample.People
		UPDATE aud2
		SET aud2.TitleID = 0 , 
			aud2.Initials = @RemovalText, 
			aud2.FirstName = @RemovalText, 
			aud2.MiddleName = @RemovalText, 
			aud2.LastName = @RemovalText, 
			aud2.SecondLastName = @RemovalText, 
			aud2.GenderID = 0, 
			aud2.BirthDate = NULL, 
			aud2.MonthAndYearOfBirth = NULL, 
			aud2.MergedDate = NULL, 
			aud2.ParentFlag = NULL, 
			aud2.ParentFlagDate = NULL, 
			aud2.UnMergedDate = NULL
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].RollbackSample.Audit_People aud ON aud.AuditItemID = odr.OriginatingAuditItemID
		INNER JOIN [$(AuditDB)].RollbackSample.People aud2 ON aud2.AuditID = aud.AuditID
														  AND aud2.PartyID = aud.PartyID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('RollbackSample.People', 'Erase details', @@RowCount)






		-- RollbackSample.Audit_People
		UPDATE aud
		SET aud.TitleID = 0 , 
			aud.Title = @RemovalText,
			aud.Initials = @RemovalText, 
			aud.FirstName = @RemovalText, 
			aud.FirstNameOrig = @RemovalText, 
			aud.MiddleName = @RemovalText, 
			aud.LastName = @RemovalText, 
			aud.LastNameOrig = @RemovalText, 
			aud.SecondLastName = @RemovalText, 
			aud.SecondLastNameOrig = @RemovalText, 
			aud.GenderID = 0, 
			aud.BirthDate = NULL
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].RollbackSample.Audit_People aud ON aud.AuditItemID = odr.OriginatingAuditItemID
	

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('RollbackSample.Audit_People', 'Erase details', @@RowCount)




		-- Rollback.SampleQualityAndSelectionLogging
		UPDATE sq
		SET 
			sq.LoadedDate = '1900-01-01',
			sq.MatchedODSOrganisationID = @DummyOrganisationID, 
			sq.MatchedODSAddressID = @DummyPostalID, 
			sq.CountryID = @DummyCountryID, 
			sq.AddressChecksum = 0, 
			sq.MatchedODSTelID = @DummyPhoneID, 
			sq.MatchedODSPrivTelID = @DummyPhoneID, 
			sq.MatchedODSBusTelID = @DummyPhoneID, 
			sq.MatchedODSMobileTelID = @DummyPhoneID, 
			sq.MatchedODSPrivMobileTelID = @DummyPhoneID, 
			sq.MatchedODSEmailAddressID = @DummyEmailID, 
			sq.MatchedODSPrivEmailAddressID = @DummyEmailID, 
			sq.MatchedODSVehicleID = CASE WHEN Brand = 'Jaguar' THEN @DummyJagVehicleID ELSE @DummyLRVehicleID END, 
			sq.ODSRegistrationID = 0, 
			sq.MatchedODSModelID = CASE WHEN Brand = 'Jaguar' THEN @DummyJagModelID ELSE @DummyLRModelID END, 
			sq.SaleDateOrig = @RemovalText, 
			sq.SaleDate = NULL, 
			sq.ServiceDateOrig = @RemovalText, 
			sq.ServiceDate = NULL, 
			sq.InvoiceDateOrig = @RemovalText, 
			sq.InvoiceDate = NULL, 
			sq.WarrantyID = NULL, 
			sq.RoadsideDate = NULL, 
			sq.CRCDate = NULL, 
			sq.BodyshopEventDateOrig = @RemovalText, 
			sq.BodyshopEventDate = NULL, 
			sq.SelectionOrganisationID = @DummyOrganisationID, 
			sq.SelectionPostalID = @DummyPostalID, 
			sq.SelectionEmailID = @DummyEmailID, 
			sq.SelectionPhoneID = @DummyPhoneID, 
			sq.SelectionLandlineID = @DummyPhoneID, 
			sq.SelectionMobileID = @DummyPhoneID
		FROM #OriginatingDataRows odr
		INNER JOIN [$(AuditDB)].RollbackSample.SampleQualityAndSelectionLogging sq ON sq.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Rollback.SampleQualityAndSelectionLogging', 'Erase details', @@RowCount)


*/


	---------------------------------------------------------------------------------------------------------
	--
	-- SAMPLE QUALITY AND LOGGING TABLES 
	-- 
	---------------------------------------------------------------------------------------------------------



		-- SampleQualityAndSelectionLogging
		UPDATE sq
		SET 
			sq.LoadedDate = '1900-01-01',
			sq.MatchedODSOrganisationID = @DummyOrganisationID, 
			sq.MatchedODSAddressID = @DummyPostalID, 
			sq.CountryID = @DummyCountryID, 
			sq.AddressChecksum = 0, 
			sq.MatchedODSTelID = @DummyPhoneID, 
			sq.MatchedODSPrivTelID = @DummyPhoneID, 
			sq.MatchedODSBusTelID = @DummyPhoneID, 
			sq.MatchedODSMobileTelID = @DummyPhoneID, 
			sq.MatchedODSPrivMobileTelID = @DummyPhoneID, 
			sq.MatchedODSEmailAddressID = @DummyEmailID, 
			sq.MatchedODSPrivEmailAddressID = @DummyEmailID, 
			sq.MatchedODSVehicleID = CASE WHEN Brand = 'Jaguar' THEN @DummyJagVehicleID ELSE @DummyLRVehicleID END, 
			sq.ODSRegistrationID = 0, 
			sq.MatchedODSModelID = CASE WHEN Brand = 'Jaguar' THEN @DummyJagModelID ELSE @DummyLRModelID END, 
			sq.SaleDateOrig = @RemovalText, 
			sq.SaleDate = NULL, 
			sq.ServiceDateOrig = @RemovalText, 
			sq.ServiceDate = NULL, 
			sq.InvoiceDateOrig = @RemovalText, 
			sq.InvoiceDate = NULL, 
			sq.WarrantyID = NULL, 
			sq.RoadsideDate = NULL, 
			sq.CRCDate = NULL, 
			sq.BodyshopEventDateOrig = @RemovalText, 
			sq.BodyshopEventDate = NULL, 
			sq.SelectionOrganisationID = @DummyOrganisationID, 
			sq.SelectionPostalID = @DummyPostalID, 
			sq.SelectionEmailID = @DummyEmailID, 
			sq.SelectionPhoneID = @DummyPhoneID, 
			sq.SelectionLandlineID = @DummyPhoneID, 
			sq.SelectionMobileID = @DummyPhoneID
		FROM #OriginatingDataRows odr
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.AuditItemID = odr.OriginatingAuditItemID

		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('dbo.SampleQualityAndSelectionLogging', 'Erase details', @@RowCount)






		-- SampleQualityAndSelectionLoggingAudit
		UPDATE sq
		SET 
			sq.LoadedDate = '1900-01-01',
			sq.MatchedODSOrganisationID = @DummyOrganisationID, 
			sq.MatchedODSAddressID = @DummyPostalID, 
			sq.CountryID = @DummyCountryID, 
			sq.AddressChecksum = 0, 
			sq.MatchedODSTelID = @DummyPhoneID, 
			sq.MatchedODSPrivTelID = @DummyPhoneID, 
			sq.MatchedODSBusTelID = @DummyPhoneID, 
			sq.MatchedODSMobileTelID = @DummyPhoneID, 
			sq.MatchedODSPrivMobileTelID = @DummyPhoneID, 
			sq.MatchedODSEmailAddressID = @DummyEmailID, 
			sq.MatchedODSPrivEmailAddressID = @DummyEmailID, 
			sq.MatchedODSVehicleID = CASE WHEN Brand = 'Jaguar' THEN @DummyJagVehicleID ELSE @DummyLRVehicleID END, 
			sq.ODSRegistrationID = 0, 
			sq.MatchedODSModelID = CASE WHEN Brand = 'Jaguar' THEN @DummyJagModelID ELSE @DummyLRModelID END, 
			sq.SaleDateOrig = @RemovalText, 
			sq.SaleDate = NULL, 
			sq.ServiceDateOrig = @RemovalText, 
			sq.ServiceDate = NULL, 
			sq.InvoiceDateOrig = @RemovalText, 
			sq.InvoiceDate = NULL, 
			sq.WarrantyID = NULL, 
			sq.RoadsideDate = NULL, 
			sq.CRCDate = NULL, 
			sq.BodyshopEventDateOrig = @RemovalText, 
			sq.BodyshopEventDate = NULL, 
			sq.SelectionOrganisationID = @DummyOrganisationID, 
			sq.SelectionPostalID = @DummyPostalID, 
			sq.SelectionEmailID = @DummyEmailID, 
			sq.SelectionPhoneID = @DummyPhoneID, 
			sq.SelectionLandlineID = @DummyPhoneID, 
			sq.SelectionMobileID = @DummyPhoneID
		FROM #OriginatingDataRows odr
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLoggingAudit sq ON sq.AuditItemID = odr.OriginatingAuditItemID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('dbo.SampleQualityAndSelectionLoggingAudit', 'Erase details', @@RowCount)








	---------------------------------------------------------------------------------------------------------
	--
	--  META.CASEDETAILS
	--
	---------------------------------------------------------------------------------------------------------


		-- Meta.CaseDetails 
		UPDATE cd
		SET cd.ModelDerivative = @RemovalText, 
			cd.Title = @RemovalText, 
			cd.FirstName = @RemovalText, 
			cd.Initials = @RemovalText, 
			cd.MiddleName = @RemovalText, 
			cd.LastName = @RemovalText, 
			cd.SecondLastName = @RemovalText, 
			cd.GenderID = 0, 
			cd.LanguageID = NULL, 
			cd.OrganisationPartyID = @DummyOrganisationID,
			cd.OrganisationName = @RemovalText, 
			cd.PostalAddressContactMechanismID = @DummyPostalID, 
			cd.EmailAddressContactMechanismID = @DummyEmailID, 
			cd.CountryID = @DummyCountryID, 
			cd.Country = @RemovalText, 
			cd.CountryISOAlpha3 = NULL, 
			cd.CountryISOAlpha2 = NULL, 
			cd.VehicleID = CASE WHEN ManufacturerPartyID = 2 THEN @DummyJagVehicleID ELSE @DummyLRVehicleID END, 
			cd.RegistrationNumber = NULL, 
			cd.RegistrationDate = '1900-01-01', 
			cd.ModelDescription = @RemovalText, 
			cd.VIN = @RemovalText, 
			cd.VinPrefix = '', 
			cd.ChassisNumber = '', 
			cd.ModelVariant = @RemovalText,
			cd.EventDate = '1900-01-01'
		FROM #Events e
		INNER JOIN Meta.CaseDetails cd ON cd.PartyID = e.PartyID


		-- Save the update count
		INSERT INTO #ErasedRecordCounts (TableName, UpdateType, RecordCount)
		VALUES ('Meta.CaseDetails', 'Erase details', @@RowCount)







		------------------------------------------------------------------------
		------------------------------------------------------------------------
		--
		-- Write out all the audit records 
		--
		------------------------------------------------------------------------
		------------------------------------------------------------------------
		
		DECLARE @Max_AuditID		BIGINT,
				@Max_AuditItemID	BIGINT,
				@EraseDatetime		DATETIME,
				@FileDateTime		VARCHAR(20)

		SET @EraseDatetime = GETDATE()

		SELECT @Max_AuditID = MAX(AuditID) FROM [$(AuditDB)].dbo.Audit 
		SELECT @Max_AuditItemID	= MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems 

		SELECT @FileDateTime = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(25), @EraseDatetime, 120), '-', ''), ':', ''), ' ', '_')


		-- Create audit record
		INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
		SELECT @Max_AuditID + 1

		-- Create dbo.File entry
		INSERT INTO [$(AuditDB)].dbo.Files (AuditID, FileTypeID, FileName, FileRowCount, ActionDate)
		SELECT	 @Max_AuditID + 1 AS AuditID,
				(SELECT FileTypeID FROM [$(AuditDB)].[dbo].[FileTypes] WHERE FileType = 'GDPR Update') AS FileTypeID,
				'GDPR_RightOfErasure_' + @FileDateTime AS Filename,
				(SELECT COUNT(*) FROM #OriginatingDataRows) AS FileRowCount,
				@EraseDatetime AS ActionDate

		-- Create linked AuditItemIDs
		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID) 
		SELECT  @Max_AuditID + 1 AS AuditID,
				@Max_AuditItemID + odr.ID AS AuditItemID 
		FROM #OriginatingDataRows odr

	
		-- Write out erasure request
		INSERT INTO [$(AuditDB)].GDPR.ErasureRequests (AuditID, PartyID, FullErasure, RequestDate, RequestedBy)
		SELECT @Max_AuditID + 1, @PartyID, @FullErase, @EraseDatetime, @RequestedBy 
	
	
		-- Write out originating data rows
		INSERT INTO  [$(AuditDB)].GDPR.OriginatingDataRows (AuditItemID, OriginatingAuditID, FileName, ActionDate, PhysicalRow, OriginatingAuditItemID, FileType)
		SELECT  @Max_AuditItemID + odr.ID AS AuditItemID, 
				OriginatingAuditID, 
				FileName, 
				ActionDate, 
				PhysicalRow, 
				OriginatingAuditItemID, 
				FileType
		FROM #OriginatingDataRows odr
		WHERE NOT EXISTS (	SELECT er.AuditID									-- Check that we have not already added this row previously (i.e. on a partial erase) 
							FROM [$(AuditDB)].GDPR.ErasureRequests er 
							INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditID = er.AuditID
							INNER JOIN [$(AuditDB)].GDPR.OriginatingDataRows odl ON odl.AuditItemID = ai.AuditItemID
							WHERE er.PartyID = @PartyID
							AND odl.OriginatingAuditItemID = odr.OriginatingAuditItemID 
						)
						


		-- Get new Max_AuditID for ErasedRecordCount records
		DECLARE @Add_Max_AuditItemID INT
		SELECT @Add_Max_AuditItemID = MAX(ID) + @Max_AuditItemID FROM #OriginatingDataRows  -- Get the new max audititemID after adding the Orginating data rows

		-- Create linked AuditItemIDs
		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID) 
		SELECT  @Max_AuditID + 1 AS AuditID,
				@Add_Max_AuditItemID + erc.ID AS AuditItemID 
		FROM #ErasedRecordCounts erc

		-- Write out Audit.ErasedRecordCounts
		INSERT INTO  [$(AuditDB)].GDPR.ErasedRecordCounts (AuditItemID, TableName, UpdateType, RecordCount)
		SELECT  @Add_Max_AuditItemID + erc.ID AS AuditItemID, 
				TableName,	
				UpdateType,	
				RecordCount
		FROM #ErasedRecordCounts erc



	
		--------------------------------------------------------------------------------
		-- ADD "Right to Erasure" NON-SOLICITATION
		--------------------------------------------------------------------------------

		DECLARE @NonSol_AuditItemID INT
		SELECT @NonSol_AuditItemID = @Add_Max_AuditItemID + MAX(ID) + 1  FROM #ErasedRecordCounts

		-- Insert the linked AuditItem record
		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID) 
		SELECT  @Max_AuditID + 1 AS AuditID,
				@NonSol_AuditItemID AS AuditItemID


		-- Insert the non-solicitation
		DECLARE @GDPRErasureNonSolTextID  INT
		SELECT @GDPRErasureNonSolTextID = NonSolicitationTextID FROM dbo.NonSolicitationTexts WHERE NonSolicitationText = 'GDPR Right to Erasure'

		INSERT	Party.vwDA_NonSolicitations 
		(
			NonSolicitationID,
			NonSolicitationTextID, 
			PartyID,
			FromDate,
			AuditItemID
		)
		SELECT 0 AS NonSolicitationID,
			@GDPRErasureNonSolTextID,
			@PartyID,
			@EraseDatetime AS FromDate,
			@NonSol_AuditItemID AS AuditItemID
	


	COMMIT

	RETURN 1
	

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

