CREATE PROCEDURE uspVWT_StandardiseStreet AS
 
/*
	Purpose:	Standardise where relevant each of the individual words that make up a streets Prefix or Suffix e.g. Road, Via

	Rationale:	1. Load Street1 field into a temorary table
				2. Split the Street into individual words and place in a permanent temorary table
				3. Join individual words to a list of known variants and substitute for a standard value
				4. Put Street back together again
				5. Write standardised version back to the source table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISEADDRESS_StandardiseStreetType
	1.1				2021-04-30		Chris Ledger		Task 410 - Remove LF from Postal Address Fields

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	--------------------------------------------------------------------------------------------
	-- V1.1 Remove LF from Postal Address Fields
	--------------------------------------------------------------------------------------------
	UPDATE V
	SET V.BuildingName = REPLACE(V.BuildingName,CHAR(10), ''),
		V.SubStreetAndNumberOrig = REPLACE(V.SubStreetAndNumberOrig,CHAR(10), ''),
		V.SubStreetOrig = REPLACE(V.SubStreetOrig,CHAR(10), ''),
		V.SubStreet = REPLACE(V.SubStreet,CHAR(10), ''),
		V.StreetAndNumberOrig = REPLACE(V.StreetAndNumberOrig,CHAR(10), ''),
		V.StreetOrig = REPLACE(V.StreetOrig,CHAR(10), ''),
		V.Street = REPLACE(V.Street,CHAR(10), ''),
		V.SubLocality = REPLACE(V.SubLocality,CHAR(10), ''),
		V.Locality = REPLACE(V.Locality,CHAR(10), ''),
		V.Town = REPLACE(V.Town,CHAR(10), ''),
		V.Region = REPLACE(V.Region,CHAR(10), ''),
		V.PostCode = REPLACE(V.PostCode,CHAR(10), '')
	FROM dbo.VWT V
	WHERE 
		V.BuildingName LIKE '%' + CHAR(10) + '%'
		OR V.SubStreetAndNumberOrig LIKE '%' + CHAR(10) + '%'
		OR V.SubStreetOrig LIKE '%' + CHAR(10) + '%'
		OR V.SubStreet LIKE '%' + CHAR(10) + '%'
		OR V.StreetAndNumberOrig LIKE '%' + CHAR(10) + '%'
		OR V.StreetOrig LIKE '%' + CHAR(10) + '%'
		OR V.Street LIKE '%' + CHAR(10) + '%'
		OR V.SubLocality LIKE '%' + CHAR(10) + '%'
		OR V.Locality LIKE '%' + CHAR(10) + '%'
		OR V.Town LIKE '%' + CHAR(10) + '%'
		OR V.Region LIKE '%' + CHAR(10) + '%'
		OR V.PostCode LIKE '%' + CHAR(10) + '%'
	--------------------------------------------------------------------------------------------


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

	-- POPULATE INPUT STRING TABLE WITH THE STRINGS THAT YOU WANT TO STANDARDISE
	INSERT INTO #InputString (InputStringID, CountryID, InputString)	
	SELECT AuditItemID, CountryID, StreetOrig
	FROM VWT
	WHERE ISNULL(StreetOrig, '') <> ''

	-- STANDARDISE WORD DELIMITERS. THIS COULD BE COUNTRY SPECIFIC SO MAY WELL STORE THIS DATA IN A META DATA TABLE AND DO A WHILE LOOP. 
	-- EG. ITALIAN BUILDING/FLAT NUMBERS HAVE A FORWARD SLASH BETWEEN THEM SO KEEP IT IN TO KEEP THE NUMBER TOGETHER, HOWEVER HOUSE NUMBERS 
	-- HAVE A COMMA DELIMITING IT FROM THE ADDRESS SO THAT CAN BE REMOVED. HARD CODED FOR ITALY AT PRESENT

	UPDATE #InputString
	SET InputString = REPLACE(InputString, ' ', '|')
	
	UPDATE #InputString
	SET InputString = REPLACE(InputString, ',', '|')
	
	UPDATE #InputString
	SET InputString = InputString + '|'

	-- SPLIT STREET NAMES INTO CONSTITUENT WORDS AND POPULATE TABLE INPUTWORDS
	BEGIN
		WHILE (SELECT COUNT(*) FROM #InputString WHERE LEN(InputString) > 0) > 0
		BEGIN
			INSERT INTO #InputWords (InputStringID, CountryID, Value, Position)
			SELECT
				 S.InputStringID
				,S.CountryID
				,LEFT(S.InputString, PATINDEX('%|%', S.InputString) - 1)
				,(
					SELECT (ISNULL(MAX(W.Position),0) + 1)
					FROM #InputWords W
				 	WHERE W.InputStringID = S.InputStringID
				 )
			FROM #InputString S
			WHERE ISNULL(PATINDEX('%|%', S.InputString), 0) > 0		--There is a word delimiter
			AND LEFT(S.InputString, PATINDEX('%|%', S.InputString) - 1) <> ''	--Not an empty string
			
			/*	Truncate processed portion from name string		*/
			UPDATE #InputString
			SET InputString = RIGHT(InputString, (LEN(InputString) - PATINDEX('%|%', InputString)))
			WHERE ISNULL(PATINDEX('%|%', InputString), 0) > 0
		
		CONTINUE
		
		END
	END

	-- STANDARDISE STREET PREFIXES AND SUFFIXES BASED ON META DATA DERIVED FROM A VIEW
	-- CAN ONLY STANDARDISE THE FIRST OR LAST WORD DEPENDING ON WHETHER THE COUNTRY HAS
	-- THE STREET TYPE AT THE BEGINNING OR END OF ADDRESS LINE 1

	-- STREET TYPE AT THE BEGINNING OF THE STREET
	UPDATE W
	SET W.Value = V.Standard
	FROM #InputWords W
	INNER JOIN Lookup.vwStreetNames V ON W.CountryID = V.CountryID
									AND W.Value = V.Variance

	-- RE-ASSEMBLE WORDS THAT MAKE STREET AND WRITE BACK TO VWT
	
	-- ASSEMBLE FIRSTWORD
	BEGIN
		INSERT INTO #OutputString (InputStringID, CountryID, OutputString)
		SELECT InputstringID, CountryID, Value
		FROM #InputWords
		WHERE Position = 1
	END

	-- ADD ADDITIONAL WORDS
	BEGIN
		DECLARE @MaxWords INT
		DECLARE @WordDelimiter VARCHAR(1)
		DECLARE @Position INT
	
		SET @Position = 2
		SET @WordDelimiter = ' '
		SET @MaxWords = (SELECT MAX(Position) FROM #InputWords)
	
		WHILE @Position <= @MaxWords
		BEGIN
			UPDATE O
			SET O.OutputString = O.OutputString + @WordDelimiter + I.Value
			FROM #OutputString O
			INNER JOIN #InputWords I ON O.InputStringID = I.InputStringID 
			WHERE I.Position = @Position
		
			SET @Position = @Position + 1
		
			CONTINUE
		END
	END

	-- WRITE CLEANSED STREET BACK TO VWT
	UPDATE VWT
	SET VWT.Street = O.OutputString
	FROM VWT
	INNER JOIN #OutputString O ON VWT.AuditItemID = O.InputStringID

	-- DROP TABLES
	DROP TABLE #InputString
	DROP TABLE #InputWords
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