CREATE PROC Meta.uspPartyBestEmailAddresses

AS

/*
	Purpose:	Drops, recreates and reindexes Meta.PartyBestEmailAddresses META table which is a denormalised set of data containing the latest non solicitated email address for a party
				The requirement for email addresses is that we always consider the latest email address we've loaded to be
				the current email, instead of the one with the greatest ContactMechanismID.  NB. in most cases this will be
				the same.  
		
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.uspIP_Update_META_GENERAL_PartyBestElectronicAddress
LIVE	1.1			18/03/2014		Ali Yuksel			BUG 10077: ContactMechanismNonSolicitations section fixed. ContactMechanismID check added
LIVE	1.2			29/10/2015		Chris Ross			BUG 11933: Add in creation and population of Meta.PartyBestEmailAddressesAFRL table 
LIVE	1.3			02/03/2016		Chris Ross			BUG 12226: Add in creation and population of Meta.PartyBestEmailAddressesLatestOnly table 
LIVE	1.4			12/04/2016		Chris Ross		    BUG 12226: NEW functionality to calculate latest received email addresses by Event Category 
LIVE	1.5			29/11/2017		Chris Ledger		BUG 13437: Add in creation and population of Meta.PartyBestEmailAddressesBlacklistIncluded table
LIVE	1.6			03/10/2018		Eddie Thomas		BUG 14987: Include email addresses added in OWAP, when generating Meta.PartyLatestReceivedEmails
LIVE	1.7							Eddie Thomas		[CR 24/10/19: Missing change from source safe - re-engineered from Live]
LIVE	1.8			25/11/2021		Chris Ledger		TASK 701: Exclude Russian email addresses with non ASCII characters
LIVE	1.9			07/04/2022		Chris Ledger		Replace function with WHERE clause to identify non ASCII characters
LIVE	1.10		28/04/2022		Ben King			TASK 840 - Improve metadata creation step

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	------------------------------------------
	-- DROP THE TABLES PRIOR TO RECREATION
	------------------------------------------
	DROP TABLE IF EXISTS Meta.PartyBestEmailAddresses
	DROP TABLE IF EXISTS Meta.PartyBestEmailAddressesAFRL
	DROP TABLE IF EXISTS Meta.PartyBestEmailAddressesLatestOnly
	DROP TABLE IF EXISTS Meta.PartyLatestReceivedEmails
	DROP TABLE IF EXISTS Meta.PartyBestEmailAddressesBlacklistIncluded
	
	
	------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	-- FIRST BUILD THE NORMAL PARTY BEST EMAIL TABLE  -- Original functionality
	------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------		
	--
	-- Release manage does not allow implicit temporary table creation and be explicitly created
	--
	CREATE TABLE #EMails
	(
		PartyID BIGINT,
		ContactMechanismID BIGINT,
		AuditItemID BIGINT
	)


	----------------------------------------
	-- GET ALL EMAILS FOR ALL PARTIES
	----------------------------------------
	INSERT INTO #EMails (PartyID, ContactMechanismID, AuditItemID)
	SELECT 
		PCM.PartyID, 
		CM.ContactMechanismID, 
		APCM.AuditItemID
	FROM ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = PCM.ContactMechanismID
		INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APCM ON APCM.PartyID = PCM.PartyID AND APCM.ContactMechanismID = PCM.ContactMechanismID
	WHERE CM.Valid = 1
		AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address')


	----------------------------------------
	-- DELETE ANY PartyNonSolicitations
	----------------------------------------
	DELETE E
	FROM #Emails E 
		INNER JOIN (	SELECT DISTINCT 
							NS.PartyID 
						FROM dbo.NonSolicitations NS
							INNER JOIN Party.NonSolicitations PNS ON NS.NonSolicitationID = PNS.NonSolicitationID
						WHERE GETDATE() >= NS.FromDate
							AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')) AS PNS ON E.PartyID = PNS.PartyID


	----------------------------------------------------
	-- DELETE ANY ContactMechanismNonSolicitations
	----------------------------------------------------
	DELETE E
	FROM #Emails E
		INNER JOIN (	SELECT DISTINCT
							NS.PartyID,
							CMNS.ContactMechanismID 
						FROM dbo.NonSolicitations NS
							INNER JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
							INNER JOIN ContactMechanism.EmailAddresses EA ON CMNS.ContactMechanismID = EA.ContactMechanismID
						WHERE GETDATE() >= NS.FromDate
							AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')) AS CMNS ON E.PartyID = CMNS.PartyID 
																									AND E.ContactMechanismID=CMNS.ContactMechanismID


	----------------------------------------------------
	-- DELETE ANY ContactMechanismTypeNonSolicitations
	----------------------------------------------------
	DELETE E
	FROM #Emails E
		INNER JOIN (	SELECT DISTINCT
							NS.PartyID
						FROM dbo.NonSolicitations NS
							INNER JOIN ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
						WHERE CMTNS.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address')
							AND GETDATE() >= NS.FromDate
							AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')) AS CMTNS ON E.PartyID = CMTNS.PartyID
	

	----------------------------------------------------
	-- DELETE ANY BLACKLISTED EMAILS
	----------------------------------------------------
	DELETE E
	FROM #Emails E
		INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = E.ContactMechanismID


	----------------------------------------------------
	-- V1.8 DELETE RUSSIAN NON-ASCII EMAILS
	----------------------------------------------------	
	DELETE E
	FROM #EMails E
		INNER JOIN WebsiteReporting.dbo.SampleQualityAndSelectionLogging SL ON E.AuditItemID = SL.AuditItemID
		INNER JOIN ContactMechanism.EmailAddresses EA ON E.ContactMechanismID = EA.ContactMechanismID
	WHERE SL.Market = 'Russian Federation'
		AND EA.EmailAddress != CAST(EA.EmailAddress AS VARCHAR(4000))		-- V1.9		
		--AND dbo.udfIdentifyNonASCIICharacters(EA.EmailAddress) = 1		-- V1.9


	---------------------------------------------------------------------------------------
	--- BUILD THE Party Best Email table out of whatever records are left in #Emails
	---------------------------------------------------------------------------------------
	CREATE TABLE Meta.PartyBestEmailAddresses
	(
		PartyID dbo.PartyID NOT NULL,
		ContactMechanismID dbo.ContactMechanismID NOT NULL,
		AuditItemID dbo.AuditItemID NOT NULL
	)
	
	INSERT INTO Meta.PartyBestEmailAddresses
	SELECT E.PartyID, 
		MAX(E.ContactMechanismID) AS ContactMechanismID, 
		E.AuditItemID
	FROM #Emails E
		INNER JOIN (	SELECT PartyID,
							MAX(AuditItemID) AS MaxAuditItemID
						FROM #Emails
						GROUP BY PartyID) M ON M.MaxAuditItemID = E.AuditItemID
												AND M.PartyID = E.PartyID
	GROUP BY E.PartyID, 
		E.AuditItemID	

	-- DELETE THE TEMPORARY TABLES	
	DROP TABLE #Emails
	
	-----------------------------------
	-- CREATE INDEXES
	-----------------------------------
	CREATE NONCLUSTERED INDEX [IX_Meta_PartyBestEmailAddresses_PartyID]
    ON [Meta].[PartyBestEmailAddresses]([PartyID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);


	------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	-- SECOND BUILD THE LATEST RECEIVED AND AFRL BEST PARTY EMAIL ADDRESS TABLES  -- V1.4
	------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	CREATE TABLE [Meta].[PartyLatestReceivedEmails] 
	(
		PartyID				[dbo].[PartyID]				NOT NULL,
		EventCategoryID		[dbo].[EventCategoryID]		NOT NULL,
		PartyType			 CHAR(1)					NOT NULL,
		LatestAuditItemID	[dbo].[AuditItemID]			NOT NULL,
		ContactMechanismID	[dbo].[ContactMechanismID]	NULL,
		EmailAddressSource	[dbo].[EmailAddressSource]	NULL,
		EmailPriorityOrder	INT							NOT NULL
	);

	CREATE TABLE [Meta].[PartyBestEmailAddressesLatestOnly] 
	(
		PartyID            [dbo].[PartyID]				NOT NULL,
		EventCategoryID	   [dbo].[EventCategoryID]		NOT NULL,
		LatestAuditItemID  [dbo].[AuditItemID]			NOT NULL,
		ContactMechanismID [dbo].[ContactMechanismID]	NOT NULL,
		EmailAddressSource [dbo].[EmailAddressSource]	NULL
	);

	CREATE TABLE [Meta].[PartyBestEmailAddressesAFRL] 
	(
		PartyID            [dbo].[PartyID]				NOT NULL,
		EventCategoryID	   [dbo].[EventCategoryID]		NOT NULL,
		LatestAuditItemID  [dbo].[AuditItemID]			NOT NULL,
		ContactMechanismID [dbo].[ContactMechanismID]	NOT NULL,
		EmailAddressSource [dbo].[EmailAddressSource]	NULL
	);

	CREATE TABLE [Meta].[PartyBestEmailAddressesBlacklistIncluded] 
	(
		PartyID            [dbo].[PartyID]				NOT NULL,
		EventCategoryID	   [dbo].[EventCategoryID]		NOT NULL,
		LatestAuditItemID  [dbo].[AuditItemID]			NOT NULL,
		ContactMechanismID [dbo].[ContactMechanismID]	NOT NULL,
		EmailAddressSource [dbo].[EmailAddressSource]	NULL
	);
		
	

	---------------------------------------------------------------------------------------------------
	-- Get latest action date from file first rather than highest AuditItemID because the action date 
	-- can be changed when when we invalidate a loaded file.  We don't want to use the latest email 
	-- from an invalidated file.
	---------------------------------------------------------------------------------------------------
	-- Create temp table
	CREATE TABLE #LatestActionDatesByParty
	(
		PartyID				BIGINT, 
		EventCategoryID		INT, 
		LatestActionDate	DATETIME2,
		PartyType			CHAR(1)
	)
	
	-- Add people
	INSERT INTO #LatestActionDatesByParty (PartyID, EventCategoryID, LatestActionDate, PartyType)
	SELECT AP.PartyID, 
		ETC.[EventCategoryID], 
		MAX(F.ActionDate) AS LatestActionDate, 
		'P' AS PartyType
	FROM [$(AuditDB)].Audit.People AP
		INNER JOIN Party.People P ON P.PartyID = AP.PartyID
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = AP.AuditItemID
		INNER JOIN Event.EventTypeCategories ETC ON ETC.EventTypeID = AE.EventTypeID
		INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
												  AND EC.IncludeInLatestEmailMetadata = 1
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AP.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = AI.AuditID
												--AND F.FileTypeID = (SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Sample')   -- Customer Updates are added seperately
		INNER JOIN [$(AuditDB)].dbo.FileTypes FT ON F.FileTypeID = FT.FileTypeID -- V1.10
		WHERE FT.FileType = 'Sample' -- V1.10
	GROUP BY AP.PartyID, 
		ETC.EventCategoryID

	-- Add Organisations
	INSERT INTO #LatestActionDatesByParty (PartyID, EventCategoryID, LatestActionDate, PartyType)
	SELECT AO.PartyID, 
		ETC.EventCategoryID, 
		MAX(F.ActionDate) AS LatestActionDate, 
		'O' AS PartyType
	FROM [$(AuditDB)].Audit.Organisations AO
		INNER JOIN Party.Organisations O ON O.PartyID = AO.PartyID
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = AO.AuditItemID
		INNER JOIN Event.EventTypeCategories ETC ON ETC.EventTypeID = AE.EventTypeID
		INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
												  AND EC.IncludeInLatestEmailMetadata = 1
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AO.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = AI.AuditID
												--AND F.FileTypeID = (SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Sample')   -- Customer Updates are added seperately
		INNER JOIN [$(AuditDB)].dbo.FileTypes FT ON F.FileTypeID = FT.FileTypeID -- V1.10
		WHERE FT.FileType = 'Sample' -- V1.10
	GROUP BY AO.PartyID, 
		ETC.EventCategoryID



	---------------------------------------------------------------------------------------------------
	-- Get the latest AuditItemID for each party and actiondate
	---------------------------------------------------------------------------------------------------
	CREATE TABLE #LatestAuditItemIDsForActionDate
	(
		PartyID				BIGINT, 
		EventCategoryID		INT, 
		PartyType			CHAR(1),
		LatestAuditItemID	BIGINT
	)
	
	-- Add People
	INSERT INTO #LatestAuditItemIDsForActionDate (PartyID, EventCategoryID, PartyType, LatestAuditItemID)
	SELECT AP.PartyID, 
		ETC.EventCategoryID, 
		LAD.PartyType, 
		MAX(AP.AuditItemID) AS LatestAuditItemID 
	FROM [$(AuditDB)].Audit.People AP
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = AP.AuditItemID
		INNER JOIN Event.EventTypeCategories ETC ON ETC.EventTypeID = AE.EventTypeID
		INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
												  AND EC.IncludeInLatestEmailMetadata = 1
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AP.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = AI.AuditID
												--AND F.FileTypeID = (SELECT FileTypeID FROM Sample_Audit.dbo.FileTypes WHERE FileType = 'Sample')   -- Customer Updates are added seperately
		INNER JOIN #LatestActionDatesByParty LAD ON LAD.PartyID = AP.PartyID			-- Constrain by last latest action dates
												AND LAD.EventCategoryID = ETC.EventCategoryID
												AND LAD.LatestActionDate = F.ActionDate
		INNER JOIN [$(AuditDB)].dbo.FileTypes FT ON F.FileTypeID = FT.FileTypeID -- V1.10
		WHERE FT.FileType = 'Sample' -- V1.10
	GROUP BY AP.PartyID, 
		LAD.PartyType, 
		ETC.EventCategoryID

	-- Add Organisations
	INSERT INTO #LatestAuditItemIDsForActionDate (PartyID, EventCategoryID, PartyType, LatestAuditItemID)
	SELECT AO.PartyID, 
		ETC.EventCategoryID, 
		LAD.PartyType, 
		MAX(AO.AuditItemID) AS LatestAuditItemID
	FROM [$(AuditDB)].Audit.Organisations AO
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = AO.AuditItemID
		INNER JOIN Event.EventTypeCategories ETC ON ETC.[EventTypeID] = AE.EventTypeID
		INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID
												  AND EC.IncludeInLatestEmailMetadata = 1
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AO.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = AI.AuditID
											  --AND F.FileTypeID = (SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Sample')   -- Customer Updates are added seperately
		INNER JOIN #LatestActionDatesByParty LAD ON LAD.PartyID = AO.PartyID			-- Constrain by last latest action dates
												AND LAD.EventCategoryID = ETC.EventCategoryID
												AND LAD.LatestActionDate = F.ActionDate
		INNER JOIN [$(AuditDB)].dbo.FileTypes FT ON F.FileTypeID = FT.FileTypeID -- V1.10
		WHERE FT.FileType = 'Sample' -- V1.10
	GROUP BY AO.PartyID, 
		LAD.PartyType, 
		ETC.EventCategoryID

	-- Remove old temp table
	DROP TABLE #LatestActionDatesByParty

	-- REMOVE rows where party not found in People or Organisations Tables
	DELETE LAI 
	FROM #LatestAuditItemIDsForActionDate LAI 
		LEFT JOIN Sample.Party.People P ON P.PartyID = LAI.PartyID
		LEFT JOIN Sample.Party.Organisations O ON O.PartyID = LAI.PartyID
	WHERE P.PartyID IS NULL
		AND O.PartyID IS NULL
	

	---------------------------------------------------
	-- NOW CREATE TABLE OF LATEST EMAIL ADDRESSES BY PARTY 
	---------------------------------------------------
	INSERT INTO Meta.PartyLatestReceivedEmails (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder)
	SELECT DISTINCT 
		LAI.PartyID, 
		LAI.EventCategoryID, 
		LAI.PartyType, 
		LAI.LatestAuditItemID, 
		EA.ContactMechanismID, 
		EA.EmailAddressSource, 
		CASE	WHEN EmailAddressSource = 'EmailAddress' THEN 1 
				WHEN EmailAddressSource = 'PrivEmailAddress' THEN 2 
				ELSE 3 END AS EmailPriorityOrder
	FROM #LatestAuditItemIDsForActionDate LAI 
		LEFT JOIN [$(AuditDB)].Audit.PartyContactMechanisms PCM ON PCM.AuditItemID = LAI.LatestAuditItemID
																  AND PCM.PartyID = LAI.PartyID
		LEFT JOIN [$(AuditDB)].Audit.EmailAddresses EA ON EA.AuditItemID = LAI.LatestAuditItemID

	-- Remove temp table
	DROP TABLE #LatestAuditItemIDsForActionDate


	------------------------------------------------------
	-- ADD IN CUSTOMER UPDATE EMAIL ADDRESSES
	------------------------------------------------------
	CREATE TABLE #CustomerUpdatesOrdered
	(
		PartyID				BIGINT, 
		AuditItemID			BIGINT,
		ActionDate			DATETIME2,
		ContactMechanismID	BIGINT,
		RowID				INT  
	)
	
	-- Get the time window in which Customer Update Emails are valid
	DECLARE @CustomerUpdateEmailWindow_Days  INT     
	SELECT @CustomerUpdateEmailWindow_Days = LatestEmail_CustomerUpdateWindow FROM Meta.System


	---- Create an ordered list in case we get 2 customer updates for the same Party in the time period specified, we take latest received
	--INSERT INTO #CustomerUpdatesOrdered (PartyID, AuditItemID, ActionDate, ContactMechanismID, RowID)
	--SELECT CUEA.PartyID, 
	--	CUEA.AuditItemID, 
	--	F.ActionDate, 
	--	EA.ContactMechanismID,
	--	ROW_NUMBER() OVER( PARTITION BY CUEA.PartyID ORDER BY F.ActionDate DESC, CUEA.AuditItemID DESC) AS RowID  
	--FROM [$(AuditDB)].Audit.CustomerUpdate_EmailAddress CUEA 
	--	INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = CUEA.AuditItemID
	--	INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = AI.AuditID
	--										AND F.ActionDate >= DATEADD(DAY, @CustomerUpdateEmailWindow_Days, GETDATE())
	--	INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CUEA.ContactMechanismID 
	--WHERE CUEA.DateProcessed IS NOT NULL				
	--	AND CUEA.CasePartyCombinationValid = 1


	-------------------------------------------------------  V1.6  -------------------------------------------------------	
	-- Create an ordered list in case we get 2 customer updates for the same Party in the time period specified, we take latest received
	INSERT INTO #CustomerUpdatesOrdered (PartyID, AuditItemID, ActionDate, ContactMechanismID, RowID)
	SELECT CTE_CU.PartyID, 
		CTE_CU.AuditItemID, 
		CTE_CU.ActionDate, 
		CTE_CU.ContactMechanismID,
		ROW_NUMBER() OVER (PARTITION BY PartyID ORDER BY ActionDate DESC, AuditItemID DESC) AS RowID 
	FROM (	-- CUSTOMER UPDATES
			SELECT CUEA.PartyID, 
				CUEA.AuditItemID, 
				F.ActionDate, 
				EA.ContactMechanismID
			FROM [$(AuditDB)].Audit.CustomerUpdate_EmailAddress CUEA 
				INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = CUEA.AuditItemID
				INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = AI.AuditID
														AND F.ActionDate >= DATEADD(DAY, @CustomerUpdateEmailWindow_Days, GETDATE())
				INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CUEA.ContactMechanismID 
			WHERE CUEA.DateProcessed IS NOT NULL				
				AND CUEA.CasePartyCombinationValid = 1
			UNION
			-- OWAP UPDATES 
			SELECT PCM.PartyID, 
				CUEA.AuditItemID, 
				F.ActionDate, 
				PCM.ContactMechanismID
			FROM [$(AuditDB)].Audit.EmailAddresses CUEA  
				INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = CUEA.AuditItemID
				INNER JOIN [$(AuditDB)].OWAP.Actions F ON  AI.AuditItemID = F.AuditItemID
															AND F.ActionDate >= DATEADD(DAY, @CustomerUpdateEmailWindow_Days, GETDATE())	-- V1.7
				INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms PCM  ON CUEA.AuditItemID = PCM.AuditItemID
				INNER JOIN ContactMechanism.EmailAddresses EA  ON EA.ContactMechanismID = PCM.ContactMechanismID)	CTE_CU					-- V1.7
	-------------------------------------------------------  V1.6  -------------------------------------------------------	
	



	-- Add the customer update Emails into the PartyLatestReceivedEmails reference table (this is what will be used to check for Barred emails)
	INSERT INTO Meta.PartyLatestReceivedEmails (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder)
	SELECT CUO.PartyID, 
		0 AS EventCategoryID,						-- Unspecified as Customer Update Email Address is for all Event Types
		CASE	WHEN P.PartyID IS NOT NULL THEN 'P' 
				ELSE 'O' END AS PartyType,
		CUO.AuditItemID AS LatestAuditItemID,
		CUO.ContactMechanismID,
		'CustomerUpdate' AS EmailAddressSource,
		0 AS EmailPriorityOrder						-- Puts Customer updates ahead of all other EmailAddresses 
	FROM #CustomerUpdatesOrdered CUO
		LEFT JOIN Party.People P ON P.PartyID = CUO.PartyID
		LEFT JOIN Party.Organisations O ON O.PartyID = CUO.PartyID
	WHERE CUO.RowID = 1

	-- Remove temp table
	DROP TABLE #CustomerUpdatesOrdered


	------------------------------------------------------
	-- Copy latest emails for processing best email
	------------------------------------------------------
	CREATE TABLE #LatestReceivedPartyBestEmails
	(
		PartyID				BIGINT, 
		EventCategoryID		INT,
		PartyType			CHAR(1),
		LatestAuditItemID	BIGINT,
		ContactMechanismID	BIGINT,
		EmailAddressSource	VARCHAR(50),
		EmailPriorityOrder	INT
	)

	--Copy genuine Event Category records first
	INSERT INTO #LatestReceivedPartyBestEmails (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder)
	SELECT PartyID,
		EventCategoryID,
		PartyType,
		LatestAuditItemID,
		ContactMechanismID,
		EmailAddressSource,
		EmailPriorityOrder    
	FROM Meta.PartyLatestReceivedEmails LRE
	WHERE LRE.EventCategoryID <> 0
		AND ContactMechanismID Is NOT NULL

	-- Then copy in the Customer Update email addresses - split them out by Event Category for processing by Survey Type
	INSERT INTO #LatestReceivedPartyBestEmails (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder)
	SELECT LRE.PartyID, 
		EC.EventCategoryID,
		LRE.PartyType,
		LRE.LatestAuditItemID,
		LRE.ContactMechanismID,
		LRE.EmailAddressSource,
		LRE.EmailPriorityOrder
	FROM Meta.PartyLatestReceivedEmails LRE
		INNER JOIN Event.EventCategories EC ON EC.IncludeInLatestEmailMetadata = 1  -- Join to split into the EventCatgories
	WHERE LRE.EventCategoryID = 0



	----------------------------------------
	-- DELETE ANY PartyNonSolicitations
	----------------------------------------
	DELETE LAI
	FROM #LatestReceivedPartyBestEmails LAI 
		INNER JOIN (	SELECT DISTINCT
							NS.PartyID 
						FROM dbo.NonSolicitations NS
							INNER JOIN Party.NonSolicitations PNS ON NS.NonSolicitationID = PNS.NonSolicitationID
						WHERE GETDATE() >= NS.FromDate
							AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')) AS PNS ON LAI.PartyID = PNS.PartyID


	----------------------------------------------------
	-- DELETE ANY ContactMechanismNonSolicitations
	----------------------------------------------------
	DELETE E
	FROM #LatestReceivedPartyBestEmails E
		INNER JOIN (	SELECT DISTINCT
							NS.PartyID,
							CMNS.ContactMechanismID 
						FROM dbo.NonSolicitations NS
							INNER JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
							INNER JOIN ContactMechanism.EmailAddresses EA ON CMNS.ContactMechanismID = EA.ContactMechanismID
						WHERE GETDATE() >= NS.FromDate
							AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')) AS CMNS ON E.PartyID = CMNS.PartyID 
																									AND E.ContactMechanismID=CMNS.ContactMechanismID


	----------------------------------------------------
	-- DELETE ANY ContactMechanismTypeNonSolicitations
	----------------------------------------------------
	DELETE E
	FROM #LatestReceivedPartyBestEmails E
	INNER JOIN (	SELECT DISTINCT
						NS.PartyID
					FROM dbo.NonSolicitations NS
						INNER JOIN ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
					WHERE CMTNS.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address')
						AND GETDATE() >= NS.FromDate
						AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')) AS CMTNS ON E.PartyID = CMTNS.PartyID


	----------------------------------------------------
	-- V1.8 DELETE RUSSIAN NON-ASCII EMAILS
	----------------------------------------------------	
	DELETE E
	FROM #LatestReceivedPartyBestEmails E
		INNER JOIN WebsiteReporting.dbo.SampleQualityAndSelectionLogging SL ON E.LatestAuditItemID = SL.AuditItemID
		INNER JOIN ContactMechanism.EmailAddresses EA ON E.ContactMechanismID = EA.ContactMechanismID
	WHERE SL.Market = 'Russian Federation'
		AND EA.EmailAddress != CAST(EA.EmailAddress AS VARCHAR(4000))		-- V1.9		
		--AND dbo.udfIdentifyNonASCIICharacters(EA.EmailAddress) = 1		-- V1.9
		
		
	------------------------------------------------------------------------------------------------------------------------
	-- Now split out remaining Emails into AFRL temp table prior to removing Blacklists as AFRL has different blacklistings
	------------------------------------------------------------------------------------------------------------------------
	CREATE TABLE #LatestReceivedPartyBestEmailsAFRL
	(
		PartyID				BIGINT, 
		EventCategoryID		INT,
		PartyType			CHAR(1),
		LatestAuditItemID	BIGINT,
		ContactMechanismID	INT,
		EmailAddressSource	VARCHAR(50),
		EmailPriorityOrder	INT
	)

	--Copy genuine Event Category records first
	INSERT INTO #LatestReceivedPartyBestEmailsAFRL (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder)
	SELECT PartyID,
		EventCategoryID,
		PartyType,
		LatestAuditItemID,
		ContactMechanismID,
		EmailAddressSource,
		EmailPriorityOrder    
	FROM #LatestReceivedPartyBestEmails 


	------------------------------------------------------------------------------------------------------------------------
	-- V1.5 Now split out remaining Emails into temp table so have a table without blacklists removed
	------------------------------------------------------------------------------------------------------------------------
	CREATE TABLE #LatestReceivedPartyBestEmailsBlacklistIncluded
	(
		PartyID				BIGINT, 
		EventCategoryID		INT,
		PartyType			CHAR(1),
		LatestAuditItemID	BIGINT,
		ContactMechanismID	INT,
		EmailAddressSource	VARCHAR(50),
		EmailPriorityOrder	INT
	)

	--Copy genuine Event Category records first
	INSERT INTO #LatestReceivedPartyBestEmailsBlacklistIncluded (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder)
	SELECT PartyID,
		   EventCategoryID,
		   PartyType,
		   LatestAuditItemID,
		   ContactMechanismID,
		   EmailAddressSource,
		   EmailPriorityOrder    
	FROM #LatestReceivedPartyBestEmails 
	
	
	----------------------------------------------------
	-- DELETE ANY BLACKLISTED EMAILS
	----------------------------------------------------	
	-- Normal 
	DELETE E
	FROM #LatestReceivedPartyBestEmails E
		INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = E.ContactMechanismID

	-- AFRL 
	DELETE E
	FROM #LatestReceivedPartyBestEmailsAFRL E
		INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = E.ContactMechanismID
		INNER JOIN ContactMechanism.BlacklistStrings BS ON BS.BlacklistStringID = BCM.BlacklistStringID
	WHERE BS.BlacklistTypeID IN (SELECT BlacklistTypeID FROM ContactMechanism.BlacklistTypes BT WHERE BT.AFRLFilter = 1)



	----------------------------------------------------
	-- CREATE PARTY BEST EMAIL ADDRESS TABLES
	----------------------------------------------------
	
	-----------------
	-- NORMAL FIRST
	-----------------
	CREATE TABLE #LatestReceivedPartyBestEmailsOrdered
	(
		PartyID				BIGINT, 
		EventCategoryID		INT,
		PartyType			CHAR(1),
		LatestAuditItemID	BIGINT,
		ContactMechanismID	BIGINT,
		EmailAddressSource	VARCHAR(50),
		EmailPriorityOrder	INT,
		RowID				BIGINT
	)
	
	-- First order them by Email Priority
	INSERT INTO #LatestReceivedPartyBestEmailsOrdered (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder, RowID)
	SELECT LRE.PartyID, 
		LRE.EventCategoryID, 
		LRE.PartyType, 
		LRE.LatestAuditItemID, 
		LRE.ContactMechanismID, 
		LRE.EmailAddressSource, 
		LRE.EmailPriorityOrder,
		ROW_NUMBER() OVER (PARTITION BY LRE.PartyID, LRE.EventCategoryID ORDER BY LRE.EmailPriorityOrder ASC, LRE.LatestAuditItemID DESC, ContactMechanismID DESC) AS RowID  
	FROM #LatestReceivedPartyBestEmails LRE
	ORDER BY LRE.PartyID, 
		LRE.EventCategoryID 

	-- Then save highest priority email as "Best" 
	INSERT INTO Meta.PartyBestEmailAddressesLatestOnly (PartyID, EventCategoryID, LatestAuditItemID, ContactMechanismID, EmailAddressSource)
	SELECT EO.PartyID, 
		EO.EventCategoryID, 
		EO.LatestAuditItemID, 
		EO.ContactMechanismID, 
		EO.EmailAddressSource
	FROM #LatestReceivedPartyBestEmailsOrdered EO
	WHERE EO.RowID = 1

	-- Remove temp table
	DROP TABLE #LatestReceivedPartyBestEmailsOrdered

	
	-----------------
	-- THEN AFRL
	-----------------
	CREATE TABLE #LatestReceivedPartyBestEmailsOrderedAFRL
	(
		PartyID				BIGINT, 
		EventCategoryID		INT,
		PartyType			CHAR(1),
		LatestAuditItemID	BIGINT,
		ContactMechanismID	BIGINT,
		EmailAddressSource	VARCHAR(50),
		EmailPriorityOrder	INT,
		RowID				BIGINT
	)
	
	-- First order them by Email Priority
	INSERT INTO #LatestReceivedPartyBestEmailsOrderedAFRL (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder, RowID)
	SELECT LRE.PartyID, 
		LRE.EventCategoryID, 
		LRE.PartyType, 
		LRE.LatestAuditItemID, 
		LRE.ContactMechanismID, 
		LRE.EmailAddressSource, 
		LRE.EmailPriorityOrder,
		ROW_NUMBER() OVER (PARTITION BY LRE.PartyID, LRE.EventCategoryID ORDER BY LRE.EmailPriorityOrder ASC, LRE.LatestAuditItemID DESC, ContactMechanismID DESC) AS RowID  
	FROM #LatestReceivedPartyBestEmailsAFRL LRE
	ORDER BY LRE.PartyID, LRE.EventCategoryID 

	-- Then save highest priority email as "Best" 
	INSERT INTO Meta.PartyBestEmailAddressesAFRL (PartyID, EventCategoryID, LatestAuditItemID, ContactMechanismID, EmailAddressSource)
	SELECT EO.PartyID, 
		EO.EventCategoryID, 
		EO.LatestAuditItemID, 
		EO.ContactMechanismID, 
		EO.EmailAddressSource
	FROM #LatestReceivedPartyBestEmailsOrderedAFRL EO
	WHERE EO.RowID = 1

	-- Remove temp table
	DROP TABLE #LatestReceivedPartyBestEmailsOrderedAFRL
	

	-----------------
	-- THEN BLACKLIST INCLUDED
	-----------------
	CREATE TABLE #LatestReceivedPartyBestEmailsBlacklistIncludedOrdered
	(
		PartyID				BIGINT, 
		EventCategoryID		INT,
		PartyType			CHAR(1),
		LatestAuditItemID	BIGINT,
		ContactMechanismID	BIGINT,
		EmailAddressSource	VARCHAR(50),
		EmailPriorityOrder	INT,
		RowID				BIGINT
	)
	
	-- First order them by Email Priority
	INSERT INTO #LatestReceivedPartyBestEmailsBlacklistIncludedOrdered (PartyID, EventCategoryID, PartyType, LatestAuditItemID, ContactMechanismID, EmailAddressSource, EmailPriorityOrder, RowID)
	SELECT LRE.PartyID, 
		LRE.EventCategoryID, 
		LRE.PartyType, 
		LRE.LatestAuditItemID, 
		LRE.ContactMechanismID, 
		LRE.EmailAddressSource, 
		LRE.EmailPriorityOrder,
		ROW_NUMBER() OVER (PARTITION BY LRE.PartyID, LRE.EventCategoryID ORDER BY LRE.EmailPriorityOrder ASC, LRE.LatestAuditItemID DESC, ContactMechanismID DESC) AS RowID  
	FROM #LatestReceivedPartyBestEmailsBlacklistIncluded LRE
	ORDER BY LRE.PartyID, 
		LRE.EventCategoryID 
	
	-- Then save highest priority email as "Best" 
	INSERT INTO Meta.PartyBestEmailAddressesBlacklistIncluded (PartyID, EventCategoryID, LatestAuditItemID, ContactMechanismID, EmailAddressSource)
	SELECT EO.PartyID, 
		EO.EventCategoryID, 
		EO.LatestAuditItemID, 
		EO.ContactMechanismID, 
		EO.EmailAddressSource
	FROM #LatestReceivedPartyBestEmailsBlacklistIncludedOrdered EO
	WHERE EO.RowID = 1

	-- Remove temp table
	DROP TABLE #LatestReceivedPartyBestEmailsBlacklistIncludedOrdered
	DROP TABLE #LatestReceivedPartyBestEmailsBlacklistIncluded
	

	-----------------------------------------------------------------
	-- CREATE INDEX
	-----------------------------------------------------------------
	CREATE NONCLUSTERED INDEX [IX_Meta_PartyBestEmailAddressesAFRL_PartyID]
    ON [Meta].[PartyBestEmailAddressesAFRL]([PartyID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

	CREATE NONCLUSTERED INDEX [IX_Meta_PartyBestEmailAddressesLatestOnly_PartyID]
    ON [Meta].[PartyBestEmailAddressesLatestOnly]([PartyID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

	CREATE NONCLUSTERED INDEX [IX_Meta_PartyLatestReceivedEmails_PartyID]
    ON [Meta].[PartyLatestReceivedEmails]([PartyID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

	CREATE NONCLUSTERED INDEX [IX_Meta_PartyBestEmailAddressesBlacklistIncluded_PartyID]
    ON [Meta].[PartyBestEmailAddressesBlacklistIncluded]([PartyID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);


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