CREATE PROCEDURE [dbo].[uspVWT_DedupeOrganisations]

AS

/*
	Purpose:	Deduplicate Organisation records in the VWT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspDEDUPE_VWTOrganisations
	1.1				23/07/2012		Chris Ross			Added in code to ensure South African events which do not have 
														a CustomerIdentifier are not de-duped as a default address is used.
	1.2				03/12/2014		Chris Ross			BUG 11025 - Add in functionality to de-dupe on Company name (and country) only for Email PartyMatchMethodology
	1.3				07/07/2016		Eddie Thomas		BUG 12449 - Added in functionailty to de-dupe by mobile telephoen fields
	1.1				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
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


	
	-- BUILD UP A DISTINCT LIST OF UNMATCHED COMPANIES CURRENTLY IN THE VWT
	CREATE TABLE #DistinctCompanies
	(
		 DistinctCompanyID INT IDENTITY(1,1) NOT NULL
		,CountryID SMALLINT
		,OrganisationName NVARCHAR(510)
		,OrganisationNameChecksum INT
		,AddressParentAuditItemID BIGINT
		,Cnt INT
	)
	
	INSERT INTO #DistinctCompanies
	(
		 CountryID
		,OrganisationName
		,OrganisationNameChecksum
		,AddressParentAuditItemID
		,Cnt
	)
	SELECT DISTINCT
		CountryID, 
		OrganisationName, 
		OrganisationNameChecksum, 
		AddressParentAuditItemID,
		COUNT(*) AS Cnt
	FROM dbo.vwVWT_Organisations
	WHERE ISNULL(OrganisationParentAuditItemID, 0) = 0 	-- NOT BEEN PROCESED BEFORE
	AND (  CountryID <> (select CountryID							--v1.1 Not South African Orgs unless they have a Cust Identifier
						from [$(SampleDB)].ContactMechanism.Countries 
						where Country = 'South Africa')
		  OR CustomerIdentifier <> ''
		)
	AND PartyMatchingMethodologyID = @PostalAddressMatchingMethodID
	GROUP BY CountryID, OrganisationName, OrganisationNameChecksum, AddressParentAuditItemID
	
	
	-- EVERY ORGANISATION RECORD IN THE VWT HAS A ROW IN THE RELATIONSHIPS TABLE
	-- THE TABLE CHARTS THE RELATIONSHIP BETWEEN THE VWT ORGANISATION RECORDS AND A DISTINCT LIST OF COMPANY 
	-- NAME / POSTCODE.
	CREATE TABLE #DistinctCompanyRelationships
	(
		 AuditItemID BIGINT
		,DistinctCompanyID INT
		,ParentDistinctCompanyID INT
		,ParentDistinctAuditItemID BIGINT
	)
	
	INSERT INTO #DistinctCompanyRelationships (AuditItemID, DistinctCompanyID)
	SELECT V.AuditItemID, C.DistinctCompanyID
	FROM dbo.vwVWT_Organisations V
	INNER JOIN #DistinctCompanies C ON V.OrganisationNameChecksum = C.OrganisationNameChecksum
									AND V.AddressParentAuditItemID = C.AddressParentAuditItemID
							    	AND V.CountryID = C.CountryID
	
	/*
	 	FUZZY MATCH THE DISTINCT COMPANIES TABLE AGAINST ITSELF
	
		EXCLUDE SAME ROW MATCHES
		
		INNER JOIN ON ADDRESS CHECKSUM THEN FUZZY MATCH THE COMPANYNAME. 
	
		WE WANT TO WRITE THE DISTINCT ID FROM THE DISTINCT COMPANIES TABLE WITH THE HIGHEST MATCH RATING (IF > 50)
		BACK TO THE RELATIONSHIPS TABLE AS ITS DISTINCT PARENT ID.
	
		AS WE ARE COMPARING THE DISTINCT TABLE AGAINST ITSELF THERE WILL BE INVERSE RATINGS 
	
		E.G. 	DISTINCT ID A 		=	 DISTINCT ID B		RATING 80
			DISTINCT ID B 		=	 DISTINCT ID A		RATING 80
	
		CHOOSE THE DISTINCT COMPANY NAME THAT OCCURS THE MOST OFTEN IN THE VWT AS THE PARENT

		THEREFORE COMPANY A OCCURS 3 TIME WHEREAS COMPANY B OCCURS ONCE THEREFORE COMPANY A IS THE PARENT OF COMPANY B
	
	*/
		
	UPDATE DCR
	SET DCR.ParentDistinctCompanyID = ParentDistinctCompanyIDs.ParentID
	FROM #DistinctCompanyRelationships DCR
	INNER JOIN (	
		SELECT 
			MAX(CO1.DistinctCompanyID) AS DistinctCompanyID,
			MAX(CASE WHEN T1.Cnt > T2.Cnt THEN T1.DistinctCompanyID ELSE T2.DistinctCompanyID END) AS ParentID
		FROM #DistinctCompanies CO1
		INNER JOIN #DistinctCompanies CO2 ON CO1.AddressParentAuditItemID = CO2.AddressParentAuditItemID
										AND CO1.DistinctCompanyID <> CO2.DistinctCompanyID -- DO NOT INCLUDE COMPARISONS ON THE SAME ROW
		INNER JOIN #DistinctCompanies T1 ON CO1.DistinctCompanyID = T1.DistinctCompanyID
		INNER JOIN #DistinctCompanies T2 ON CO2.DistinctCompanyID = T2.DistinctCompanyID
		WHERE CO1.CountryID NOT IN (SELECT CountryID FROM Lookup.vwCountries WHERE Country in  ('Japan', 'South Africa') )	--Don't fuzzy match japan or South Africa (v1.1)
		GROUP BY 	
			(CO1.DistinctCompanyID + CO2.DistinctCompanyID), 
			(CO1.DistinctCompanyID * CO2.DistinctCompanyID) -- USE THE SUM AND PRODUCT OF ID'S TOGETHER TO DEDUPE INVERSE MATCHES
		HAVING MIN(dbo.udfFuzzyMatchWeighted(CO1.OrganisationName, CO2.OrganisationName)) > 50
				
		UNION
				
		SELECT 
			MIN(CO2.DistinctCompanyID) DistinctCompanyID,
			MAX(CASE WHEN T1.Cnt > T2.Cnt THEN T1.DistinctCompanyID ELSE T2.DistinctCompanyID END) ParentID
		FROM #DistinctCompanies CO1
		INNER JOIN #DistinctCompanies CO2 ON CO1.AddressParentAuditItemID = CO2.AddressParentAuditItemID
										AND CO1.DistinctCompanyID <> CO2.DistinctCompanyID -- DO NOT INCLUDE COMPARISONS ON THE SAME ROW
		INNER JOIN #DistinctCompanies T1 ON CO1.DistinctCompanyID = T1.DistinctCompanyID
		INNER JOIN #DistinctCompanies T2 ON CO2.DistinctCompanyID = T2.DistinctCompanyID
		WHERE CO1.CountryID not in  (SELECT CountryID FROM Lookup.vwCountries WHERE Country in ('Japan', 'South Africa' ))	--Don't fuzzy match japan or South Africa (v1.1)
		GROUP BY 
			(CO1.DistinctCompanyID + CO2.DistinctCompanyID), 
			(CO1.DistinctCompanyID * CO2.DistinctCompanyID) -- USE THE SUM AND PRODUCT OF ID'S TOGETHER TO DEDUPE INVERSE MATCHES
		HAVING MIN(dbo.udfFuzzyMatchWeighted(CO1.OrganisationName, CO2.OrganisationName)) > 50
	) ParentDistinctCompanyIDs ON ParentDistinctCompanyIDs.DistinctCompanyID = DCR.DistinctCompanyID
	

	/*	FOR NON FUZZY MATCHED RECORDS UPDATE THE PARENT DISTINCT COMPANY ID TO ITSELF

		THIS IS ESSENTIALLY THE EXACT MATCH PHASE BECAUSE THE RELATIONSHIPS TABLE PLOT
		
		THE RELATIONSHIPS BETWEEN EXACT COMPANY MATCHES AND THE VWT		*/
	
	UPDATE #DistinctCompanyRelationships
	SET ParentDistinctCompanyID = DistinctCompanyID
	WHERE ParentDistinctCompanyID IS NULL
	
	
	/* 
		NOW GET A VALID AUDIT ITEM ID FOR EACH DISTINCT PARENT ID AND WRITE THIS TO THE RELATIONSHIPS TABLE
		
		ARBITRARILY TAKE THE HIGHEST LAST 
	
	*/
	
	UPDATE DCR
	SET DCR.ParentDistinctAuditItemID = Parents.AuditItemID
	FROM #DistinctCompanyRelationships DCR
	INNER JOIN (
		SELECT 
			MAX(AuditItemID) AS AuditItemID, 
			ParentDistinctCompanyID
		FROM #DistinctCompanyRelationships
		GROUP BY ParentDistinctCompanyID
	) Parents ON DCR.ParentDistinctCompanyID = Parents.ParentDistinctCompanyID
	
	
	/*	WRITE PARENT ORGANISATIONS BACK TO VWT	*/
	UPDATE V
	SET V.OrganisationParentAuditItemID = DCR.ParentDistinctAuditItemID
	FROM dbo.vwVWT_Organisations V
	INNER JOIN #DistinctCompanyRelationships DCR ON V.AuditItemID = DCR.AuditItemID


	/*	WRITE RECORDS WITH NO ADDRESSES AS OWN PARENTS	*/
	UPDATE VWT
	SET OrganisationParentAuditItemID = VWT.AuditItemID
	FROM vwVWT_Organisations O
	INNER JOIN VWT ON O.AuditItemID = VWT.AuditItemID
	WHERE ISNULL(VWT.OrganisationParentAuditItemID, 0) = 0
	AND O.PartyMatchingMethodologyID = @PostalAddressMatchingMethodID
	
	DROP TABLE #DistinctCompanies
	DROP TABLE #DistinctCompanyRelationships
	




	------------------------------------------------------------------------------------------------------------------
	-- NAME AND EMAIL ADDRESS MATCHING METHODOLOGY - Only matches on exact company name (ignores Email and Address)
	------------------------------------------------------------------------------------------------------------------
	
	-- GET the Methodology ID
	DECLARE @EmailAddressMatchingMethodID INT
	SELECT @EmailAddressMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address'
	IF @EmailAddressMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and Email Address Party Matching Methodology - lookup ERROR.', 16, 1)
	END
	
	-- BUILD UP A DISTINCT LIST OF UNMATCHED COMPANIES CURRENTLY IN THE VWT
	CREATE TABLE #DistinctCompanies_Alt
	(
		 DistinctCompanyID INT IDENTITY(1,1) NOT NULL
		,CountryID SMALLINT
		,OrganisationName NVARCHAR(510)
		,Cnt INT
	)
	
	INSERT INTO #DistinctCompanies_Alt
	(
		 CountryID
		,OrganisationName
		,Cnt
	)
	SELECT DISTINCT
		CountryID, 
		OrganisationName, 
		COUNT(*) AS Cnt
	FROM dbo.vwVWT_Organisations
	WHERE ISNULL(OrganisationParentAuditItemID, 0) = 0 	-- NOT BEEN PROCESED BEFORE
	AND (  CountryID <> (select CountryID							--v1.1 Not South African Orgs unless they have a Cust Identifier
						from [$(SampleDB)].ContactMechanism.Countries 
						where Country = 'South Africa')
		  OR CustomerIdentifier <> ''
		)
	AND PartyMatchingMethodologyID = @EmailAddressMatchingMethodID		
	GROUP BY CountryID, OrganisationName
	

	
	-- EVERY ORGANISATION RECORD IN THE VWT HAS A ROW IN THE RELATIONSHIPS TABLE
	-- THE TABLE CHARTS THE RELATIONSHIP BETWEEN THE VWT ORGANISATION RECORDS AND A DISTINCT LIST OF COMPANY 
	-- NAME / POSTCODE.
	CREATE TABLE #DistinctCompanyRelationships_Alt
	(
		 AuditItemID BIGINT
		,DistinctCompanyID INT
		,ParentAuditItemID BIGINT
	)
	
	INSERT INTO #DistinctCompanyRelationships_Alt (AuditItemID, DistinctCompanyID)
	SELECT V.AuditItemID, C.DistinctCompanyID
	FROM dbo.vwVWT_Organisations V
	INNER JOIN #DistinctCompanies_Alt C ON V.OrganisationName = C.OrganisationName
									AND V.CountryID = C.CountryID

	
	-- FOR EACH RECORD IN THE RELATIONSHIPS TABLE, SELECT ONE RECORD TO BE THE VWT PARENT RECORD
	-- (ARBITRARILY TAKE THE LAST VWTID ONE BUT DOESN'T MATTER) AND UPDATE EACH RELATIONSHIP ROW
	UPDATE PR
	SET PR.ParentAuditItemID = ParentRecords.ParentAuditItemID
	FROM #DistinctCompanyRelationships_Alt PR
	INNER JOIN (	--GROUP BY DISTINCTID BRINGING BACK THE HIGHEST VWTID WHICH WILL BE THE PARENT
		SELECT 
			MAX(AuditItemID) AS ParentAuditItemID,
			DistinctCompanyID
		FROM #DistinctCompanyRelationships_Alt
		GROUP BY DistinctCompanyID
	) AS ParentRecords ON PR.DistinctCompanyID = ParentRecords.DistinctCompanyID


	-- WRITE THE PARENT RECORD IDS BACK TO THE RELEVANT VWT RECORDS
	UPDATE V
	SET V.OrganisationParentAuditItemID = PR.ParentAuditItemID
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctCompanyRelationships_Alt PR ON AP.AuditItemID = PR.AuditItemID
	INNER JOIN dbo.VWT V ON AP.AuditItemID = V.AuditItemID



	DROP TABLE #DistinctCompanies_Alt
	DROP TABLE #DistinctCompanyRelationships_Alt



	------------------------------------------------------------------------------------------------------------------
	-- NAME AND TELEPHONE ADDRESS MATCHING METHODOLOGY - Only matches on exact company name (ignores Tel # and Address)
	-- V1.3
	------------------------------------------------------------------------------------------------------------------
	
	-- GET the Methodology ID
	DECLARE @TelephoneMatchingMethodID INT
	SELECT @TelephoneMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address'
	IF @TelephoneMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and telephone Party Matching Methodology - lookup ERROR.', 16, 1)
	END
	
	-- BUILD UP A DISTINCT LIST OF UNMATCHED COMPANIES CURRENTLY IN THE VWT
	CREATE TABLE #DistinctCompanies_Tel
	(
		 DistinctCompanyID INT IDENTITY(1,1) NOT NULL
		,CountryID SMALLINT
		,OrganisationName NVARCHAR(510)
		,Cnt INT
	)
	
	INSERT INTO #DistinctCompanies_Tel
	(
		 CountryID
		,OrganisationName
		,Cnt
	)
	SELECT DISTINCT
		CountryID, 
		OrganisationName, 
		COUNT(*) AS Cnt
	FROM dbo.vwVWT_Organisations
	WHERE ISNULL(OrganisationParentAuditItemID, 0) = 0 	-- NOT BEEN PROCESED BEFORE
	AND (  CountryID <> (select CountryID							--v1.1 Not South African Orgs unless they have a Cust Identifier
						from [$(SampleDB)].ContactMechanism.Countries 
						where Country = 'South Africa')
		  OR CustomerIdentifier <> ''
		)
	AND PartyMatchingMethodologyID = @TelephoneMatchingMethodID
	GROUP BY CountryID, OrganisationName
	

	
	-- EVERY ORGANISATION RECORD IN THE VWT HAS A ROW IN THE RELATIONSHIPS TABLE
	-- THE TABLE CHARTS THE RELATIONSHIP BETWEEN THE VWT ORGANISATION RECORDS AND A DISTINCT LIST OF COMPANY 
	-- NAME / POSTCODE.
	CREATE TABLE #DistinctCompanyRelationships_Tel
	(
		 AuditItemID BIGINT
		,DistinctCompanyID INT
		,ParentAuditItemID BIGINT
	)
	
	INSERT INTO #DistinctCompanyRelationships_Tel (AuditItemID, DistinctCompanyID)
	SELECT V.AuditItemID, C.DistinctCompanyID
	FROM dbo.vwVWT_Organisations V
	INNER JOIN #DistinctCompanies_Tel C ON V.OrganisationName = C.OrganisationName
									AND V.CountryID = C.CountryID

	
	-- FOR EACH RECORD IN THE RELATIONSHIPS TABLE, SELECT ONE RECORD TO BE THE VWT PARENT RECORD
	-- (ARBITRARILY TAKE THE LAST VWTID ONE BUT DOESN'T MATTER) AND UPDATE EACH RELATIONSHIP ROW
	UPDATE PR
	SET PR.ParentAuditItemID = ParentRecords.ParentAuditItemID
	FROM #DistinctCompanyRelationships_Tel PR
	INNER JOIN (	--GROUP BY DISTINCTID BRINGING BACK THE HIGHEST VWTID WHICH WILL BE THE PARENT
		SELECT 
			MAX(AuditItemID) AS ParentAuditItemID,
			DistinctCompanyID
		FROM #DistinctCompanyRelationships_Tel
		GROUP BY DistinctCompanyID
	) AS ParentRecords ON PR.DistinctCompanyID = ParentRecords.DistinctCompanyID


	-- WRITE THE PARENT RECORD IDS BACK TO THE RELEVANT VWT RECORDS
	UPDATE V
	SET V.OrganisationParentAuditItemID = PR.ParentAuditItemID
	FROM dbo.vwVWT_People AP
	INNER JOIN #DistinctCompanyRelationships_Tel PR ON AP.AuditItemID = PR.AuditItemID
	INNER JOIN dbo.VWT V ON AP.AuditItemID = V.AuditItemID



	DROP TABLE #DistinctCompanies_Tel
	DROP TABLE #DistinctCompanyRelationships_Tel


	---------------------------------------------------------------------------------------------------------
	-- SET THE OrganisationParentAuditItemID IN THE VWT TO BE SAME AS THE AuditItemID WHERE WE'VE NOT ALREADY SET IT
	---------------------------------------------------------------------------------------------------------
	
	UPDATE dbo.VWT
	SET OrganisationParentAuditItemID = AuditItemID
	WHERE OrganisationParentAuditItemID IS NULL	



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