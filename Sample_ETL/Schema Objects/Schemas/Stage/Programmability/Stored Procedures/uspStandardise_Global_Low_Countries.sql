CREATE PROCEDURE [Stage].[uspStandardise_Global_Low_Countries]
/*
	Purpose:		(I)		Convert the supplied dates FROM a text string to a valid DATETIME type
					(II)	Populate mandatory meta data
	
	Version			Date			Developer			Comment
	1.0				10/12/2020		Ben King			BUG 18039
	1.1				10/02/2021		Ben King			BUG 18106
	  
*/

		@SampleFileName  NVARCHAR(100)

AS

DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)



SET LANGUAGE ENGLISH
SET DATEFORMAT DMY
BEGIN TRY


	----------------------------------------------------------------------------------------------------
	-- Set the BMQ specific load variables 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate	(ID, Manufacturer, CountryCode, EventType, Country, CountryID)

	AS

	(
	--Add In CountryID
	SELECT		LC.ID, LC.SampleManufacturer, LC.SampleCountryCode, LC.SampleEventType, C.Country,C.CountryID
	FROM		Stage.Global_Low_Countries		LC
	INNER JOIN	[$(SampleDB)].ContactMechanism.Countries	C  ON LC.SampleCountryCode =	(  
																						Case
																							WHEN LEN(LC.SampleCountryCode) = 2 THEN ISOAlpha2
																							ELSE ISOAlpha3
																						End
																					)	
	)
	--Retrieve Metadata values for each event in the table
	SELECT	DISTINCT	RU.*, MD.ManufacturerPartyID, MD.EventTypeID, MD.LanguageID, MD.SetNameCapitalisation,
						MD.DealerCodeOriginatorPartyID, MD.CreateSelection, MD.SampleTriggeredSelection,
						MD.QuestionnaireRequirementID, MD.SampleFileID

	INTO	#Completed							
	FROM	RecordsToUpdate RU
	INNER JOIN 
	(
		SELECT DISTINCT M.ManufacturerPartyID, M.CountryID, ET.EventTypeID,  
						C.DefaultLanguageID AS LanguageID, M.SetNameCapitalisation, M.DealerCodeOriginatorPartyID,
						M.Brand, M.Questionnaire, M.SampleLoadActive, M.SampleFileNamePrefix,
						M.CreateSelection, M.SampleTriggeredSelection, 
						M.QuestionnaireRequirementID,
						M.SampleFileID
						
		FROM			[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
		INNER JOIN		[$(SampleDB)].Event.EventTypes								ET ON ET.EventType = M.Questionnaire
		INNER JOIN		[$(SampleDB)].ContactMechanism.Countries					C ON C.CountryID = M.CountryID
		
		WHERE			(M.Questionnaire	IN ('Sales','PreOwned')) AND
						(M.SampleLoadActive = 1	) AND
						(@SampleFileName LIKE SampleFileNamePrefix + '%')	
						--('GLCL_TEST_COMBINED_V5' LIKE SampleFileNamePrefix + '%')	

	)	MD				ON	RU.Manufacturer = MD.Brand AND
							RU.CountryID	= MD.CountryID AND
					CASE 
						WHEN RU.EventType = 1
						THEN 'Sales'
						WHEN RU.EventType = 2
						THEN 'PreOwned'
						ELSE ''
					END
											= MD.Questionnaire
							
							
	--Populate the meta data fields for each record
	UPDATE		GL
	SET			ManufacturerPartyID			= C.ManufacturerPartyID,	 
				SampleSupplierPartyID		= C.ManufacturerPartyID,
				CountryID					= C.CountryID,
				EventTypeID					= C.EventTypeID,
				--LanguageID					= C.LanguageID,
				SalesDealerCodeOriginatorPartyID	= C.DealerCodeOriginatorPartyID,
				SetNameCapitalisation		= C.SetNameCapitalisation,
				SampleTriggeredSelectionReqID = (
													Case
														WHEN	C.CreateSelection = 1 AND 
																C.SampleTriggeredSelection = 1 THEN C.QuestionnaireRequirementID
														ELSE	0
													END
												)
	
	FROM 		Stage.Global_Low_Countries		GL
	INNER JOIN	#Completed					C ON GL.ID =C.ID	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert the Date 
	---------------------------------------------------------------------------------------------------------

	UPDATE Stage.Global_Low_Countries
	SET ConvertedRegistrationDate = CAST(RegistrationDate AS DATETIME2)
	WHERE ISDATE(RegistrationDate) = 1


	UPDATE Stage.Global_Low_Countries
	SET ConvertedSalesEventDate = CAST(RetailDate AS DATETIME2)
	WHERE ISDATE(RetailDate) = 1
	

	---------------------------------------------------------------------------------------------------------
	-- Update the preferred LanguageID, if a Preferred language supplied
	---------------------------------------------------------------------------------------------------------
	
	--NO DEFULAT PERMITTED FOR BELGIUM
	UPDATE S
	SET LanguageID = CASE 
						WHEN S.LanguageCode = 'F' THEN 148
						WHEN S.LanguageCode = 'N' THEN 121
						ELSE 0
					 END
	FROM Stage.Global_Low_Countries S
	WHERE S.SampleCountryCode = 'BE'


	--APPLY FRENCH DEFAULT IF NO LANGUAGE CODE GIVEN
	UPDATE S
	SET LanguageID = CASE 
						WHEN S.LanguageCode = 'F' THEN 148
						WHEN S.LanguageCode = 'N' THEN 121
						ELSE 148 --DEFAULT TO FRENCH
					 END
	FROM Stage.Global_Low_Countries S
	WHERE S.SampleCountryCode = 'LU'



		--APPLY DUTCH DEFAULT IF NO LANGUAGE CODE GIVEN
	UPDATE S
	SET LanguageID = CASE 
						WHEN S.LanguageCode = 'F' THEN 148
						WHEN S.LanguageCode = 'N' THEN 121
						ELSE 121 --DEFAULT TO DUTCH
					 END
	FROM Stage.Global_Low_Countries S
	WHERE S.SampleCountryCode = 'NL'
	

	---------------------------------------------------------------------------------------------------------
	--Validate for all records that require metadata fields to be populated. Raise an error otherwise.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	[Stage].[Global_Low_Countries] 
				WHERE	(ManufacturerPartyID		IS NULL OR
						SampleSupplierPartyID	IS NULL OR
						CountryID				IS NULL OR 
						EventTypeID				IS NULL OR	
						SalesDealerCodeOriginatorPartyID IS NULL OR
						SetNameCapitalisation  IS NULL) --OR
						--LanguageID				IS NULL)
			)			 
			
			RAISERROR(	N'Data in Stage.Global_Low_Countries has missing Meta-Data.', 
						16,
						1
					 )
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
		INTO [Sample_Errors].Stage.Global_Low_Countries_' + @TimestampString + '
		FROM Global_Low_Countries
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
