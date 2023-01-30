
CREATE TRIGGER [Party].[TR_I_vwDA_ContactPreferences]
    ON [Party].[vwDA_ContactPreferences]
	INSTEAD OF INSERT

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
	Purpose:	Handles insert into Party.ContactPreferences and Party.ContactPreferencesBySurvey from VWT (including auditing)
	
	Version			Date			Developer			Comment
	1.0				01-12-2016		Chris Ross			Created as part of BUG 13364. 
	1.1				10-01-2018		Chris Ross			BUG 14196 + 14486 - Introduce OverridePreferences flag to allow manual contact preferences updates.
																			Also include a Comments columns to allow the addition of Bug numbers etc for identification purposes.
	1.2				22-06-2018		Chris Ross			BUG 14730 - Add in RemoveUnsubscribe funtionality.  [Released to Live: 28-02-2019]
	1.3				31-07-2018		Chris Ross			BUG 14842 - Add in the EventCategoryPersistOveride indicator. Also, change sort order to ensure we prioritise 
																	any Suppressions present where multiple entries for the same customer.  	
	1.4				21-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
*/


	BEGIN TRAN


		DECLARE @UpdateDate DATETIME2			-- We have a single update time to pull all the updates together and to ensure the DISTINCT works on the new record inserts at the end
		SET @UpdateDate = GETDATE()


		-----------------------------------------------------------------
		-- Create the temporary working tables 
		-----------------------------------------------------------------
		CREATE TABLE #PrefsBySurvey
			(
				AuditItemID				[bigint],
				PartyID					[bigint] ,
				EventCategoryID			[int] ,

				OriginalPartySuppression	BIT NULL,
				OriginalPostalSuppression	BIT NULL,
				OriginalEmailSuppression	BIT NULL,
				OriginalPhoneSuppression	BIT NULL,
				
				SuppliedPartySuppression  [bit] ,
				SuppliedPostalSuppression [bit] ,
				SuppliedEmailSuppression  [bit] ,
				SuppliedPhoneSuppression  [bit] ,
				SuppliedPartyUnsubscribe  [bit] ,
				
				NewPartySuppression		[bit] DEFAULT (0),
				NewPostalSuppression	[bit] DEFAULT (0),
				NewEmailSuppression		[bit] DEFAULT (0),
				NewPhoneSuppression		[bit] DEFAULT (0),
											 
				UpdateDate				[datetime2](7),
				UpdateSource			[varchar](50),
				MarketCountryID			[int],
				
				SampleMarketID			[int],
				ContactPreferencesPersist [bit],
				
				EventCategoryPersistOveride [bit],		-- v1.3
				
				OverridePreferences		[bit],			-- v1.1
				RemoveUnsubscribe		[bit],			-- v1.2
				Comments				VARCHAR(255)	-- v1.1
				
				
			)

		CREATE TABLE #PrefsByParty
			(
				AuditItemID				[bigint],
				PartyID					[bigint] ,
				EventCategoryID			[int] ,

				OriginalPartySuppression	BIT NULL,
				OriginalPostalSuppression	BIT NULL,
				OriginalEmailSuppression	BIT NULL,
				OriginalPhoneSuppression	BIT NULL,
				OriginalPartyUnsubscribe	BIT NULL,
				
				SuppliedPartySuppression  [bit] ,
				SuppliedPostalSuppression [bit] ,
				SuppliedEmailSuppression  [bit] ,
				SuppliedPhoneSuppression  [bit] ,
				SuppliedPartyUnsubscribe  [bit] ,
				
				NewPartySuppression		[bit] DEFAULT (0),
				NewPostalSuppression	[bit] DEFAULT (0),
				NewEmailSuppression		[bit] DEFAULT (0),
				NewPhoneSuppression		[bit] DEFAULT (0),
				NewPartyUnsubscribe		[bit] DEFAULT (0),
				
				UpdateDate				[datetime2](7),
				UpdateSource			[varchar](50),
				MarketCountryID			[int],
				
				SampleMarketID			[int],
				ContactPreferencesPersist [bit],
				
				EventCategoryPersistOveride [bit],		-- v1.3
				
				OverridePreferences		[bit],			-- v1.1
				RemoveUnsubscribe		[bit],			-- v1.2
				Comments				VARCHAR(255)	-- v1.1
			)




		-----------------------------------------------------------------
		-- Populate the temporary working tables 
		-----------------------------------------------------------------


		-- Save the preferences by Survey we are loading/updating with
		INSERT INTO #PrefsBySurvey (
							AuditItemID, 
							PartyID, 
							EventCategoryID   , 

							OriginalPartySuppression,
							OriginalPostalSuppression,
							OriginalEmailSuppression,
							OriginalPhoneSuppression,
		
							SuppliedPartySuppression, 
							SuppliedPostalSuppression, 
							SuppliedEmailSuppression, 
							SuppliedPhoneSuppression, 
							SuppliedPartyUnsubscribe, 
							
							UpdateSource,
							UpdateDate,
							MarketCountryID, 
							SampleMarketID,
							ContactPreferencesPersist,
							
							EventCategoryPersistOveride,	-- v1.3
							
							OverridePreferences,			-- v1.1
							RemoveUnsubscribe,				-- v1.2
							Comments						-- v1.1
							)
		SELECT 	
			I.AuditItemID, 
			I.PartyID, 
			I.EventCategoryID   , 

			cps.PartySuppression  AS OriginalPartySuppression, 
			cps.PostalSuppression AS OriginalPostalSuppression, 
			cps.EmailSuppression  AS OriginalEmailSuppression, 
			cps.PhoneSuppression  AS OriginalPhoneSuppression, 
			
			I.PartySuppression  AS SuppliedPartySuppression, 
			I.PostalSuppression AS SuppliedPostalSuppression, 
			I.EmailSuppression  AS SuppliedEmailSuppression, 
			I.PhoneSuppression  AS SuppliedPhoneSuppression, 
			I.PartyUnsubscribe  AS SuppliedPartyUnsubscribe, 
			
			I.UpdateSource,
			@UpdateDate AS UpdateDate,
			I.MarketCountryID, 
			m.MarketID,
			CASE WHEN ISNULL(I.OverridePreferences, 0) = 1 THEN 0 
					WHEN eco.EventCategoryPersistOveride IS NOT NULL THEN eco.EventCategoryPersistOveride
					ELSE ISNULL(m.ContactPreferencesPersist, 0) END AS ContactPreferencesPersist,
					
			eco.EventCategoryPersistOveride,	-- v1.3
					
			I.OverridePreferences,			-- v1.1
			I.RemoveUnsubscribe,			-- v1.2
			I.Comments						-- v1.1
			
		FROM INSERTED I
		LEFT JOIN dbo.Markets m ON m.CountryID = I.MarketCountryID
		LEFT JOIN Party.ContactPreferencesBySurvey cps ON cps.PartyID = I.PartyID AND cps.EventCategoryID = I.EventCategoryID
		LEFT JOIN Party.ContactPreferencesEventCategoryOverides eco ON eco.MarketID = m.MarketID AND eco.EventCategoryID = I.EventCategoryID			-- v1.3
		

		-- Save the preferences by Party we are loading/updating with
		INSERT INTO #PrefsByParty (
							AuditItemID, 
							PartyID, 
							EventCategoryID   , 

							OriginalPartySuppression,
							OriginalPostalSuppression,
							OriginalEmailSuppression,
							OriginalPhoneSuppression,
							OriginalPartyUnsubscribe,
							
							SuppliedPartySuppression, 
							SuppliedPostalSuppression, 
							SuppliedEmailSuppression, 
							SuppliedPhoneSuppression, 
							SuppliedPartyUnsubscribe, 
							
							UpdateSource,
							UpdateDate,
							MarketCountryID, 
							SampleMarketID,
							ContactPreferencesPersist,
							
							EventCategoryPersistOveride,	-- v1.3
							
							OverridePreferences,			-- v1.1
							RemoveUnsubscribe,				-- v1.2
							Comments					    -- v1.1
							)
		SELECT 	
			I.AuditItemID, 
			I.PartyID, 
			I.EventCategoryID   , 

			cp.PartySuppression  AS OriginalPartySuppression, 
			cp.PostalSuppression AS OriginalPostalSuppression, 
			cp.EmailSuppression  AS OriginalEmailSuppression, 
			cp.PhoneSuppression  AS OriginalPhoneSuppression, 
			cp.PartyUnsubscribe  AS OriginalPartyUnsubscribe, 

			I.PartySuppression  AS SuppliedPartySuppression, 
			I.PostalSuppression AS SuppliedPostalSuppression, 
			I.EmailSuppression  AS SuppliedEmailSuppression, 
			I.PhoneSuppression  AS SuppliedPhoneSuppression, 
			I.PartyUnsubscribe  AS SuppliedPartyUnsubscribe, 
			
			I.UpdateSource,
			@UpdateDate AS UpdateDate,
			I.MarketCountryID, 
			m.MarketID,
			CASE WHEN ISNULL(I.OverridePreferences, 0) = 1 THEN 0 
										WHEN eco.EventCategoryPersistOveride IS NOT NULL THEN eco.EventCategoryPersistOveride			-- v1.3
										ELSE ISNULL(m.ContactPreferencesPersist, 0) END AS ContactPreferencesPersist,
					
			eco.EventCategoryPersistOveride, -- v1.3		
					
			I.OverridePreferences,			-- v1.1
			I.RemoveUnsubscribe,			-- v1.2
			I.Comments						-- v1.1
			
		FROM INSERTED I
		LEFT JOIN dbo.Markets m ON m.CountryID = I.MarketCountryID
		LEFT JOIN Party.ContactPreferences cp ON cp.PartyID = I.PartyID
		LEFT JOIN Party.ContactPreferencesEventCategoryOverides eco ON eco.MarketID = m.MarketID AND eco.EventCategoryID = I.EventCategoryID			-- v1.3
		
				


			
		---------------------------------------------------------------------------------------------------------------
		-- LATEST VALUE UPDATES (NON-PERSISTANT)
		---------------------------------------------------------------------------------------------------------------

		; WITH CTE_LatestSuppress		-- v1.3
		AS (
			SELECT PartyID, EventCategoryID, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression, 
					CAST(SuppliedPartySuppression AS INT) AS PartySuppressINT, 
					(CAST(ISNULL(SuppliedPartySuppression, 0) AS int) + 
					 CAST(ISNULL(SuppliedPostalSuppression, 0) AS int) + 
					 CAST(ISNULL(SuppliedEmailSuppression, 0) AS int) +
					 CAST(ISNULL(SuppliedPhoneSuppression, 0) AS int) ) AS TotalSuppressions
			FROM #PrefsBySurvey p 
			WHERE p.ContactPreferencesPersist = 0
			AND COALESCE(SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression) IS NOT NULL		-- Where we have been supplied actual suppressions (i.e. not unsubscribe only)
			)
		, CTE_LatestSuppressionsBySurveyOrdered
		AS (
			SELECT PartyID, EventCategoryID, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression, 
					ROW_NUMBER() OVER(PARTITION BY PartyID, EventCategoryID ORDER BY PartySuppressINT DESC, TotalSuppressions DESC) AS RowNumber
			FROM CTE_LatestSuppress ls 
			) 
		UPDATE pbs
		SET pbs.NewPartySuppression	 = po.SuppliedPartySuppression	,
			pbs.NewPostalSuppression = po.SuppliedPostalSuppression	,
			pbs.NewEmailSuppression	 = po.SuppliedEmailSuppression	,
			pbs.NewPhoneSuppression	 = po.SuppliedPhoneSuppression
		FROM CTE_LatestSuppressionsBySurveyOrdered po
		INNER JOIN #PrefsBySurvey pbs ON pbs.PartyID = po.PartyID AND pbs.EventCategoryID = po.EventCategoryID
		WHERE po.RowNumber = 1
		

		; WITH CTE_LatestSuppress			-- v1.3
		AS (
			SELECT PartyID, EventCategoryID, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression, 
					CAST(SuppliedPartySuppression AS INT) AS PartySuppressINT, 
					(CAST(ISNULL(SuppliedPartySuppression, 0) AS int) + 
					 CAST(ISNULL(SuppliedPostalSuppression, 0) AS int) + 
					 CAST(ISNULL(SuppliedEmailSuppression, 0) AS int) +
					 CAST(ISNULL(SuppliedPhoneSuppression, 0) AS int) ) AS TotalSuppressions
			FROM #PrefsBySurvey p 
			WHERE p.ContactPreferencesPersist = 0
			AND COALESCE(SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression) IS NOT NULL		-- Where we have been supplied actual suppressions (i.e. not unsubscribe only)
			)
		,CTE_LatestSuppressionsByPartyOrdered
		AS (
			SELECT PartyID, EventCategoryID, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression, 
					ROW_NUMBER() OVER(PARTITION BY PartyID ORDER BY PartySuppressINT DESC, TotalSuppressions DESC, EventCategoryID ASC) AS RowNumber
			FROM CTE_LatestSuppress ls 
		) 
		UPDATE pbp
		SET pbp.NewPartySuppression	 = po.SuppliedPartySuppression	,
			pbp.NewPostalSuppression = po.SuppliedPostalSuppression	,
			pbp.NewEmailSuppression	 = po.SuppliedEmailSuppression	,
			pbp.NewPhoneSuppression	 = po.SuppliedPhoneSuppression
		FROM CTE_LatestSuppressionsByPartyOrdered po
		INNER JOIN #PrefsByParty pbp ON pbp.PartyID = po.PartyID 
		WHERE po.RowNumber = 1
		AND pbp.ContactPreferencesPersist = 0	-- Only update entries where Persist if FALSE





		---------------------------------------------------------------------------------------------------------------
		-- PERSISTING VALUES 
		---------------------------------------------------------------------------------------------------------------

		-----------------
		--- BY SURVEY ---
		-----------------
		CREATE TABLE #PersistedSuppressionsBySurvey
			(
				PartyID					BIGINT,
				EventCategoryID			INT, 
				NewPartySuppression		TINYINT,	
				NewPostalSuppression	TINYINT, 
				NewEmailSuppression		TINYINT, 
				NewPhoneSuppression		TINYINT	
			)

		-- Roll-up the values
		;WITH CTE_SuppliedAndOriginalSuppressionsBySurvey
		AS(
			SELECT PartyID, EventCategoryID, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression
				FROM #PrefsBySurvey p 
				WHERE p.ContactPreferencesPersist = 1
				AND COALESCE(SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression) IS NOT NULL		-- Where we have been supplied actual suppressions (i.e. not unsubscribe only)
			UNION 
				SELECT PartyID, EventCategoryID, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression
				FROM #PrefsBySurvey p 
				WHERE p.ContactPreferencesPersist = 1
				AND COALESCE(OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression) IS NOT NULL		-- Where we have existing suppressions
		)
		INSERT INTO #PersistedSuppressionsBySurvey (PartyID, EventCategoryID, NewPartySuppression, NewPostalSuppression, NewEmailSuppression, NewPhoneSuppression)
		SELECT	PartyID,
				EventCategoryID, 
				MAX(CAST(ISNULL(SuppliedPartySuppression , 0) AS tinyint))		AS NewPartySuppression,	
				MAX(CAST(ISNULL(SuppliedPostalSuppression, 0) AS tinyint))		AS NewPostalSuppression, 
				MAX(CAST(ISNULL(SuppliedEmailSuppression , 0) AS tinyint))		AS NewEmailSuppression, 
				MAX(CAST(ISNULL(SuppliedPhoneSuppression , 0) AS tinyint))		AS NewPhoneSuppression
		FROM CTE_SuppliedAndOriginalSuppressionsBySurvey
		GROUP BY PartyID, EventCategoryID


		-- Now apply the persisted values 
		UPDATE prefs
		SET prefs.NewPartySuppression	 = psb.NewPartySuppression	,
			prefs.NewPostalSuppression	 = psb.NewPostalSuppression	,
			prefs.NewEmailSuppression	 = psb.NewEmailSuppression	,
			prefs.NewPhoneSuppression	 = psb.NewPhoneSuppression
		FROM #PersistedSuppressionsBySurvey psb
		INNER JOIN #PrefsBySurvey prefs ON prefs.PartyID = psb.PartyID AND prefs.EventCategoryID = psb.EventCategoryID

		
		-----------------
		--- BY PARTY ---
		-----------------
		CREATE TABLE #PersistedSuppressionsByParty
			(
				PartyID					BIGINT,
				NewPartySuppression		TINYINT,	
				NewPostalSuppression	TINYINT, 
				NewEmailSuppression		TINYINT, 
				NewPhoneSuppression		TINYINT	
			)
		
		;WITH CTE_SuppliedAndOriginalSuppressionsByParty
		AS(
			SELECT PartyID, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression

				FROM #PrefsByParty p 
				WHERE p.ContactPreferencesPersist = 1
				AND COALESCE(SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression) IS NOT NULL		-- Where we have been supplied actual suppressions (i.e. not unsubscribe only)
			UNION 
				SELECT PartyID, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression
				FROM #PrefsByParty p 
				WHERE p.ContactPreferencesPersist = 1
				AND COALESCE(OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression) IS NOT NULL
			UNION
				SELECT p.PartyID, pnp.NewPartySuppression, pnp.NewPostalSuppression, pnp.NewEmailSuppression, pnp.NewPhoneSuppression				-- v1.3	-- Include any Non-persist suppressions that have been set for a persist customer (this will be due to a persist override)
				FROM #PrefsByParty p
				INNER JOIN #PrefsByParty pnp ON pnp.PartyID = p.PartyID
													   AND pnp.ContactPreferencesPersist = 0
													   AND COALESCE(pnp.SuppliedPartySuppression, pnp.SuppliedPostalSuppression, pnp.SuppliedEmailSuppression, pnp.SuppliedPhoneSuppression) IS NOT NULL		-- Where we have been supplied actual suppressions (i.e. not unsubscribe only)
				WHERE p.ContactPreferencesPersist = 1
				AND COALESCE(p.SuppliedPartySuppression, p.SuppliedPostalSuppression, p.SuppliedEmailSuppression, p.SuppliedPhoneSuppression) IS NOT NULL		-- Where we have been supplied actual suppressions (i.e. not unsubscribe only) 
		)
		INSERT INTO #PersistedSuppressionsByParty (PartyID, NewPartySuppression, NewPostalSuppression, NewEmailSuppression, NewPhoneSuppression)
		SELECT	PartyID,
				MAX(CAST(ISNULL(SuppliedPartySuppression , 0) AS tinyint))		AS NewPartySuppression,	
				MAX(CAST(ISNULL(SuppliedPostalSuppression, 0) AS tinyint))		AS NewPostalSuppression, 
				MAX(CAST(ISNULL(SuppliedEmailSuppression , 0) AS tinyint))		AS NewEmailSuppression, 
				MAX(CAST(ISNULL(SuppliedPhoneSuppression , 0) AS tinyint))		AS NewPhoneSuppression
		
		FROM CTE_SuppliedAndOriginalSuppressionsByParty
		GROUP BY PartyID


		-- Now apply the persisted values 
		UPDATE prefp
		SET prefp.NewPartySuppression	 = psp.NewPartySuppression	,
			prefp.NewPostalSuppression	 = psp.NewPostalSuppression	,
			prefp.NewEmailSuppression	 = psp.NewEmailSuppression	,
			prefp.NewPhoneSuppression	 = psp.NewPhoneSuppression
		FROM #PersistedSuppressionsByParty psp
		INNER JOIN #PrefsByParty prefp ON prefp.PartyID = psp.PartyID 




		---------------------------------------------------------------------------------------------------------------
		-- Apply Unsubscribes
		---------------------------------------------------------------------------------------------------------------
		
		-- Apply at Party level to loaded suppressions temp table
		UPDATE pbp2
		SET pbp2.NewPartySuppression = 1,
			pbp2.NewPartyUnsubscribe = 1
		FROM #PrefsByParty pbp
		INNER JOIN #PrefsByParty pbp2 ON pbp2.PartyID = pbp.PartyID		-- We link on PartyID to the same file in case there are multiple records for the same Party (Although this is extremely unlikely)
		WHERE ISNULL(pbp.OriginalPartyUnsubscribe,0) = 1
		OR ISNULL(pbp.SuppliedPartyUnsubscribe,0) = 1 
		AND ISNULL(pbp.RemoveUnsubscribe, 0) = 0		-- v1.2


		-- Apply at Survey level to loaded suppressions temp table
		UPDATE pbs
		SET pbs.NewPartySuppression = 1
		FROM #PrefsByParty pbp
		INNER JOIN #PrefsBySurvey pbs ON pbs.PartyID = pbp.PartyID
		WHERE ISNULL(pbp.OriginalPartyUnsubscribe,0) = 1
		OR ISNULL(pbp.SuppliedPartyUnsubscribe,0) = 1 
		AND ISNULL(pbp.RemoveUnsubscribe, 0) = 0		-- v1.2


		-- Apply PartySuppressions to any existing Survey level ContactPreferences records
		UPDATE cps
		SET cps.PartySuppression = 1,
			cps.UpdateDate = pbp.UpdateDate
		FROM #PrefsByParty pbp
		INNER JOIN Party.ContactPreferencesBySurvey cps ON cps.PartyID = pbp.PartyID
		WHERE pbp.OriginalPartyUnsubscribe = 1
		OR pbp.SuppliedPartyUnsubscribe = 1 
		AND ISNULL(pbp.RemoveUnsubscribe, 0) = 0		-- v1.2



		---------------------------------------------------------------------------------------------------------------
		-- Remove Unsubscribes			-- v1.2
		---------------------------------------------------------------------------------------------------------------

				------------------------------------------------------------------------------------------------------------------------
				-- Get the existing Party and Survey combinations as Unsubscribe is independent of individual Event Categories
				------------------------------------------------------------------------------------------------------------------------
	
				CREATE TABLE #PartiesAndSurveys
					(
						PartyID							BIGINT,
						EventCategoryID					INT,
						ContactPreferencesPersist		BIT
					)
	
				INSERT INTO #PartiesAndSurveys (PartyID, EventCategoryID, ContactPreferencesPersist)
				SELECT DISTINCT cpbs.PartyID, cpbs.EventCategoryID, pbs.ContactPreferencesPersist
				FROM  #PrefsBySurvey pbs
				INNER JOIN Party.ContactPreferencesBySurvey cpbs  ON cpbs.PartyID = pbs.PartyID
				WHERE ISNULL(pbs.RemoveUnsubscribe, 0) = 1


				------------------------------------------------------------------------------------------------------------------------
				-- Process "Persist" ContactPreferences (Global) records
				------------------------------------------------------------------------------------------------------------------------
	
				-- Find the MAX AuditItemId of any Override records associated with the customer
	
				CREATE TABLE #MaxOverridePreferencesRecord
					(
						PartyID							BIGINT,
						MaxOverridePreferencesRecord	BIGINT	
					)

				INSERT INTO #MaxOverridePreferencesRecord (PartyID, MaxOverridePreferencesRecord)
				SELECT cpp.PartyID, MAX(acps.AuditItemID) AS MaxOverridePreferencesRecord  -- look for an override preferences record on file.  This is fixed and we should not look further back than this record, if it exists
				FROM  #PrefsByParty cpp 
				LEFT JOIN [$(AuditDB)].Audit.ContactPreferences acps ON acps.PartyId = cpp.PartyID
																	AND ISNULL(acps.SuppliedPartyUnsubscribe, 0) <> 1  -- Exclude Unsubscribes
																	AND ISNULL(acps.RollbackIndicator,0) = 0  -- ignore any rollback records   --- CGR What do we do about ROLLBACK not being released!!!
																	AND ISNULL(acps.OverridePreferences, 0) = 1
				WHERE  cpp.ContactPreferencesPersist = 1
				AND ISNULL(cpp.RemoveUnsubscribe, 0) = 1
				GROUP BY cpp.PartyID

	
				-- Get the latest non-persist values remaining on file for each PartyID, after we ignore the rollback and customer update records
	
				CREATE TABLE #MaxNonPersistSampleRecord
					(
						PartyID							BIGINT,
						MaxNonPersistSampleRecord		BIGINT	
					)

				INSERT INTO #MaxNonPersistSampleRecord (PartyID, MaxNonPersistSampleRecord)
				SELECT cpp.PartyID, MAX(acps.AuditItemID) AS MaxNonPersistSampleRecord  
				FROM #PrefsByParty cpp 
				INNER JOIN #MaxOverridePreferencesRecord mop ON mop.PartyID = cpp.PartyID
				LEFT JOIN [$(AuditDB)].Audit.ContactPreferences acps ON acps.PartyID = cpp.PartyID
																			AND ISNULL(acps.SuppliedPartyUnsubscribe, 0) <> 1  -- Exclude Unsubscribes
																			AND ISNULL(acps.RollbackIndicator,0) = 0   -- ignore any rollback records
																			AND (acps.AuditItemID >= mop.MaxOverridePreferencesRecord OR mop.MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record
																			AND acps.ContactPreferencesPersist = 0
				WHERE  cpp.ContactPreferencesPersist = 1
				AND ISNULL(cpp.RemoveUnsubscribe, 0) = 1
				GROUP BY cpp.PartyID
		

				-- Save out any required adjustments -----------------------
	
				CREATE TABLE #ContactPreferenceAdjustments
		
					(
						ID						INT IDENTITY(1,1),
						PartyID					BIGINT,
						CalcPartySuppression	INT
					) 

				; WITH CTE_CalcSuppressionsForRollup
				AS (
					SELECT 
					  cpp.[PartyID],
					  acps.SuppliedPartySuppression AS CalcPartySuppression
					FROM #PrefsByParty cpp 
					INNER JOIN #MaxOverridePreferencesRecord mop ON mop.PartyID = cpp.PartyID
					INNER JOIN #MaxNonPersistSampleRecord mnp ON mnp.PartyID = cpp.PartyID
					LEFT JOIN Party.ContactPreferences cp ON cp.PartyID = cpp.PartyID
					LEFT JOIN [$(AuditDB)].[Audit].[ContactPreferences] acps 
											ON acps.PartyID = cpp.PartyID   -- left join here so that we can still populate with zero's if there are no values here to roll up
											AND ISNULL(acps.SuppliedPartyUnsubscribe, 0) <> 1  -- Exclude Unsubscribes
											AND ISNULL(acps.RollbackIndicator,0) = 0
											AND (acps.AuditItemID >= MaxOverridePreferencesRecord OR MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record 
											AND (   acps.AuditItemID >= MaxNonPersistSampleRecord	-- Get all records back to and including the last non-persist record, it's values are carried forward when the market is persist.
													OR MaxNonPersistSampleRecord IS NULL
												)
					WHERE  cpp.ContactPreferencesPersist = 1		-- Persist Market
					AND ISNULL(cpp.RemoveUnsubscribe, 0) = 1
				),
				CTE_CalcSuppressionsForAdjustment
				AS ( 
					SELECT PartyID,
							MAX(ISNULL(CAST(CalcPartySuppression AS INT), 0)) AS CalcPartySuppression
					FROM CTE_CalcSuppressionsForRollup		
					GROUP BY PartyID
				)
				INSERT INTO #ContactPreferenceAdjustments (
															PartyID					,
															CalcPartySuppression
														)
				SELECT	csa.PartyID, 
						csa.CalcPartySuppression
				FROM CTE_CalcSuppressionsForAdjustment csa
				INNER JOIN Party.ContactPreferences cp ON cp.PartyID = csa.PartyID
	 

	
				------------------------------------------------------------------------------------------------------------------------
				-- Process "Persist" ContactPreferencesBySurvey records
				------------------------------------------------------------------------------------------------------------------------


				-- Find the AuditItemId of any Override records associated with the customer
	
				CREATE TABLE #MaxOverridePreferencesRecordBySurvey
					(
						PartyID							BIGINT,
						EventCategoryID					INT,
						MaxOverridePreferencesRecord	BIGINT	
					)

				INSERT INTO #MaxOverridePreferencesRecordBySurvey (PartyID, EventCategoryID, MaxOverridePreferencesRecord)
				SELECT cpp.PartyID, cpp.EventCategoryID, MAX(acps.AuditItemID) AS MaxOverridePreferencesRecord  -- look for an override preferences record on file.  This is fixed and we should not look further back than this record, if it exists
				FROM  #PartiesAndSurveys cpp 
				LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps ON acps.PartyId = cpp.PartyID
																	AND acps.EventCategoryID = cpp.EventCategoryID
																	AND ISNULL(acps.SuppliedPartyUnsubscribe, 0) <> 1  -- Exclude Unsubscribes
																	AND ISNULL(acps.RollbackIndicator,0) = 0  -- ignore any rollback records
																	AND ISNULL(acps.OverridePreferences, 0) = 1
				WHERE  cpp.ContactPreferencesPersist = 1
				GROUP BY cpp.PartyID, cpp.EventCategoryID
	


				-- Get the latest non-persist values remaining on file for each PartyID, after we ignore the rollback and customer update records
	
				CREATE TABLE #MaxNonPersistSampleRecordBySurvey
					(
						PartyID							BIGINT,
						EventCategoryID					INT,
						MaxNonPersistSampleRecord		BIGINT
					)

				INSERT INTO #MaxNonPersistSampleRecordBySurvey (PartyID, EventCategoryID, MaxNonPersistSampleRecord)
				SELECT cpp.PartyID, cpp.EventCategoryID, MAX(acps.AuditItemID) AS MaxNonPersistSampleRecord  
				FROM #PartiesAndSurveys cpp 
				INNER JOIN #MaxOverridePreferencesRecordBySurvey mop ON mop.PartyID = cpp.PartyID AND mop.EventCategoryID = cpp.EventCategoryID
				LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps ON acps.PartyID = cpp.PartyID
																					AND acps.EventCategoryID = cpp.EventCategoryID
																					AND ISNULL(acps.SuppliedPartyUnsubscribe, 0) <> 1  -- Exclude Unsubscribes
																					AND ISNULL(RollbackIndicator,0) = 0   -- ignore any rollback records
																					AND (acps.AuditItemID > mop.MaxOverridePreferencesRecord OR mop.MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record
																					AND acps.ContactPreferencesPersist = 0
				WHERE  cpp.ContactPreferencesPersist = 1
				GROUP BY cpp.PartyID, cpp.EventCategoryID


	
				-- Save out any required adjustments -----------------------
	
				CREATE TABLE #ContactPreferenceAdjustmentsBySurvey
		
					(
						ID						INT IDENTITY(1,1),
						PartyID					BIGINT,
						EventCategoryID			INT,
						CalcPartySuppression	INT
					) 

				; WITH CTE_CalcSuppressionsForRollup
				AS (
					SELECT DISTINCT
					   cpp.PartyID
					  ,cpp.EventCategoryID
					  ,acps.SuppliedPartySuppression AS CalcPartySuppression
					FROM #PartiesAndSurveys cpp 
					INNER JOIN #MaxOverridePreferencesRecordBySurvey mop ON mop.PartyID = cpp.PartyID AND mop.EventCategoryID = cpp.EventCategoryID
					INNER JOIN #MaxNonPersistSampleRecordBySurvey mnp ON mnp.PartyID = cpp.PartyID AND mnp.EventCategoryID = cpp.EventCategoryID
					LEFT JOIN Party.ContactPreferences cp ON cp.PartyID = cpp.PartyID
					LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps  -- left join here so that we can still populate with zero's if there are no values here to roll up 
											ON acps.PartyID = cpp.PartyID   
											AND acps.EventCategoryID = cpp.EventCategoryID
											AND (acps.SuppliedPartyUnsubscribe <> 1 OR acps.UpdateSource <> 'Customer Update') -- Exclude Unsubscribes
											AND ISNULL(acps.RollbackIndicator,0) = 0
											AND (acps.AuditItemID >= MaxOverridePreferencesRecord OR MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record 
											AND (   acps.AuditItemID >= MaxNonPersistSampleRecord	-- Get all records back to and including the last non-persist record, it's values are carried forward when the market is persist.
													OR MaxNonPersistSampleRecord IS NULL
												)
					WHERE  cpp.ContactPreferencesPersist = 1   -- Persist Market
				) ,
				CTE_CalcSuppressionsForAdjustment
				AS ( 
					SELECT PartyID,
							EventCategoryID,
							MAX(ISNULL(CAST(CalcPartySuppression AS INT), 0)) AS CalcPartySuppression 
					FROM CTE_CalcSuppressionsForRollup		
					GROUP BY PartyID, EventCategoryID
				)
				INSERT INTO #ContactPreferenceAdjustmentsBySurvey (
															PartyID					,
															EventCategoryID			,
															CalcPartySuppression
														)
				SELECT	csa.PartyID, 
						csa.EventCategoryID,
						csa.CalcPartySuppression
				FROM CTE_CalcSuppressionsForAdjustment csa
				INNER JOIN Party.ContactPreferencesBySurvey cp ON cp.PartyID = csa.PartyID AND cp.EventCategoryID = csa.EventCategoryID 

	 

				-------------------------------------------------------------------------------------------------------------------------------
				-- Process "NON-Persist" ContactPreference (Global) records. Just get the latest non-Unsubscribe, non-Rollback record on file.
				-------------------------------------------------------------------------------------------------------------------------------
	
				-- Save out any required adjustments -----------------------
	
				; WITH CTE_CalcSuppressions
				AS (
					SELECT 
					  cpp.PartyID,
					 acps.SuppliedPartySuppression AS CalcPartySuppression
					FROM #PrefsByParty cpp 
					LEFT JOIN Party.ContactPreferences cp ON cp.PartyID = cpp.PartyID
					LEFT JOIN [$(AuditDB)].Audit.ContactPreferences acps  -- left join here so that we can still populate with zero's if there are no values here to roll up 
										ON  acps.AuditItemID = (SELECT MAX(AuditItemID)  -- get the latest value remaining on file after we ignore the rollback and customer update records
																FROM [$(AuditDB)].[Audit].[ContactPreferencesBySurvey] acps
																  WHERE acps.PartyID = cpp.PartyID 
																  AND ISNULL(acps.SuppliedPartyUnsubscribe, 0) <> 1  -- Exclude Unsubscribes
																  AND ISNULL(RollbackIndicator,0) = 0										-- Ignore records that have been flagged as roll back
																)
					WHERE  cpp.ContactPreferencesPersist = 0		-- Non-persist Markets
					AND ISNULL(cpp.RemoveUnsubscribe, 0) = 1
				)
				INSERT INTO #ContactPreferenceAdjustments (
															PartyID					,
															CalcPartySuppression
														)
				SELECT	csa.PartyID, 
						csa.CalcPartySuppression 
				FROM CTE_CalcSuppressions csa
				INNER JOIN Party.ContactPreferences cp ON cp.PartyID = csa.PartyID 
		


				--------------------------------------------------------------------------------------------------------------------------------
				-- Process "NON-Persist" ContactPreferencesBySurvey records.  Just get the latest non-Unsubscribe, non-Rollback record on file.
				--------------------------------------------------------------------------------------------------------------------------------
	
				-- Save out any required adjustments -----------------------
	
				; WITH CTE_CalcSuppressions
				AS (
					SELECT 
					   cpp.[PartyID]
					  ,cpp.EventCategoryID
					 ,acps.SuppliedPartySuppression AS CalcPartySuppression
					FROM #PartiesAndSurveys cpp 
					LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps  -- left join here so that we can still populate with zero's if there are no values here to roll up 
										ON  acps.AuditItemID = (SELECT MAX(AuditItemID)  -- get the latest value remaining on file after we ignore the rollback and customer update records
																FROM [$(AuditDB)].Audit.ContactPreferencesBySurvey acps
																  WHERE acps.PartyID = cpp.PartyID 
																  AND acps.EventCategoryID = cpp.EventCategoryID
																  AND ISNULL(acps.SuppliedPartyUnsubscribe, 0) <> 1  -- Exclude Unsubscribes
																  AND ISNULL(RollbackIndicator,0) = 0				-- Ignore records that have been flagged as roll back
																)
					WHERE  cpp.ContactPreferencesPersist = 0		-- Non-persist Markets
				)
				INSERT INTO #ContactPreferenceAdjustmentsBySurvey (
															PartyID					,
															EventCategoryID			, 
															CalcPartySuppression
														)
				SELECT	csa.PartyID, 
						csa.EventCategoryID,
						csa.CalcPartySuppression 
				FROM CTE_CalcSuppressions csa
				INNER JOIN Party.ContactPreferencesBySurvey cp ON cp.PartyID = csa.PartyID AND cp.EventCategoryID = csa.EventCategoryID 
	

				--------------------------------------------------------------------------------------------------------------------------------
				-- Apply the adjustments to the Preferences temp tables (which are used to do the updates in the next step
				--------------------------------------------------------------------------------------------------------------------------------

				UPDATE pbp
				SET pbp.NewPartyUnsubscribe = 0, 
					pbp.NewPartySuppression = cpa.CalcPartySuppression
				from #ContactPreferenceAdjustments  cpa
				inner join #PrefsByParty pbp ON cpa.PartyID = pbp.PartyID


				UPDATE pbs
				SET pbs.NewPartySuppression = cabs.CalcPartySuppression
				FROM #ContactPreferenceAdjustmentsBySurvey cabs
				INNER JOIN #PrefsBySurvey pbs ON pbs.PartyID = cabs.PartyID 
											 AND pbs.EventCategoryID = cabs.EventCategoryID






		---------------------------------------------------------------------------------------------------------------
		-- Update and insert Contact Preference records 
		---------------------------------------------------------------------------------------------------------------

		-- UPDATE EXISTING CONTACT PREFERENCES RECORDS
		UPDATE cp
		SET cp.PartySuppression = p.NewPartySuppression,
			cp.EmailSuppression = p.NewEmailSuppression,
			cp.PhoneSuppression = p.NewPhoneSuppression,
			cp.PostalSuppression= p.NewPostalSuppression,
			cp.PartyUnsubscribe = p.NewPartyUnsubscribe,
			cp.UpdateDate		= p.UpdateDate
		FROM #PrefsByParty p 
		INNER JOIN Party.ContactPreferences cp ON cp.PartyID = p.PartyID
		

		UPDATE cps
		SET cps.PartySuppression = p.NewPartySuppression,
			cps.EmailSuppression = p.NewEmailSuppression,
			cps.PhoneSuppression = p.NewPhoneSuppression,
			cps.PostalSuppression= p.NewPostalSuppression,
			cps.UpdateDate		 = p.UpdateDate
		FROM #PrefsBySurvey p 
		INNER JOIN Party.ContactPreferencesBySurvey cps ON cps.PartyID = p.PartyID  AND cps.EventCategoryID = p.EventCategoryID
		


		-- FOR REMOVE UNSUBSCRIBES, WE NEED TO MAKE SURE ALL "BY SURVEY" RECORDS ARE UPDATED AS WELL  -- v1.2
		UPDATE cps
		SET cps.PartySuppression = cabs.CalcPartySuppression,
			cps.UpdateDate		 = @UpdateDate
		FROM #ContactPreferenceAdjustmentsBySurvey cabs 
		INNER JOIN Party.ContactPreferencesBySurvey cps ON cps.PartyID = cabs.PartyID  AND cps.EventCategoryID = cabs.EventCategoryID
		
		
		

		-- INSERT NEW CONTACT PREFERENCES RECORDS
		INSERT INTO Party.ContactPreferences
		(
			PartyID, 
			PartySuppression, 
			PostalSuppression, 
			EmailSuppression, 
			PhoneSuppression, 
			PartyUnsubscribe, 
			UpdateDate
		)
		SELECT DISTINCT			
			PartyID, 
			NewPartySuppression, 
			NewPostalSuppression, 
			NewEmailSuppression, 
			NewPhoneSuppression, 
			NewPartyUnsubscribe,
			UpdateDate 
		FROM #PrefsByParty p 
		WHERE NOT EXISTS(SELECT cp.PartyID FROM Party.ContactPreferences cp 
						 WHERE cp.PartyID = p.PartyID )
		AND ISNULL(p.RemoveUnsubscribe, 0 ) <> 1   -- v1.2



		INSERT INTO Party.ContactPreferencesBySurvey
		(
			PartyID, 
			EventCategoryID, 
			PartySuppression, 
			PostalSuppression, 
			EmailSuppression, 
			PhoneSuppression, 
			UpdateDate
		)
		SELECT DISTINCT			
			PartyID, 
			EventCategoryID, 
			NewPartySuppression, 
			NewPostalSuppression, 
			NewEmailSuppression, 
			NewPhoneSuppression, 
			UpdateDate
		FROM #PrefsBySurvey p 
		WHERE NOT EXISTS (SELECT cp.PartyID FROM Party.ContactPreferencesBySurvey cp 
						  WHERE cp.PartyID = p.PartyID  
						    AND cp.EventCategoryID = p.EventCategoryID)
		AND ISNULL(p.RemoveUnsubscribe, 0 ) <> 1   -- v1.2



		---------------------------------------------------------------------------------------------------------------
		-- Write the Audit records
		---------------------------------------------------------------------------------------------------------------

		-- INSERT ALL ROWS INTO Audit.CONTACT PREFERENCES
		INSERT INTO [$(AuditDB)].Audit.ContactPreferences
		(	
			AuditItemID,
			PartyID, 
			
			OriginalPartySuppression	,
			OriginalPostalSuppression	,
			OriginalEmailSuppression	,
			OriginalPhoneSuppression	,
			OriginalPartyUnsubscribe	,

			SuppliedPartySuppression	,
			SuppliedPostalSuppression	,
			SuppliedEmailSuppression	,
			SuppliedPhoneSuppression	,
			SuppliedPartyUnsubscribe	,
	
			PartySuppression			,
			PostalSuppression			,
			EmailSuppression			,
			PhoneSuppression			,
			PartyUnsubscribe			,

			UpdateDate, 
			UpdateSource,

			ContactPreferencesPersist,
			
			EventCategoryPersistOveride,	-- v1.3
			
			OverridePreferences,			-- v1.1
			RemoveUnsubscribe,				-- v1.2
			Comments						-- v1.1
		)
		SELECT 		
			AuditItemID,
			PartyID, 
			
			OriginalPartySuppression	,
			OriginalPostalSuppression	,
			OriginalEmailSuppression	,
			OriginalPhoneSuppression	,
			OriginalPartyUnsubscribe	,

			SuppliedPartySuppression	,
			SuppliedPostalSuppression	,
			SuppliedEmailSuppression	,
			SuppliedPhoneSuppression	,
			SuppliedPartyUnsubscribe	,
	
			NewPartySuppression			,
			NewPostalSuppression		,
			NewEmailSuppression			,
			NewPhoneSuppression			,
			NewPartyUnsubscribe			,

			UpdateDate, 
			UpdateSource,
			
			ContactPreferencesPersist,
			
			EventCategoryPersistOveride,	-- v1.3
			
			OverridePreferences,			-- v1.1
			RemoveUnsubscribe,				-- v1.2
			Comments						-- v1.1

		FROM #PrefsByParty p 
		WHERE NOT EXISTS(SELECT cp.AuditItemID FROM [$(AuditDB)].Audit.ContactPreferences cp 
						 WHERE cp.AuditItemID = p.AuditItemID )



		-- INSERT ALL ROWS INTO Audit.CONTACT PREFERENCES By Survey
		INSERT INTO [$(AuditDB)].Audit.ContactPreferencesBySurvey
		(	
			AuditItemID,
			PartyID, 
			EventCategoryID, 

			OriginalPartySuppression	,
			OriginalPostalSuppression	,
			OriginalEmailSuppression	,
			OriginalPhoneSuppression	,

			SuppliedPartySuppression	,
			SuppliedPostalSuppression	,
			SuppliedEmailSuppression	,
			SuppliedPhoneSuppression	,
			SuppliedPartyUnsubscribe	,
	
			PartySuppression			,
			PostalSuppression			,
			EmailSuppression			,
			PhoneSuppression			,

			UpdateDate, 
			UpdateSource,

			MarketCountryID,
			SampleMarketID,

			ContactPreferencesPersist,
			
			EventCategoryPersistOveride,	-- v1.3
			
			OverridePreferences,					-- v1.1
			RemoveUnsubscribe,						-- v1.2
			AdditionalAuditsCreatedByRemoveUnsub,	-- v1.2
			Comments								-- v1.1
		)
		SELECT 		
			AuditItemID,
			PartyID, 
			EventCategoryID, 

			OriginalPartySuppression	,
			OriginalPostalSuppression	,
			OriginalEmailSuppression	,
			OriginalPhoneSuppression	,

			SuppliedPartySuppression	,
			SuppliedPostalSuppression	,
			SuppliedEmailSuppression	,
			SuppliedPhoneSuppression	,
			SuppliedPartyUnsubscribe	,
	
			NewPartySuppression			,
			NewPostalSuppression		,
			NewEmailSuppression			,
			NewPhoneSuppression			,

			UpdateDate, 
			UpdateSource,
			
			MarketCountryID,
			SampleMarketID,
			
			ContactPreferencesPersist,
			
			EventCategoryPersistOveride,	-- v1.3
			
			OverridePreferences,						-- v1.1
			RemoveUnsubscribe,							-- v1.2
			0 AS AdditionalAuditsCreatedByRemoveUnsub,	-- v1.2
			Comments									-- v1.1

		FROM #PrefsBySurvey p 
		WHERE NOT EXISTS(SELECT cp.AuditItemID FROM [$(AuditDB)].Audit.ContactPreferencesBySurvey cp 
						 WHERE cp.AuditItemID = p.AuditItemID )




		-- INSERT ADDITIONAL CONTACT PREFERENCES ROWS INTO Audit.CONTACT PREFERENCES By Survey		--v1.2
		-- THIS IS FOR THE EXTRA EventCategoryIDs THAT HAVE BEEN UPDATED BUT WERE NOT SUPPLIED
		-- VIA THE VIEW.

		;WITH CTE_PartiesWithRemoveUnsubscribe	
		AS (
			SELECT PartyID, MAX(AuditItemID) As AuditItemID
			FROM #PrefsByParty
			WHERE ISNULL(RemoveUnsubscribe, 0 ) = 1
			GROUP BY PartyID
		)
		INSERT INTO [$(AuditDB)].Audit.ContactPreferencesBySurvey
		(	
			AuditItemID,
			PartyID, 
			EventCategoryID, 

			OriginalPartySuppression	,
			OriginalPostalSuppression	,
			OriginalEmailSuppression	,
			OriginalPhoneSuppression	,

			SuppliedPartySuppression	,
			SuppliedPostalSuppression	,
			SuppliedEmailSuppression	,
			SuppliedPhoneSuppression	,
			SuppliedPartyUnsubscribe	,
	
			PartySuppression			,
			PostalSuppression			,
			EmailSuppression			,
			PhoneSuppression			,

			UpdateDate, 
			UpdateSource,

			MarketCountryID,
			SampleMarketID,

			ContactPreferencesPersist,
			
			EventCategoryPersistOveride,	-- v1.3
			
			OverridePreferences,
			RemoveUnsubscribe,	
			AdditionalAuditsCreatedByRemoveUnsub,
			Comments						
		)
		SELECT DISTINCT
			pbp.AuditItemID,
			pas.PartyID, 
			pas.EventCategoryID, 

			1 AS OriginalPartySuppression	,
			NULL AS OriginalPostalSuppression	,
			NULL AS OriginalEmailSuppression	,
			NULL AS OriginalPhoneSuppression	,

			NULL AS SuppliedPartySuppression	,
			NULL AS SuppliedPostalSuppression	,
			NULL AS SuppliedEmailSuppression	,
			NULL AS SuppliedPhoneSuppression	,
			0 AS SuppliedPartyUnsubscribe	,
	
			pas.CalcPartySuppression AS NewPartySuppression	,
			NULL AS NewPostalSuppression		,
			NULL AS NewEmailSuppression			,
			NULL AS NewPhoneSuppression			,

			pbp.UpdateDate, 
			pbp.UpdateSource,
			
			pbp.MarketCountryID,
			pbp.SampleMarketID,
			
			0 AS ContactPreferencesPersist,
			
			NULL AS EventCategoryPersistOveride,	-- v1.3
			
			NULL AS OverridePreferences,
			pbp.RemoveUnsubscribe,			
			1 AS AdditionalAuditsCreatedByRemoveUnsub,
			pbp.Comments					

		FROM CTE_PartiesWithRemoveUnsubscribe rup
		INNER JOIN #PrefsByParty pbp ON pbp.PartyID = rup.PartyID AND pbp.AuditItemID = rup.AuditItemID
		INNER JOIN #ContactPreferenceAdjustmentsBySurvey pas ON pas.PartyID = rup.PartyID 
		WHERE NOT EXISTS(SELECT cp.AuditItemID FROM [$(AuditDB)].Audit.ContactPreferencesBySurvey cp 
						 WHERE cp.AuditItemID = rup.AuditItemID
						 AND cp.EventCategoryID = pas.EventCategoryID)





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

