CREATE TRIGGER dbo.TR_IUD_DW_JLRCSPDealers
ON dbo.DW_JLRCSPDealers
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


	DECLARE @Changed TABLE(id INT NOT NULL)

	INSERT INTO @Changed
	(
		id
	)
	SELECT
		I.id
	FROM INSERTED I
		JOIN DELETED D ON I.id = D.id
	WHERE
		BINARY_CHECKSUM	
		(
			I.Manufacturer, 
			I.SuperNationalRegion, 
			I.BusinessRegion,
			I.Market, 
			I.SubNationalTerritory, 
			I.SubNationalRegion, 
			I.CombinedDealer, 
			I.CombinedDealerCode, 
			I.TransferDealer, 
			I.TransferDealerCode, 
			I.Outlet, 
			I.OutletCode, 
			I.OutletFunction, 
			I.ManufacturerPartyID, 
			I.SuperNationalRegionPartyID, 
			I.MarketPartyID, 
			I.SubNationalRegionPartyID, 
			I.CombinedDealerPartyID, 
			I.TransferPartyID, 
			I.OutletPartyID, 
			I.OutletLevelReport, 
			I.OutletLevelWeb, 
			I.OutletSiteCode,
			I.FromDate, 
			I.ThroughDate,
			I.TransferDealerCode_GDD,
			I.OutletCode_GDD,
			I.PAGCode,
			I.PAGName,
			I.BilingualSelectionOutput,		-- 2017-10-27 BUG 14245
			I.SVODealer,					-- 2017-11-11 BUG 14365
			I.FleetDealer,					-- 2017-11-11 BUG 14365
			I.InterCompanyOwnUseDealer,		-- 2017-11-17 BUG 14347
			I.Dealer10DigitCode,			-- 2020-01-17 BUG 16793	
			I.ChinaDMSRetailerCode,         -- TASK 578
			I.ReportingRetailerName,		-- TASK 643
			I.ApprovedUser					-- TASK 751
		)
		<>
		BINARY_CHECKSUM
		(
			D.Manufacturer, 
			D.SuperNationalRegion, 
			D.BusinessRegion,
			D.Market, 
			D.SubNationalTerritory, 
			D.SubNationalRegion, 
			D.CombinedDealer, 
			D.CombinedDealerCode, 
			D.TransferDealer, 
			D.TransferDealerCode, 
			D.Outlet, 
			D.OutletCode, 
			D.OutletFunction, 
			D.ManufacturerPartyID, 
			D.SuperNationalRegionPartyID, 
			D.MarketPartyID, 
			D.SubNationalRegionPartyID, 
			D.CombinedDealerPartyID, 
			D.TransferPartyID, 
			D.OutletPartyID, 
			D.OutletLevelReport, 
			D.OutletLevelWeb, 
			D.OutletSiteCode,
			D.FromDate, 
			D.ThroughDate,
			D.TransferDealerCode_GDD,
			D.OutletCode_GDD,
			D.PAGCode,
			D.PAGName,
			D.BilingualSelectionOutput,	-- 2017-10-08 BUG 14245
			D.SVODealer,				-- 2017-11-11 BUG 14365
			D.FleetDealer,				-- 2017-11-11 BUG 14365
			D.InterCompanyOwnUseDealer,	-- 2017-11-17 BUG 14347
			D.Dealer10DigitCode,		-- 2020-01-17 BUG 16793	
			D.ChinaDMSRetailerCode,     -- TASK 578
			D.ReportingRetailerName,    -- TASK 643
			D.ApprovedUser				-- TASK 751
		)


	INSERT INTO dbo.DW_JLRCSPDealers_History
	(
		[User], 
		DateStamp, 
		State, 
		id, 
		Manufacturer, 
		SuperNationalRegion, 
		BusinessRegion,
		Market, 
		SubNationalTerritory, 
		SubNationalRegion, 
		CombinedDealer, 
		CombinedDealerCode, 
		TransferDealer, 
		TransferDealerCode, 
		Outlet, 
		OutletCode, 
		OutletFunction, 
		ManufacturerPartyID, 
		SuperNationalRegionPartyID, 
		MarketPartyID, 
		SubNationalRegionPartyID, 
		CombinedDealerPartyID, 
		TransferPartyID, 
		OutletPartyID, 
		OutletLevelReport, 
		OutletLevelWeb, 
		OutletFunctionID, 
		OutletSiteCode,
		FromDate, 
		ThroughDate,
		TransferDealerCode_GDD,
		OutletCode_GDD,
		PAGCode,
		PAGName,
		BilingualSelectionOutput,	-- 2017-10-08 BUG 14245
		SVODealer,					-- 2017-11-11 BUG 14365
		FleetDealer,				-- 2017-11-11 BUG 14365
		InterCompanyOwnUseDealer,	-- 2017-11-17 BUG 14347
		Dealer10DigitCode,			-- 2020-01-17 BUG 16793	
		ChinaDMSRetailerCode,       -- TASK 578
		ReportingRetailerName,      -- TASK 643
		ApprovedUser				-- TASK 751
	)
	SELECT
		SYSTEM_USER AS 'User', 
		CURRENT_TIMESTAMP AS DateStamp, 
		'Before' AS State, 
		D.id, 
		D.Manufacturer, 
		D.SuperNationalRegion, 
		D.BusinessRegion,
		D.Market, 
		D.SubNationalTerritory, 
		D.SubNationalRegion, 
		D.CombinedDealer, 
		D.CombinedDealerCode, 
		D.TransferDealer, 
		D.TransferDealerCode, 
		D.Outlet, 
		D.OutletCode, 
		D.OutletFunction, 
		D.ManufacturerPartyID, 
		D.SuperNationalRegionPartyID, 
		D.MarketPartyID, 
		D.SubNationalRegionPartyID, 
		D.CombinedDealerPartyID, 
		D.TransferPartyID, 
		D.OutletPartyID, 
		D.OutletLevelReport, 
		D.OutletLevelWeb, 
		D.OutletFunctionID, 
		D.OutletSiteCode,
		D.FromDate, 
		D.ThroughDate,
		D.TransferDealerCode_GDD,
		D.OutletCode_GDD,
		D.PAGCode,
		D.PAGName,
		D.BilingualSelectionOutput,	-- 2017-10-27 BUG 14245
		D.SVODealer,				-- 2017-11-11 BUG 14365
		D.FleetDealer,				-- 2017-11-11 BUG 14365		
		D.InterCompanyOwnUseDealer,	-- 2017-11-17 BUG 14347
		D.Dealer10DigitCode,		-- 2020-01-17 BUG 16793	
		D.ChinaDMSRetailerCode,     -- TASK 578
		D.ReportingRetailerName,    -- TASK 643
		D.ApprovedUser				-- TASK 751
	FROM DELETED D
		LEFT JOIN @changed CH ON D.id = CH.id
		LEFT JOIN INSERTED I ON D.id = I.id
	WHERE CH.id IS NOT NULL
		OR I.id IS NULL
	
	UNION
	
	SELECT
		SYSTEM_USER AS 'User', 
		CURRENT_TIMESTAMP AS DateStamp, 
		'After' AS State, 
		I.id, 
		I.Manufacturer, 
		I.SuperNationalRegion, 
		I.BusinessRegion,
		I.Market, 
		I.SubNationalTerritory, 
		I.SubNationalRegion, 
		I.CombinedDealer, 
		I.CombinedDealerCode, 
		I.TransferDealer, 
		I.TransferDealerCode, 
		I.Outlet, 
		I.OutletCode, 
		I.OutletFunction, 
		I.ManufacturerPartyID, 
		I.SuperNationalRegionPartyID, 
		I.MarketPartyID, 
		I.SubNationalRegionPartyID, 
		I.CombinedDealerPartyID, 
		I.TransferPartyID, 
		I.OutletPartyID, 
		I.OutletLevelReport, 
		I.OutletLevelWeb, 
		I.OutletFunctionID, 
		I.OutletSiteCode,
		I.FromDate, 
		I.ThroughDate,
		I.TransferDealerCode_GDD,
		I.OutletCode_GDD,
		I.PAGCode,
		I.PAGName,
		I.BilingualSelectionOutput,		-- 2017-10-27 BUG 14245
		I.SVODealer,					-- 2017-11-11 BUG 14365
		I.FleetDealer,					-- 2017-11-11 BUG 14365
		I.InterCompanyOwnUseDealer,		-- 2017-11-17 BUG 14347
		I.Dealer10DigitCode,		    -- 2020-01-17 BUG 16793	
		I.ChinaDMSRetailerCode,         -- TASK 578
		I.ReportingRetailerName,        -- TASK 643
		I.ApprovedUser					-- TASK 751
	FROM INSERTED I
		LEFT JOIN @changed CH ON I.id = CH.id		
		LEFT JOIN DELETED D ON D.id = I.id
	WHERE CH.id IS NOT NULL
		OR D.id IS NULL





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
