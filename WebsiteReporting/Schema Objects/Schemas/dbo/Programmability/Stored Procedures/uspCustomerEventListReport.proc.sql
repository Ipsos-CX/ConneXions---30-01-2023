
CREATE PROCEDURE dbo.uspCustomerEventListReport 
@DealerMDXSlice NVARCHAR( 1000 ),
@EventDateFrom SMALLDATETIME,
@EventDateTo SMALLDATETIME

AS
/*
	Purpose:	It will select the data from the CustomerEventList table based on the parameters passed in.
			It accesses the dealer hierarchy remotely to build the party id list for data selection. 
	
	Version			Date			Developer			Comment
	1.0			$(ReleaseDate)		Pardip Mudhar		Created
	1.1				17/04/2012		Attila Kubanda		Bug 6749 had an issue with the SuperNationalRegion level. This has been fixed as it was a typo. Old script: WHEN (D.Manufacturer = LTRIM(RTRIM(DS.Man))) THEN 1	
	1.2				08/05/2012		Pardip Mudhar		BUG 6879 names were supressed which contained . in text.
*/
/*
BEGIN
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
		Dimsn NVARCHAR(100)
		, Hrchy NVARCHAR(100)
		, Man NVARCHAR(100)
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
			LTRIM(RTRIM(REPLACE (REPLACE (SUBSTRING(@DealerMDXSlice, 1, @Pos) ,'[','') ,']','')))
		BEGIN
			UPDATE @SliceOnColumn SET Dimsn = (SELECT RTRIM(LTRIM(Member)) FROM @MemberOnRow WHERE Row_ID = 1)
			UPDATE @SliceOnColumn SET Hrchy = (SELECT RTRIM(LTRIM(Member)) FROM @MemberOnRow WHERE Row_ID = 2)
			UPDATE @SliceOnColumn SET Man = (SELECT RTRIM(LTRIM(Member)) FROM @MemberOnRow WHERE Row_ID = 3)
			UPDATE @SliceOnColumn SET Sup = (SELECT RTRIM(LTRIM(Member)) FROM @MemberOnRow WHERE Row_ID = 4)
			UPDATE @SliceOnColumn SET Ter = (SELECT RTRIM(LTRIM(Member)) FROM @MemberOnRow WHERE Row_ID = 5)
			UPDATE @SliceOnColumn SET Mar = (SELECT RTRIM(LTRIM(Member)) FROM @MemberOnRow WHERE Row_ID = 6)
			UPDATE @SliceOnColumn SET Sub = (SELECT RTRIM(LTRIM(Member)) FROM @MemberOnRow WHERE Row_ID = 7)
			UPDATE @SliceOnColumn SET Del = (SELECT REPLACE(RTRIM(LTRIM(Member)), '.' ,'') FROM @MemberOnRow WHERE Row_ID = 8)

		END

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
				WHEN NULLIF(LTRIM(RTRIM((DS.Man))), '') IS NULL THEN 1
				WHEN (D.Manufacturer = LTRIM(RTRIM(DS.Man))) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(LTRIM(RTRIM((DS.Sup))), '') IS NULL THEN 1
				WHEN (D.SuperNationalRegion = LTRIM(RTRIM(DS.Sup))) THEN 1			--v1.1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(LTRIM(RTRIM((DS.Ter))), '') IS NULL THEN 1
				WHEN (D.Territory = LTRIM(RTRIM(DS.Ter))) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(LTRIM(RTRIM((DS.Mar))), '') IS NULL THEN 1
				WHEN (D.Market = LTRIM(RTRIM(DS.Mar))) THEN 1
				ELSE 0
				END = 1
		)
		AND
		(	
			CASE
				WHEN NULLIF(LTRIM(RTRIM(DS.Sub)), '') IS NULL THEN 1
				WHEN @HierarchyType = 2 AND (D.SalesDealerGroup = LTRIM(RTRIM((DS.Sub)))) THEN 1
				WHEN @HierarchyType = 2 AND (D.AftersalesDealerGroup = LTRIM(RTRIM((DS.Sub)))) THEN 1
				WHEN @HierarchyType = 1 AND (D.SalesSubNationalRegion = LTRIM(RTRIM(DS.Sub))) THEN 1
				WHEN @HierarchyType = 1 AND (D.AftersalesSubNationalRegion = LTRIM(RTRIM(DS.Sub))) THEN 1
				ELSE 0
				END = 1
		)

		AND
		(	
			CASE
				WHEN NULLIF(LTRIM(RTRIM(DS.Del)), '') IS NULL THEN 1
				WHEN (D.SalesOutlet + ' (' + d.SalesOutletCode + ')' = LTRIM(RTRIM(DS.Del))) THEN 1
				WHEN (D.AftersalesOutlet + ' (' + d.AftersalesOutletCode + ')' = LTRIM(RTRIM(DS.Del))) THEN 1
				ELSE 0
				END = 1
		)

		END

	SELECT
		DISTINCT
		cel.TransferPartyID, 
		cel.Market AS Market,
		cel.SuperNationalRegion AS 'Super National Region', 
		cel.SubNationalRegion AS 'Sub National Region',  
		cel.EventTypeDesc AS 'Survey', 
		cel.TransferDealer AS 'Dealer Name', 
		cel.Customer AS 'Customer', 
		cel.RegNo AS 'Reg Plate', 
		cel.VIN AS 'VIN', 
		cel.Model AS 'Model', 
		cel.EventDate 'Event Date', 
		cel.ReceivedDate AS 'Received Date', 
		cel.Selected AS 'Usability'
	FROM
		dbo.CustomerEventList cel
	JOIN @OutletParties op on op.TransferPartyID = cel.TransferPartyID
	WHERE ( cel.EventDate >= @EventDateFrom and cel.EventDate <= @EventDateTo )
	ORDER BY 
		SuperNationalRegion, 
		SubNationalRegion, 
		Market, 
		EventTypeDesc, 
		TransferDealer, 
		Customer


END -- Stored Procedure
*/