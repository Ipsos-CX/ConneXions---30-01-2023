CREATE PROCEDURE [GDPR].[uspGetAccessDetails]
@PartyID INT, @Validated BIT OUTPUT, @ValidationFailureReason VARCHAR (255) OUTPUT
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
		Purpose:	Output GDPR Information
	
		Version		Date			Developer			Comment
		1.0			2018-02-19		Chris Ledger		Created
		1.1			2018-06-06		Chris Ledger		Match CaseID By PartyID
		1.2			2018-06-26		Chris Ledger		Use DENSE_RANK to avoid duplicate Customer Information
		1.3			2018-06-28		Chris Ledger		Add Validation
		1.4			2020-01-15		Chris Ledger 		BUG 15372 - Fix cases
	*/

	------------------------------------------------------------------------
	-- V1.3 Check params populated correctly
	------------------------------------------------------------------------
	SET @Validated = 0
		
	IF	@PartyID IS NULL
	BEGIN
		SET @ValidationFailureReason = '@PartyID parameter has not been supplied'
		RETURN 0
	END 

	IF	0 = (SELECT COUNT(*) FROM [$(SampleDB)].Party.People WHERE PartyID = @PartyID)
	BEGIN
		SET @ValidationFailureReason = 'The supplied PartyID is not found in the People table.'
		RETURN 0
	END 

	SET @Validated = 1
	------------------------------------------------------------------------


	DECLARE @Pivot TABLE
	(
		name NVARCHAR(400),
		[1] NVARCHAR(400) DEFAULT(''), 
		[2] NVARCHAR(400) DEFAULT(''),
		[3] NVARCHAR(400) DEFAULT(''),
		[4] NVARCHAR(400) DEFAULT(''), 
		[5] NVARCHAR(400) DEFAULT(''), 
		[6] NVARCHAR(400) DEFAULT(''), 
		[7] NVARCHAR(400) DEFAULT(''), 
		[8] NVARCHAR(400) DEFAULT(''), 
		[9] NVARCHAR(400) DEFAULT(''), 
		[10] NVARCHAR(400) DEFAULT(''), 
		[11] NVARCHAR(400) DEFAULT(''), 
		[12] NVARCHAR(400) DEFAULT(''),
		[13] NVARCHAR(400) DEFAULT(''),
		[14] NVARCHAR(400) DEFAULT(''), 
		[15] NVARCHAR(400) DEFAULT(''), 
		[16] NVARCHAR(400) DEFAULT(''), 
		[17] NVARCHAR(400) DEFAULT(''), 
		[18] NVARCHAR(400) DEFAULT(''), 
		[19] NVARCHAR(400) DEFAULT(''), 
		[20] NVARCHAR(400) DEFAULT(''), 
		[21] NVARCHAR(400) DEFAULT(''), 
		[22] NVARCHAR(400) DEFAULT(''),
		[23] NVARCHAR(400) DEFAULT(''),
		[24] NVARCHAR(400) DEFAULT(''), 
		[25] NVARCHAR(400) DEFAULT(''), 
		[26] NVARCHAR(400) DEFAULT(''), 
		[27] NVARCHAR(400) DEFAULT(''), 
		[28] NVARCHAR(400) DEFAULT(''), 
		[29] NVARCHAR(400) DEFAULT(''), 
		[30] NVARCHAR(400) DEFAULT(''),
		[31] NVARCHAR(400) DEFAULT(''), 
		[32] NVARCHAR(400) DEFAULT(''),
		[33] NVARCHAR(400) DEFAULT(''),
		[34] NVARCHAR(400) DEFAULT(''), 
		[35] NVARCHAR(400) DEFAULT(''), 
		[36] NVARCHAR(400) DEFAULT(''), 
		[37] NVARCHAR(400) DEFAULT(''), 
		[38] NVARCHAR(400) DEFAULT(''), 
		[39] NVARCHAR(400) DEFAULT(''), 
		[40] NVARCHAR(400) DEFAULT('')
	)

	DECLARE @colsUnpivot AS NVARCHAR(MAX)
	DECLARE @query  AS NVARCHAR(MAX)
	DECLARE @colsPivot AS  NVARCHAR(MAX)
	DECLARE @colsPivotSelect AS  NVARCHAR(MAX)

	DECLARE @colsNumber AS INT = 40

	--------------------------------------------------------------------
	-- OUTPUT CUSTOMER INFO
	--------------------------------------------------------------------   
	DELETE FROM GDPR.CustomerInformation

	INSERT INTO GDPR.CustomerInformation (ID) VALUES(0)
	       
	INSERT INTO GDPR.CustomerInformation
	SELECT TOP (@colsNumber) C.*
	FROM
	(	SELECT B.ID, A.Title, A.[First Name], A.Initials, A.[Middle Name], A.[Last Name], A.[Second Last Name], A.[Birth Date], A.Gender, A.[Organisation Name], A.[Person/Organisation], A.[Language], A.[Permission to Contact?]
		FROM
			(SELECT * FROM GDPR.CustomerInformation) A
			CROSS JOIN
			(SELECT TOP (@colsNumber) ROW_NUMBER() OVER (ORDER BY column_id) AS ID FROM sys.columns) B

		UNION ALL 
		       
		SELECT DISTINCT
				--ROW_NUMBER() OVER(ORDER BY P.PartyID) AS ID,
				DENSE_RANK() OVER(ORDER BY P.PartyID, 
											COALESCE(PP.LastName, PP_O.LastName, ''), 
											COALESCE(PP.FirstName, PP_O.FirstName, ''), 
											COALESCE(T.Title, T_O.Title, ''), 
											COALESCE(PP.Initials, PP_O.Initials, ''), 
											COALESCE(PP.MiddleName, PP_O.MiddleName, ''),
											COALESCE(CONVERT(NVARCHAR(24), PP.BirthDate, 103),CONVERT(NVARCHAR(24), PP_O.BirthDate, 103), ''),
											COALESCE(O.OrganisationName, O_PP.OrganisationName, ''), 
											CASE	WHEN NS.NonSolicitationID IS NOT NULL THEN 'No'
													WHEN CP.PartySuppression = 1 THEN 'No'
													ELSE 'Yes'
													END,
											ISNULL(L.Language,N'')) AS ID,					-- V1.2
				--P.PartyID,
				CONVERT(NVARCHAR(400),COALESCE(T.Title, T_O.Title, '')) AS [Title],
				CONVERT(NVARCHAR(400),COALESCE(PP.FirstName, PP_O.FirstName, '')) AS [First Name],
				CONVERT(NVARCHAR(400),COALESCE(PP.Initials, PP_O.Initials, '')) AS [Initials],
				CONVERT(NVARCHAR(400),COALESCE(PP.MiddleName, PP_O.MiddleName, '')) AS [Middle Name],
				CONVERT(NVARCHAR(400),COALESCE(PP.LastName, PP_O.LastName, '')) AS [Last Name],
				CONVERT(NVARCHAR(400),COALESCE(PP.SecondLastName, PP_O.SecondLastName, '')) AS [Second Last Name],
				CONVERT(NVARCHAR(400),COALESCE(CONVERT(NVARCHAR(24), PP.BirthDate, 103),
						 CONVERT(NVARCHAR(24), PP_O.BirthDate, 103), '')) AS [Birth Date],
				CONVERT(NVARCHAR(400),COALESCE(G.Gender, G_O.Gender, '')) AS [Gender],
				CONVERT(NVARCHAR(400),COALESCE(O.OrganisationName, O_PP.OrganisationName, '')) AS [Organisation Name],
				CONVERT(NVARCHAR(400),CASE WHEN PP.PartyID IS NOT NULL THEN 'Person'
						WHEN O.PartyID IS NOT NULL THEN 'Organisation' END) AS [Person/Organisation],
				CONVERT(NVARCHAR(400),ISNULL(L.Language,N'')) AS [Language],
				CONVERT(NVARCHAR(400),CASE 
						WHEN NS.NonSolicitationID IS NOT NULL THEN 'No'
						WHEN CP.PartySuppression = 1 THEN 'No'
						ELSE 'Yes'
						END) AS [Permission to Contact?]
		FROM    [$(SampleDB)].Party.Parties P
				LEFT JOIN [$(SampleDB)].Party.People PP
					INNER JOIN [$(SampleDB)].Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = P.PartyID
				LEFT JOIN [$(SampleDB)].Party.Genders G ON G.GenderID = PP.GenderID
				LEFT JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = P.PartyID
				-- FOR A PERSON PARTY GET ANY RELATED ORGANISATION
				LEFT JOIN [$(SampleDB)].Party.PartyRelationships PR_PP
					INNER JOIN [$(SampleDB)].Party.Organisations O_PP ON O_PP.PartyID = PR_PP.PartyIDTo
								AND PR_PP.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employee')
								AND PR_PP.RoleTypeIDTo = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employer') 
							ON PR_PP.PartyIDFrom = PP.PartyID
				-- FOR AN ORGANISATION PARTY GET ANY RELATED EMPLOYEE
				LEFT JOIN [$(SampleDB)].Party.PartyRelationships PR_O
					INNER JOIN [$(SampleDB)].Party.People PP_O ON PP_O.PartyID = PR_O.PartyIDFrom
								AND PR_O.RoleTypeIDFrom = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employee')
								AND PR_O.RoleTypeIDTo = (SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Employer')
					INNER JOIN [$(SampleDB)].Party.Titles T_O ON T_O.TitleID = PP_O.TitleID
				LEFT JOIN [$(SampleDB)].Party.Genders G_O ON G_O.GenderID = PP_O.GenderID ON PR_O.PartyIDTo = O.PartyID
				LEFT JOIN [$(SampleDB)].Party.PartyLanguages PL
					INNER JOIN [$(SampleDB)].dbo.Languages L ON L.LanguageID = PL.LanguageID
								AND PL.PreferredFlag = 1 ON PL.PartyID = P.PartyID
				LEFT JOIN [$(SampleDB)].dbo.NonSolicitations NS
					INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID													
								AND ISNULL(NS.FromDate, '1 Jan 1900') < GETDATE()
								AND ISNULL(NS.ThroughDate,'31 Dec 9999') > GETDATE() 
							ON NS.PartyID = P.PartyID
				LEFT JOIN [$(SampleDB)].Party.ContactPreferences CP ON P.PartyID = CP.PartyID
				

		WHERE   P.PartyID = @PartyID
	) C
	ORDER BY C.[Person/Organisation] DESC, C.ID DESC

	--SELECT * FROM GDPR.CustomerInformation
	--SELECT * FROM sys.columns AS C WHERE C.object_id = object_id('GDPR.CustomerInformation') AND C.name <> 'ID'
	             
	SELECT @colsUnpivot = STUFF((SELECT ','+ QUOTENAME(name)
			 FROM sys.columns AS C
			 WHERE C.object_id = object_id('GDPR.CustomerInformation')
				AND C.name <> 'ID'
			 FOR XML PATH('')), 1, 1, '')

	SELECT @colsPivot = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.CustomerInformation t
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SELECT @colsPivotSelect = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.CustomerInformation t
						WHERE t.ID <> 0
						ORDER BY ID
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SET @query 
	  = 'SELECT O.name, '+@colsPivotSelect+'
		  FROM
		  ( SELECT ID, name, value
			FROM GDPR.CustomerInformation 
			UNPIVOT
			( value FOR name IN ('+@colsUnpivot+')) unpiv
		  ) src
		  PIVOT
		  ( MAX(value) FOR ID IN ('+@colsPivot+')
		  ) piv
		  INNER JOIN	(SELECT C.name, C.column_id 
						FROM sys.columns AS C
						WHERE C.object_id = object_id(''GDPR.CustomerInformation'')
						) O ON piv.name = O.name
		ORDER BY O.column_id'

	--SELECT @query, @colsUnpivot, @colsPivot

	INSERT INTO @Pivot (name)
	SELECT 'Customer Information:-' AS name

	INSERT INTO @Pivot
	EXEC(@query)

	--SELECT * FROM @Pivot
	--------------------------------------------------------------------


	--------------------------------------------------------------------
	-- GET THE POSTAL ADDRESS DETAILS
	--------------------------------------------------------------------
	DELETE FROM GDPR.PostalAddresses

	INSERT INTO GDPR.PostalAddresses (ID) VALUES(0)
	       
	INSERT INTO GDPR.PostalAddresses		
	SELECT TOP (@colsNumber) C.*
	FROM
	(	SELECT B.ID, A.[Building Name], A.[Sub Street Number], A.[Sub Street], A.[Street Number], A.Street, A.[Sub Locality], A.Locality, A.Town, A.Region, A.PostCode, A.Country ,A.[Permission to Contact By Post?], A.[Best Postal Address?]
		FROM
			(SELECT * FROM GDPR.PostalAddresses) A
		CROSS JOIN
			(SELECT TOP (@colsNumber) ROW_NUMBER() OVER (ORDER BY column_id) AS ID FROM sys.columns) B

		UNION ALL
		       
		SELECT DISTINCT
				ROW_NUMBER() OVER(ORDER BY PA.ContactMechanismID) AS ID,
				--E.EventID,
				CONVERT(NVARCHAR(400),PA.BuildingName) AS [Building Name],
				CONVERT(NVARCHAR(400),PA.SubStreetNumber) AS [Sub Street Number],
				CONVERT(NVARCHAR(400),PA.SubStreet) AS [Sub Street],
				CONVERT(NVARCHAR(400),PA.StreetNumber) AS [Street Number],
				CONVERT(NVARCHAR(400),PA.Street) AS [Street],
				CONVERT(NVARCHAR(400),PA.SubLocality) AS [Sub Locality],
				CONVERT(NVARCHAR(400),PA.Locality) AS [Locality],
				CONVERT(NVARCHAR(400),PA.Town) AS [Town],
				CONVERT(NVARCHAR(400),PA.Region) AS [Region],
				CONVERT(NVARCHAR(400),PA.PostCode) AS [PostCode],
				CONVERT(NVARCHAR(400),C.Country) AS [Country],
				CONVERT(NVARCHAR(400),CASE 
						WHEN NS.NonSolicitationID IS NOT NULL THEN 'No'
						WHEN CP.PostalSuppression = 1 THEN 'No'
						ELSE 'Yes'
				END) AS [Permission to Contact By Post?],
				CONVERT(NVARCHAR(400),CASE WHEN PBPA.PartyID IS NOT NULL THEN 'Yes'
					 ELSE 'No'
				END) AS [Best Postal Address?]
		FROM    [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
				INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PCM.ContactMechanismID
				INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = PA.CountryID
				LEFT JOIN [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID
																-- begin Version: 2.0 change	
															  AND ISNULL(NS.FromDate,
															  '1 Jan 1900') < GETDATE()
															  AND ISNULL(NS.ThroughDate,
															  '31 Dec 9999') > GETDATE() ON NS.PartyID = PCM.PartyID
															  -- end Version: 2.0 change  (there are others)
															  AND CMNS.ContactMechanismID = PA.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PCM.PartyID
															  AND PBPA.ContactMechanismID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Party.ContactPreferences CP ON PCM.PartyID = CP.PartyID
		WHERE   PCM.PartyID = @PartyID
	) C
	ORDER BY C.Country DESC, C.ID DESC

	--SELECT * FROM GDPR.PostalAddresses
	--SELECT * FROM sys.columns AS C WHERE C.object_id = object_id('GDPR.PostalAddresses') AND C.name <> 'ID'
	             
	SELECT @colsUnpivot = STUFF((SELECT ','+ QUOTENAME(name)
			 FROM sys.columns AS C
			 WHERE C.object_id = object_id('GDPR.PostalAddresses')
				AND C.name <> 'ID'
			 FOR XML PATH('')), 1, 1, '')

	SELECT @colsPivot = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.PostalAddresses t
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SELECT @colsPivotSelect = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.PostalAddresses t
						WHERE t.ID <> 0
						ORDER BY ID
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SET @query 
	  = 'SELECT O.name, '+@colsPivotSelect+'
		  FROM
		  ( SELECT ID, name, value
			FROM GDPR.PostalAddresses 
			UNPIVOT
			( value FOR name IN ('+@colsUnpivot+')) unpiv
		  ) src
		  PIVOT
		  ( MAX(value) FOR ID IN ('+@colsPivot+')
		  ) piv
		  INNER JOIN	(SELECT C.name, C.column_id 
						FROM sys.columns AS C
						WHERE C.object_id = object_id(''GDPR.PostalAddresses'')
						) O ON piv.name = O.name
		ORDER BY O.column_id'

	--SELECT @query, @colsUnpivot, @colsPivot

	INSERT INTO @Pivot (name)
	SELECT '' AS name

	INSERT INTO @Pivot (name)
	SELECT 'Postal Addresses:-'

	INSERT INTO @Pivot
	EXEC(@query)

	--SELECT * FROM @Pivot
	--------------------------------------------------------------------


	--------------------------------------------------------------------
	-- GET THE TELEPHONE NUMBERS
	--------------------------------------------------------------------
	DELETE FROM GDPR.PhoneNumbers

	INSERT INTO GDPR.PhoneNumbers (ID) VALUES(0)
	       
	INSERT INTO GDPR.PhoneNumbers
	SELECT TOP (@colsNumber) *
	FROM
	(	SELECT B.ID, A.[Contact Number], A.[Contact Number Type], A.[Permission to Contact By Phone?], A.[Best Telephone Number?]
		FROM
			(SELECT * FROM GDPR.PhoneNumbers) A
		CROSS JOIN
			(SELECT TOP (@colsNumber) ROW_NUMBER() OVER (ORDER BY column_id) AS ID 
			FROM sys.columns) B
		
		UNION ALL
	       
		SELECT DISTINCT
				ROW_NUMBER() OVER(ORDER BY PCM.ContactMechanismID) AS ID,
				--PCM.ContactMechanismID AS COL1,
				CONVERT(NVARCHAR(400),TN.ContactNumber) AS [Contact Number],
				CONVERT(NVARCHAR(400),CMT.ContactMechanismType) AS [Contact Number Type],
				CONVERT(NVARCHAR(400),CASE 
						WHEN NS.NonSolicitationID IS NOT NULL THEN 'No'
						WHEN CP.PhoneSuppression = 1 THEN 'No'
						ELSE 'Yes'
				END) AS [Permission to Contact By Phone?],
				CONVERT(NVARCHAR(400),CASE WHEN PBTN_HOME.PartyID IS NOT NULL THEN 'Yes'
					 WHEN PBTN_LAND.PartyID IS NOT NULL THEN 'Yes'
					 WHEN PBTN_MOB.PartyID IS NOT NULL THEN 'Yes'
					 WHEN PBTN_PHONE.PartyID IS NOT NULL THEN 'Yes'
					 WHEN PBTN_WORK.PartyID IS NOT NULL THEN 'Yes'
					 ELSE 'No'
				END) AS [Best Telephone Number?]        
		        
		FROM    [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
				INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = PCM.ContactMechanismID
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = TN.ContactMechanismID
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CM.ContactMechanismTypeID
				LEFT JOIN [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID ON NS.PartyID = PCM.PartyID
																-- begin Version: 2.0 change
															  AND ISNULL(NS.FromDate,
															  '1 Jan 1900') < GETDATE()
															  AND ISNULL(NS.ThroughDate,
															  '31 Dec 9999') > GETDATE()
															  -- end Version: 2.0 change
															  AND CMNS.ContactMechanismID = TN.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Meta.PartyBestTelephoneNumbers PBTN_HOME ON PBTN_HOME.PartyID = PCM.PartyID
															  AND PBTN_HOME.HomeLandlineID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Meta.PartyBestTelephoneNumbers PBTN_LAND ON PBTN_LAND.PartyID = PCM.PartyID
															  AND PBTN_LAND.LandlineID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Meta.PartyBestTelephoneNumbers PBTN_MOB ON PBTN_MOB.PartyID = PCM.PartyID
															  AND PBTN_MOB.MobileID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Meta.PartyBestTelephoneNumbers PBTN_PHONE ON PBTN_PHONE.PartyID = PCM.PartyID
															  AND PBTN_PHONE.PhoneID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Meta.PartyBestTelephoneNumbers PBTN_WORK ON PBTN_WORK.PartyID = PCM.PartyID
															  AND PBTN_WORK.WorkLandlineID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Party.ContactPreferences CP ON PCM.PartyID = CP.PartyID
		WHERE   PCM.PartyID = @PartyID
	) C
	ORDER BY C.[Contact Number] DESC, C.ID DESC

	--SELECT * FROM GDPR.PhoneNumbers
	--SELECT * FROM sys.columns AS C WHERE C.object_id = object_id('GDPR.PhoneNumbers') AND C.name <> 'ID'
	             
	SELECT @colsUnpivot = STUFF((SELECT ','+ QUOTENAME(name)
			 FROM sys.columns AS C
			 WHERE C.object_id = object_id('GDPR.PhoneNumbers')
				AND C.name <> 'ID'
			 FOR XML PATH('')), 1, 1, '')

	SELECT @colsPivot = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.PhoneNumbers t
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SELECT @colsPivotSelect = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.PhoneNumbers t
						WHERE t.ID <> 0
						ORDER BY ID
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SET @query 
	  = 'SELECT O.name, '+@colsPivotSelect+'
		  FROM
		  ( SELECT ID, name, value
			FROM GDPR.PhoneNumbers 
			UNPIVOT
			( value FOR name IN ('+@colsUnpivot+')) unpiv
		  ) src
		  PIVOT
		  ( MAX(value) FOR ID IN ('+@colsPivot+')
		  ) piv
		  INNER JOIN	(SELECT C.name, C.column_id 
						FROM sys.columns AS C
						WHERE C.object_id = object_id(''GDPR.PhoneNumbers'')
						) O ON piv.name = O.name
		ORDER BY O.column_id'

	--SELECT @query, @colsUnpivot, @colsPivot

	INSERT INTO @Pivot (name)
	SELECT '' AS name

	INSERT INTO @Pivot (name)
	SELECT 'Phone Numbers:-' AS name

	INSERT INTO @Pivot
	EXEC(@query)

	--SELECT * FROM @Pivot
	--------------------------------------------------------------------


	--------------------------------------------------------------------
	-- GET THE EMAIL ADDRESS DETAILS
	--------------------------------------------------------------------
	DELETE FROM GDPR.EmailAddresses
	 
	INSERT INTO GDPR.EmailAddresses (ID) VALUES(0)
	      
	INSERT INTO GDPR.EmailAddresses
	SELECT TOP (@colsNumber) *
	FROM
	(	SELECT B.ID, A.[Email Address], A.[Permission to Contact By Email?], A.[Best Email Address?]
		FROM
			(SELECT * FROM GDPR.EmailAddresses) A
		CROSS JOIN
			(SELECT TOP (@colsNumber) ROW_NUMBER() OVER (ORDER BY column_id) AS ID 
			FROM sys.columns) B

		UNION ALL 
		       
		SELECT DISTINCT
				ROW_NUMBER() OVER(ORDER BY PCM.ContactMechanismID) AS ID,
				CONVERT(NVARCHAR(400),EA.EmailAddress) AS [Email Address],
				CONVERT(NVARCHAR(400),CASE 
						WHEN NS.NonSolicitationID IS NOT NULL THEN 'No'
						WHEN CP.EmailSuppression = 1 THEN 'No'
						ELSE 'Yes'
				END) AS [Permission to Contact By Email?],
				CONVERT(NVARCHAR(400),CASE WHEN PBEA.PartyID IS NOT NULL THEN 'Yes'
					 ELSE 'No'
				END) AS [Best Email Address?]

		FROM    [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
				INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID ON NS.PartyID = PCM.PartyID
																-- begin Version: 2.0 change
															  AND ISNULL(NS.FromDate,
															  '1 Jan 1900') < GETDATE()
															  AND ISNULL(NS.ThroughDate,
															  '31 Dec 9999') > GETDATE()
															  -- end Version: 2.0 change
															  AND CMNS.ContactMechanismID = EA.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Meta.PartyBestEmailAddresses PBEA ON PBEA.PartyID = PCM.PartyID
															  AND PBEA.ContactMechanismID = PCM.ContactMechanismID
				LEFT JOIN [$(SampleDB)].Party.ContactPreferences CP ON PCM.PartyID = CP.PartyID
		WHERE   PCM.PartyID = @PartyID
		AND LEN(EA.EmailAddress) > 0
	) C
	ORDER BY C.[Email Address] DESC, C.ID DESC 


	--SELECT * FROM GDPR.EmailAddresses
	--SELECT * FROM sys.columns AS C WHERE C.object_id = object_id('GDPR.EmailAddresses') AND C.name <> 'ID'
	             
	SELECT @colsUnpivot = STUFF((SELECT ','+ QUOTENAME(name)
			 FROM sys.columns AS C
			 WHERE C.object_id = object_id('GDPR.EmailAddresses')
				AND C.name <> 'ID'
			 FOR XML PATH('')), 1, 1, '')

	SELECT @colsPivot = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.EmailAddresses t
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SELECT @colsPivotSelect = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.EmailAddresses t
						WHERE t.ID <> 0
						ORDER BY ID
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SET @query 
	  = 'SELECT O.name, '+@colsPivotSelect+'
		  FROM
		  ( SELECT ID, name, value
			FROM GDPR.EmailAddresses 
			UNPIVOT
			( value FOR name IN ('+@colsUnpivot+')) unpiv
		  ) src
		  PIVOT
		  ( MAX(value) FOR ID IN ('+@colsPivot+')
		  ) piv
		  INNER JOIN	(SELECT C.name, C.column_id 
						FROM sys.columns AS C
						WHERE C.object_id = object_id(''GDPR.EmailAddresses'')
						) O ON piv.name = O.name
		ORDER BY O.column_id'

	--SELECT @query, @colsUnpivot, @colsPivot

	INSERT INTO @Pivot (name)
	SELECT '' AS name

	INSERT INTO @Pivot (name)
	SELECT 'Email Addresses:-'

	INSERT INTO @Pivot
	EXEC(@query)

	--SELECT * FROM @Pivot
	--------------------------------------------------------------------


	--------------------------------------------------------------------
	-- GET EVENTS AND VEHICLES
	--------------------------------------------------------------------
	DELETE FROM GDPR.Events

	INSERT INTO GDPR.Events (ID) VALUES(0)
	       
	INSERT INTO GDPR.Events
	SELECT TOP (@colsNumber) C.*
	FROM
	(	SELECT B.ID, A.[Event Type], A.[Event Date], A.VIN, A.[Model Description], A.[Registration Number], A.[Registration Date], A.[Invoice Number], A.[Invoice Value], A.[Dealer Name], A.[Dealer Code], A.[Customer Contact?], A.[Customer Contact Status], A.[Customer Contact Description], A.[Customer Contact Creation Date]
		FROM
			(SELECT * FROM GDPR.Events) A
		CROSS JOIN
			(SELECT TOP (@colsNumber) ROW_NUMBER() OVER (ORDER BY column_id) AS ID FROM sys.columns) B

		UNION ALL 

		SELECT DISTINCT
				DENSE_RANK() OVER (ORDER BY  E.EventID, C.CaseID, R.RegistrationNumber, R.RegistrationDate, R1.Requirement) AS ID,
				--E.EventID,
				CONVERT(NVARCHAR(400),CASE ET.EventType
					WHEN 'Bodyshop' THEN 'Bodyshop Repair'
					WHEN 'CRC' THEN 'Customer Relations Contact'
					WHEN 'LostLeads' THEN 'Lost Leads Enquiry'
					WHEN 'PreOwned' THEN 'Used Car Sales'
					WHEN 'Roadside' THEN 'Roadside Repair'
					WHEN 'Sales' THEN 'New Car Sales'
					WHEN 'Service' THEN 'Car Service'
					WHEN 'Warranty' THEN 'Car Service (Under Warranty)' 
					ELSE ET.EventType END) AS [Event Type],
				CONVERT(NVARCHAR(400),CONVERT(NVARCHAR(24), ISNULL(E.EventDate,N''), 103)) AS [Event Date],
				--V.VehicleID,
				CONVERT(NVARCHAR(400),V.VIN) AS [VIN],
				--CONVERT(NVARCHAR(400),ISNULL(V.ChassisNumber, N'')) AS [Chassis Number],
				CONVERT(NVARCHAR(400),M.ModelDescription) AS [Model Description],
				--R.RegistrationID,
				CONVERT(NVARCHAR(400),ISNULL(R.RegistrationNumber, N'')) AS [Registration Number],
				CONVERT(NVARCHAR(400),ISNULL(CONVERT(NVARCHAR(24), R.RegistrationDate, 103), N'')) AS [Registration Date],
				CONVERT(NVARCHAR(400),ISNULL(AIS.InvoiceNumber, N'')) AS [Invoice Number],
				CONVERT(NVARCHAR(400),ISNULL(AIS.InvoiceValue, N'')) AS [Invoice Value],
				CONVERT(NVARCHAR(400),D.Outlet) AS [Dealer Name],
				CONVERT(NVARCHAR(400),D.OutletCode) AS [Dealer Code],
				--ISNULL(CONVERT(NVARCHAR,C.CaseID), N'') AS COL10,
				CONVERT(NVARCHAR(400),	CASE	WHEN ISNULL(C.CaseID,0) > 0 AND CR.CaseID IS NULL THEN 'Yes' 				
										ELSE 'No' END) AS [Customer Contact?],
				CONVERT(NVARCHAR(400),	CASE	WHEN CR.CaseID IS NULL THEN
											CASE R1.Requirement
												WHEN 'JLR 2004' THEN 'JLR Sales/Service Survey'
												WHEN 'PreOwned' THEN 'PreOwned Survey'
												ELSE ISNULL(R1.Requirement,N'') END 
										ELSE '' END) AS [Customer Contact Description],
				CONVERT(NVARCHAR(400),	CASE	WHEN CR.CaseID IS NULL THEN	ISNULL(CST.CaseStatusType, N'')
										ELSE '' END) AS [Customer Contact Status],
				CONVERT(NVARCHAR(400),	CASE	WHEN CR.CaseID IS NULL THEN ISNULL(CONVERT(NVARCHAR(24), C.CreationDate, 103), N'') 
										ELSE '' END) AS [Customer Contact Creation Date]
				--ISNULL(CONVERT(NVARCHAR(24), C.ClosureDate, 103), N'') AS COL13
				--ISNULL(S.Requirement, N'') AS Selection
				--ISNULL(COT.CaseOutputType, N'') AS COL13
				--ISNULL(F.FileName,N'') AS COL14

		FROM    [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
				INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = VPRE.VehicleID
				INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID
				INNER JOIN [$(SampleDB)].Event.Events E ON E.EventID = VPRE.EventID
				INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
				LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
					INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID ON VRE.EventID = VPRE.EventID
															  AND VRE.VehicleID = VPRE.VehicleID
				LEFT JOIN [$(SampleDB)].Event.EventPartyRoles EPR
					INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID
													 AND D.OutletFunctionID = EPR.RoleTypeID ON EPR.EventID = E.EventID
				LEFT JOIN [$(SampleDB)].Event.AdditionalInfoSales AIS ON E.EventID = AIS.EventID
				LEFT JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI
					INNER JOIN [$(SampleDB)].Event.Cases C ON C.CaseID = AEBI.CaseID
					LEFT JOIN [$(SampleDB)].Event.CaseRejections CR ON C.CaseID = CR.CaseID
					INNER JOIN [$(SampleDB)].Event.CaseStatusTypes CST ON CST.CaseStatusTypeID = C.CaseStatusTypeID
					INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
					INNER JOIN [$(SampleDB)].Requirement.Requirements S ON S.RequirementID = SC.RequirementIDPartOf
					INNER JOIN [$(SampleDB)].Requirement.RequirementRollups RRS ON S.RequirementID = RRS.RequirementIDMadeUpOf
					INNER JOIN [$(SampleDB)].Requirement.RequirementRollups RRR ON RRS.RequirementIDPartOf = RRR.RequirementIDMadeUpOf
					INNER JOIN [$(SampleDB)].Requirement.Requirements R1 ON RRR.RequirementIDPartOf = R1.RequirementID AND R1.RequirementTypeID = 1
				--LEFT JOIN [Sample].Event.CaseOutput CO
				--INNER JOIN [Sample].Event.CaseOutputTypes COT ON COT.CaseOutputTypeID = CO.CaseOutputTypeID ON CO.CaseID = C.CaseID 
					ON AEBI.EventID = E.EventID
                                      AND AEBI.PartyID = VPRE.PartyID							-- V1.1
                                      AND AEBI.VehicleID = VPRE.VehicleID						-- V1.1
                                      AND AEBI.VehicleRoleTypeID = VPRE.VehicleRoleTypeID		-- V1.1
				--LEFT JOIN [Sample_Audit].Audit.Events AE  ON E.EventID = AE.EventID
				--LEFT JOIN [Sample_Audit].dbo.AuditItems AI ON AE.AuditItemID  = AI.AuditItemID
				--LEFT JOIN [Sample_Audit].dbo.Files F ON AI.AuditID = F.AuditID

	WHERE   VPRE.PartyID = @PartyID
	) C
	ORDER BY C.[Event Type] DESC, C.ID DESC

	--SELECT * FROM GDPR.Events
	--SELECT * FROM sys.columns AS C WHERE C.object_id = object_id('GDPR.Events') AND C.name <> 'ID'
	             
	SELECT @colsUnpivot = STUFF((SELECT ','+ QUOTENAME(name)
			 FROM sys.columns AS C
			 WHERE C.object_id = object_id('GDPR.Events')
				AND C.name <> 'ID'
			 FOR XML PATH('')), 1, 1, '')

	SELECT @colsPivot = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.Events t
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SELECT @colsPivotSelect = STUFF((SELECT  ',' 
						  + QUOTENAME(ID)
						FROM GDPR.Events t
						WHERE t.ID <> 0
						ORDER BY ID
				FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)') 
			,1,1,'')

	SET @query 
	  = 'SELECT O.name, '+@colsPivotSelect+'
		  FROM
		  ( SELECT ID, name, value
			FROM GDPR.Events 
			UNPIVOT
			( value FOR name IN ('+@colsUnpivot+')) unpiv
		  ) src
		  PIVOT
		  ( MAX(value) FOR ID IN ('+@colsPivot+')
		  ) piv
		  INNER JOIN	(SELECT C.name, C.column_id 
						FROM sys.columns AS C
						WHERE C.object_id = object_id(''GDPR.Events'')
						) O ON piv.name = O.name
		ORDER BY O.column_id'

	--SELECT @query, @colsUnpivot, @colsPivot

	INSERT INTO @Pivot (name)
	SELECT '' AS name

	INSERT INTO @Pivot (name)
	SELECT 'Event Details:-' AS name

	INSERT INTO @Pivot
	EXEC(@query)

	SELECT * FROM @Pivot

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