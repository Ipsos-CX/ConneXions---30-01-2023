/****** Object: Procedure [Stage].[uspStandardise_LandRover_Brazil_Sales_Combine]   Script Date: 23/02/2012 10:46:47 ******/
CREATE PROC [Stage].[uspStandardise_LandRover_Brazil_Sales_Combine]
AS

/*
	Purpose:	Combine data from STAGE_Landrover_Brazil_Sales_Customer and STAGE_Landrover_Brazil_Sales_Contract
				and load into STAGE_Landrover_Brazil_Sales.  Audit it and then this data can be used to insert into VWT
				
	Version			Date			Developer			Comment
	1.0				08/08/2011		Simon Peacock		Created
	1.1				30/03/2012		Attila Kubanda		If multiple files are loaded at the same time and a CustomerID is persent in multiple files 
														duplicates will be pushed into the Staging Table. To Prevent this DISTINST added to the script.
	1.2				08/08/2012		Pardip Mudhar		A record for incoming files are inserted to allow auditing
	1.3				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)
DECLARE @Date NVARCHAR(24) = NULL
DECLARE @DateParts NVARCHAR(24) = NULL

BEGIN TRY

	BEGIN TRAN

	INSERT INTO [Stage].LandRover_Brazil_Sales
	(
		 CustomerID
		,Title
		,Forename
		,Surname
		,CompanyName
		,DateOfBirth
		,Address1
		,Address2
		,Town
		,State
		,PostCode
		,Country
		,Email
		,MobileTelephone
		,HomeTelephone
		,WorkTelephone
		,VIN
		,DealerCode
		,SaleDate
		,EmailOptIn
		,TelephoneOptIn
		,MobileOptIn
	)
	SELECT DISTINCT				--v1.1
		 ST.CustomerID
		,ST.Title
		,ST.Forename
		,ST.Surname
		,ST.CompanyName
		,dbo.udfGENERAL_FormatDateFromText(ST.DateOfBirth) AS DateOfBirth
		,ST.Address1
		,ST.Address2
		,ST.Town
		,St.State
		,ST.PostCode
		,ST.Country
		,ST.Email
		,ST.MobileTelephone
		,ST.HomeTelephone
		,ST.WorkTelephone
		,TR.VIN
		,RIGHT(TR.PartnerUniqueID, 5) AS DealerCode
		,dbo.udfGENERAL_FormatDateFromText(TR.HandoverDate) AS SaleDate
		,ST.EmailOptIn
		,ST.TelephoneOptIn
		,ST.MobileOptIn
	FROM [$(AuditDB)].[Audit].LandRover_Brazil_Sales_Matching M
	INNER JOIN [Stage].Landrover_Brazil_Sales_Customer ST ON ST.AuditItemID = M.CustomerAuditItemID
	INNER JOIN [Stage].Landrover_Brazil_Sales_Contract TR ON TR.AuditItemID = M.ContractAuditItemID

	DECLARE @RowCount INT
	SET @RowCount = @@ROWCOUNT

	-- GET THE MAXIMUM AuditID FROM Audit
	DECLARE @AuditID dbo.AuditID
	SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(AuditDB)].dbo.Audit

	-- INSERT THE NEW AuditID INTO Audit
	INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
	SELECT @AuditID

	UPDATE [Stage].LandRover_Brazil_Sales
	SET AuditID = @AuditID

	SET @Date = CONVERT( nvarchar(24), getdate(), 112) 
	select @DateParts = SUBSTRING( @date, 7, 2) + SUBSTRING( @date, 5, 2) + SUBSTRING( @date, 3, 2)
	INSERT INTO [$(AuditDB)].dbo.Files (AuditID, FileTypeID, FileName, FileRowCount, ActionDate )
	VALUES (@AuditID, 1, 'LandRover_Brazil_Sales_'+@DateParts, @RowCount, GETDATE() )

	INSERT INTO [$(AuditDB)].dbo.IncomingFiles 
	(	AuditID, 
		FileChecksum,
		FileLoadFailureID,
		LoadSuccess
	)
	VALUES
	(	@AuditID,
		0,
		NULL,
		1
	)

	UPDATE Stage.LandRover_Brazil_Sales
	SET ConvertedDateOfBirth = CAST( DateOfBirth AS DATETIME2 )
	WHERE ISDATE(DateOfBirth) = 1

	UPDATE Stage.LandRover_Brazil_Sales
	SET ConvertedSaleDate = CAST( SaleDate AS DATETIME2 )
	WHERE ISDATE(SaleDate) = 1

	DECLARE @MaxID BIGINT
	
	SELECT @MaxID = MAX(ID)
	FROM Stage.LandRover_Brazil_Sales
	
	UPDATE Stage.LandRover_Brazil_Sales
	SET PhysicalRowID = @MaxID - ( @MaxID - ID ) + 1
	
	-- CLEAR DOWN SEPARATED TABLES
	TRUNCATE TABLE [STAGE].Landrover_Brazil_Sales_Customer
	TRUNCATE TABLE [STAGE].Landrover_Brazil_Sales_Contract

	COMMIT TRAN
	
END TRY
BEGIN CATCH

	ROLLBACK

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
