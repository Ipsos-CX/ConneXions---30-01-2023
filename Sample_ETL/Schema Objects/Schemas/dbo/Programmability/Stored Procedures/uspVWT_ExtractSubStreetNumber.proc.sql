CREATE PROCEDURE uspVWT_ExtractSubStreetNumber
AS

/*
	Purpose:	Extract Street Number from Street field

				Split House/Building number and Street in field 'StreetBuildingNumberOrig' into their own explicit fields.
				Whether a house number is positioned at the beginning or the end of the street depends on the country.
				This routine should do both. Currently hardcoded to deal with Italy (Right) and UK (Left)

				DECIDED TO DO THIS FOR UK ONLY AS KNOWLEDGE OF ROW COUNTRIES ADDRESSES NOT COMPREHENSIVE ENOUGH.
				
				FROM						DATA								->		TO
				SubStreetAndNumberOrig		Sub Street Number					->		VWT.SubStreetNumber
				SubStreetAndNumberOrig		Sub Street (incl. Prefix/Suffix)	->		VWT.SubStreetOrig	

				Some street Building numbers may not be identifiable or even exist therefore all records run through this routine must
				me flagged so we know which records have been processed.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISEADDRESS_ExtractSubStreetNumber
	bk 2222
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
	DECLARE @CountryID SMALLINT
	SELECT @CountryID = CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'United Kingdom'


	-- POPULATE #InputString TABLE WITH STREET RECORDS THAT HAVE YET TO HAVE PREFIXES / SUFFIXES EXTRACTED
	INSERT INTO #InputString (InputStringID, CountryID, InputString)
	SELECT AuditItemID, CountryID, SubStreetAndNumberOrig
	FROM VWT
	WHERE CountryID = @CountryID

/* 	Standardise word delimiters. This MAY be country specific. Could store this data in a meta data table 
   	and do a While loop. EG. Italian Building/Flat numbers have a forward slash between them so keep it in
   	to keep the number together, however house numbers have a comma delimiting it from the address so that
	can be removed. These characters may not have the same useage in other countries 	*/

	UPDATE #InputString
	SET InputString = REPLACE(InputString, ' ', '|')

	UPDATE #InputString
	SET InputString = REPLACE(InputString, ',', '|')

	UPDATE #InputString
	SET InputString = InputString + '|'	--Need a delimiter at the end of the string to ensure it is left empty by the loop

	-- SPLIT STREET NAMES INTO CONSTITUENT WORDS AND POPULATE TABLE #InputString
	BEGIN
		WHILE (SELECT COUNT(*) FROM #InputString WHERE LEN(InputString) > 0) > 0
		BEGIN
			INSERT INTO #InputWords (InputStringID, CountryID, Value, Position)
			SELECT
				 S.InputStringID
				,S.CountryID
				,LEFT(S.InputString, PATINDEX('%|%', S.InputString) - 1)
				,(
					SELECT (ISNULL(MAX(Position),0) + 1)
					FROM #InputWords W
				 	WHERE W.InputStringID = S.InputStringID
				) AS Position
			FROM #InputString S
			WHERE ISNULL(PATINDEX('%|%', S.InputString), 0) > 0		-- THERE IS A WORD DELIMITER
			AND LEFT(S.InputString, PATINDEX('%|%', S.InputString) - 1) <> ''	-- NOT AN EMPTY STRING
				
			-- TRUNCATE PROCESSED PORTION FROM NAME STRING
			UPDATE #InputString
			SET InputString = RIGHT(InputString, (LEN(InputString) - PATINDEX('%|%', InputString)))
			WHERE ISNULL(PATINDEX('%|%', InputString), 0) > 0
		
			CONTINUE
		END
	END

	-- Extract house number for countries where it appears at the beginning of the street
	INSERT INTO #HouseNumber (InputWordID, InputStringID, CountryID, Position, Value)
	SELECT InputWordID, InputStringID, CountryID, Position, Value
	FROM #InputWords IW
	WHERE IW.Position = (
		SELECT MIN(Position)
		FROM #InputWords IW2
		WHERE IW.InputStringID = IW2.InputStringID
	)
	AND IW.CountryID = @CountryID -- UK HARDCODED: CAN ADD A FIELD TO THE COUNTRY TABLE DENOTING IF HOUSE NUMBER ON THE LEFT OR RIGHT AND THEN JOIN TO THAT.
	AND dbo.udfIsHouseNumber(IW.Value, IW.CountryID) = 1

	-- REMOVE HOUSE NUMBER FROM INPUTWORDS
	DELETE IW
	FROM #InputWords IW
	WHERE IW.Position = (
		SELECT MIN(Position)
		FROM #InputWords IW2
		WHERE IW.InputStringID = IW2.InputStringID
	)
	AND IW.CountryID = @CountryID -- UK HARDCODED: CAN ADD A FIELD TO THE COUNTRY TABLE DENOTING IF HOUSE NUMBER ON THE LEFT OR RIGHT AND THEN JOIN TO THAT.
	AND dbo.udfIsHouseNumber(IW.Value, IW.CountryID) = 1

	-- THE INPUT WORD TABLE IS NOW MISSING IT HOUSE NUMBERS THAT DEPENDING ON THE COUNTRY COULD BE AT THE BEGINNING OR END OF THE STRING.
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

	-- WRITE STREET NUMBERS BACK TO THE VWT
	UPDATE VWT
	SET SubStreetNumber = H.Value
	FROM VWT
	INNER JOIN #HouseNumber H ON VWT.AuditItemID = H.InputStringID


	-- RE-ASSEMBLE STREET NAMES MINUS THE EXTRACTED HOUSE NUMBER

	-- ADD FIRST WORD
	BEGIN
		INSERT INTO #OutputString (InputStringID, CountryID, OutputString)
		SELECT InputstringID, CountryID, Value
		FROM #InputWordsPositionReset
		WHERE Position = 1
	END

	-- ADD ADDITIONAL WORDS
	BEGIN
		DECLARE @MaxWords INT
		DECLARE @WordDelimiter CHAR(1)
		DECLARE @Position INT
		
		SET @Position = 2
		SET @WordDelimiter = ' '
		SET @MaxWords = (SELECT MAX(Position) FROM #InputWords)
		
		WHILE @Position <= @MaxWords
		BEGIN
			UPDATE O
			SET OutputString = O.OutputString + @WordDelimiter + IR.Value
			FROM #OutputString O
			INNER JOIN #InputWordsPositionReset IR ON O.InputStringID = IR.InputStringID 
			WHERE IR.Position = @Position
		
			SET @Position = @Position + 1
			
			CONTINUE
		END
	END

	-- WRITE RE-ASSEMBLED STREET BACK TO VWT AND SET FLAG SO WE KNOW THESE RECORDS HAVE BEEN PROCESSED
	UPDATE VWT
	SET VWT.SubStreetOrig = O.OutputString
	FROM  VWT
	INNER JOIN #OutputString O ON VWT.AuditItemID = O.InputStringID

	-- DROP TABLES
	DROP TABLE #InputString
	DROP TABLE #InputWords
	DROP TABLE #HouseNumber
	DROP TABLE #InputWordsPositionReset
	DROP TABLE #OutputString
	
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