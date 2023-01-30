CREATE PROCEDURE [dbo].[uspChinaVINsReport]

AS
/*	
		Version			Date			Developer			Comment
LIVE	1.0				2021-03-16		Ben King			BUG 18109 - China VINs Report
LIVE	1.1				2021-07-14		Ben King			Task 519
LIVE	1.2				2021-08-04		Eddie Thomas		BUG 18304 - Add SVO status & Fix Align model description with Selection output
LIVE	1.3             2021-10-20      Ben King            TASK 665 - 18374 - Changes to China VIN decoding
LIVE	1.4				2021-12-06		Eddie homas			BUG 18406 - UPDATED VIN matching string 85
LIVE	1.5				2022-03-17		Ben King			TASK 824 - Incoming Feed China VINs change
LIVE	1.6				2022-09-26		Edde Thomas			TASK 1017 - Add sub brand
*/


SET NOCOUNT ON

		DECLARE @ErrorNumber INT
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ErrorLocation NVARCHAR(500)
		DECLARE @ErrorLine INT
		DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
		
	INSERT INTO [dbo].[ChinaVINsReport] (VIN, AuditID, AuditItemID, VehicleParentAuditItemID)
	SELECT DISTINCT -- V1.5
			C.VIN,
			C.AuditID,
			C.AuditItemID,
			C.VehicleParentAuditItemID
	FROM [$(ETLDB)].[Stage].[Chinese_VINs] C


	-- V1.5
	UPDATE CV
	SET CV.ModelID = MVM.ModelID,
		CV.ModelVariantID = MVM.ModelVariantID			
	FROM [dbo].[ChinaVINsReport] CV
		INNER JOIN [$(SampleDB)].Vehicle.VehicleMatchingStrings VMS ON CV.VIN LIKE VMS.VehicleMatchingString
		INNER JOIN [$(SampleDB)].Vehicle.ModelVariantMatching MVM ON VMS.VehicleMatchingStringID = MVM.VehicleMatchingStringID			-- V1.10
	WHERE (LEN(ISNULL(CV.ModelID,'')) = 0 OR CV.ModelID = 7) 
	AND VMS.VehicleMatchingStringTypeID = 1 
	AND LEN(REPLACE(CV.VIN, ' ', '')) = 12 
	AND CV.ReportDate IS NULL



	-- V1.5
	UPDATE C
	SET	C.VIN = C.VIN + '+++++'
	FROM [dbo].[ChinaVINsReport] C
	WHERE LTRIM(RTRIM(LEN(C.VIN))) = 12
	AND C.ReportDate IS NULL


	-- V1.5
	UPDATE CV
		SET CV.AlreadyLoaded = CASE 
									WHEN LEN(V.VIN) > 0 
									THEN 1 ELSE 0 
								END
	FROM [dbo].[ChinaVINsReport] CV
	LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON LTRIM(RTRIM(CV.VIN)) = V.VIN


	-- V1.5
	IF EXISTS 
			(
				SELECT *
				FROM [dbo].[ChinaVINsReport] 
				WHERE AlreadyLoaded = 0
				AND ReportDate IS NULL
			)

	BEGIN 

		-- V1.5 (INSERT INTO Vehicles tables)
		CREATE TABLE #NewVehicles 
			(
				ID INT IDENTITY(1, 1), 
				VehicleID BIGINT,
				ModelID SMALLINT,
				ModelVariantID SMALLINT,				
				VIN NVARCHAR(50),
				BuildDateOrig VARCHAR(20),
				BuildYear SMALLINT,
				AuditItemID BIGINT,
				VehicleIdentificationNumberUsable BIT
			)


			-- GET NEW VEHICLE RECS FROM VWT
			INSERT #NewVehicles
			(
				ModelID,
				ModelVariantID,
				VIN,
				BuildDateOrig,
				BuildYear,
				AuditItemID,
				VehicleIdentificationNumberUsable
			)
			SELECT DISTINCT 
				V.ModelID,
				V.ModelVariantID,
				V.VIN,
				NULL AS BuildDateOrig,
				NULL AS BuildYear,
				V.AuditItemID,
				0 AS VehicleIdentificationNumberUsable
			FROM [dbo].[ChinaVINsReport] V
			WHERE AlreadyLoaded = 0
			AND	LEN(ISNULL(V.VIN,'')) = 17
			AND V.AuditItemID = V.VehicleParentAuditItemID
			AND V.ReportDate IS NULL


			-- GENERATE NEW VEHCILEIDS
			DECLARE @Max_VehicleID BIGINT
			SELECT @Max_VehicleID = MAX(VehicleID) FROM [$(SampleDB)].Vehicle.Vehicles
	

			UPDATE #NewVehicles
			SET VehicleID = ID + @Max_VehicleID

	
			-- INSERT THE NEW VEHICLES INTO THE VEHICLES TABLE
			INSERT INTO [$(SampleDB)].Vehicle.Vehicles 
			(
				VehicleID, 
				ModelID,
				ModelVariantID,
				VIN, 
				VehicleIdentificationNumberUsable
			)
			SELECT	
				VehicleID, 
				ModelID,
				ModelVariantID,
				VIN, 
				VehicleIdentificationNumberUsable
			FROM #NewVehicles


			-- UPDATE FOBCODE
			EXEC [$(SampleDB)].Vehicle.uspUpdateVehicleFOBCode


			-- UPDATE SVOTYPEID
			EXEC [$(ETLDB)].Load.uspFlagSVOvehicles


			-- V1.1 UPDATE MODEL YEAR
			EXEC [$(SampleDB)].Vehicle.uspUpdateVehicleBuildYear


			-- V1.1 UPDATE MODELVARIANTID BY MODEL YEAR
			EXEC [$(SampleDB)].Vehicle.uspUpdateVehicleModelVariantIDByModelYear


				INSERT INTO [$(AuditDB)].Audit.Vehicles 
				(
					AuditItemID,
					VehicleID,
					ModelID,
					ModelVariantID,							
					VIN, 
					VehicleIdentificationNumberUsable,
					BuildDateOrig, 
					BuildYear, 
					ThroughDate, 
					ModelDescription,
					BodyStyleDescription,
					EngineDescription,
					TransmissionDescription
				)
				SELECT	
					I.AuditItemID,
					NULLIF(NV.VehicleID, 0) AS VehicleID,	
					I.ModelID,
					V.ModelVariantID,						
					I.VIN, 
					0 AS VehicleIdentificationNumberUsable,
					NULL AS BuildDateOrig, 
					V.BuildYear,							
					NULL AS ThroughDate, 
					NULL AS ModelDescription,
					NULL AS BodyStyleDescription,
					NULL AS EngineDescription,
					NULL AS TransmissionDescription
				FROM [dbo].[ChinaVINsReport] I
					LEFT JOIN #NewVehicles NV ON I.VehicleParentAuditItemID = NV.AuditItemID													-- V1.1
					LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON NULLIF(NV.VehicleID, 0) = V.VehicleID		-- V1.1
					LEFT JOIN [$(AuditDB)].Audit.Vehicles AV ON AV.AuditItemID = I.AuditItemID
				WHERE AV.AuditItemID IS NULL
				AND I.ReportDate IS NULL
				AND NV.VehicleID IS NOT NULL


	END
		
		--UPDATE --build year, modelVariantID, svoTypeid, fobcode
		UPDATE C
		SET C.ModelYear = V.BuildYear,
			C.ModelVariantID = V.ModelVariantID
		--SELECT v.*, c.*
		FROM [dbo].[ChinaVINsReport] C
		INNER JOIN [$(SampleDB)].Vehicle.Vehicles v on c.VIN = v.VIN
		WHERE ReportDate IS NULL



	--SET THE DESCRIPTIONS
	UPDATE C
	SET C.ModelDescription = M.ModelDescription, 
		C.Variant = MV.Variant
	FROM [dbo].[ChinaVINsReport] C
	LEFT JOIN [$(SampleDB)].Vehicle.Models M ON C.ModelID = M.ModelID
	LEFT JOIN [$(SampleDB)].Vehicle.ModelVariants MV ON C.ModelVariantID = MV.VariantID
	WHERE C.ReportDate IS NULL

	

	--V1.2 UPDATE MODEL DESCRIPTION BEFORE MODELID
	--REMOVED V 1.5
	--UPDATE  C
	--SET		ModelDescription =
	--				CASE  --V1.2
	--					WHEN BR.Brand = 'Jaguar' THEN BR.Brand + N' ' + M.ModelDescription --V1.2
	--					WHEN M.ModelDescription = 'New Range Rover' THEN 'Range Rover' --V1.2
	--					ELSE M.ModelDescription  --V1.2
	--				END --V1.2
	--FROM [dbo].[ChinaVINsReport] C
	--INNER JOIN [$(SampleDB)].Vehicle.Models M ON C.ModelID = M.ModelID
	--INNER JOIN [$(SampleDB)].dbo.Brands BR ON M.ManufacturerPartyID = BR.ManufacturerPartyID
	--WHERE C.ReportDate IS NULL


	--V1.1
	UPDATE		c
	SET			c.EV_FLAG = 'BEV'
	FROM		[dbo].[ChinaVINsReport]	c
	
	INNER JOIN	[$(SampleDB)].Vehicle.PHEVModels	ph ON c.ModelID =	ph.ModelID	
	WHERE		(LEFT(c.VIN,4)				= ph.VINPrefix) AND 
				(SUBSTRING(c.VIN, 8, 1)	= ph.VINCharacter) AND 
				(ph.EngineDescription Like '%BEV%') AND
				(c.ModelID <> 'Uncoded') AND
				(c.ReportDate IS NULL)		--V1.2
	
	
	UPDATE		c
	SET			c.EV_FLAG = 'PHEV'
	FROM		[dbo].[ChinaVINsReport]	c
	
	INNER JOIN	[$(SampleDB)].Vehicle.PHEVModels	ph ON c.ModelID =	ph.ModelID	
	WHERE		(LEFT(c.VIN,4)				= ph.VINPrefix) AND 
				(SUBSTRING(c.VIN, 8, 1)	= ph.VINCharacter) AND 
				(ph.EngineDescription Like '%PHEV%') AND 
				(LEN(ISNULL(c.EV_FLAG,'' )) = 0) AND
				(c.ModelID <> 'Uncoded') AND
				(c.ReportDate IS NULL)		--V1.2


	------------------------------------------------
	-- V1.2 SVO
	------------------------------------------------
	UPDATE		C
	SET			SVOType = ISNULL(SVT.SVOTypeID, 0)
	FROM		[dbo].[ChinaVINsReport]	C
	INNER JOIN	[$(ETLDB)].Lookup.SVOLookup LK ON LEFT(C.VIN, 12) = LEFT(LK.Vin, 12) --V1.3
	LEFT JOIN	[$(ETLDB)].dbo.SVOTypes		SVT ON LTRIM(RTRIM(LK.SaleType)) = SVT.SVODescription
	WHERE		C.ReportDate IS NULL


	--V1.2 - BUILD MODELCODE LOOKUP, BASED ON UK QUESTIONNAIRE VEHICLES
	;With ModelCodesLookup_CTE (ModelCode, ModelID, ModelDescription) 
	AS
	(
		SELECT			RM.RequirementID AS [ModelCode], M.ModelID, 
						CASE 
							WHEN ModelDescription = 'New Range Rover' THEN 'Range Rover'
							ELSE ModelDescription
						END AS ModelDescription
		FROM			[$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM
						INNER JOIN [$(SampleDB)].Requirement.Requirements R ON SM.QuestionnaireRequirementID = R.RequirementID
						INNER JOIN [$(SampleDB)].Requirement.QuestionnaireModelRequirements QMR ON SM.QuestionnaireRequirementID = QMR.RequirementIDPartOf
						INNER JOIN [$(SampleDB)].Requirement.ModelRequirements MR ON MR.RequirementID = QMR.RequirementIDMadeUpOf
						INNER JOIN [$(SampleDB)].Requirement.Requirements RM ON MR.RequirementID = RM.RequirementID
						INNER JOIN [$(SampleDB)].Vehicle.Models M ON MR.ModelID = M.ModelID
						INNER JOIN [$(SampleDB)].dbo.Brands B ON M.ManufacturerPartyID = B.ManufacturerPartyID
		WHERE			SM.SampleLoadActive = 1 AND
						SM.Questionnaire IN ('Sales', 'Service') AND
						SM.Market ='United Kingdom'	
						
		UNION
		--	UNKOWN MODELS BY MANUFACTURER
		SELECT			rq.RequirementID AS ModelCode, 
						md.ModelID, rq.Requirement As ModelDescription
		FROM			[$(SampleDB)].Requirement.ModelRequirements	mr
		INNER JOIN		[$(SampleDB)].Vehicle.Models					md ON mr.ModelID		= md.ModelID
		INNER JOIN		[$(SampleDB)].Requirement.Requirements			rq ON mr.RequirementID	= rq.RequirementID
		WHERE			md.ModelDescription = 'Unknown Vehicle'
	)
	UPDATE		c
	SET			[ModelCode] =  CASE 
									WHEN CTE.ModelCode IS NULL THEN 'Uncoded'
									ELSE CAST(CTE.ModelCode AS VARCHAR)
								END
	FROM		[dbo].[ChinaVINsReport]					c
	LEFT JOIN	ModelCodesLookup_CTE					CTE ON c.ModelID = CTE.ModelID
	WHERE		c.ReportDate IS NULL


	--V1.2 UPDATE MODELID ; ATTEMPTING TO DO MODEL DESCRIPTION & MODELID  AT SAME TIME INTRODUCES BLANK MODELID'S
	UPDATE  C
	SET C.ModelID = 
				   CASE
						WHEN C.ModelDescription IS NULL THEN 'Uncoded'
						ELSE C.ModelID
					END
	FROM [dbo].[ChinaVINsReport] C
	INNER JOIN [$(SampleDB)].Vehicle.Models M ON C.ModelID = M.ModelID
	WHERE C.ReportDate IS NULL


	--V1.5 ADD SUBBRAND INFORMATION
	UPDATE		C
	SET			SubBrand = SB.SubBrand
	FROM		[dbo].[ChinaVINsReport] C
	INNER JOIN  [$(SampleDB)].Vehicle.Models		MD ON C.ModelID = MD.ModelID
	INNER JOIN  [$(SampleDB)].Vehicle.SubBrands		SB ON MD.SubBrandID = SB.SubBrandID
	WHERE		C.ReportDate IS NULL
	
	--V1.2 FINALLY UPDATE REPORT DATE FLAG LOADED FROM CURRENT FILE
	UPDATE		[dbo].[ChinaVINsReport]
	SET			ReportDate= GETDATE()
	WHERE		ReportDate IS NULL




		

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
