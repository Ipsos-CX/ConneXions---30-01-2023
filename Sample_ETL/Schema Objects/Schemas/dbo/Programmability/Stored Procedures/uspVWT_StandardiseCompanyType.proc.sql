CREATE PROCEDURE dbo.uspVWT_StandardiseCompanyType 

AS

/*
	Purpose:	Standardise where relevant each of the individual words that make up a companies type. e.g. Co, Ltd, Plc etc
	
	Rationale:	1. Load grouped company names into a temorary table
				2. Split the company name into individual words and place in a permanent temorary table
				3. Join individual words to a list of known variants and substitute for a standard value
				4. Put company names back together again
				5. Write standardised version back to the source table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISECOMPANY_StandardiseCompanyType

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

	-- POPULATE INPUT TABLE WITH THE SUPPLIED OrganisationNames 
	INSERT INTO #InputString (InputStringID, CountryID, InputString)
	SELECT AuditItemID, CountryID, RTRIM(OrganisationNameOrig)
	FROM dbo.VWT
	WHERE ISNULL(LEN(OrganisationNameOrig),0) > 0	-- MUST HAVE A COMPANY NAME TO STANDARDISE

	-- STANDARDISE WORD DELIMITERS. 
	-- THIS COULD BE COUNTRY SPECIFIC SO MAY WELL STORE THIS DATA IN A META DATA TABLE AND DO A WHILE LOOP. e.g. ITALIAN BUILDING/FLAT NUMBERS 
	-- HAVE A FORWARD SLASH BETWEEN THEM SO KEEP IT IN TO KEEP THE NUMBER TOGETHER, HOWEVER HOUSE NUMBERS HAVE A COMMA DELIMITING IT FROM THE 
	-- ADDRESS SO THAT CAN BE REMOVED. 
	-- HARD CODED FOR ITALY AT PRESENT
	UPDATE #InputString
	SET InputString = REPLACE(InputString, ' ', '|')
	UPDATE #InputString
	SET InputString = REPLACE(InputString, ',', '|')
	UPDATE #InputString
	SET InputString = InputString + '|' -- PLACE A DELIMITER VALUE AT THE END OF THE STRING.

	-- SPLIT STREET NAMES INTO CONSTITUENT WORDS AND POPULATE TABLE INPUTWORDS
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
					FROM #InputWords
		 			WHERE #InputWords.InputStringID = #InputString.InputStringID
				) AS Position
			FROM #InputString
			WHERE ISNULL(PATINDEX('%|%', InputString), 0) > 0		-- THERE IS A WORD DELIMITER
			AND LEFT(InputString, PATINDEX('%|%', InputString) - 1) <> ''	-- NOT AN EMPTY STRING
			
			-- TRUNCATE PROCESSED PORTION FROM NAME STRING
			UPDATE #InputString
			SET InputString = RIGHT(InputString, (LEN(InputString) - PATINDEX('%|%', InputString)))
			WHERE ISNULL(PATINDEX('%|%', InputString), 0) > 0
			
			CONTINUE
		END
	END

	-- STANDARDISE COMPANY TYPES BASED ON META DATA DERIVED FROM A VIEW
	UPDATE IW
	SET IW.Value = V.Standard
	FROM #InputWords IW
	INNER JOIN Lookup.vwCompanyTypeStandardisation V ON IW.CountryID = V.CountryID	--COUNTRY SPECIFIC BUT NEED IT BE?
													AND IW.Value = V.Variant

	-- ASSEMBLE FIRSTWORD
	BEGIN
		INSERT INTO #OutputString (InputStringID, CountryID, OutputString)
		SELECT InputStringID, CountryID, Value
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
			SET O.OutputString = O.OutputString + @WordDelimiter + W.Value
			FROM #OutputString O
			INNER JOIN #InputWords W ON O.InputStringID = W.InputStringID 
			WHERE W.Position = @Position
	
			SET @Position = @Position + 1
		
			CONTINUE
		END
	END

	-- WRITE STANDARDISED DATA BACK TO VWT
	UPDATE VWT
	SET VWT.OrganisationName = O.OutputString
	FROM VWT
	INNER JOIN #OutputString O ON VWT.AuditItemID = O.InputStringID

	-- DROP TABLES
	TRUNCATE TABLE #InputString
	TRUNCATE TABLE #InputWords
	TRUNCATE TABLE #OutputString

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