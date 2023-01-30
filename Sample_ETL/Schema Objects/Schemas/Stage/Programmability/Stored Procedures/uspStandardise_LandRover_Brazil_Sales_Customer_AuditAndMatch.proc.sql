/****** Object: Procedure [dbo].[uspSTANDARDISE_STAGE_Landrover_Brazil_Sales_Customer_AuditAndMatch]   Script Date: 24/02/2012 10:13:12 ******/
CREATE PROC [Stage].[uspStandardise_LandRover_Brazil_Sales_Customer_AuditAndMatch]
AS

/*
	Purpose:	Generates AuditItems for the Customer rows, matches rows with the Contract then copies to an audit table
	
	Version			Date			Developer			Comment
	1.0				08/08/2011		Simon Peacock		Created
	1.1				14/11/2011		Chris Ross			Bug 5870: Add in PartnerUniqueID and CustType fields
																  Remove LastUpdatedBy field.
	
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET NOCOUNT ON
SET XACT_ABORT ON

BEGIN TRY
	BEGIN TRAN

	-- CREATE AUDITITEMS
	DECLARE @MaxAuditItemID BIGINT

	SELECT @MaxAuditItemID = MAX(AuditItemID) + 1 FROM [$(AuditDB)].dbo.AuditItems

	UPDATE [STAGE].Landrover_Brazil_Sales_Customer
	SET AuditItemID = ID + @MaxAuditItemID

	INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID)
	SELECT AuditID, AuditItemID FROM [STAGE].Landrover_Brazil_Sales_Customer

	-- DO THE MATCHING TO LINK THE TWO FILES TOGETHER
	INSERT INTO [$(AuditDB)].[Audit].LandRover_Brazil_Sales_Matching
	SELECT DISTINCT
		 ST.AuditID AS CustomerAuditID
		,ST.AuditItemID AS CustomerAuditItemID
		,TR.AuditID AS ContractAuditID
		,TR.AuditItemID AS ContractAuditItemID
	FROM [STAGE].Landrover_Brazil_Sales_Customer ST
	INNER JOIN [STAGE].LandRover_Brazil_Sales_Contract TR ON TR.CustomerID = ST.CustomerID


	-- ARCHIVE OFF THE LOADED DATA
	INSERT INTO [$(AuditDB)].[Audit].LandRover_Brazil_Sales_Customer
	(
		 CustomerID
		,Surname
		,Forename
		,Title
		,DateOfBirth
		,Occupation
		,Email
		,MobileTelephone
		,HomeTelephone
		,WorkTelephone
		,Address1
		,Address2
		,PostCode
		,Town
		,Country
		,CompanyName
		,State
		,PersonalTaxNumber
		,CompanyTaxNumber
		,MaritalStatus
		,EmailOptIn
		,EmailOptInDate
		,TelephoneOptIn
		,TelephoneOptInDate
		,MobileOptIn
		,MobileOptInDate
		,DateCreated
		,CreatedBy
		,LastUpdated
		,AuditID
		,AuditItemID
		,PartnerUniqueID
		,CustType
	)
	SELECT
		 CustomerID
		,Surname
		,Forename
		,Title
		,DateOfBirth
		,Occupation
		,Email
		,MobileTelephone
		,HomeTelephone
		,WorkTelephone
		,Address1
		,Address2
		,PostCode
		,Town
		,Country
		,CompanyName
		,State
		,PersonalTaxNumber
		,CompanyTaxNumber
		,MaritalStatus
		,EmailOptIn
		,EmailOptInDate
		,TelephoneOptIn
		,TelephoneOptInDate
		,MobileOptIn
		,MobileOptInDate
		,DateCreated
		,CreatedBy
		,LastUpdated
		,AuditID
		,AuditItemID
		,PartnerUniqueID
		,CustType
	FROM [STAGE].Landrover_Brazil_Sales_Customer

	COMMIT TRAN
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
GO
