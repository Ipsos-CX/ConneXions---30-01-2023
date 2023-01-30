CREATE PROCEDURE CustomerUpdate.uspPostalAddress_ExtractStreetNumber

AS

/*
	Purpose: Extract Street Number from StreetAndNumber field in CustomerUpdate.PostalAddress.

	Split House/Building number and Street in field 'StreetAndNumber' in CustomerUpdate.PostalAddress into their 
	own explicit fields.
	Whether a house number is positioned at the beginning or the end of the street depends on the country.
	This routine should do both. Currently hardcoded to deal with Italy (Right) and UK (Left)

	DECIDED TO DO THIS FOR UK ONLY AS KNOWLEDGE OF ROW COUNTRIES ADDRESSES NOT COMPREHENSIVE ENOUGH.

	
	FROM			DATA					->		TO
					
	StreetAndNumber		Street Number				->		StreetNumber
	StreetAndNumber		Street (incl. Prefix/Suffix)		->		Street

	Some street Building numbers may not be identifiable or even exist therefore all records run through this routine must
	me flagged so we know which records have been processed.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ExtractStreetNumber

*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	CREATE TABLE #InputString
	(
		InputStringID INT             NULL,
		CountryID     SMALLINT   NULL,
		InputString   NVARCHAR(1200)  NULL
	)

	CREATE TABLE #InputWords
	(
		InputWordID   INT            IDENTITY (1, 1) NOT NULL,
		InputStringID INT            NULL,
		CountryID     SMALLINT  NULL,
		Position      INT            NULL,
		Value         NVARCHAR (200) NULL
	)

	CREATE TABLE #OutputString
	(
		InputStringID INT             NULL,
		CountryID     SMALLINT   NULL,
		OutputString  NVARCHAR (1200) NULL
	)
	
	CREATE TABLE #HouseNumber
	(
		InputWordID INT NULL,
		InputStringID INT NULL,
		CountryID SMALLINT NULL,
		Position INT NULL,
		Value NVARCHAR(200) NULL
	)
	
	CREATE TABLE #InputWordsPositionReset
	(
		InputWordID INT NULL,
		InputStringID INT NULL,
		CountryID SMALLINT NULL,
		Position INT NULL,
		Value NVARCHAR(200) NULL
	)
	
	-- GET THE UK CountryID
	DECLARE @UKCountryID SMALLINT
	SELECT @UKCountryID = CountryID FROM Lookup.vwCountries WHERE Country = 'United Kingdom'
	DECLARE @CANCountryID SMALLINT
	SELECT @CANCountryID = CountryID FROM Lookup.vwCountries WHERE Country = 'Canada'
	DECLARE @AUSCountryID SMALLINT
	SELECT @AUSCountryID = CountryID FROM Lookup.vwCountries WHERE Country = 'Australia'

	/* POPULATE #InputString TABLE WITH STREET RECORDS THAT HAVE YET TO HAVE PREFIXES / SUFFIXES EXTRACTED */
	INSERT INTO #InputString (InputStringID, CountryID, InputString)
	SELECT AuditItemID, CountryID, StreetAndNumber
	FROM CustomerUpdate.PostalAddress
	WHERE CountryID IN (@UKCountryID, @CANCountryID, @AUSCountryID)

	/* STANDARDISE WORD DELIMITERS. THIS MAY BE COUNTRY SPECIFIC. COULD STORE THIS DATA IN A META DATA TABLE AND DO A 
	WHILE LOOP. EG. ITALIAN BUILDING/FLAT NUMBERS HAVE A FORWARD SLASH BETWEEN THEM SO KEEP IT IN TO KEEP THE NUMBER 
	TOGETHER, HOWEVER HOUSE NUMBERS HAVE A COMMA DELIMITING IT FROM THE ADDRESS SO THAT CAN BE REMOVED. THESE 
	CHARACTERS MAY NOT HAVE THE SAME USEAGE IN OTHER COUNTRIES */

	UPDATE #InputString
	SET InputString = REPLACE(InputString, ' ', '|')
	
	UPDATE #InputString
	SET InputString = REPLACE(InputString, ',', '|')
	
	UPDATE #InputString
	SET InputString = InputString + '|'	-- NEED A DELIMITER AT THE END OF THE STRING TO ENSURE IT IS LEFT EMPTY BY THE LOOP

	-- SPLIT STREET NAMES INTO CONSTITUENT WORDS
	BEGIN
		WHILE (SELECT COUNT(*) FROM #InputString WHERE LEN(InputString) > 0) > 0
		BEGIN
			INSERT INTO #InputWords (InputStringID, CountryID, Value, Position)
			SELECT
				 InputStringID
				,CountryID
				,LEFT(InputString, PATINDEX('%|%', InputString) - 1)
				,(
					SELECT (ISNULL(MAX(Position),0) + 1)
					FROM #InputWords W
				 	WHERE W.InputStringID = S.InputStringID
				) AS Position
			FROM #InputString S
			WHERE ISNULL(PATINDEX('%|%', InputString), 0) > 0		-- THERE IS A WORD DELIMITER
			AND LEFT(InputString, PATINDEX('%|%', InputString) - 1) <> ''	-- NOT AN EMPTY STRING
				
			-- TRUNCATE PROCESSED PORTION FROM NAME STRING
			UPDATE #InputString
			SET InputString = RIGHT(InputString, (LEN(InputString) - PATINDEX('%|%', InputString)))
			WHERE ISNULL(PATINDEX('%|%', InputString), 0) > 0
		
			CONTINUE
		END
	END

	-- EXTRACT HOUSE NUMBER FOR COUNTRIES WHERE IT APPEARS AT THE BEGINNING OF THE STREET
	INSERT INTO #HouseNumber (InputWordID, InputStringID, CountryID, Position, Value)
	SELECT InputWordID, InputStringID, CountryID, Position, Value
	FROM #InputWords IW
	WHERE IW.Position = (
		SELECT MIN(Position)
		FROM #InputWords IW2
		WHERE IW.InputStringID = IW2.InputStringID
	)
	AND IW.CountryID IN (@UKCountryID, @CANCountryID, @AUSCountryID)
	AND dbo.udfIsHouseNumber(IW.Value, IW.Countryid) = 1

	-- REMOVE HOUSE NUMBER FRM #InputWords
	DELETE #InputWords
	FROM #InputWords IW
	WHERE IW.Position = (
		SELECT MIN(Position)
		FROM #InputWords IW2
		WHERE IW.InputStringID = IW2.InputStringID
	)
	AND IW.CountryID IN (@UKCountryID, @CANCountryID, @AUSCountryID)
	AND dbo.udfIsHouseNumber(IW.Value, IW.CountryID) = 1

	-- THE INPUT WORD TABLE IS NOW MISSING IT HOUSENUMBERS THAT DEPENDING ONTE COUNTRY COULD BE AT THE BEGINNING OR END OF THE STRING.
	-- THEREFORE RESET INPUTWORD POSITIONS OF THE WORDS THAT ARE LEFT SO THE WORDS CAN BE PUT BACK TOGETHER INTO A SINGLE STRING
	INSERT INTO #InputWordsPositionReset (InputWordID, InputStringID, CountryID, Value, Position)
	SELECT
		 InputWordID
		,InputStringID
		,CountryID
		,Value
		,(
			SELECT COUNT(*)
			FROM #InputWords T2
			WHERE T1.InputStringID = T2.InputStringID
			AND T1.Position > T2.Position
		) + 1 AS NewPosition
	FROM #InputWords T1

	-- WRITE STREET NUMBERS BACK TO THE CustomerUpdate.PostalAddress
	UPDATE PA
	SET PA.StreetNumber = H.Value
	FROM CustomerUpdate.PostalAddress PA
	INNER JOIN #HouseNumber H ON PA.AuditItemID = H.InputStringID

	-- RE-ASSEMBLE STREET NAMES MINUS THE EXTRACTED HOUSE NUMBER

	-- ADD FIRST WORD
	BEGIN
		INSERT INTO #OutputString (InputStringID, CountryID, OutputString)
		SELECT InputstringID, Countryid, Value
		FROM #InputWordsPositionReset
		WHERE Position = 1
	END

	-- ADD ADDITIONAL WORDS
	BEGIN
		DECLARE @MaxWords int
		DECLARE @WordDelimiter varchar(1)
		DECLARE @Position int
		
		SET @Position = 2
		SET @WordDelimiter = ' '
		SET @MaxWords = (SELECT MAX(Position) FROM #InputWords)
		
		WHILE @Position <= @MaxWords
		BEGIN
			UPDATE #OutputString
			SET OutputString = O.OutputString + @WordDelimiter + IR.Value			
			FROM #OutputString O
			INNER JOIN #InputWordsPositionReset IR ON O.InputStringID = IR.InputStringID 
			WHERE IR.Position = @Position
		
			SET @Position = @Position + 1
			
			CONTINUE
		END
	END

	-- WRITE RE-ASSEMBLED STREET BACK TO CustomerUpdate.PostalAddress AND SET FLAG SO WE KNOW THESE RECORDS HAVE BEEN PROCESSED
	UPDATE PA
	SET PA.Street = O.OutputString
	FROM CustomerUpdate.PostalAddress PA
	INNER JOIN #OutputString O ON PA.AuditItemID = O.InputStringID

	-- DROP TABLES
	DROP TABLE #InputString
	DROP TABLE #InputWords
	DROP TABLE #HouseNumber
	DROP TABLE #InputWordsPositionReset
	DROP TABLE #OutputString

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

