CREATE PROCEDURE [dbo].[uspVWT_DedupePeople]

AS

/*
	Purpose:	Deduplicate People records in the VWT
	
	Rationale:	1. Populate a list of 'Distinct Person Records' (DPR) based on

					CountryID
					Checksum(Name details)
					Checksum(Address Prefix) 
					AddressParentAuditItemID (this is a row in the VWT whereby rows with a similar address roll up to)

				2. Populate a relationships table joining VWT and DCR on criteria listed directly above.
				3. Assign a parent VWTID to each record in the relationships table.  Arbitrarily take the highest
				4. Write back Parent Audit Item ID to the VWT. 
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspDEDUPE_VWTPeople
	1.1				23/07/2012		Chris Ross			Added in code to ensure South African events which do not have 
														a CustomerIdentifier are not de-duped as a default address is used.
	1.2				03/12/2014		Chris Ross			BUG 11025 - Add in functionality to de-dupe on Email for Email PartyMatchMethodology
	1.3				????			Edward Thomas		????
	1.4				15/08/2018		Chris Ross			BUG 14919 - Remove old South Africa customer ID specific functionality.
	1.5				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/	

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	------------------------------------------------------------------------------------------------------------------
	-- NAME AND POSTAL ADDRESS MATCHING METHODOLOGY
	------------------------------------------------------------------------------------------------------------------

	-- GET the Methodology ID
	DECLARE @PostalAddressMatchingMethodID INT
	SELECT @PostalAddressMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Postal Address'
	IF @PostalAddressMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and Postal Address Party Matching Methodology - lookup ERROR.', 16, 1)
	END

	CREATE TABLE #DistinctPeople
		(
			DistinctPersonID			int IDENTITY (1, 1),
			CountryID					int,
			NameChecksum				int, 
			AddressParentAuditItemID	int
		);
	
	
	-- GET THE DISTINCT PEOPLE INFORMATION -- for Everyone except South Africa records with no UniqueIdentifier
	INSERT INTO #DistinctPeople
	SELECT DISTINCT 
		CountryID, 
		NameChecksum,
		AddressParentAuditItemID
	FROM dbo.vwVWT_People
	WHERE ISNULL(PersonParentAuditItemID, 0) = 0 -- No parent
	AND PartyMatchingMethodologyID = @PostalAddressMatchingMethodID

	-- v1.4 -- AND (  CountryID <> (select CountryID 
	-- v1.4 -- 					from [$(SampleDB)].ContactMechanism.Countries 
	-- v1.4 -- 					where Country = 'South Africa')
	-- v1.4 -- 	  OR CustomerIdentifier <> ''
	-- v1.4 -- 	)



--------------------------------------------------------------------------------

	
	-- 	POPULATE A TABLE WITH THE RELATIONSHIPS BETWEEN THE DISTINCT PEOPLE RECORDS AND ACTUAL VWT ROWS.
	SELECT
		AP.AuditItemID,
		DP.DistinctPersonID,
		CAST(NULL AS BIGINT) AS ParentAuditItemID
	INTO #DistinctPeopleRelationships
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctPeople DP ON AP.NameChecksum = DP.NameChecksum
							AND AP.AddressParentAuditItemID = DP.AddressParentAuditItemID
							AND AP.CountryID = DP.CountryID

	-- FOR EACH RECORD IN THE RELATIONSHIPS TABLE, SELECT ONE RECORD TO BE THE VWT PARENT RECORD
	-- (ARBITRARILY TAKE THE LAST VWTID ONE BUT DOESN'T MATTER) AND UPDATE EACH RELATIONSHIP ROW
	UPDATE PR
	SET PR.ParentAuditItemID = ParentRecords.ParentAuditItemID
	FROM #DistinctPeopleRelationships PR
	INNER JOIN (	--GROUP BY DISTINCTID BRINGING BACK THE HIGHEST VWTID WHICH WILL BE THE PARENT
		SELECT 
			MAX(AuditItemID) AS ParentAuditItemID,
			DistinctPersonID
		FROM #DistinctPeopleRelationships
		GROUP BY DistinctPersonID
	) AS ParentRecords ON PR.DistinctPersonID = ParentRecords.DistinctPersonID
	
	-- WRITE THE PARENT RECORD IDS BACK TO THE RELEVANT VWT RECORDS
	UPDATE V
	SET V.PersonParentAuditItemID = PR.ParentAuditItemID
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctPeopleRelationships PR ON AP.AuditItemID = PR.AuditItemID
	INNER JOIN dbo.VWT V ON AP.AuditItemID = V.AuditItemID
	
	DROP TABLE #DistinctPeopleRelationships
	DROP TABLE #DistinctPeople
	



	------------------------------------------------------------------------------------------------------------------
	-- NAME AND EMAIL ADDRESS MATCHING METHODOLOGY
	------------------------------------------------------------------------------------------------------------------
	
	-- GET the Methodology ID
	DECLARE @EmailAddressMatchingMethodID INT
	SELECT @EmailAddressMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address'
	IF @EmailAddressMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and Email Address Party Matching Methodology - lookup ERROR.', 16, 1)
	END
	

	CREATE TABLE #DistinctPeopleByEMail
		(
			DistinctPersonID			int IDENTITY (1, 1),
			CountryID					int,
			NameChecksum				int, 
			EmailAddress				NVARCHAR(510)
		);
	
	
	-- GET THE DISTINCT PEOPLE INFORMATION 
	INSERT INTO #DistinctPeopleByEMail
	SELECT DISTINCT 
		CountryID, 
		NameChecksum,
		EmailAddress
	FROM dbo.vwVWT_People
	WHERE ISNULL(PersonParentAuditItemID, 0) = 0 -- No parent
	AND PartyMatchingMethodologyID = @EmailAddressMatchingMethodID
	AND ISNULL(EmailAddress, '') <> ''

	-- v1.4 -- AND (  CountryID <> (select CountryID 
	-- v1.4 -- 					from [$(SampleDB)].ContactMechanism.Countries 
	-- v1.4 -- 					where Country = 'South Africa')
	-- v1.4 -- 	  OR CustomerIdentifier <> ''
	-- v1.4 -- 	)

	
	-- 	POPULATE A TABLE WITH THE RELATIONSHIPS BETWEEN THE DISTINCT PEOPLE RECORDS AND ACTUAL VWT ROWS.
	SELECT
		AP.AuditItemID,
		DP.DistinctPersonID,
		CAST(NULL AS BIGINT) AS ParentAuditItemID
	INTO #DistinctPeopleByEmailRelationships
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctPeopleByEMail DP ON AP.NameChecksum = DP.NameChecksum
							AND AP.EmailAddress = DP.EmailAddress
							AND AP.CountryID = DP.CountryID


	-- FOR EACH RECORD IN THE RELATIONSHIPS TABLE, SELECT ONE RECORD TO BE THE VWT PARENT RECORD
	-- (ARBITRARILY TAKE THE LAST VWTID ONE BUT DOESN'T MATTER) AND UPDATE EACH RELATIONSHIP ROW
	UPDATE PR
	SET PR.ParentAuditItemID = ParentRecords.ParentAuditItemID
	FROM #DistinctPeopleByEmailRelationships PR
	INNER JOIN (	--GROUP BY DISTINCTID BRINGING BACK THE HIGHEST VWTID WHICH WILL BE THE PARENT
		SELECT 
			MAX(AuditItemID) AS ParentAuditItemID,
			DistinctPersonID
		FROM #DistinctPeopleByEmailRelationships
		GROUP BY DistinctPersonID
	) AS ParentRecords ON PR.DistinctPersonID = ParentRecords.DistinctPersonID
	
	-- WRITE THE PARENT RECORD IDS BACK TO THE RELEVANT VWT RECORDS
	UPDATE V
	SET V.PersonParentAuditItemID = PR.ParentAuditItemID
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctPeopleByEmailRelationships PR ON AP.AuditItemID = PR.AuditItemID
	INNER JOIN dbo.VWT V ON AP.AuditItemID = V.AuditItemID


	DROP TABLE #DistinctPeopleByEmailRelationships
	DROP TABLE #DistinctPeopleByEMail
	
	------------------------------------------------------------------------------------------------------------------
	-- NAME AND TELEPHONE MATCHING METHODOLOGY
	------------------------------------------------------------------------------------------------------------------
	
	-- GET the Methodology ID
	DECLARE @TelephoneMatchingMethodID INT
	SELECT @TelephoneMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Telephone Number'
	IF @TelephoneMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and Telephone Party Matching Methodology - lookup ERROR.', 16, 1)
	END
	

	CREATE TABLE #DistinctPeopleByTelephone
		(
			DistinctPersonID			int IDENTITY (1, 1),
			CountryID					int,
			NameChecksum				int, 
			TelephoneNumber				NVARCHAR(70)
		);
	
	
	-- GET THE DISTINCT PEOPLE INFORMATION -- for Everyone except South Africa records with no UniqueIdentifier
	INSERT INTO #DistinctPeopleByTelephone
	SELECT DISTINCT 
		CountryID, 
		NameChecksum,
		--BUG 12449 : TELEPHONE MATCHING --> NOTE THE PRECEDENCE ORDER, MOBILES GIVEN PRIORITY 
		COALESCE(NULLIF(MobileTel,''),NULLIF(PrivMobileTel,''),'')
	FROM dbo.vwVWT_People
	WHERE ISNULL(PersonParentAuditItemID, 0) = 0 -- No parent
	AND PartyMatchingMethodologyID = @TelephoneMatchingMethodID
	AND (ISNULL(MobileTel, '') <> '' OR ISNULL(PrivMobileTel, '') <> '')

	-- v1.4 -- AND (  CountryID <> (select CountryID 
	-- v1.4 -- 					from [$(SampleDB)].ContactMechanism.Countries 
	-- v1.4 -- 					where Country = 'South Africa')
	-- v1.4 -- 	  OR CustomerIdentifier <> ''
	-- v1.4 -- 	)


	-- 	POPULATE A TABLE WITH THE RELATIONSHIPS BETWEEN THE DISTINCT PEOPLE RECORDS AND ACTUAL VWT ROWS.
	SELECT
		AP.AuditItemID,
		DP.DistinctPersonID,
		CAST(NULL AS BIGINT) AS ParentAuditItemID
	INTO #DistinctPeopleByTelephoneRelationships
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctPeopleByTelephone DP ON AP.NameChecksum = DP.NameChecksum
							AND COALESCE(NULLIF(AP.MobileTel,''),NULLIF(AP.PrivMobileTel,''),'') = DP.TelephoneNumber
							AND AP.CountryID = DP.CountryID


	-- FOR EACH RECORD IN THE RELATIONSHIPS TABLE, SELECT ONE RECORD TO BE THE VWT PARENT RECORD
	-- (ARBITRARILY TAKE THE LAST VWTID ONE BUT DOESN'T MATTER) AND UPDATE EACH RELATIONSHIP ROW
	UPDATE PR
	SET PR.ParentAuditItemID = ParentRecords.ParentAuditItemID
	FROM #DistinctPeopleByTelephoneRelationships PR
	INNER JOIN (	--GROUP BY DISTINCTID BRINGING BACK THE HIGHEST VWTID WHICH WILL BE THE PARENT
		SELECT 
			MAX(AuditItemID) AS ParentAuditItemID,
			DistinctPersonID
		FROM #DistinctPeopleByTelephoneRelationships
		GROUP BY DistinctPersonID
	) AS ParentRecords ON PR.DistinctPersonID = ParentRecords.DistinctPersonID
	
	-- WRITE THE PARENT RECORD IDS BACK TO THE RELEVANT VWT RECORDS
	UPDATE V
	SET V.PersonParentAuditItemID = PR.ParentAuditItemID
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctPeopleByTelephoneRelationships PR ON AP.AuditItemID = PR.AuditItemID
	INNER JOIN dbo.VWT V ON AP.AuditItemID = V.AuditItemID


	DROP TABLE #DistinctPeopleByTelephoneRelationships
	DROP TABLE #DistinctPeopleByTelephone


--------------------------------------------------------------------------------

	
	
	


	------------------------------------------------------------------------------------------------------------------
	-- SET THE PersonParentAuditItemID IN THE VWT TO BE SAME AS THE AuditItemID WHERE WE'VE NOT ALREADY SET IT
	------------------------------------------------------------------------------------------------------------------

	UPDATE dbo.VWT
	SET PersonParentAuditItemID = AuditItemID
	WHERE PersonParentAuditItemID IS NULL


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