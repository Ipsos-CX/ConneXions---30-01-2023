CREATE PROCEDURE [SelectionOutput].[uspAuditChinaCRCWithResponsesOutput]
@FileName VARCHAR (255)
AS
SET NOCOUNT ON


---------------------------------------------------------------------------------------------------
--	
--	Change History...
--	
--	Date					Author					Version		Description
--  ----					------					-------		-----------
--	13-03-2018				Eddie Thomas			1.0			Orginal version

---------------------------------------------------------------------------------------------------

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		-- CREATE A TEMP TABLE TO HOLD EACH TYPE OF OUTPUT
		CREATE TABLE #OutputtedSelections
		(
			PhysicalRowID INT IDENTITY(1,1) NOT NULL,
			AuditID INT NULL,
			AuditItemID INT NULL,
			CaseID INT NULL,
			PartyID INT NULL,
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, PartyID, CaseOutputTypeID)
		SELECT DISTINCT
			O.[ID] AS CaseID, 
			O.PartyID,
			CASE SUBSTRING(O.ITYPE,1,1)			--v1.1
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'SMS')		--v1.1
				ELSE (SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
		INNER JOIN Sample_ETL.China.CRC_WithResponses CSE ON O.ID = CSE.CaseID 	

		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
			INSERT INTO [$(AuditDB)].Audit.SelectionOutput
			(
				[AuditID], 
				[AuditItemID], 
				[SelectionOutputTypeID], 
				[PartyID], 
				[CaseID], 
				[FullModel], 
				[Model], 
				[sType], 
				[CarReg], 
				[Title], 
				[Initial], 
				[Surname], 
				[Fullname], 
				[DearName], 
				[CoName], 
				[Add1], 
				[Add2], 
				[Add3], 
				[Add4], 
				[Add5], 
				[Add6], 
				[Add7], 
				[Add8], 
				[Add9], 
				[CTRY], 
				[EmailAddress], 
				[Dealer], 
				[sno], 
				[ccode], 
				[modelcode], 
				[lang], 
				[manuf], 
				[gender], 
				[qver], 
				[blank], 
				[etype], 
				[reminder], 
				[week], 
				[test], 
				[SampleFlag], 
				[SalesServiceFile],
				[Expired],
				[DateOutput],
				ITYPE,
				PilotCode,
				[Owner],
				[OwnerCode],
				CRCCode,	
				MarketCode,
				SampleYear,
				VehicleMileage,
				VehicleMonthsinService,
				RowId,
				SRNumber,
				BilingualFlag,
				langBilingual,
				DearNameBilingual,
				EmailSignatorTitleBilingual,
				EmailContactTextBilingual,
				EmailCompanyDetailsBilingual
				
			)
			
			SELECT DISTINCT
					O.[AuditID], 
					O.[AuditItemID], 
					(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'All') AS [SelectionOutputTypeID],
					O.PartyID ,
					S.[ID] AS [CaseID], 
					S.FullModel ,
					S.Model ,
					S.sType , 
					REPLACE(S.CarReg, CHAR(9), '') AS CarReg,
					REPLACE(S.Title , CHAR(9), '') AS Title,
					REPLACE(S.Initial , CHAR(9), '') AS Initial,
					REPLACE(S.Surname , CHAR(9), '') AS Surname,
					REPLACE(S.Fullname , CHAR(9), '') AS Fullname,
					REPLACE(S.DearName , CHAR(9), '') AS DearName,
					REPLACE(S.CoName , CHAR(9), '') AS CoName,
					REPLACE(S.Add1 , CHAR(9), '') AS Add1,
					REPLACE(S.Add2 , CHAR(9), '') AS Add2,
					REPLACE(S.Add3 , CHAR(9), '') AS Add3,
					REPLACE(S.Add4 , CHAR(9), '') AS Add4,
					REPLACE(S.Add5 , CHAR(9), '') AS Add5,
					REPLACE(S.Add6 , CHAR(9), '') AS Add6,
					REPLACE(S.Add7 , CHAR(9), '') AS Add7,
					REPLACE(S.Add8 , CHAR(9), '') AS Add8,
					REPLACE(S.Add9 , CHAR(9), '') AS Add9,
					S.CTRY,
					REPLACE(S.EmailAddress , CHAR(9), '') AS EmailAddress,
					ISNULL(S.dealer, '') AS Dealer,
					S.sno ,
					S.ccode ,
					CASE WHEN S.VIN LIKE '%_CRC_Unknown_V' OR S.Model = 'Unknown Vehicle' THEN '99999' ELSE S.modelcode END AS modelcode,
					S.lang ,
					S.manuf ,
					S.gender ,
					S.qver ,
					S.blank ,
					S.etype ,
					S.reminder ,
					S.week ,
					S.test , 
					S.[SampleFlag], 
					S.SalesServiceFile AS CRCsurveyfile,
					S.Expired , 
					@Date,
					S.ITYPE ,
					--S.PilotCode,		
					'' AS PilotCode,
					'' AS [Owner],
					'' AS [OwnerCode],	
					CSE.CRCCode,
					CSE.MarketCode,
					YEAR (GetDate())  AS SampleYear,
					CSE.VehicleMileage,
					CSE.VehicleMonthsinService,
					CSE.RowId,
					CSE.Respondent_Serial AS SRNumber,
					S.BilingualFlag,					
					S.langBilingual,
					S.DearNameBilingual,
					S.EmailSignatorTitleBilingual,
					S.EmailContactTextBilingual,
					S.EmailCompanyDetailsBilingual
		FROM	#OutputtedSelections O
		INNER	JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID] AND 
																						O.PartyID = S.PartyID
		INNER JOIN Sample_ETL.China.CRC_WithResponses CSE ON O.CaseID = CSE.CaseID 	
		ORDER BY O.AuditItemID

		END

		-- DROP THE TEMPORARY TABLE
		DROP TABLE #OutputtedSelections
		
	COMMIT TRAN
		
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

