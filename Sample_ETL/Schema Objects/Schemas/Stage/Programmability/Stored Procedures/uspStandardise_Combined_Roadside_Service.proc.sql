CREATE PROCEDURE Stage.uspStandardise_Combined_Roadside_Service

	@SampleFileName NVARCHAR (1000)

AS

/*
			Purpose:	Convert the service date from a text string to a valid DATETIME type
	
Release		Version		Date			Developer			Comment
LIVE		1.0			$(ReleaseDate)	Chris Ross			Created from [Sample-ETL].Stage.uspStandardise_Combined_DDW_Service
LIVE		1.1			11/10/2013		Chris Ross			8967 - Convert 2 digit country and breakdown country codes to 3 digit
																 - (Convert 2 digit Luxembourg into 3 digit Belgium)
																 - Convert CarHireStartTime column to time if it's set.
LIVE		1.2			01/07/2015		Peter Doyle			BUG 11682: deal with blank/null countries arriving in column 22
LIVE		1.3			07/03/2016		Chris Ledger		BUG 12439: deal with Japan having Japan in column 22
LIVE		1.4			16/05/2016		Chris Ross			BUG 12659: change to also look at breakdown country when determining 
LIVE																   default language (as address country may be blank).
LIVE		1.5			29/11/2018		Chris Ledger		Changes Copied From LIVE back to Solution.
LIVE		1.6			31/10/2019		Chris Ross			BUG 15651 - Split the French sample surnname fields for Companies
LIVE		1.7			15/02/2021		Ben King	        BUG 18106 - Belgium Preferred Language	
LIVE		1.8			17/12/2021      Ben King			TASK 731 - 18419 - File Failures 14122021
LIVE		1.9			18/02/2022		Chris Ledger		TASK 728 - Set [Address7(Postcode/Zipcode)] to [Address8(Country)] for Russia
LIVE		1.10		02/09/2022		Eddie Thomas		TASK 994 - Brazil Roadside Reconfiguration
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH

BEGIN TRY

	SET DATEFORMAT DMY  -- First ensure dmy format for ISDATE functions

	UPDATE S
	SET S.ConvertedBreakdownDate = CONVERT (DATETIME, S.BreakdownDate, 103)
	FROM Stage.Combined_Roadside_Service S
	WHERE ISDATE(S.BreakdownDate) = 1
	
	
	------
	UPDATE S
	SET S.ConvertedCarHireStartDate = CONVERT (DATETIME, S.CarHireStartDate, 103)
	FROM Stage.Combined_Roadside_Service S
	WHERE ISDATE(S.CarHireStartDate) =  1

	
	-- V1.9 Set [Address7(Postcode/Zipcode)] to [Address8(Country)] for Russia
	UPDATE S
	SET S.[Address7(Postcode/Zipcode)] = S.[Address8(Country)]
	FROM Stage.Combined_Roadside_Service S
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.ISOAlpha2 =	CASE	WHEN S.CountryCodeISOAlpha2 = 'Japan' THEN S.CountryCode	-- V1.3 Japan sent instead of ISOalpha2
																						WHEN S.CountryCodeISOAlpha2 = 'Turkey' THEN S.CountryCode	-- V1.6 Turkey sent instead of ISOalpha2
																						WHEN S.CountryCodeISOAlpha2 IS NULL	OR S.CountryCodeISOAlpha2 = '' THEN S.CountryCode
																						ELSE S.CountryCodeISOAlpha2 END				  
	WHERE C.Country = 'Russian Federation'


	-----
	-- V1.2
	UPDATE S
    SET S.[Address8(Country)] =	CASE C.ISOAlpha3	WHEN 'LUX' THEN 'BEL'
													ELSE C.ISOAlpha3 END
    FROM Stage.Combined_Roadside_Service S
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.ISOAlpha2 =	CASE	--WHEN S.CountryCodeISOAlpha2 = 'Japan' THEN S.CountryCode	-- V1.3 Japan sent instead of ISOalpha2
																						--WHEN S.CountryCodeISOAlpha2 = 'Turkey' THEN S.CountryCode	-- V1.6 Turkey sent instead of ISOalpha2
																						WHEN S.CountryCodeISOAlpha2	IN ('Japan','Turkey','Brazil') THEN S.CountryCode -- V1.3 --V1.6  --V1.10	
																						WHEN S.CountryCodeISOAlpha2 IS NULL	OR S.CountryCodeISOAlpha2 = '' THEN S.CountryCode
																						ELSE S.CountryCodeISOAlpha2 END				  


	-- V1.5
	UPDATE S
	SET	S.CountryCodeISOAlpha2 = CASE S.CountryCodeISOAlpha2	WHEN 'Japan' THEN S.CountryCode
																WHEN 'Turkey' THEN S.CountryCode			-- V1.6
																WHEN 'Brazil' THEN S.CountryCode			--V1.10
																WHEN '' THEN S.CountryCode
																ELSE S.CountryCodeISOAlpha2 END	
	FROM Stage.Combined_Roadside_Service S
									

	-----
	UPDATE S
	SET S.BreakdownCountry = CASE C.ISOAlpha3	WHEN 'LUX' THEN 'BEL' 
												ELSE C.ISOAlpha3 END
	FROM Stage.Combined_Roadside_Service S
		INNER JOIN [$(SampleDB)].ContactMechanism .Countries C ON C.ISOAlpha2 = S.BreakdownCountryISOAlpha2


	-----
	UPDATE S
	SET S.ConvertedCarHireStartTime = CONVERT(TIME, S.CarHireStartTime)
	FROM Stage.Combined_Roadside_Service S
	WHERE ISDATE(S.CarHireStartTime) = 1
	
	
	-----  SET PREFERRED LANGUAGE ----------------------------------------
	-- 1st Lookup Preferred Language in Language table
	UPDATE S
	SET S.PreferredLanguageID = L.LanguageID
	FROM Stage.Combined_Roadside_Service S
		INNER JOIN [$(SampleDB)].dbo.Languages L ON L.Language = S.PreferredLanguage

	
	-- Then, if not found, set using default language for country  
	UPDATE S
	SET S.PreferredLanguageID = C.DefaultLanguageID 
	FROM Stage.Combined_Roadside_Service S
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.ISOAlpha2 = COALESCE(NULLIF(S.CountryCodeISOAlpha2, ''), NULLIF(S.BreakdownCountryISOAlpha2, ''))    -- Use the original country code (or breakdown country) supplied to determine preferred language
	WHERE S.PreferredLanguageID IS NULL
	

	--V1.7
	--NO DEFULAT PERMITTED FOR BELGIUM
	UPDATE S
	SET PreferredLanguageID = CASE	WHEN S.PreferredLanguage = 'French' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='FR')
									WHEN S.PreferredLanguage = 'Dutch' THEN (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE ISOAlpha2 ='NL')
									ELSE 0 END
	FROM Stage.Combined_Roadside_Service S
	WHERE COALESCE(NULLIF(S.CountryCodeISOAlpha2, ''), NULLIF(S.BreakdownCountryISOAlpha2, '')) = 'BE'


	-- Failing that default to English
	UPDATE S
	SET S.PreferredLanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	FROM Stage.Combined_Roadside_Service S
	WHERE S.PreferredLanguageID IS NULL	
		AND COALESCE(NULLIF(S.CountryCodeISOAlpha2, ''), NULLIF(S.BreakdownCountryISOAlpha2, '')) <> 'BE' --V1.7


	----------------------------------------------------------------------------------------------------
	-- Set SampleTriggeredSelectionReqID for MENA RoadSide
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate (ID, Manufacturer, CountryCode, EventType, Country, CountryID) AS
	(
		-- Add In CountryID
		SELECT GS.ID, 
			GS.Manufacturer, 
			GS.CountryCodeISOAlpha2, 
			GS.EventType, 
			C.Country,
			C.CountryID
		FROM Stage.Combined_Roadside_Service	GS
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries	C ON GS.CountryCodeISOAlpha2 = C.ISOAlpha2
	)
	-- Retrieve Metadata values for each event in the table
	SELECT DISTINCT	RU.ID, 
		RU.Manufacturer, 
		RU.CountryCode, 
		RU.EventType, 
		RU.Country, 
		RU.CountryID, 
		MD.ManufacturerPartyID, 
		MD.EventTypeID, 
		MD.LanguageID, 
		MD.SetNameCapitalisation,
		MD.DealerCodeOriginatorPartyID, 
		MD.CreateSelection, 
		MD.SampleTriggeredSelection,
		MD.QuestionnaireRequirementID
	INTO #Completed							
	FROM RecordsToUpdate RU
		INNER JOIN (	SELECT DISTINCT M.ManufacturerPartyID, 
							M.CountryID, 
							ET.EventTypeID,  
							C.DefaultLanguageID AS LanguageID, 
							M.SetNameCapitalisation, 
							M.DealerCodeOriginatorPartyID,
							M.Brand, 
							M.Questionnaire, 
							M.SampleLoadActive, 
							M.SampleFileNamePrefix,
							M.CreateSelection, 
							M.SampleTriggeredSelection, 
							M.QuestionnaireRequirementID					
						FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
							INNER JOIN [$(SampleDB)].Event.EventTypes ET ON ET.EventType = M.Questionnaire
							INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = M.CountryID		
						WHERE M.Questionnaire	= 'Roadside' 
							AND M.SampleLoadActive = 1 
							AND	@SampleFileName LIKE SampleFileNamePrefix + '%') MD ON RU.Manufacturer = MD.Brand 
																						AND RU.CountryID = MD.CountryID
							

							
	-- Populate SampleTriggeredSelectionReqID
	UPDATE S
	SET S.SampleTriggeredSelectionReqID = CASE		WHEN C.CreateSelection = 1 AND C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
													ELSE NULL END
	FROM Stage.Combined_Roadside_Service S
		INNER JOIN #Completed C ON S.ID =C.ID
	

	---------------------------------------------------------------------------
	-- Split out name values for the Allianz France Company records   
	---------------------------------------------------------------------------
	-- Get the AuditID so we only process the records for the current file (i.e. we do not process more than once)
	DECLARE @AuditID BIGINT
	SELECT @AuditID = AuditID FROM [$(AuditDB)].dbo.Files WHERE FileName = @SampleFileName


	-- Create working tables
    DROP TABLE IF EXISTS #NamesToSplit

	CREATE TABLE #NamesToSplit
	(
		ID				INT NOT NULL,
		SurnameField1	NVARCHAR(100) NULL,
		FullName		NVARCHAR(100) NULL
	)
 

    DROP TABLE IF EXISTS #CheckWords

	CREATE TABLE #CheckWords
	(
		ID				INT NOT NULL,
		SurnameField1	NVARCHAR(100) NULL,
		FullName		NVARCHAR(100) NULL,
		FirstWord		NVARCHAR(100) NULL,
		SecondWord		NVARCHAR(100) NULL,
		ThirdWord		NVARCHAR(100) NULL,
		FourthWord		NVARCHAR(100) NULL,
		FifthWord		NVARCHAR(100) NULL,
		TitleFlag		INT NULL, 
		Title			NVARCHAR(20) NULL,
		FirstName		NVARCHAR(100) NULL,
		LastName		NVARCHAR(100) NULL
	)


	-- Get the names to split.  Provide first level cleaning: Remove full stops, spaces and any chars after "/" 
	INSERT INTO #NamesToSplit (ID, SurnameField1, FullName)
	SELECT ID, 
		SurnameField1,
		REPLACE(REPLACE(REPLACE(CASE	WHEN CHARINDEX('/', SurnameField1) = 0 THEN SurnameField1
										ELSE SUBSTRING(SurnameField1, 1, CHARINDEX('/', SurnameField1)-1) END,'.', ' '), '   ', ' ') , '  ', ' ') AS FullName
	FROM Stage.Combined_Roadside_Service S
	WHERE S.AuditID = @AuditID
		AND S.CountryCode = 'FR'
		AND S.CompanyName <> ''
		AND S.Firstname = ''
		AND S.SurnameField1 <> ''
		AND S.SurnameField2 = ''


	-- Replace any "Mr and Mrs" with blank
	UPDATE #NamesToSplit
	SET Fullname = REPLACE(Fullname, 'MR ET MME', '')


	UPDATE #NamesToSplit
	SET Fullname = REPLACE(Fullname, 'M ET MME', '')


	-- Split the name into seperate "words" 
	INSERT INTO #CheckWords (ID,SurnameField1, FullName, FirstWord,SecondWord, ThirdWord, FourthWord, FifthWord, TitleFlag, Title, FirstName, LastName)
	SELECT ID,
		SurnameField1, 
		FullName, 
		FirstWord,
		SecondWord, 
		ThirdWord, 
		FourthWord, 
		FifthWord, 
		CASE	WHEN FirstWord IN ('MR', 'MME', 'M', 'ME', 'MM') THEN 1 
				ELSE 0 END AS TitleFlag,
		'' AS Title, 
		'' AS FirstName, 
		'' AS LastName
	FROM #NamesToSplit S
		CROSS APPLY (SELECT NameWork = REPLACE(LTRIM(FullName), ' ', '|') + '|||||') F1
		CROSS APPLY (SELECT P1 = CHARINDEX('|', NameWork)) F2
		CROSS APPLY (SELECT P2 = CHARINDEX('|', NameWork, P1+1)) F3
		CROSS APPLY (SELECT P3 = CHARINDEX('|', NameWork, P2+1)) F4
		CROSS APPLY (SELECT P4 = CHARINDEX('|', NameWork, P3+1)) F5
		CROSS APPLY (SELECT P5 = CHARINDEX('|', NameWork, P4+1)) F6
		CROSS APPLY (SELECT FirstWord = SUBSTRING(NameWork, 1, P1-1),
						SecondWord = SUBSTRING(NameWork, P1+1, P2-P1-1),
						ThirdWord = SUBSTRING(NameWork, P2+1, P3-P2-1),
						FourthWord = SUBSTRING(NameWork, P3+1, P4-P3-1),
						FifthWord = SUBSTRING(NameWork, P4+1, P5-P4-1)) F7


	-- Move Titles out to Title column
	UPDATE #CheckWords 
	SET Title = FirstWord,
		FirstWord = SecondWord,
		SecondWord = ThirdWord,
		ThirdWord = FourthWord,
		FourthWord = FifthWord,
		FifthWord = ''
	WHERE TitleFlag = 1


	-- Check for double pre-fixes (e.g. "VAN DEN", "DE LA")
	UPDATE #CheckWords
	SET FirstWord = FirstWord + ' ' + SecondWord + ' ' + ThirdWord,
		SecondWord = FourthWord,
		ThirdWord = FifthWord,
		FourthWord = '',
		FifthWord = ''
	WHERE (FirstWord = 'VAN' AND SecondWord = 'DEN')
		OR (FirstWord = 'DE' AND SecondWord = 'LA')


	-- Check for single name pre-fixes (e.g. "LE", "LA", "DELA")
	UPDATE #CheckWords
	SET FirstWord = FirstWord + ' ' + SecondWord,
		SecondWord = ThirdWord,
		ThirdWord = FourthWord,
		FourthWord = FifthWord,
		FifthWord = ''
	WHERE FirstWord IN ('LE', 'LA', 'VAN', 'DELA', 'DE', 'EL')


	-- Set Firstname and Lastname values
	UPDATE #CheckWords
	SET FirstName = RTRIM(SecondWord + ' ' + Thirdword), 
		LastName = Firstword	
	WHERE FourthWord = ''


	-- Remove titles where fourthword exists
	UPDATE #CheckWords
	SET Title = ''
	WHERE FourthWord <> ''


	-- Blank Lastname where no Title or FirstName
	UPDATE #Checkwords
	SET LastName = ''
	WHERE FirstName = ''
		AND Title = ''

	-- Update the staging table values 
	UPDATE S
	SET S.Title = CW.Title,
		S.Firstname = CW.FirstName,
		S.SurnameField1 = CW.LastName
	FROM #CheckWords CW
		INNER JOIN Stage.Combined_Roadside_Service S ON S.ID = CW.ID


	-- V1.8
	INSERT INTO dbo.Removed_Records_Prevent_PartialLoad (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, CountryCode, RemovalReason)
	SELECT S.AuditID, 
		F.FileName, 
		F.ActionDate,
		S.PhysicalRowID,
		S.VIN, 
		S.CountryCode, 
		'Model year not numeric' AS RemovalReason
	FROM Stage.Combined_Roadside_Service S
		INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
	WHERE ISNUMERIC(S.MODELYEAR) <> 1 
		AND LEN(MODELYEAR) > 0


	DELETE S
	FROM Stage.Combined_Roadside_Service S
	WHERE ISNUMERIC(S.MODELYEAR) <> 1 
		AND LEN(S.MODELYEAR) > 0


	UPDATE S
	SET S.MODELYEAR = FLOOR(S.MODELYEAR)
	FROM Stage.Combined_Roadside_Service S
	WHERE ISNUMERIC(S.MODELYEAR) = 1 


	UPDATE S
	SET S.MODELYEAR = ''
	FROM Stage.Combined_Roadside_Service S
	WHERE ISNUMERIC(S.MODELYEAR) = 1 
		AND LEN(S.MODELYEAR) > 4


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
		
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [Sample_Errors].Stage.Combined_Roadside_Service_' + @TimestampString + '
		FROM Stage.Combined_Roadside_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH