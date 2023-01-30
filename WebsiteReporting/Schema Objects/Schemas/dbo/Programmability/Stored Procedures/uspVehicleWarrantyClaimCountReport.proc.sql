CREATE PROCEDURE [dbo].[uspVehicleWarrantyClaimCountReport]
(
	@ManagerDealerRole INT,
	@DealerMDXSlice NVARCHAR(1000)
)
AS

/*

	Purpose:	Gets the Vehicle Warranty Claim Counts for a given level within the dealer hierarchy

	Version		Developer		Date		Comment
	1.0			Simon Peacock	$(ReleaseDate)	Created
	1.1			Attila Kubanda	18/04/2012	BUG 6706 - The script was connecting to a dealer table that doesn't exist in the production environment. The script has been altered to find the correct dealer to show the dealership where the last visit took place.
	1.2			Pardip Mudhar	08/05/2012	BUG 6879 - Name was suppressed when it contained .
*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

/*
	DECLARE @ManagerDealerRole INT

	DECLARE @DealerMDXSlice NVARCHAR(1000)

	SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover]'
	SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[Europe]'
	SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom]'
	SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified]'
	SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified].[UK]'
	SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified].[UK].[Region 8]'
	SET @DealerMDXSlice = N'[Dealers].[Dealers].[Land Rover].[United Kingdom].[Unspecified].[UK].[Region 8].[Westover Land Rover, Dorset (A6443)]'

	SET @ManagerDealerRole = 0
*/

	DECLARE @HierarchyType TINYINT
	DECLARE @OutletParties TABLE 			
	(
		  TransferPartyID BIGINT PRIMARY KEY
		, ManufacturerPartyID INT
	)
	DECLARE @Pos INT
	DECLARE	@MemberOnRow TABLE
	(
		Row_ID INT IDENTITY (1,1) PRIMARY KEY, 
		Member NVARCHAR(500)
	)

	DECLARE	@SliceOnColumn TABLE	
	(
		Dimsn NVARCHAR(10)
		, Hrchy NVARCHAR(15)
		, Man NVARCHAR(15)
		, Sup NVARCHAR(100)
		, Ter NVARCHAR(100)
		, Mar NVARCHAR(100)
		, Sub NVARCHAR(100)
		, Del NVARCHAR(100)
	)


	SET @HierarchyType = CASE WHEN PATINDEX('%DealerGroups%', @DealerMDXSlice) > 1 THEN 2 ELSE 1 END
		
		
	IF @DealerMDXSlice != ''
	BEGIN
		/********** REPLACE '.' WITH ',  ' SO WE CAN REMOVE PERIODS IN THE DEALER NAME **********/
		SET @DealerMDXSlice = REPLACE(@DealerMDXSlice,'].[','],  [')

		-- PRIME SLICE TABLE
		INSERT INTO @SliceOnColumn VALUES ('', '', '', '', '', '', '', '')

		SELECT @Pos = CHARINDEX(', ', @DealerMDXSlice)

		INSERT INTO @MemberOnRow
		(
			Member
		)
		SELECT	
			REPLACE (REPLACE (SUBSTRING(@DealerMDXSlice, 1, @Pos - 1) ,'[','') ,']','')

		WHILE @Pos > 0
		BEGIN
			SELECT @DealerMDXSlice = SUBSTRING(@DealerMDXSlice, @Pos + 1, LEN(@DealerMDXSlice))
			SELECT @Pos = CHARINDEX(',  ', @DealerMDXSlice)

			IF @Pos > 0
			BEGIN
				INSERT INTO @MemberOnRow
				SELECT
					REPLACE (REPLACE (SUBSTRING(@DealerMDXSlice, 1, @pos - 1) ,'[','')
										,']','')
			END -- if @pos
		END -- while @pos
		
		

		SELECT @Pos = CHARINDEX(']', @DealerMDXSlice)

		INSERT INTO @MemberOnRow
		(
			Member
		)
		SELECT	
			REPLACE (REPLACE (SUBSTRING(@DealerMDXSlice, 1, @Pos) ,'[','') ,']','')
		BEGIN
			UPDATE @SliceOnColumn SET Dimsn = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 1)
			UPDATE @SliceOnColumn SET Hrchy = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 2)
			UPDATE @SliceOnColumn SET Man = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 3)
			UPDATE @SliceOnColumn SET Sup = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 4)
			UPDATE @SliceOnColumn SET Ter = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 5)
			UPDATE @SliceOnColumn SET Mar = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 6)
			UPDATE @SliceOnColumn SET Sub = (SELECT LTRIM(Member) FROM @MemberOnRow WHERE Row_ID = 7)
			UPDATE @SliceOnColumn SET Del = (SELECT REPLACE(LTRIM(Member), '.' ,'') FROM @MemberOnRow WHERE Row_ID = 8)

		END
		
/*		
		INSERT INTO @OutletParties 
		(
			TransferPartyID, 
			ManufacturerPartyID 
		)
		SELECT DISTINCT
			TransferPartyID,
			CASE Manufacturer
				WHEN 'Jaguar' THEN 2
				WHEN 'Land Rover' THEN 3
			END
		FROM [NUEW-SQUKCXP02].[CNX_JLR_TransactionRepository].dbo.LU_DealerHierarchy D
		INNER JOIN @SliceOnColumn DS ON 
		(	
			CASE
				WHEN NULLIF(DS.Man, '') IS NULL THEN 1
				WHEN (D.Manufacturer = DS.Man) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Sup, '') IS NULL THEN 1
				WHEN (D.SuperNationalRegion = DS.Sup) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Ter, '') IS NULL THEN 1
				WHEN (D.Territory = DS.Ter) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Mar, '') IS NULL THEN 1
				WHEN (D.Market = DS.Mar) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Sub, '') IS NULL THEN 1
				WHEN @HierarchyType = 2 AND (D.SalesDealerGroup = DS.Sub) THEN 1
				WHEN @HierarchyType = 2 AND (D.AftersalesDealerGroup = DS.Sub) THEN 1
				WHEN @HierarchyType = 1 AND (D.SalesSubNationalRegion = DS.Sub) THEN 1
				WHEN @HierarchyType = 1 AND (D.AftersalesSubNationalRegion = DS.Sub) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(DS.Del, '') IS NULL THEN 1
				WHEN (D.SalesOutlet + ' (' + d.SalesOutletCode + ')' = DS.Del) THEN 1
				WHEN (D.AftersalesOutlet + ' (' + d.AftersalesOutletCode + ')' = DS.Del) THEN 1
				ELSE 0
				END = 1
		)
*/
	END

	-- Manager level
	IF @ManagerDealerRole = 1
	BEGIN
		SELECT DISTINCT
			VWCC.CustomerName,
			LTRIM(RTRIM(D.TransferDealer)) AS DealerLastVisited,
			VWCC.VIN,
			VWCC.ReportingModel AS Model,
			VWCC.SalesDate,
			VWCC.LastWarrantyVisit AS LastWarrantyVisitDate,
			ISNULL(VWCC.AllVisitsLastSixMonths, 0) AS AllVisitsLastSixMonths,
			ISNULL(VWCC.TotalVisits, 0) AS TotalVisitsAnyDealer
		FROM dbo.VehicleWarrantyClaimCount VWCC
		INNER JOIN @OutletParties OP ON VWCC.DealerPartyID = OP.TransferPartyID
		LEFT JOIN [Sample].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = OP.TransferPartyID
														AND D.ManufacturerPartyID = OP.ManufacturerPartyID
		WHERE VWCC.LastWarrantyVisit between getdate() - 180 and getdate() 
		AND ISNULL(VWCC.AllVisitsLastSixMonths, 0) > 1
		ORDER BY ISNULL(AllVisitsLastSixMonths, 0) DESC, ISNULL(TotalVisits, 0) DESC
	END 
	ELSE
	BEGIN
	-- Dealer
		SELECT DISTINCT
			CustomerName,
			VIN,
			ReportingModel AS Model,
			SalesDate,
			LastWarrantyVisit AS LastWarrantyVisitDate,
			ISNULL(DealerVisitsLastSixMonths, 0) AS DealerVisitsLastSixMonths,
			ISNULL(AllVisitsLastSixMonths, 0) AS AllVisitsLastSixMonths,
			ISNULL(TotalVisits, 0) AS TotalVisitsAnyDealer
		FROM dbo.VehicleWarrantyClaimCount VWCC
		INNER JOIN @OutletParties OP ON VWCC.DealerPartyID = OP.TransferPartyID
		LEFT JOIN [Sample].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = OP.TransferPartyID
														AND D.ManufacturerPartyID = OP.ManufacturerPartyID
		WHERE ISNULL(VWCC.DealerVisitsLastSixMonths,0) > 1
		ORDER BY ISNULL(DealerVisitsLastSixMonths, 0) DESC, ISNULL(AllVisitsLastSixMonths, 0) DESC, ISNULL(TotalVisits, 0) DESC
	END


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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

GO


