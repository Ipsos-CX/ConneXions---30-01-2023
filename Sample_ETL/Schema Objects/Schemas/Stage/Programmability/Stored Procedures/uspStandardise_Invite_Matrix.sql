
CREATE PROCEDURE [Stage].[uspStandardise_Invite_Matrix]
AS

/*
	Purpose:	Stanadise data & flag data errors which can not be processed
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				19112021		Ben King    		TASK 690
	LIVE			1.1				19082022		Eddie Thomas		Added new questionnaire Land Rover 'Experience'
	LIVE			1.2				22092022		Eddie Thomas		TASK 1017:  Add support for sub brands

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

		--Delete header row
		DELETE
		FROM [Stage].[InviteMatrix]
		WHERE PhysicalRowID = 1


		-- Report where Brand is not found
	    UPDATE I
		SET I.IP_DataError = 'Brand not correct'
		--SELECT * 
		FROM [Stage].[InviteMatrix] I
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].dbo.Brands b WHERE b.Brand = I.Brand)



		-- Report where Country/Market is not found
		UPDATE I
		SET I.IP_DataError = 'Market not found'
		--SELECT * 
		FROM [Stage].[InviteMatrix] I
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].dbo.Markets mk WHERE mk.Market = I.Market)



		-- Report where Questionnaire is not found
		UPDATE I
		SET I.IP_DataError = 'Questionnaire is not found'
		--SELECT * 
		FROM [Stage].[InviteMatrix] I
		--WHERE Questionnaire NOT IN ('Sales', 'Service', 'CRC', 'Roadside','PreOwned','LostLeads','CQI','I-Assistance','Bodyshop','MCQI','CRC General Enquiry','Land Rover Experience')
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].[dbo].[Questionnaires] q WHERE CASE 
																							WHEN q.Questionnaire LIKE 'CQI%' THEN 'CQI'
																							ELSE q.Questionnaire 
																					 END = I.Questionnaire AND q.IncludeInInviteMatrix = 1)		--V1.2



		-- Report where Language is not found
		UPDATE I
		SET I.IP_DataError = 'Language is not found'
		--SELECT * 
		FROM [Stage].[InviteMatrix] I
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].dbo.Languages l WHERE l.Language = I.EmailLanguage)

		--V1.2
		--Report where Sub Brand is not found
		UPDATE I
		SET I.IP_DataError = 'Sub Brand  is not found'
		--SELECT * 
		FROM [Stage].[InviteMatrix] I
		WHERE NOT EXISTS (SELECT * FROM [$(SampleDB)].[Vehicle].[SubBrands] s WHERE s.SubBrand = I.SubBrand)

		--Report duplicate entries
		UPDATE I
		SET I.IP_DataError = 'Duplicate Brand, Market, Questionnaire, Email Language, Sub Brand'
		--SELECT DISTINCT * 
		FROM [Stage].[InviteMatrix] I
		INNER JOIN (
						SELECT 
							LTRIM(RTRIM(Brand)) AS 'Brand', 
							LTRIM(RTRIM(Market)) AS 'Market', 
							LTRIM(RTRIM(Questionnaire)) AS 'Questionnaire', 
							LTRIM(RTRIM(EmailLanguage)) AS 'EmailLanguage', 
							LTRIM(RTRIM(SubBrand)) AS 'SubBrand', 
							COUNT(EmailLanguage) AS COUNT
						FROM [Stage].[InviteMatrix] I
						GROUP BY Brand, Market, Questionnaire, EmailLanguage, SubBrand
						HAVING COUNT(EmailLanguage) > 1
					) C ON
						LTRIM(RTRIM(I.Brand)) = C.Brand
					AND LTRIM(RTRIM(I.Market)) = C.Market
					AND LTRIM(RTRIM(I.Questionnaire)) = C.Questionnaire
					AND LTRIM(RTRIM(I.EmailLanguage)) = C.EmailLanguage
					AND LTRIM(RTRIM(I.SubBrand)) = C.SubBrand


		---------------------------------------------------------------------------------------------------------
		-- Check which markets are not present 
		---------------------------------------------------------------------------------------------------------

		--SELECT * FROM Sample.dbo.Markets mk
		--WHERE mk.Market NOT IN (SELECT Market FROM [Stage].[InviteMatrix])


		IF EXISTS(SELECT * FROM [Stage].[InviteMatrix] WHERE IP_DataError IS NOT NULL)
		BEGIN                                                                            
			SELECT 1/0
		END 
		
	
	
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
	
	EXEC(	'SELECT *
			INTO [$(ErrorDB)].Stage.InviteMatrix_' + @TimestampString + '
			FROM Stage.InviteMatrix')
	
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH

GO