
CREATE PROCEDURE [Stage].[uspStandardise_Combined_IAssistance]

@SampleFileName NVARCHAR (1000)

AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				2018-10-22		Chris Ledger		Created from [Sample-ETL].Stage.uspStandardise_Combined_Roadside_Service
	1.1				2020-01-10		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

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


	UPDATE [Stage].Combined_IAssistance
	SET [ConvertedIAssistanceCallStartDate] = CONVERT (DATETIME, [IAssistanceCallStartDate], 103)
	WHERE ISDATE([IAssistanceCallStartDate]) =  1

	------

	UPDATE [Stage].Combined_IAssistance
	SET [ConvertedIAssistanceCallCloseDate] = CONVERT (DATETIME, [IAssistanceCallCloseDate], 103)
	WHERE ISDATE([IAssistanceCallCloseDate]) = 1
	
	------

	--v1.2
	UPDATE  s
    SET     s.[Address8(Country)] =	CASE c.ISOAlpha3
										WHEN 'LUX' THEN 'BEL'
                                        ELSE c.ISOAlpha3
                                    END
    FROM    Stage.Combined_IAssistance s
    INNER JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha2 =	CASE
																			WHEN s.CountryCodeISOAlpha2 = 'Japan'	-- V1.3 Japan sent instead of ISOalpha2
																				THEN s.CountryCode
																			WHEN s.CountryCodeISOAlpha2 IS NULL
																				OR s.CountryCodeISOAlpha2 = ''
																				THEN s.CountryCode
																			ELSE s.CountryCodeISOAlpha2
																		END				  
	
	-----

	
	-----  SET PREFERRED LANGUAGE ----------------------------------------
	
	-- 1st Lookup Preferred Language in Language table
	UPDATE s
	SET s.PreferredLanguageID = l.LanguageID
	FROM  Stage.Combined_IAssistance s
	INNER JOIN [$(SampleDB)].dbo.Languages l on l.Language = s.PreferredLanguage
	
	-- Then, if not found, set using default language for country  
	UPDATE s
	SET s.PreferredLanguageID = c.DefaultLanguageID 
	FROM Stage.Combined_IAssistance s
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries c on c.ISOAlpha2 = NULLIF(s.CountryCodeISOAlpha2, '')    -- Use the original country code (or breakdown country) supplied to determine preferred language
	WHERE s.PreferredLanguageID IS NULL
	
	-- Failing that default to English
	UPDATE Stage.Combined_IAssistance
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
	FROM		Stage.Combined_IAssistance	GS
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
		
		WHERE			(M.Questionnaire	= 'I-Assistance') AND
						(M.SampleLoadActive = 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')	

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID
							
							
	--Populate SampleTriggeredSelectionReqID
	UPDATE		GS
	SET			SampleTriggeredSelectionReqID = (
													CASE
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
														ELSE	NULL
													END
												)
	
	FROM 		Stage.Combined_IAssistance		GS
	INNER JOIN	#Completed							C ON GS.ID =C.ID
	
	
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
		INTO [$(ErrorDB)].Stage.Combined_IAssistance_' + @TimestampString + '
		FROM Stage.Combined_IAssistance
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH