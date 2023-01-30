CREATE TRIGGER Party.TR_I_vwDA_Titles ON [Party].[vwDA_Titles] 
INSTEAD OF INSERT
AS


/*
	Purpose:	Inserts into Titles
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PreNominalTitles.TR_I_vwDA_PreNominalTitles
	1.1				11/04/2012		Attila Kubanda		BUG 6677, Title can't load in 'N' or 'n' AS THE MATCHING WILL USE CHECKSUM AND CHECKSUM ('N' WILL PRODUCE 0 JUST AS '' SO THE OUTPUT WILL SHOW TITLE 'N' TO PEOPLE WHERE IT SHOULD BE ''.
	1.2				23/03/2018		Chris Ledger		BUG 14626: Move FILTER FROM LEFT JOIN TO WHERE CLAUSE
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @MaxTitleID SMALLINT
	DECLARE @CurrentTimestamp DATETIME

	SET @CurrentTimestamp = CURRENT_TIMESTAMP

	-- CREATE TABLE VARIABLE TO PUT THE INSERTED TITLES THAT DO NOT ALREADY EXIST IN THE Titles TABLE
	DECLARE @NewTitles TABLE
	(
		NewTitleID dbo.TitleID IDENTITY(1, 1) NOT NULL, 
		Title dbo.Title
	)

	-- ADD THE TITLES TO THE TABLE THAT DO NOT ALREADY EXIST
	INSERT INTO @NewTitles
	(
		Title
	)
	SELECT DISTINCT
		I.Title
	FROM INSERTED I
	LEFT JOIN Party.Titles T ON ISNULL(T.Title, N'') = ISNULL(I.Title, N'')
															--	AND (I.Title <> 'N' OR I.Title <> 'n')	--1.1v V1.2
	WHERE T.TitleID IS NULL
	AND (I.Title <> 'N' OR I.Title <> 'n')		-- V1.2

	-- GET HIGHEST CURRENT TitleID
	SELECT @MaxTitleID = ISNULL(MAX(TitleID), 0) FROM Party.Titles


	-- INSERT INTO Titles
	INSERT INTO Party.Titles
	(
			TitleID, 
			Title
	)
	SELECT
		NewTitleID + @MaxTitleID AS TitleID, 
		Title
	FROM @NewTitles
	ORDER BY NewTitleID

	-- WRITE ROWS TO TitleVariations AS EACH NEW STANDARDISED TITLE NEEDS TO HAVE ITSELF AS A VARIATION TO BE MATCHED
	INSERT INTO Party.vwDA_TitleVariations
		(
			AuditItemID, 
			TitleID, 
			TitleVariationID, 
			TitleVariation
		)
	SELECT
		I.AuditItemID, 
		NT.NewTitleID + @MaxTitleID AS TitleID, 
		0 AS TitleVariationID, 
		NT.Title
	FROM @NewTitles NT
	INNER JOIN INSERTED I ON ISNULL(NT.Title, N'') = ISNULL(I.Title, N'')

	-- INSERT INTO AUDIT
	INSERT INTO [$(AuditDB)].Audit.Titles
	(
		AuditItemID, 
		TitleID, 
		Title
	)
	SELECT DISTINCT
		I.AuditItemID, 
		NT.NewTitleID + @MaxTitleID, 
		NT.Title
	FROM @NewTitles NT
	INNER JOIN INSERTED I ON ISNULL(NT.Title, N'') = ISNULL(I.Title, N'')
		
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












