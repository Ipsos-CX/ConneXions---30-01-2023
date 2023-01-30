CREATE PROCEDURE [SelectionOutput].[uspMoveSMSforOutputByLanguage]
AS


/*
	Purpose:	Moves records from the SMS table to the SMSOutputByLanguage where the Market is set to be 
				"SMS output by language".  
	
	Version			Date			Developer			Comment
	1.0				03/12/2014		Chris Ross			Original version
	1.1				22/01/2015		Chris Ross			Fixed bug where removing all SMS records rather than just moved
														to SMSOutputByLanguage table.
	

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY



INSERT INTO [SelectionOutput].[SMSOutputByLanguage] (
										Password, 
										ID, 
										FullModel, 
										Model, 
										VIN, 
										sType, 
										CarReg, 
										Title, 
										Initial, 
										Surname, 
										Fullname, 
										DearName, 
										CoName, 
										Add1, 
										Add2, 
										Add3, 
										Add4, 
										Add5, 
										Add6, 
										Add7, 
										Add8, 
										Add9, 
										CTRY, 
										EmailAddress, 
										Dealer, 
										sno, 
										ccode, 
										modelcode, 
										lang, 
										manuf, 
										gender, 
										qver, 
										blank, 
										etype, 
										reminder, 
										week, 
										test, 
										SampleFlag, 
										SalesServiceFile, 
										EventDate, 
										DealerCode, 
										LandPhone, 
										WorkPhone, 
										MobilePhone, 
										PartyID, 
										GDDDealerCode, 
										ReportingDealerPartyID, 
										VariantID, 
										ModelVariant,
										Region,
										Questionnaire
									)
	SELECT
		SO.[Password],            
		SO.[ID], 
		SO.[FullModel], 
		SO.[Model], 
		SO.[VIN],
		SO.[sType], 
		SO.[CarReg], 
		SO.[Title], 
		SO.[Initial], 
		SO.[Surname], 
		SO.[Fullname], 
		SO.[DearName], 
		SO.[CoName], 
		SO.[Add1], 
		SO.[Add2], 
		SO.[Add3], 
		SO.[Add4], 
		SO.[Add5], 
		SO.[Add6], 
		SO.[Add7], 
		SO.[Add8], 
		SO.[Add9], 
		SO.[CTRY], 
		SO.[EmailAddress], 
		SO.[Dealer], 
		SO.[sno], 
		SO.[ccode], 
		SO.[modelcode], 
		SO.[lang], 
		SO.[manuf], 
		SO.[gender], 
		SO.[qver], 
		SO.[blank], 
		SO.[etype], 
		SO.[reminder], 
		SO.[week], 
		SO.[test], 
		SO.[SampleFlag], 
		SO.[SalesServiceFile],
		SO.EventDate,
		SO.DealerCode,
		SO.LandPhone,
		SO.WorkPhone,
		SO.MobilePhone,
		SO.PartyID,
		SO.GDDDealerCode,
		SO.ReportingDealerPartyID,
		SO.VariantID,
		SO.ModelVariant,
		BMQ.Region,
		BMQ.Questionnaire
	FROM SelectionOutput.SMS SO
	INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
	INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
	INNER JOIN Event.Events E ON E.EventID = AEBI.EventID
	INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
	INNER JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf
	INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = SO.sType
																AND BMQ.ISOAlpha3 = O.Market
																AND BMQ.Questionnaire = ET.EventCategory
	WHERE BMQ.SMSOutputByLanguage = 1;


	-- Remove the output by Language entries
	DELETE SO
	FROM SelectionOutput.SMS SO
	INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
	INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
	INNER JOIN Event.Events E ON E.EventID = AEBI.EventID
	INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
	INNER JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf
	INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = SO.sType
																AND BMQ.ISOAlpha3 = O.Market
																AND BMQ.Questionnaire = ET.EventCategory
	WHERE BMQ.SMSOutputByLanguage = 1; 

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH