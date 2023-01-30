CREATE PROCEDURE [Load].[uspSVOLookup_Insert]

AS

/*
	Purpose: Insert SVO Lookup table
	
	Version		Date			Developer			Comment
	1.1			2021-07-15		Chris Ledger		Task 552: Update SaleType and add PARTION BY Vin to ROW_NUMBER() OVER statement
	1.2			2021-07-21		Chris Ledger		Task 552: Update SaleType (SVO to SV)
	1.3			2021-10-04		Eddie Thomas		Bug 18326: New SaleType 'Core Bespoke'
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	/* JLR ARE UNABLE TO DE-DUPE THE SVO REPORT FILES

		1.	For the Sale Type issue, if two rows in the file for same Vin – 1 row with ‘SV’ and 1 row with ‘SV Bespoke’ then the row with ‘SV Bespoke’ 
			is used and the row with ‘SVO’ is discarded/ignored. 

		2.  For the FeatureID/Featuredesc issue, if two rows in the file for the same Vin, then the first row in the file is used and the second row 
			is discarded/ignored. 
	
	*/

	-- 1. DE-DUPE BY Vin & SaleType; KEEP THE LAST RECORD IN A GROUP THAT HAS BEEN SORTED IN A 'SPECIFIC' ORDER
	SELECT MAX(AuditItemID) AS AuditItemID, 
		LK.Vin 
	INTO #De_Duped_By_SaleType
	FROM (	SELECT  Vin,  
				MAX(RowNum) AS RowNum
			FROM (	SELECT Vin,
						SaleType,
					ROW_NUMBER() OVER (	PARTITION BY Vin 																						-- V1.1 V1.2
										ORDER BY CASE	WHEN SaleType NOT IN ('SV','SV Bespoke','Bespoke','Core Bespoke') THEN 1				-- V1.1, V1.3
														WHEN SaleType ='Bespoke' THEN 2
														WHEN SaleType ='SV' THEN 3 
														WHEN SaleType ='SV Bespoke' THEN 4														-- V1.1 V1.2
														WHEN SaleType ='Core Bespoke' THEN 5	END ASC) AS RowNum								-- V1.3
					FROM  Stage.SVOLookup) T
			GROUP BY Vin) T2 INNER JOIN (	SELECT Vin,
												SaleType,
												ROW_NUMBER() OVER (	PARTITION BY Vin 															-- V1.1
																	ORDER BY CASE	WHEN SaleType NOT IN ('SVO','SV Bespoke','Bespoke','Core Bespoke') THEN 1	-- V1.1 V1.2 V1.3
																					WHEN SaleType ='Bespoke' THEN 2
																					WHEN SaleType ='SVO' THEN 3 
																					WHEN SaleType ='SV Bespoke' THEN 4							-- V1.1 V1.2
																					WHEN SaleType ='Core Bespoke' THEN 5	END ASC) AS RowNum	-- V1.3
											FROM Stage.SVOLookup) T3 ON T2.Vin = T3.Vin 
																		AND T2.RowNum = T3.RowNum
		INNER JOIN Stage.SVOLookup LK ON T3.Vin = LK.Vin 
										AND T3.SaleType = LK.SaleType
	GROUP BY LK.Vin


	-- 2. DE-DUPE RECORDS BY Vin & FeatureID; KEEP THE FIRST RECORD IN A GROUP
	SELECT LK.*
	INTO #De_Duped_By_FeatureID
	FROM Stage.SVOLookup LK
		INNER JOIN (	SELECT MIN(AuditItemID) AS AuditItemID, 
							LK.Vin
						FROM Stage.SVOLookup LK
							INNER JOIN (	SELECT DISTINCT Vin,
												FeatureId
											FROM Stage.SVOLookup) X  ON LK.Vin = X.Vin 
																		AND LK.FeatureId = X.FeatureId
						GROUP BY LK.Vin) X2 ON LK.AuditItemID = X2.AuditItemID


	-- USE DE-DUPPED DATA SETS TO BUILD A SINGLE DE-DUPPED DATA SET
	SELECT LK.Vin, 
		LK.ShortVin, 
		CASE	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.ModelYearDescription
				ELSE B.ModelYearDescription END AS ModelYearDescription,
		CASE	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.ModelDescription
				ELSE B.ModelDescription	END AS ModelDescription,
		CASE	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.ExteriorColourDescription
				ELSE B.ExteriorColourDescription END AS ExteriorColourDescription,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.TrimDescription
				ELSE B.TrimDescription END AS TrimDescription,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.TransmissionDescription
				ELSE B.TransmissionDescription END AS TransmissionDescription,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.TrimPackDescription
				ELSE B.TrimPackDescription END AS TrimPackDescription,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.VistaMarketDesc
				ELSE B.VistaMarketDesc END AS VistaMarketDesc,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.DealerCICode
				ELSE B.DealerCICode END AS DealerCICode,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.PartnerUniqueId
				ELSE B.PartnerUniqueId END AS PartnerUniqueId,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.PartnerUniqueIdDesc
				ELSE B.PartnerUniqueIdDesc END AS PartnerUniqueIdDesc,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.CommonTypeOfSaleDesc
				ELSE B.CommonTypeOfSaleDesc END AS CommonTypeOfSaleDesc,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.CommonOrderNo
				ELSE B.CommonOrderNo END AS CommonOrderNo,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.NscOrderNumber
				ELSE B.NscOrderNumber END AS NscOrderNumber,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.FactoryOrderNumber
				ELSE B.FactoryOrderNumber END AS FactoryOrderNumber,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.CommonStatusPointDesc
				ELSE B.CommonStatusPointDesc END AS CommonStatusPointDesc,
		CASE	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.BuildDate
				ELSE B.BuildDate END AS BuildDate,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.DeliveredDate
				ELSE B.DeliveredDate END AS DeliveredDate,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.CustomerHandoverDate
				ELSE B.CustomerHandoverDate END AS CustomerHandoverDate,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.FeatureId
				ELSE B.FeatureId END AS FeatureId,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.FeatureDesc
				ELSE B.FeatureDesc END AS FeatureDesc,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.SaleType
				ELSE B.SaleType	END AS SaleType,
		CASE 	WHEN A.SaleType <> ISNULL(B.SaleType,'') THEN A.Paint
				ELSE B.Paint END AS Paint		
	INTO #Final_Deduped
	FROM Stage.SVOLookup LK	
		INNER JOIN (	SELECT LK.*
						FROM Stage.SVOLookup LK
							INNER JOIN #De_Duped_By_SaleType ST ON LK.AuditItemID = ST.AuditItemID) A ON LK.AuditItemID = A.AuditItemID	
		INNER JOIN #De_Duped_By_FeatureID B ON A.Vin = B.Vin


	BEGIN TRAN
	
		-- ADD THE NEW ITEMS TO THE LOOKUP 
		INSERT INTO Lookup.SVOLookup
		(
			Vin,
			ShortVin,
			ModelYearDescription,
			ModelDescription,
			ExteriorColourDescription,
			TrimDescription,
			TransmissionDescription,
			TrimPackDescription,
			VistaMarketDesc,
			DealerCICode,
			PartnerUniqueId,
			PartnerUniqueIdDesc,
			CommonTypeOfSaleDesc,
			CommonOrderNo,
			NscOrderNumber,
			FactoryOrderNumber,
			CommonStatusPointDesc,
			BuildDate,
			DeliveredDate,
			CustomerHandoverDate,
			FeatureId,
			FeatureDesc,
			SaleType,
			SVOTypeID,
			Paint
		)
		SELECT DISTINCT
			ST.Vin,
			ST.ShortVin,
			ST.ModelYearDescription,
			ST.ModelDescription,
			ST.ExteriorColourDescription,
			ST.TrimDescription,
			ST.TransmissionDescription,
			ST.TrimPackDescription,
			ST.VistaMarketDesc,
			ST.DealerCICode,
			ST.PartnerUniqueId,
			ST.PartnerUniqueIdDesc,
			ST.CommonTypeOfSaleDesc,
			ST.CommonOrderNo,
			ST.NscOrderNumber,
			ST.FactoryOrderNumber,
			ST.CommonStatusPointDesc,
			ST.BuildDate,
			ST.DeliveredDate,
			ST.CustomerHandoverDate,
			ST.FeatureId,
			ST.FeatureDesc,
			ST.SaleType,
			SVT.SVOTypeID,
			ST.Paint			
		FROM #Final_Deduped ST
		LEFT JOIN Lookup.SVOLookup LK ON ST.Vin = LK.Vin
		LEFT JOIN dbo.SVOTypes SVT ON LTRIM(RTRIM(ST.SaleType)) = SVT.SVODescription									 		
		WHERE LK.Vin IS NULL 
			AND	LEN(ISNULL(ST.Vin,'')) > 0


		-- INSERT INTO Audit.SVOLookupData WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.SVOLookup	
		(
			AuditItemID,
			Vin,
			ShortVin,
			ModelYearDescription,
			ModelDescription,
			ExteriorColourDescription,
			TrimDescription,
			TransmissionDescription,
			TrimPackDescription,
			VistaMarketDesc,
			DealerCICode,
			PartnerUniqueId,
			PartnerUniqueIdDesc,
			CommonTypeOfSaleDesc,
			CommonOrderNo,
			NscOrderNumber,
			FactoryOrderNumber,
			CommonStatusPointDesc,
			BuildDate,
			DeliveredDate,
			CustomerHandoverDate,
			FeatureId,
			FeatureDesc,
			SaleType,
			SVOTypeID,
			Paint
		)
		SELECT DISTINCT
			ST.AuditItemID,
			ST.Vin,
			ST.ShortVin,
			ST.ModelYearDescription,
			ST.ModelDescription,
			ST.ExteriorColourDescription,
			ST.TrimDescription,
			ST.TransmissionDescription,
			ST.TrimPackDescription,
			ST.VistaMarketDesc,
			ST.DealerCICode,
			ST.PartnerUniqueId,
			ST.PartnerUniqueIdDesc,
			ST.CommonTypeOfSaleDesc,
			ST.CommonOrderNo,
			ST.NscOrderNumber,
			ST.FactoryOrderNumber,
			ST.CommonStatusPointDesc,
			ST.BuildDate,
			ST.DeliveredDate,
			ST.CustomerHandoverDate,
			ST.FeatureId,
			ST.FeatureDesc,
			ST.SaleType,
			SVT.SVOTypeID,
			ST.Paint			 	 
		FROM Stage.SVOLookup ST
		LEFT JOIN [$(AuditDB)].Audit.SVOLookup AUD ON ST.Vin = AUD.Vin
		LEFT JOIN dbo.SVOTypes SVT ON LTRIM(RTRIM(ST.SaleType)) = SVT.SVODescription
		WHERE AUD.AuditItemID IS NULL 
			AND LEN(ISNULL(ST.Vin,'')) > 0

	COMMIT TRAN

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