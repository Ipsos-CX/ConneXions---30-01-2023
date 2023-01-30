CREATE TRIGGER [TR_IUD_Franchises]
ON [dbo].[Franchises]
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


	DECLARE @Changed TABLE(ID INT NOT NULL)

	INSERT INTO @Changed
	(
		ID
	)
	SELECT
		I.ID
	FROM INSERTED I
	JOIN DELETED D ON I.ID = D.ID
	WHERE
		HASHBYTES('MD5', CONCAT	
			(	I.[OutletFunctionID], '|' ,  
				I.[OutletFunction], '|' ,  
				I.[OutletPartyID], '|' ,  
				I.[ContactMechanismID], '|' ,  
				I.[ManufacturerPartyID], '|' ,  
				ISNULL(I.[LanguageID],0), '|' ,		-- TASK 579 
				I.[CountryID], '|' ,  
				I.[ImporterPartyID], '|' , 
				I.[ImportAuditItemID], '|' , 
				I.[RDsRegionID], '|' ,  
				I.[BusinessRegionID], '|' ,  
				I.[FranchiseRegionID], '|' ,  
				I.[FranchiseMarketID], '|' , 
				I.[SalesZoneID], '|' ,  
				I.[AuthorisedRepairerZoneID], '|' ,  
				I.[BodyshopZoneID], '|' ,  
				I.[RDsRegion], '|' ,  
				I.[BusinessRegion], '|' ,  
				I.[DistributorCountryCode], '|' ,  
				I.[DistributorCountry], '|' ,  
				I.[DistributorCICode], '|' ,  
				I.[DistributorName], '|' ,  
				I.[FranchiseCountryCode], '|' ,  
				I.[FranchiseCountry], '|' ,  
				I.[JLRNumber], '|' ,  
				I.[RetailerLocality], '|' ,  
				I.[Brand], '|' ,  
				I.[FranchiseCICode], '|' ,  
				I.[FranchiseTradingTitle], '|' ,  
				I.[FranchiseShortName], '|' ,  
				I.[RetailerGroup], '|' ,  
				I.[FranchiseType], '|' ,  
				I.[Address1], '|' ,  
				I.[Address2], '|' ,  
				I.[Address3], '|' ,  
				I.[AddressTown], '|' ,  
				I.[AddressCountyDistrict], '|' ,  
				I.[AddressPostcode], '|' ,  
				I.[AddressLatitude], '|' ,  
				I.[AddressLongitude], '|' ,  
				I.[AddressActivity], '|' ,  
				I.[Telephone], '|' ,  
				I.[Email], '|' ,  
				I.[URL], '|' ,  
				I.[FranchiseStatus], '|' ,  
				I.[FranchiseStartDate], '|' ,  
				I.[FranchiseEndDate], '|' ,  
				I.[LegacyFlag], '|' ,  
				I.[10CharacterCode], '|' ,  
				I.[FleetandBusinessRetailer], '|' ,  
				I.[SVO], '|' ,  
				I.[FranchiseMarket], '|' ,  
				I.[FranchiseMarketNumber], '|' ,  
				I.[FranchiseRegion], '|' ,  
				I.[FranchiseRegionNumber], '|' ,  
				I.[SalesZone], '|' ,  
				I.[SalesZoneCode], '|' ,  
				I.[AuthorisedRepairerZone], '|' ,  
				I.[AuthorisedRepairerZoneCode], '|' ,  
				I.[BodyshopZone], '|' ,  
				I.[BodyshopZoneCode], '|' ,  
				I.[LocalTradingTitle1], '|' ,  
				I.[LocalLanguage1], '|' ,  
				I.[LocalTradingTitle2], '|' ,  
				I.[LocalLanguage2], '|' , 
				I.[ChinaDMSRetailerCode],			-- TASK 578
				I.[ApprovedUser]					-- TASK 751
			)
		)
		<>
		HASHBYTES('MD5', CONCAT	
			(	D.[OutletFunctionID], '|' ,  
				D.[OutletFunction], '|' ,  
				D.[OutletPartyID], '|' ,  
				D.[ContactMechanismID], '|' ,  
				D.[ManufacturerPartyID], '|' ,  
				ISNULL(D.[LanguageID],0), '|' ,		-- TASK 579
				D.[CountryID], '|' ,  
				D.[ImporterPartyID], '|' , 
				D.[ImportAuditItemID], '|' , 
				D.[RDsRegionID], '|' ,  
				D.[BusinessRegionID], '|' ,  
				D.[FranchiseRegionID], '|' , 
				D.[FranchiseMarketID], '|' , 
				D.[SalesZoneID], '|' ,  
				D.[AuthorisedRepairerZoneID], '|' ,  
				D.[BodyshopZoneID], '|' ,  
				D.[RDsRegion], '|' ,  
				D.[BusinessRegion], '|' ,  
				D.[DistributorCountryCode], '|' ,  
				D.[DistributorCountry], '|' ,  
				D.[DistributorCICode], '|' ,  
				D.[DistributorName], '|' ,  
				D.[FranchiseCountryCode], '|' ,  
				D.[FranchiseCountry], '|' ,  
				D.[JLRNumber], '|' ,  
				D.[RetailerLocality], '|' ,  
				D.[Brand], '|' ,  
				D.[FranchiseCICode], '|' ,  
				D.[FranchiseTradingTitle], '|' ,  
				D.[FranchiseShortName], '|' ,  
				D.[RetailerGroup], '|' ,  
				D.[FranchiseType], '|' ,  
				D.[Address1], '|' ,  
				D.[Address2], '|' ,  
				D.[Address3], '|' ,  
				D.[AddressTown], '|' ,  
				D.[AddressCountyDistrict], '|' ,  
				D.[AddressPostcode], '|' ,  
				D.[AddressLatitude], '|' ,  
				D.[AddressLongitude], '|' ,  
				D.[AddressActivity], '|' ,  
				D.[Telephone], '|' ,  
				D.[Email], '|' ,  
				D.[URL], '|' ,  
				D.[FranchiseStatus], '|' ,  
				D.[FranchiseStartDate], '|' ,  
				D.[FranchiseEndDate], '|' ,  
				D.[LegacyFlag], '|' ,  
				D.[10CharacterCode], '|' ,  
				D.[FleetandBusinessRetailer], '|' ,  
				D.[SVO], '|' ,  
				D.[FranchiseMarket], '|' ,  
				D.[FranchiseMarketNumber], '|' ,  
				D.[FranchiseRegion], '|' ,  
				D.[FranchiseRegionNumber], '|' ,  
				D.[SalesZone], '|' ,  
				D.[SalesZoneCode], '|' ,  
				D.[AuthorisedRepairerZone], '|' ,  
				D.[AuthorisedRepairerZoneCode], '|' ,  
				D.[BodyshopZone], '|' ,  
				D.[BodyshopZoneCode], '|' ,  
				D.[LocalTradingTitle1], '|' ,  
				D.[LocalLanguage1], '|' ,  
				D.[LocalTradingTitle2], '|' ,  
				D.[LocalLanguage2], '|' , 
				D.[ChinaDMSRetailerCode],				-- TASK 578
				D.[ApprovedUser]						-- TASK 751

			)
		)


	INSERT INTO dbo.Franchises_History
	(
		[User], 
		[DateStamp], 
		[State],
		[ID], 
		[OutletFunctionID], 
		[OutletFunction], 
		[OutletPartyID], 
		[ContactMechanismID], 
		[ManufacturerPartyID], 
		[LanguageID], 
		[CountryID],
		[ImporterPartyID],
		[ImportAuditItemID],
		[RDsRegionID], 
		[BusinessRegionID], 
		[FranchiseRegionID],
		[FranchiseMarketID],
		[SalesZoneID], 
		[AuthorisedRepairerZoneID], 
		[BodyshopZoneID], 
		[RDsRegion], 
		[BusinessRegion], 
		[DistributorCountryCode], 
		[DistributorCountry], 
		[DistributorCICode], 
		[DistributorName], 
		[FranchiseCountryCode], 
		[FranchiseCountry], 
		[JLRNumber], 
		[RetailerLocality], 
		[Brand], 
		[FranchiseCICode], 
		[FranchiseTradingTitle], 
		[FranchiseShortName], 
		[RetailerGroup], 
		[FranchiseType], 
		[Address1], 
		[Address2], 
		[Address3], 
		[AddressTown], 
		[AddressCountyDistrict], 
		[AddressPostcode], 
		[AddressLatitude], 
		[AddressLongitude], 
		[AddressActivity], 
		[Telephone], 
		[Email], 
		[URL], 
		[FranchiseStatus], 
		[FranchiseStartDate], 
		[FranchiseEndDate], 
		[LegacyFlag], 
		[10CharacterCode], 
		[FleetandBusinessRetailer], 
		[SVO], 
		[FranchiseMarket], 
		[FranchiseMarketNumber], 
		[FranchiseRegion], 
		[FranchiseRegionNumber], 
		[SalesZone], 
		[SalesZoneCode], 
		[AuthorisedRepairerZone], 
		[AuthorisedRepairerZoneCode], 
		[BodyshopZone], 
		[BodyshopZoneCode], 
		[LocalTradingTitle1], 
		[LocalLanguage1], 
		[LocalTradingTitle2], 
		[LocalLanguage2],
		[ChinaDMSRetailerCode],
		[ApprovedUser]					-- TASK 751

	)
	SELECT
		SYSTEM_USER AS 'User', 
		CURRENT_TIMESTAMP AS DateStamp, 
		'Before' AS State, 
		D.[ID], 
		D.[OutletFunctionID], 
		D.[OutletFunction], 
		D.[OutletPartyID], 
		D.[ContactMechanismID], 
		D.[ManufacturerPartyID], 
		D.[LanguageID], 
		D.[CountryID], 
		D.[ImporterPartyID],
		D.[ImportAuditItemID],
		D.[RDsRegionID], 
		D.[BusinessRegionID], 
		D.[FranchiseRegionID],
		D.[FranchiseMarketID],
		D.[SalesZoneID], 
		D.[AuthorisedRepairerZoneID], 
		D.[BodyshopZoneID], 
		D.[RDsRegion], 
		D.[BusinessRegion], 
		D.[DistributorCountryCode], 
		D.[DistributorCountry], 
		D.[DistributorCICode], 
		D.[DistributorName], 
		D.[FranchiseCountryCode], 
		D.[FranchiseCountry], 
		D.[JLRNumber], 
		D.[RetailerLocality], 
		D.[Brand], 
		D.[FranchiseCICode], 
		D.[FranchiseTradingTitle], 
		D.[FranchiseShortName], 
		D.[RetailerGroup], 
		D.[FranchiseType], 
		D.[Address1], 
		D.[Address2], 
		D.[Address3], 
		D.[AddressTown], 
		D.[AddressCountyDistrict], 
		D.[AddressPostcode], 
		D.[AddressLatitude], 
		D.[AddressLongitude], 
		D.[AddressActivity], 
		D.[Telephone], 
		D.[Email], 
		D.[URL], 
		D.[FranchiseStatus], 
		D.[FranchiseStartDate], 
		D.[FranchiseEndDate], 
		D.[LegacyFlag], 
		D.[10CharacterCode], 
		D.[FleetandBusinessRetailer], 
		D.[SVO], 
		D.[FranchiseMarket], 
		D.[FranchiseMarketNumber], 
		D.[FranchiseRegion], 
		D.[FranchiseRegionNumber], 
		D.[SalesZone], 
		D.[SalesZoneCode], 
		D.[AuthorisedRepairerZone], 
		D.[AuthorisedRepairerZoneCode], 
		D.[BodyshopZone], 
		D.[BodyshopZoneCode], 
		D.[LocalTradingTitle1], 
		D.[LocalLanguage1], 
		D.[LocalTradingTitle2], 
		D.[LocalLanguage2],
		D.[ChinaDMSRetailerCode],          -- TASK 578
		D.[ApprovedUser]				-- TASK 751
	FROM DELETED D
		LEFT JOIN @Changed CH ON D.ID = CH.ID
		LEFT JOIN INSERTED I ON D.ID = I.ID
	WHERE CH.ID IS NOT NULL
		OR I.ID IS NULL
	
	UNION
	
	SELECT
		SYSTEM_USER AS 'User', 
		CURRENT_TIMESTAMP AS DateStamp, 
		'After' AS State, 
		I.ID, 
		I.[OutletFunctionID], 
		I.[OutletFunction], 
		I.[OutletPartyID], 
		I.[ContactMechanismID], 
		I.[ManufacturerPartyID], 
		I.[LanguageID], 
		I.[CountryID], 
		I.[ImporterPartyID],
		I.[ImportAuditItemID],
		I.[RDsRegionID], 
		I.[BusinessRegionID], 
		I.[FranchiseRegionID],
		I.[FranchiseMarketID],
		I.[SalesZoneID], 
		I.[AuthorisedRepairerZoneID], 
		I.[BodyshopZoneID], 
		I.[RDsRegion], 
		I.[BusinessRegion], 
		I.[DistributorCountryCode], 
		I.[DistributorCountry], 
		I.[DistributorCICode], 
		I.[DistributorName], 
		I.[FranchiseCountryCode], 
		I.[FranchiseCountry], 
		I.[JLRNumber], 
		I.[RetailerLocality], 
		I.[Brand], 
		I.[FranchiseCICode], 
		I.[FranchiseTradingTitle], 
		I.[FranchiseShortName], 
		I.[RetailerGroup], 
		I.[FranchiseType], 
		I.[Address1], 
		I.[Address2], 
		I.[Address3], 
		I.[AddressTown], 
		I.[AddressCountyDistrict], 
		I.[AddressPostcode], 
		I.[AddressLatitude], 
		I.[AddressLongitude], 
		I.[AddressActivity], 
		I.[Telephone], 
		I.[Email], 
		I.[URL], 
		I.[FranchiseStatus], 
		I.[FranchiseStartDate], 
		I.[FranchiseEndDate], 
		I.[LegacyFlag], 
		I.[10CharacterCode], 
		I.[FleetandBusinessRetailer], 
		I.[SVO], 
		I.[FranchiseMarket], 
		I.[FranchiseMarketNumber], 
		I.[FranchiseRegion], 
		I.[FranchiseRegionNumber], 
		I.[SalesZone], 
		I.[SalesZoneCode], 
		I.[AuthorisedRepairerZone], 
		I.[AuthorisedRepairerZoneCode], 
		I.[BodyshopZone], 
		I.[BodyshopZoneCode], 
		I.[LocalTradingTitle1], 
		I.[LocalLanguage1], 
		I.[LocalTradingTitle2], 
		I.[LocalLanguage2],
		I.[ChinaDMSRetailerCode],			-- TASK 578
		I.[ApprovedUser]					-- TASK 751
	FROM INSERTED I
		LEFT JOIN @Changed CH ON I.ID = CH.ID		
		LEFT JOIN DELETED D ON D.ID = I.ID
	WHERE CH.ID IS NOT NULL
		OR D.ID IS NULL

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
GO


