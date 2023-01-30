CREATE PROCEDURE [CustomerUpdateFeeds].[uspReportOutput]
	@Market varchar(200), @Manufacturer varchar(200), @DealerCode varchar(200)
AS

/*

	Purpose:		Get report output 
		
	Version			Date			Developer			Comment
	1.1				08-02-2019		Chris Ledger		BUG 15221 - Move code from package to SP.
	1.2				26-09-2019		Chris Ledger		BUG 15562 - Add PAGCode
	1.3				15-01-2020		Chris Ledger 		BUG 15372 - Correct incorrect cases
*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	TRUNCATE TABLE CustomerUpdateFeeds.ReportingTableOutput

	INSERT INTO CustomerUpdateFeeds.ReportingTableOutput (TransactionType, DealerCode, DealerShortName, ModelDescription, RegistrationNumber, VIN, ResponseDate, Title, CustomerFirstName, CustomerSecondLastName, CustomerLastName, OrganisationName, AddressLine1, AddressLine2, AddressLine3, AddressLine4, AddressLine5, Town, Region, Country, PostCode, HomeContactNumber, WorkContactNumber, MobileContactNumber, EmailAddress, NEW_DealerCode, NEW_DealerShortName, NEW_ModelDescription, NEW_RegistrationNumber, NEW_Title, NEW_CustomerFirstName, NEW_CustomerSecondLastName, NEW_CustomerLastName, NEW_OrganisationName, NEW_AddressLine1, NEW_AddressLine2, NEW_AddressLine3, NEW_AddressLine4, NEW_AddressLine5, NEW_Town, NEW_Region, NEW_Country, NEW_PostCode, NEW_ContactNumber, NEW_WorkContactNumber, NEW_MobileContactNumber, NEW_EmailAddress, EmailValidityFLAG, Source, CustomerID_Cupid, CustomerID_Vista, CustomerID_Roadside, CustomerID_General, DateOfUpdate, Bounceback, PAGCode)
	SELECT DISTINCT  
	TransactionType, 
	DealerCode, 
	DealerShortName, 
	ModelDescription, 
	RegistrationNumber, 
	VIN, 
	CONVERT(varchar(11),ClosureDate,103) AS ResponseDate,
	Title, 
	CustomerFirstName, 
	CustomerSecondLastName, 
	CustomerLastName, 
	OrganisationName, 
	AddressLine1, 
	AddressLine2, 
	AddressLine3, 
	AddressLine4, 
	AddressLine5, 
	Town, 
	Region, 
	Market AS Country, 
	PostCode, 
	HomeContactNumber, 
	WorkContactNumber, 
	MobileContactNumber, 
	EmailAddress, 
	NEW_DealerCode, 
	NEW_DealerShortName,
	N' ' AS NEW_ModelDescription, 
	NEW_RegistrationNumber, 
	NEW_Title, 
	NEW_CustomerFirstName, 
	NEW_CustomerSecondLastName, 
	NEW_CustomerLastName, 
	NEW_OrganisationName, 
	NEW_AddressLine1, 
	NEW_AddressLine2, 
	NEW_AddressLine3, 
	NEW_AddressLine4, 
	NEW_AddressLine5, 
	NEW_Town, 
	NEW_Region, 
	NEW_Country, 
	NEW_PostCode, 
	NEW_ContactNumber, 
	NEW_WorkContactNumber,
	NEW_MobileContactNumber, 
	NEW_EmailAddress, 
	EmailValidityFLAG, 
	Source, 
	CustomerID_Cupid,
	CustomerID_Vista,
	CustomerID_Roadside, 
	CustomerID_General, 
	CONVERT(varchar(11),COALESCE(ActionDate, BouncebackActionDate),103) AS DateOfUpdate, 
	Bounceback,
	PAGCode
	FROM CustomerUpdateFeeds.CustomerUpdateFeed 
	WHERE Market = @Market
	AND Manufacturer = @Manufacturer
	AND ((ISNULL(DealerCode,'') = CASE @DealerCode WHEN 'ALL' THEN ISNULL(DealerCode,'') ELSE @DealerCode END)
			OR
		 (ISNULL(PAGCode,'') = CASE @DealerCode WHEN 'ALL' THEN ISNULL(PAGCode,'') ELSE @DealerCode END))
	AND ((ActionDate BETWEEN CONVERT(DATE, GETDATE() -8) AND CONVERT(DATE, GETDATE()))
		 OR (BouncebackActionDate BETWEEN CONVERT(DATE, GETDATE() -8) AND CONVERT(DATE, GETDATE()))
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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH	
