CREATE PROC [Stage].[uspStandardise_LandRover_Brazil_Sales_Contract_Audit]
AS

/*
	Purpose:	Generates AuditItems for the Contract rows then copies to an audit table
	
	Version			Date			Developer			Comment
	1.0				08/08/2011		Simon Peacock		Created
	1.1				14/11/2011		Chris Ross			Bug 5870: Add in CustType and Customers fields
	
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

	UPDATE Stage.LandRover_Brazil_Sales_Contract
	SET AuditItemID = ID + @MaxAuditItemID

	INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID)
	SELECT AuditID, AuditItemID FROM Stage.Landrover_Brazil_Sales_Contract



	INSERT INTO [$(AuditDB)].Audit.Landrover_Brazil_Sales_Contract
	(
		 PartnerUniqueID
		,CommonOrderNumber
		,VIN
		,ContractNo
		,ContractVersion
		,CustomerID
		,CancelDate
		,CommonTypeOfSale
		,ContractDate
		,HandoverDate
		,SalesmanCode
		,ContractRelationship
		,DealerReference
		,DateCreated
		,CreatedBy
		,LastUpdatedBy
		,LastUpdated
		,AuditID
		,AuditItemID
		,CustType
		,Customers
	)
	SELECT
		 PartnerUniqueID
		,CommonOrderNumber
		,VIN
		,ContractNo
		,ContractVersion
		,CustomerID
		,CancelDate
		,CommonTypeOfSale
		,ContractDate
		,HandoverDate
		,SalesmanCode
		,ContractRelationship
		,DealerReference
		,DateCreated
		,CreatedBy
		,LastUpdatedBy
		,LastUpdated
		,AuditID
		,AuditItemID
		,CustType
		,Customers
	FROM Stage.Landrover_Brazil_Sales_Contract

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