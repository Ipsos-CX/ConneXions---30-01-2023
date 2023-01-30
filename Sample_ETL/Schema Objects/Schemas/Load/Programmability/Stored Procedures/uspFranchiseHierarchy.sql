CREATE PROCEDURE [Load].[uspFranchiseHierarchy]

AS

/*
	Purpose:	Transfer Franchise Hierarchy data to Sample DB
				Ignore records that have failed data checks
	
	Release		Version		Date			Developer			Comment
	LIVE		1.0			03/02/2021		Ben King			BUG 18055
	LIVE		1.1         2021-08-17      Ben King            TASK 578 - China 3 digit code
	LIVE		1.2			2022-01-17		Ben King			TASK 750 - New APO column in FIMs - Ben		
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	--RECORDS ARE KEPT IF THE LATEST RECORDS SUPPLIED HAVE BEEN FLAGGED AS HAVING DATA INTEGRITY ERRORS.
	DELETE FROM [$(SampleDB)].[DealerManagement].[Franchises_Load]
	WHERE [IP_KeepOriginal] = 0
	

	INSERT INTO [$(SampleDB)].[DealerManagement].[Franchises_Load] 
		(
		IP_StagingDataValidated, 
		ImportAuditID, 
		ImportAuditItemID, 
		ImportFileName, 
		RDsRegion, 
		BusinessRegion, 
		DistributorCountryCode, 
		DistributorCountry, 
		DistributorCICode, 
		DistributorName, 
		FranchiseCountryCode, 
		FranchiseCountry, 
		JLRNumber, 
		RetailerLocality, 
		Brand, 
		FranchiseCICode, 
		FranchiseTradingTitle, 
		FranchiseShortName, 
		RetailerGroup, 
		FranchiseType, 
		Address1, 
		Address2, 
		Address3, 
		AddressTown, 
		AddressCountyDistrict, 
		AddressPostcode, 
		AddressLatitude, 
		AddressLongitude, 
		AddressActivity, 
		Telephone, 
		Email, 
		URL, 
		FranchiseStatus, 
		FranchiseStartDate, 
		FranchiseEndDate, 
		LegacyFlag, 
		[10CharacterCode], 
		FleetandBusinessRetailer, 
		SVO, 
		Market, 
		MarketNumber, 
		Region, 
		RegionNumber, 
		SalesZone, 
		SalesZoneCode, 
		AuthorisedRepairerZone, 
		AuthorisedRepairerZoneCode, 
		BodyshopZone, 
		BodyshopZoneCode, 
		LocalTradingTitle1, 
		LocalLanguage1,
		LocalTradingTitle2, 
		LocalLanguage2,
		ChinaDMSRetailerCode, --V1.1
		ApprovedUser --V1.2
		)
	SELECT
		IP_StagingDataValidated, 
		ImportAuditID, 
		ImportAuditItemID, 
		ImportFileName, 
		RDsRegion, 
		BusinessRegion, 
		DistributorCountryCode, 
		DistributorCountry, 
		DistributorCICode, 
		DistributorName, 
		FranchiseCountryCode, 
		FranchiseCountry, 
		JLRNumber, 
		RetailerLocality, 
		Brand, 
		FranchiseCICode, 
		FranchiseTradingTitle, 
		FranchiseShortName, 
		RetailerGroup, 
		FranchiseType, 
		Address1, 
		Address2, 
		Address3, 
		AddressTown, 
		AddressCountyDistrict, 
		AddressPostcode, 
		AddressLatitude, 
		AddressLongitude, 
		AddressActivity, 
		Telephone, 
		Email, 
		URL, 
		FranchiseStatus, 
		FranchiseStartDate, 
		FranchiseEndDate, 
		LegacyFlag, 
		[10CharacterCode], 
		FleetandBusinessRetailer, 
		SVO, 
		Market, 
		MarketNumber, 
		Region, 
		RegionNumber, 
		SalesZone, 
		SalesZoneCode, 
		AuthorisedRepairerZone, 
		AuthorisedRepairerZoneCode, 
		BodyshopZone, 
		BodyshopZoneCode, 
		LocalTradingTitle1, 
		LocalLanguage1,
		LocalTradingTitle2, 
		LocalLanguage2,
		ChinaDMSRetailerCode,
		ApprovedUser --V1.2
	--SELECT *
	FROM [DealerManagement].[Franchises_Load]
	WHERE (IP_StagingDataValidated = 1
	AND IP_KeepOriginal IS NULL) --CAN BE PROCESSED
	OR (IP_StagingDataValidated = 0
	AND IP_KeepOriginal IS NULL) -- CAN NOT BE PROCESSED AS DATA ISSUES WITHIN CURRENT FILE
								 -- I.E DUPLICATED ROWS OR MIS-SPELLING OF JAGUAR, LAND ROVER

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
