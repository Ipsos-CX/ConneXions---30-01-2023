CREATE PROCEDURE [Stage].[uspStandardise_CXP_Roadside]
/*
	Purpose:		(I)		Convert the supplied dates from a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				13/12/2019		Eddie Thomas		Created
	LIVE			1.1				20/05/2021		Eddie Thomas		Bugratacker 18207 - Blank Event_Type field values causes loader to bomb when copying data to VWT
	LIVE			1.2				25/08/2021      Ben King            TASK 567 - Setup SV-CRM Lost Leads Loader
	LIVE			1.3				17/12/2021      Ben King			TASK 731 - 18419 - File Failures 14122021

*/
@SampleFileName NVARCHAR (1000)
AS
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT DMY

BEGIN TRY

	SET DATEFORMAT dmy  -- First ensure dmy format for ISDATE functions

	UPDATE	Stage.CXP_Roadside
	SET		ConvertedBreakdownDate = CONVERT ( datetime, BreakdownDate, 103 )
	WHERE	ISDATE(BreakdownDate) = 1
	
	UPDATE	Stage.CXP_Roadside
	SET		ConvertedCarHireStartDate = CONVERT ( datetime, CarHireStartDate, 103 )
	WHERE	ISDATE(CarHireStartDate) =  1


	UPDATE  s
    SET     s.[Address8(Country)] =	CASE c.ISOAlpha3
										WHEN 'LUX' THEN 'BEL'
                                        ELSE c.ISOAlpha3
                                    END
    FROM		Stage.CXP_Roadside s
    INNER JOIN	[$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha2 =	CASE
																			WHEN s.CountryCodeISOAlpha2 = 'Japan'	-- V1.3 Japan sent instead of ISOalpha2
																				THEN s.CountryCode
																			WHEN s.CountryCodeISOAlpha2 = 'Turkey'	-- V1.6 Turkey sent instead of ISOalpha2
																				THEN s.CountryCode
																			WHEN s.CountryCodeISOAlpha2 IS NULL
																				OR s.CountryCodeISOAlpha2 = ''
																				THEN s.CountryCode
																			ELSE s.CountryCodeISOAlpha2
																		END				  

	
	UPDATE	Stage.CXP_Roadside
	SET		CountryCodeISOAlpha2 = CASE CountryCodeISOAlpha2
										WHEN 'Japan' THEN CountryCode
										WHEN 'Turkey' THEN CountryCode			-- V1.6
										WHEN '' THEN CountryCode
										ELSE CountryCodeISOAlpha2
									END	
									

	-----

	UPDATE s
	SET s.BreakdownCountry = CASE c.ISOAlpha3 WHEN 'LUX' THEN 'BEL' ELSE c.ISOAlpha3 END
	from stage.CXP_Roadside s
	inner join [$(SampleDB)].ContactMechanism .Countries c on c.ISOAlpha2 = s.CountryCodeISOAlpha2

	-----
	
	UPDATE [Stage].CXP_Roadside
	SET ConvertedCarHireStartTime = CONVERT(TIME, carhirestarttime)
	where ISDATE(CarHireStartTime) = 1
	
	
	-----  SET PREFERRED LANGUAGE ----------------------------------------
	
	-- 1st Lookup Preferred Language in Language table
	UPDATE s
	SET s.PreferredLanguageID = l.LanguageID
	FROM  stage.CXP_Roadside s
	INNER JOIN [$(SampleDB)].dbo.Languages l on l.ISOAlpha2 = s.PreferredLanguage
	
	-- Then, if not found, set using default language for country  
	UPDATE s
	SET s.PreferredLanguageID = c.DefaultLanguageID 
	FROM stage.CXP_Roadside s
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries c on c.ISOAlpha2 = COALESCE(NULLIF(s.CountryCodeISOAlpha2, ''), NULLIF(s.CountryCodeISOAlpha2, ''))    -- Use the original country code (or breakdown country) supplied to determine preferred language
	WHERE s.PreferredLanguageID IS NULL
	
	-- Failing that default to English
	UPDATE stage.CXP_Roadside
	SET PreferredLanguageID = (SELECT LanguageID FROM [$(SampleDB)].dbo.Languages WHERE Language = 'English')
	WHERE PreferredLanguageID IS NULL	


	----------------------------------------------------------------------------------------------------
	-- Set SampleTriggeredSelectionReqID for MENA RoadSide
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate	(ID, Manufacturer, CountryCode, EventType, Country, CountryID)

	AS

	(
	--Add In CountryID
	SELECT		GS.ID, GS.Manufacturer, GS.CountryCodeISOAlpha2, GS.EventType, C.Country,C.CountryID
	FROM		Stage.CXP_Roadside	GS
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON GS.CountryCodeISOAlpha2 =	C.ISOAlpha2
																						
	)
	--Retrieve Metadata values for each event in the table
	SELECT	DISTINCT	RU.*, MD.ManufacturerPartyID, MD.EventTypeID, MD.LanguageID, MD.SetNameCapitalisation,
						MD.DealerCodeOriginatorPartyID, MD.CreateSelection, MD.SampleTriggeredSelection,
						MD.QuestionnaireRequirementID

	INTO	#Completed							
	FROM	RecordsToUpdate RU
	INNER JOIN 
	(
		
	
		SELECT DISTINCT M.ManufacturerPartyID, M.CountryID, ET.EventTypeID,  
						C.DefaultLanguageID AS LanguageID, M.SetNameCapitalisation, M.DealerCodeOriginatorPartyID,
						M.Brand, M.Questionnaire, M.SampleLoadActive, M.SampleFileNamePrefix,
						M.CreateSelection, M.SampleTriggeredSelection, 
						M.QuestionnaireRequirementID
						
		FROM			[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
		INNER JOIN		[$(SampleDB)].Event.EventTypes								ET ON ET.EventType = M.Questionnaire
		INNER JOIN		[$(SampleDB)].ContactMechanism.Countries					C ON C.CountryID = M.CountryID
		
		WHERE			(M.Questionnaire	= 'Roadside') AND
						(M.SampleLoadActive = 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')	AND
						(M.SampleFileExtension = SUBSTRING (@SampleFileName, CHARINDEX('.',@SampleFileName) , LEN (@SampleFileName) - CHARINDEX('.',@SampleFileName)+1))

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID
							
							
	--Populate SampleTriggeredSelectionReqID
	UPDATE		GS
	SET			SampleTriggeredSelectionReqID = (
													Case
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
														ELSE	null
													END
												)
	
	FROM 		Stage.CXP_Roadside		GS
	INNER JOIN	#Completed							C ON GS.ID =C.ID
	




	---------------------------------------------------------------------------
	-- Split out name values for the Allianz France Company records   
	---------------------------------------------------------------------------

	-- Get the AuditID so we only process the records for the current file (i.e. we do not process more than once)
	DECLARE @AuditID BIGINT
	SELECT @AuditID = AuditID FROM [$(AuditDB)].dbo.Files WHERE FileName = @SampleFileName


	-- Create working tables
	IF OBJECT_ID('tempdb..#NamesToSplit') IS NOT NULL
    DROP TABLE #NamesToSplit

	CREATE TABLE #NamesToSplit
	(
		ID				[int] NOT NULL,
		SurnameField1	[nvarchar] (100) NULL,
		FullName		[nvarchar] (100) NULL
	)
 

	IF OBJECT_ID('tempdb..#CheckWords') IS NOT NULL
    DROP TABLE #CheckWords

	CREATE TABLE #CheckWords
	(
		ID				[int] NOT NULL,
		SurnameField1	[nvarchar] (100) NULL,
		FullName		[nvarchar] (100) NULL,
		FirstWord		[nvarchar] (100) NULL,
		SecondWord		[nvarchar] (100) NULL,
		ThirdWord		[nvarchar] (100) NULL,
		FourthWord		[nvarchar] (100) NULL,
		FifthWord		[nvarchar] (100) NULL,
		TitleFlag		[int] NULL, 
		Title			[nvarchar] (20) NULL,
		FirstName		[nvarchar] (100) NULL,
		LastName		[nvarchar] (100) NULL
	)


	-- Get the names to split.  Provide first level cleaning: Remove full stops, spaces and any chars after "/" 
	INSERT INTO #NamesToSplit (ID, SurnameField1, FullName)
	SELECT ID, SurnameField1,
			REPLACE(REPLACE(REPLACE(CASE WHEN CHARINDEX('/', SurnameField1) = 0 
								THEN SurnameField1
								ELSE SUBSTRING(SurnameField1, 1, CHARINDEX('/', SurnameField1)-1)
								END,'.', ' '), '   ', ' ') , '  ', ' ') AS FullName
	FROM	Stage.CXP_Roadside s
	WHERE	s.AuditID		=	@AuditID AND 
			s.CountryCode	=	'FR' AND 
			s.CompanyName	<>	'' AND 
			s.Firstname		=	'' AND 
			s.SurnameField1 <>	'' AND 
			s.SurnameField2 = ''


	-- Replace any "Mr and Mrs" with blank
	UPDATE	#NamesToSplit
	SET		Fullname = REPLACE(Fullname, 'MR ET MME', '')

	UPDATE	#NamesToSplit
	SET		Fullname = REPLACE(Fullname, 'M ET MME', '')

	-- Split the name into seperate "words" 
	INSERT INTO #CheckWords (ID,SurnameField1, FullName, FirstWord,SecondWord, ThirdWord, FourthWord, FifthWord, TitleFlag, Title, FirstName, LastName)
	SELECT ID,SurnameField1, FullName, FirstWord,SecondWord, ThirdWord, FourthWord, FifthWord
			, CASE WHEN FirstWord IN ('MR', 'MME', 'M', 'ME', 'MM') THEN 1 ELSE 0 END AS TitleFlag
			, '' AS Title, '' AS FirstName, '' AS LastName
	FROM #NamesToSplit s
	CROSS APPLY (SELECT NameWork=replace(LTRIM(FullName),' ','|')+'|||||') F1
	CROSS APPLY (SELECT p1=CHARINDEX('|',NameWork)) F2
	CROSS APPLY (SELECT p2=CHARINDEX('|',NameWork,p1+1)) F3
	CROSS APPLY (SELECT p3=CHARINDEX('|',NameWork,p2+1)) F4
	CROSS APPLY (SELECT p4=CHARINDEX('|',NameWork,p3+1)) F5
	CROSS APPLY (SELECT p5=CHARINDEX('|',NameWork,p4+1)) F6
	CROSS APPLY (SELECT FirstWord=SUBSTRING(NameWork,1,p1-1)
					   ,SecondWord=SUBSTRING(NameWork,p1+1,p2-p1-1)
					   ,ThirdWord=SUBSTRING(NameWork,p2+1,p3-p2-1)
					   ,FourthWord=SUBSTRING(NameWork,p3+1,p4-p3-1)
					   ,FifthWord=SUBSTRING(NameWork,p4+1,p5-p4-1)) F7


	-- Move Titles out to Title column
	UPDATE #CheckWords 
	SET Title		= FirstWord,
		FirstWord	= SecondWord,
		SecondWord	= ThirdWord,
		ThirdWord	= FourthWord,
		FourthWord	= FifthWord,
		FifthWord	= ''
	WHERE TitleFlag = 1


	-- Check for double pre-fixes (e.g. "VAN DEN", "DE LA")
	UPDATE #CheckWords
	SET FirstWord = FirstWord + ' ' + SecondWord + ' ' + ThirdWord,
		SecondWord = FourthWord,
		ThirdWord = FifthWord,
		FourthWord = '',
		FifthWord = ''
	WHERE	(FirstWord = 'VAN' AND SecondWord = 'DEN')
	OR		(FirstWord = 'DE' AND SecondWord = 'LA')


	-- Check for single name pre-fixes (e.g. "LE", "LA", "DELA")
	UPDATE #CheckWords
	SET FirstWord	= FirstWord + ' ' + SecondWord,
		SecondWord	= ThirdWord,
		ThirdWord	= FourthWord,
		FourthWord	= FifthWord,
		FifthWord	= ''
	WHERE FirstWord IN ('LE', 'LA', 'VAN', 'DELA', 'DE', 'EL')


	-- Set Firstname and Lastname values
	UPDATE #CheckWords
	SET FirstName	= RTRIM(SecondWord + ' ' + Thirdword), 
		LastName	= Firstword	
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
	UPDATE		s
	SET			s.Title = cw.Title,
				s.Firstname = cw.FirstName,
				s.SurnameField1 = cw.LastName
	FROM		#CheckWords cw
	INNER JOIN	Stage.CXP_Roadside s ON s.ID = cw.ID

	
	---------------------------------------------------------------------------------------------------------
	-- V1.1	SET ANY 'JLR EVENT TYPES' TO NULL
	---------------------------------------------------------------------------------------------------------cc
	UPDATE	Stage.CXP_Roadside
	SET		EVENTTYPE = NULL
	WHERE	LEN(LTRIM(RTRIM(EVENTTYPE))) = 0


	--V1.2
	INSERT INTO [dbo].[Removed_Records_Prevent_PartialLoad] (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, CountryCode, RemovalReason)
	SELECT 
		S.[AuditID], 
		F.[FileName], 
		F.[ActionDate],
		S.[PhysicalRowID],
		S.[VIN], 
		S.[CountryCode], 
		'OwnershipCycle not Numeric'
	FROM Stage.CXP_Roadside S
	INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
	WHERE (ISNUMERIC(S.OwnershipCycle) <> 1
	AND S.OwnershipCycle <> '')

	
	DELETE S
	FROM Stage.CXP_Roadside S
	WHERE (ISNUMERIC(S.OwnershipCycle) <> 1
	AND S.OwnershipCycle <> '')

	--V1.3
	INSERT INTO [dbo].[Removed_Records_Prevent_PartialLoad] (AuditID, FileName, ActionDate, PhysicalFileRow, VIN, CountryCode, RemovalReason)
	SELECT 
		S.[AuditID], 
		F.[FileName], 
		F.[ActionDate],
		S.[PhysicalRowID],
		S.[VIN], 
		S.[CountryCode], 
		'Model year not numeric'
	FROM Stage.CXP_Roadside S
	INNER JOIN [$(AuditDB)].dbo.Files F ON S.AuditID = F.AuditID
	WHERE ISNUMERIC(S.MODELYEAR) <> 1 
	AND LEN(S.MODELYEAR) > 0


	DELETE S
	FROM Stage.CXP_Roadside S
	WHERE ISNUMERIC(S.MODELYEAR) <> 1 
	AND LEN(S.MODELYEAR) > 0


	UPDATE S
	SET S.MODELYEAR = FLOOR(S.MODELYEAR)
	FROM Stage.CXP_Roadside S
	WHERE ISNUMERIC(S.MODELYEAR) = 1 


	UPDATE S
	SET S.MODELYEAR = ''
	FROM Stage.CXP_Roadside S
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
		INTO [$(ErrorDB)].Stage.CXP_Roadside_' + @TimestampString + '
		FROM Stage.CXP_Roadside
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH

