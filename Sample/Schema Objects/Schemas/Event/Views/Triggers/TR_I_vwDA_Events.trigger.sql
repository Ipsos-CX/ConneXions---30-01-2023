CREATE TRIGGER Event.TR_I_vwDA_Events ON Event.vwDA_Events
INSTEAD OF INSERT

AS

/*
		Purpose:	Loads Vehicle Event data from the VWT into the system.
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_Events.TR_I_vwDA_Events
LIVE	1.1			13/06/2013		Chris Ross			BUG 8689 - Add in TypeOfSaleOrigsOrig column for France VISTA
LIVE	1.2			03/10/2014		Chris Ross			BUG 6061 - Increase the size of the DealerID to accomodate a owner (checksum) + CentreID combined 
LIVE	1.3			13/09/2015		Chris Ross			BUG 11933 - Add in AFRL code for loading into VehiclePartyRoleEvents table
LIVE	1.4			07/04/2016		Chris Ross			BUG 12507 - Add in CRC CaseNumber into matching to ensure we don't incorrectly roll up CRC events
LIVE	1.5			29/09/2016		Chris Ross			BUG 12859 - Add in seperate Lost Leads functionality based on disitnct Person Party IDs rather than Vehicle IDs
LIVE	1.6			19/10/2016		Chris Ross			BUG 13239 - Bug found where crashes if there is no Person associated with a Lost Leads event. 
																	Add in functionality to take OrganisationID or PartyID if there is no PersonID supplied.
LIVE	1.7			16/12/2016		Chris Ross			BUG 13406 - Fix to ensure only single event is created for each Lost Leads sample row.
LIVE	1.8			14/05/2017		Chris Ledger		Fix to ensure only update New Lost Lead Events
LIVE	1.9			28/10/2019		Chris Ledger		BUG 15490 - Add in PreOwned LostLeads
LIVE	1.10		20/10/2021		Chris Ledger		TASK 567 - Add LostLeadID
LIVE	1.11		02/02/2022		Chris Ledger		TASK 777 - Fix to audit all Lost Lead events
LIVE	1.12		04/03/2022		Chris Ledger		TASK 777 - Further fix to only audit one record where more than one VehicleRole present for Lost Lead event
LIVE	1.13		09/03/2022		Ben King			TASK 807 - Long Running Queries In Overnight Load
LIVE	1.14		07/06/2022		Ben King			TASK 879 - Land Rover Experience - SSIS Loader
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE	@MaxEventID BIGINT

	-- V1.13
	DROP TABLE IF EXISTS #INSERTED

	-- V1.13
	SELECT *
	INTO #INSERTED
	FROM INSERTED

	-- V1.13
	CREATE NONCLUSTERED INDEX ONE ON #INSERTED ([EventID]) INCLUDE ([AuditItemID],[PartyID],[VehicleRoleTypeID],[VehicleID])
	CREATE NONCLUSTERED INDEX TWO ON #INSERTED ([EventID]) INCLUDE ([AuditItemID],[PartyID],[VehicleRoleTypeID],[VehicleID],[AFRLCode])
	CREATE NONCLUSTERED INDEX THREE ON #INSERTED ([EventTypeID],[VehicleID],[DealerID]) INCLUDE ([AuditItemID],[EventDate],[PartyID],[VehicleRoleTypeID],[CRCCaseNumber])
	CREATE NONCLUSTERED INDEX FOUR ON #INSERTED ([EventTypeID],[VehicleID],[DealerID]) INCLUDE ([EventDate],[PartyID],[VehicleRoleTypeID],[AFRLCode],[FromDate],[CRCCaseNumber])
	CREATE NONCLUSTERED INDEX FIVE ON #INSERTED ([EventTypeID]) INCLUDE ([AuditItemID],[EventDate],[PartyID],[VehicleRoleTypeID],[VehicleID],[DealerID],[LostLeadID])
	CREATE NONCLUSTERED INDEX SIX ON #INSERTED ([EventTypeID],[VehicleID],[DealerID]) INCLUDE ([AuditItemID],[EventDate],[CRCCaseNumber])
	CREATE NONCLUSTERED INDEX SEVEN ON #INSERTED ([EventID])

	-- V1.13
	DROP TABLE IF EXISTS #NewEvents

	-- V1.13
	CREATE TABLE #NewEvents
	(
		NewEventID INT IDENTITY(1, 1),
		EventID INT,
		EventDate DATETIME2,
		EventDateOrig NVARCHAR(50),
		EventTypeID INT,
		TypeOfSaleOrig	VARCHAR(50),
		InvoiceDate DATETIME2,
		DealerID BIGINT,
		VehicleID INT,
		CRCCaseNumber  VARCHAR(50),
		LostLeadPartyID  INT,
		LostLeadID VARCHAR(50),
		LandRoverExperienceID VARCHAR(50)
	)


	-- REMOVED BY V1.13
	-- CREATE TEMP TABLE TO HOLD NEW EVENTS
	--DECLARE @NewEvents TABLE
	--(
	--	NewEventID INT IDENTITY(1, 1),
	--	EventID INT,
	--	EventDate DATETIME2,
	--	EventDateOrig NVARCHAR(50),
	--	EventTypeID INT,
	--	TypeOfSaleOrig	VARCHAR(50),
	--	InvoiceDate DATETIME2,
	--	DealerID BIGINT,
	--	VehicleID INT,
	--	CRCCaseNumber  VARCHAR(50),
	--	LostLeadPartyID  INT,
	--	LostLeadID VARCHAR(50)			-- V1.10
	--)



	-- GET DISTINCT NEW EVENTS ONLY 
	INSERT INTO #NewEvents				-- V1.13
	(
		EventDate,
		EventDateOrig,
		EventTypeID,
		TypeOfSaleOrig,
		InvoiceDate,
		DealerID,
		VehicleID,
		CRCCaseNumber,
		LostLeadPartyID,
		LostLeadID,						-- V1.10
		LandRoverExperienceID           -- V1.14
	)
	SELECT DISTINCT
		EventDate,
		EventDateOrig,
		EventTypeID,
		TypeOfSaleOrig,
		InvoiceDate,
		DealerID,
		VehicleID,
		CRCCaseNumber,
		NULL AS LostLeadPartyID,
		NULL AS LostLeadID,				-- V1.10
		LandRoverExperienceID           -- V1.14
	FROM #INSERTED						-- V1.13
	WHERE ISNULL(EventID, 0) = 0
		AND EventTypeID NOT IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Excluding Lost Leads		-- V1.9
   UNION
	SELECT DISTINCT
		EventDate,
		EventDateOrig,
		EventTypeID,
		TypeOfSaleOrig,
		InvoiceDate,
		DealerID,
		VehicleID,
		CRCCaseNumber,
		PartyID AS PersonPartyID,
		LostLeadID,						-- V1.10
		NULL AS LandRoverExperienceID   -- V1.14
	FROM #INSERTED I						-- V1.13
	WHERE ISNULL(EventID, 0) = 0
		AND EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Lost Leads					-- V1.9
		AND EXISTS (SELECT P.PartyID FROM Party.People P WHERE P.PartyID = I.PartyID)   -- Ensure we only bring back the Person records from the INSERTED table, which will have both Person and Org, so no dupes (note: all LostLeads should have the person column populated) 
	

	-- For Lost Leads events where the Person has not been supplied we populate with the PartyID that is remaining    -- V1.6
	INSERT INTO #NewEvents			-- V1.13
	(
		EventDate,
		EventDateOrig,
		EventTypeID,
		TypeOfSaleOrig,
		InvoiceDate,
		DealerID,
		VehicleID,
		CRCCaseNumber,
		LostLeadPartyID,
		LostLeadID,							-- V1.10
		LandRoverExperienceID               -- V1.14
	)
	SELECT DISTINCT
		I.EventDate,
		I.EventDateOrig,
		I.EventTypeID,
		I.TypeOfSaleOrig,
		I.InvoiceDate,
		I.DealerID,
		I.VehicleID,
		I.CRCCaseNumber,
		I.PartyID AS NonPersonPartyID,
		I.LostLeadID,						-- V1.10
		I.LandRoverExperienceID             -- V1.14
	FROM #INSERTED I						-- V1.13
		LEFT JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE())
							AND I.EventTypeID = NE.EventTypeID
							AND I.DealerID = NE.DealerID
							AND I.PartyID = NE.LostLeadPartyID
							AND I.VehicleID = NE.VehicleID
							AND I.LostLeadID = NE.LostLeadID			-- V1.10
							AND I.LandRoverExperienceID = NE.LandRoverExperienceID -- V1.14
	WHERE ISNULL(I.EventID, 0) = 0
		AND I.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Lost Leads										  -- V1.9
		AND I.AuditItemID NOT IN  (	SELECT I_Ref.AuditItemID		-- V1.7 - Get AuditItemIDs for the rows where we have already created a Lost Lead Person record
									FROM #INSERTED I_Ref -- V1.13
										INNER JOIN #NewEvents NE ON ISNULL(I_Ref.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE()) -- V1.13
															AND I_Ref.EventTypeID = NE.EventTypeID
															AND I_Ref.DealerID = NE.DealerID
															AND I_Ref.VehicleID = NE.VehicleID
															AND I_Ref.PartyID = NE.LostLeadPartyID
															AND I_Ref.LostLeadID = NE.LostLeadID		-- V1.10
															AND I_Ref.LandRoverExperienceID = NE.LandRoverExperienceID -- V1.14
									WHERE ISNULL(I_Ref.EventID, 0) = 0
										AND I_Ref.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads')))   -- Lost Leads    -- V1.9


	-- GET NEXT AVAILABLE EVENT ID
	SELECT @MaxEventID = ISNULL(MAX(EventID), 0) FROM Event.Events

	-- ASSIGN EVENT ID TO NEW EVENTS
	UPDATE #NewEvents SET EventID = NewEventID + @MaxEventID -- V1.13

	-- WRITE BACK NEWLY CREATED EVENT IDS TO VWT  (NON-LOST LEADS)
	UPDATE V
	SET V.MatchedODSEventID = NE.EventID
	FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN #INSERTED I ON V.AuditItemID = I.AuditItemID	-- V1.13
		LEFT JOIN [$(ETLDB)].CRC.CRCEvents CRC ON CRC.AuditItemID = I.AuditItemID    -- Get CRC Case Number if relevant
		INNER JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE()) -- V1.13
								AND I.EventTypeID = NE.EventTypeID
								AND I.DealerID = NE.DealerID
								AND I.VehicleID = NE.VehicleID
								AND ISNULL(I.CRCCaseNumber, '') = ISNULL(NE.CRCCaseNumber, '')		-- V1.4
								AND ISNULL(I.LandRoverExperienceID, '') = ISNULL(NE.LandRoverExperienceID, '')		-- V1.14
	WHERE V.ODSEventTypeID NOT IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Exclude Lost Leads   -- V1.9


	-- WRITE BACK NEWLY CREATED EVENT IDS TO VWT  (LOST LEADS - Requires different matching as no-vehicle ID)
	UPDATE V
	SET V.MatchedODSEventID = NE.EventID
	FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN (	SELECT ROW_NUMBER() OVER(PARTITION BY I.AuditItemID ORDER BY VehicleRoleTypeID DESC) AS RowID , *    -- V1.7 - For Lost Leads we only want one record to link on, so we sort on VehicleRoleType taking Person first (role type ID 3 "driver") over Organisations (type 2 "owner) just in case both are present.
						FROM #INSERTED I		-- V1.13
						WHERE I.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))) X ON V.AuditItemID = X.AuditItemID 
																																							AND X.RowID = 1					  -- V1.9
	    
		INNER JOIN #NewEvents NE ON ISNULL(X.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE())					-- V1.8 Change LEFT TO INNER JOIN to make sure only update New Events, -- V1.13
								AND X.EventTypeID = NE.EventTypeID
								AND X.DealerID = NE.DealerID
								AND X.VehicleID = NE.VehicleID
								AND X.PartyID = NE.LostLeadPartyID
								AND X.LostLeadID = NE.LostLeadID		-- V1.10
	WHERE V.ODSEventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Only process LostLeads   -- V1.9
	

			
	-- INSERT NEW EVENTS
	INSERT INTO Event.Events
	(
		EventID,
		EventDate,
		EventTypeID
	)
	SELECT 
		EventID,
		EventDate,
		EventTypeID
	FROM #NewEvents -- V1.13


	-- INSERT AUDIT EVENT RECORD
	INSERT INTO [$(AuditDB)].Audit.Events 
	(
		EventID, 
		EventDate, 
		EventDateOrig,
		EventTypeID, 
		TypeOfSaleOrig,
		InvoiceDate,
		AuditItemID
	)
	SELECT DISTINCT
		COALESCE(NULLIF(NE.EventID, 0), NULLIF(I.EventID, 0)),
		I.EventDate, 
		I.EventDateOrig,
		I.EventTypeID, 
		I.TypeOfSaleOrig,
		I.InvoiceDate,		
		I.AuditItemID
	FROM #INSERTED I -- V1.13
		LEFT JOIN [$(ETLDB)].CRC.CRCEvents CRC ON CRC.AuditItemID = I.AuditItemID    -- Get CRC Case Number if relevant
		LEFT JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE()) -- V1.13
								AND I.EventTypeID = NE.EventTypeID
								AND I.DealerID = NE.DealerID
								AND I.VehicleID = NE.VehicleID
								AND ISNULL(I.CRCCaseNumber, '') = ISNULL(NE.CRCCaseNumber, '')    -- V1.4
								AND ISNULL(I.LandRoverExperienceID, '') = ISNULL(NE.LandRoverExperienceID, '')    -- V1.14
		LEFT JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = I.AuditItemID
	WHERE AE.AuditItemID IS NULL
		AND I.EventTypeID NOT IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Excluding Lost Leads		-- V1.9
  UNION
    SELECT DISTINCT
		COALESCE(NULLIF(NE.EventID, 0), NULLIF(X.EventID, 0)),
		X.EventDate, 
		X.EventDateOrig,
		X.EventTypeID, 
		X.TypeOfSaleOrig,
		X.InvoiceDate,		
		X.AuditItemID
	FROM (	SELECT ROW_NUMBER() OVER(PARTITION BY I.AuditItemID ORDER BY VehicleRoleTypeID DESC) AS RowID , *    -- V1.7 - For Lost Leads we only want one record to link on, so we sort on VehicleRoleType taking Person first (role type ID 3 "driver") over Organisations (type 2 "owner) just in case both are present.
			FROM #INSERTED I	-- V1.13	
			WHERE I.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))
		) X 							  -- V1.9  
		LEFT JOIN #NewEvents NE ON ISNULL(X.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE())			-- V1.11 Change INNER to LEFT JOIN to audit all events
								AND X.EventTypeID = NE.EventTypeID
								AND X.DealerID = NE.DealerID
								AND X.VehicleID = NE.VehicleID
								AND X.PartyID = NE.LostLeadPartyID
								AND X.LostLeadID = NE.LostLeadID								-- V1.10
		LEFT JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = X.AuditItemID
	WHERE AE.AuditItemID IS NULL
		AND X.EventTypeID IN (SELECT EventTypeID FROM [Sample].Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Lost Leads			  -- V1.9
		AND X.RowID = 1				-- V1.12
	
	-- WRITE VehiclePartyRoles
	INSERT INTO Vehicle.vwDA_VehiclePartyRoles
	(
		AuditItemID,
		PartyID,
		VehicleRoleTypeID,
		VehicleID,
		FromDate
	)
	SELECT DISTINCT
		AuditItemID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID,
		FromDate
	FROM #INSERTED -- V1.13



	-- WRITE VEHICLEPARTYROLEEVENTS FOR NEW EVENTS
	INSERT INTO Vehicle.VehiclePartyRoleEvents
	(	
		EventID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID,
		FromDate,
		AFRLCode				-- V1.3
	)
	SELECT DISTINCT
			NE.EventID, 
			I.PartyID, 
			I.VehicleRoleTypeID, 
			I.VehicleID,
			I.FromDate,
			I.AFRLCode			-- V1.3
	FROM #INSERTED I			-- V1.13
		LEFT JOIN [$(ETLDB)].CRC.CRCEvents CRC ON CRC.AuditItemID = I.AuditItemID    -- Get CRC Case Number if relevant
		INNER JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE())
								AND I.EventTypeID = NE.EventTypeID
								AND I.DealerID = NE.DealerID
								AND I.VehicleID = NE.VehicleID
								AND ISNULL(I.CRCCaseNumber, '') = ISNULL(NE.CRCCaseNumber, '')    -- V1.4
								AND ISNULL(I.LandRoverExperienceID, '') = ISNULL(NE.LandRoverExperienceID, '')    -- V1.14
	WHERE I.EventTypeID NOT IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Excluding Lost Leads     -- V1.9
  UNION
	SELECT DISTINCT
			NE.EventID, 
			I.PartyID, 
			I.VehicleRoleTypeID, 
			I.VehicleID,
			I.FromDate,
			I.AFRLCode			-- V1.3
	FROM #INSERTED I			-- V1.13
		INNER JOIN (	SELECT ROW_NUMBER() OVER(PARTITION BY I.AuditItemID ORDER BY VehicleRoleTypeID DESC) AS RowID, I.* 	-- V1.7 - For Lost Leads we only want one record to link on, so we sort on VehicleRoleType taking Person first (role type ID 3 "driver") over Organisations (type 2 "owner) just in case both are present.
						FROM #INSERTED I	-- V1.13	
						WHERE I.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))) X ON X.RowID = 1 
																																							AND I.AuditItemID = X.AuditItemID						  -- V1.9
		INNER JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE()) -- V1.13
								AND I.EventTypeID = NE.EventTypeID
								AND I.DealerID = NE.DealerID
								AND I.VehicleID = NE.VehicleID
								AND X.PartyID = NE.LostLeadPartyID
								AND I.LostLeadID = NE.LostLeadID						-- V1.10
	WHERE I.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Lost Leads					  -- V1.9




	-- WRITE VEHICLE PARTY ROLE EVENTS FOR NEW EVENTS TO AUDIT
	INSERT [$(AuditDB)].Audit.VehiclePartyRoleEvents
	(
		EventID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID,
		AuditItemID
	)
	SELECT DISTINCT
		NE.EventID, 
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID,
		I.AuditItemID
	FROM #INSERTED I	-- V1.13
		LEFT JOIN [$(ETLDB)].CRC.CRCEvents CRC ON CRC.AuditItemID = I.AuditItemID    -- Get CRC Case Number if relevant
		INNER JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE())	-- V1.13
								AND I.EventTypeID = NE.EventTypeID
								AND I.DealerID = NE.DealerID
								AND I.VehicleID = NE.VehicleID
								AND ISNULL(I.CRCCaseNumber, '') = ISNULL(NE.CRCCaseNumber, '')    -- V1.4
								AND ISNULL(I.LandRoverExperienceID, '') = ISNULL(NE.LandRoverExperienceID, '')    -- V1.14
	WHERE I.EventTypeID NOT IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Excluding Lost Leads		  -- V1.9
  UNION
	SELECT DISTINCT
		NE.EventID, 
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID,
		I.AuditItemID
	FROM #INSERTED I	-- V1.13
		INNER JOIN (	SELECT ROW_NUMBER() OVER (PARTITION BY I.AuditItemID ORDER BY VehicleRoleTypeID DESC) AS RowID,	I.*	-- V1.7 - For Lost Leads we only want one record to link on, so we sort on VehicleRoleType taking Person first (role type ID 3 "driver") over Organisations (type 2 "owner) just in case both are present.							
						FROM #INSERTED I	-- V1.13	
						WHERE I.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))) X ON X.RowID = 1 
																																							AND I.AuditItemID = X.AuditItemID						  -- V1.9
		INNER JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE())	-- V1.13
								AND I.EventTypeID = NE.EventTypeID
								AND I.DealerID = NE.DealerID
								AND I.VehicleID = NE.VehicleID
								AND X.PartyID = NE.LostLeadPartyID
								AND I.LostLeadID = NE.LostLeadID							-- V1.10
	WHERE I.EventTypeID IN (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory IN ('LostLeads','PreOwned LostLeads'))   -- Lost Leads					  -- V1.9





	-- WRITE VEHICLE PARTY ROLE EVENTS FOR NEW EVENTS TO AFRL AUDIT
	INSERT [$(AuditDB)].Audit.VehiclePartyRoleEventsAFRL
	(
		VehiclePartyRoleEventID,
		EventID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID,
		AuditItemID,
		AFRLCode				-- V1.3
	)
	SELECT DISTINCT
		VPRE.VehiclePartyRoleEventID,
		NE.EventID, 
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID,
		I.AuditItemID,
		I.AFRLCode			-- V1.3
	FROM #INSERTED I		-- V1.13
		LEFT JOIN [$(ETLDB)].CRC.CRCEvents CRC ON CRC.AuditItemID = I.AuditItemID    -- Get CRC Case Number if relevant
		INNER JOIN #NewEvents NE ON ISNULL(I.EventDate, GETDATE()) = ISNULL(NE.EventDate, GETDATE())	-- V1.13
								AND I.EventTypeID = NE.EventTypeID
								AND I.DealerID = NE.DealerID
								AND I.VehicleID = NE.VehicleID
								AND ISNULL(I.CRCCaseNumber, '') = ISNULL(NE.CRCCaseNumber, '')    -- V1.4
								AND ISNULL(I.LandRoverExperienceID, '') = ISNULL(NE.LandRoverExperienceID, '')    -- V1.14
		INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON NE.EventID = VPRE.EventID 
														AND I.PartyID = VPRE.PartyID 
														AND I.VehicleRoleTypeID = VPRE.VehicleRoleTypeID 
														AND I.VehicleID = VPRE.VehicleID
	WHERE NULLIF(I.AFRLCode, '') IS NOT NULL





	-- WRITE VEHICLEPARTYROLEEVENTS FOR PARTY/PARTYROLES THAT WE DO NOT ALREADY HAVE
	INSERT INTO Vehicle.VehiclePartyRoleEvents
	(
		EventID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID,
		FromDate,
		AFRLCode				-- V1.3
	)
	SELECT DISTINCT 
		I.EventID, 
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID,
		I.FromDate,
		I.AFRLCode			-- V1.3
	FROM #INSERTED I		-- V1.13
		LEFT JOIN Vehicle.VehiclePartyRoleEvents VPRE ON I.EventID = VPRE.EventID 
											AND I.PartyID = VPRE.PartyID 
											AND I.VehicleRoleTypeID = VPRE.VehicleRoleTypeID 
											AND I.VehicleID = VPRE.VehicleID
	WHERE ISNULL(VPRE.EventID, 0) = 0
		AND NOT ISNULL(I.EventID, 0) = 0


	-- Write VehiclePartyRoleEvents for Party/PartyRoles that we do not already have to Audit
	INSERT INTO [$(AuditDB)].Audit.VehiclePartyRoleEvents
	(
		EventID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID, 
		AuditItemID
	)
	SELECT DISTINCT 
		I.EventID, 
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID, 
		I.AuditItemID
	FROM #INSERTED I	-- V1.13
	WHERE NOT ISNULL(I.EventID, 0) = 0


	-- Write Audit.VehiclePartyRoleEventsAFRL for Party/PartyRoles that we do not already have to Audit
	INSERT INTO [$(AuditDB)].Audit.VehiclePartyRoleEventsAFRL
	(
		VehiclePartyRoleEventID,
		EventID, 
		PartyID, 
		VehicleRoleTypeID, 
		VehicleID, 
		AuditItemID,
		AFRLCode				-- V1.3
	)
	SELECT DISTINCT 
		VPRE.VehiclePartyRoleEventID,
		I.EventID, 
		I.PartyID, 
		I.VehicleRoleTypeID, 
		I.VehicleID, 
		I.AuditItemID,
		I.AFRLCode				-- V1.3
	FROM #INSERTED I			-- V1.13
		INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON I.EventID = VPRE.EventID 
										AND I.PartyID = VPRE.PartyID 
										AND I.VehicleRoleTypeID = VPRE.VehicleRoleTypeID 
										AND I.VehicleID = VPRE.VehicleID
	WHERE NOT ISNULL(I.EventID, 0) = 0
		AND NULLIF(I.AFRLCode, '') IS NOT NULL

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


