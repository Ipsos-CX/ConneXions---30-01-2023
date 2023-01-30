CREATE PROCEDURE SelectionOutput.uspInsertMerged_SMS
(
	@Questionnaire VARCHAR(255)
)
AS

/*
	Purpose:	Insert Data into SelectionOutput.Merged_SMS Table
	
	Version			Date			Developer			Comment
	1.0				2019-11-07		Chris Ledger		Bug 15191 - New SP from Insert Into Merged_SMS SQL Task (Selection Output package)  
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO SelectionOutput.Merged_SMS
	  ([Password]
	  ,ID
	  ,FullModel
	  ,Model
	  ,VIN
	  ,sType
	  ,CarReg
	  ,Title
	  ,Initial
	  ,Surname
	  ,Fullname
	  ,DearName
	  ,CoName
	  ,Add1
	  ,Add2
	  ,Add3
	  ,Add4
	  ,Add5
	  ,Add6
	  ,Add7
	  ,Add8
	  ,Add9
	  ,CTRY
	  ,EmailAddress
	  ,Dealer
	  ,sno
	  ,ccode
	  ,modelcode
	  ,lang
	  ,manuf
	  ,gender
	  ,qver
	  ,blank
	  ,etype
	  ,reminder
	  ,[week]
	  ,test
	  ,SampleFlag
	  ,SalesServiceFile
	  ,EventDate
	  ,DealerCode
	  ,LandPhone
	  ,WorkPhone
	  ,MobilePhone
	  ,PartyID
	  ,GDDDealerCode
	  ,ReportingDealerPartyID
	  ,VariantID
	  ,ModelVariant
	  ,ReoutputIndicator
	  ,Questionnaire)

	SELECT [Password]
	  ,ID
	  ,FullModel
	  ,Model
	  ,VIN
	  ,sType
	  ,CarReg
	  ,Title
	  ,Initial
	  ,Surname
	  ,Fullname
	  ,DearName
	  ,CoName
	  ,Add1
	  ,Add2
	  ,Add3
	  ,Add4
	  ,Add5
	  ,Add6
	  ,Add7
	  ,Add8
	  ,Add9
	  ,CTRY
	  ,EmailAddress
	  ,Dealer
	  ,sno
	  ,ccode
	  ,modelcode
	  ,lang
	  ,manuf
	  ,gender
	  ,qver
	  ,blank
	  ,etype
	  ,reminder
	  ,[week]
	  ,test
	  ,SampleFlag
	  ,SalesServiceFile
	  ,EventDate
	  ,DealerCode
	  ,LandPhone
	  ,WorkPhone
	  ,MobilePhone
	  ,PartyID
	  ,GDDDealerCode
	  ,ReportingDealerPartyID
	  ,VariantID
	  ,ModelVariant
	  ,ReoutputIndicator
	  ,@Questionnaire
	FROM SelectionOutput.SMS

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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END	
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH