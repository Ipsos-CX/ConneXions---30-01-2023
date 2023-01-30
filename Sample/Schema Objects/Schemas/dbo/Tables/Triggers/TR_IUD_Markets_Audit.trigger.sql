CREATE TRIGGER dbo.TR_IUD_Markets
ON dbo.Markets
AFTER INSERT, UPDATE, DELETE
AS

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY



	-- Save the datetime so we have a single value for the audit records
	DECLARE @SysDateTime DATETIME2
	SET @SysDateTime = GETDATE()


	-- insert the before and after values
	INSERT INTO [$(AuditDB)].Audit.Markets
	(
		MarketID, 
		Market, 
		CountryID, 
		DealerTableEquivMarket, 
		PartyMatchingMethodologyID, 
		RegionID, 
		SMSOutputByLanguage, 
		EventXDealerList, 
		SMSOutputFileExtension, 
		AltRoadsideEmailMatching, 
		SelectionOutput_NSCFlag, 
		IncSubNationalTerritoryInHierarchy, 
		ContactPreferencesModel, 
		ContactPreferencesPersist, 
		AltRoadsideTelephoneMatching,
		AltSMSOutputFile, 
		FranchiseCountry, 
		FranchiseCountryType, 
		ExcludeEmployeeData,
		UseLatestName,
		AuditRecordType, 
		UpdateDate, 
		UpdateBy
	)
	SELECT
		MarketID, 
		Market, 
		CountryID, 
		DealerTableEquivMarket, 
		PartyMatchingMethodologyID, 
		RegionID, 
		SMSOutputByLanguage, 
		EventXDealerList, 
		SMSOutputFileExtension, 
		AltRoadsideEmailMatching, 
		SelectionOutput_NSCFlag, 
		IncSubNationalTerritoryInHierarchy, 
		ContactPreferencesModel, 
		ContactPreferencesPersist, 
		AltRoadsideTelephoneMatching,
		AltSMSOutputFile, 
		FranchiseCountry, 
		FranchiseCountryType, 
		ExcludeEmployeeData,
		UseLatestName,
		'DELETED' AS AuditRecordType, 
		@SysDateTime,
		SYSTEM_USER 
	FROM DELETED D


	INSERT INTO [$(AuditDB)].Audit.Markets
	(
		MarketID, 
		Market, 
		CountryID, 
		DealerTableEquivMarket, 
		PartyMatchingMethodologyID, 
		RegionID, 
		SMSOutputByLanguage, 
		EventXDealerList, 
		SMSOutputFileExtension, 
		AltRoadsideEmailMatching, 
		SelectionOutput_NSCFlag, 
		IncSubNationalTerritoryInHierarchy, 
		ContactPreferencesModel, 
		ContactPreferencesPersist, 
		AltRoadsideTelephoneMatching,
		AltSMSOutputFile, 
		FranchiseCountry, 
		FranchiseCountryType, 
		ExcludeEmployeeData,
		UseLatestName,
		AuditRecordType, 
		UpdateDate, 
		UpdateBy
	)
	SELECT
		MarketID, 
		Market, 
		CountryID, 
		DealerTableEquivMarket, 
		PartyMatchingMethodologyID, 
		RegionID, 
		SMSOutputByLanguage, 
		EventXDealerList, 
		SMSOutputFileExtension, 
		AltRoadsideEmailMatching, 
		SelectionOutput_NSCFlag, 
		IncSubNationalTerritoryInHierarchy, 
		ContactPreferencesModel, 
		ContactPreferencesPersist, 
		AltRoadsideTelephoneMatching,
		AltSMSOutputFile, 
		FranchiseCountry, 
		FranchiseCountryType, 
		ExcludeEmployeeData,	
		UseLatestName,
		'INSERTED' AS AuditRecordType, 
		@SysDateTime,
		SYSTEM_USER 				
	FROM INSERTED I




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
