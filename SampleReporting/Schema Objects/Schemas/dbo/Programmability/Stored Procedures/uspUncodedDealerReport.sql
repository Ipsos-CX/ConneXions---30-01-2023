CREATE PROCEDURE [dbo].[uspUncodedDealerReport]
	
	@ReportDate			VARCHAR(10) = '',		--FORMAT OF DATE PASSED IN MUST BE YYYY-MM-DD OR YYYYMMDD
	@ReportDuration		INT = 5					--NUMBER OF DAYS

AS

/*	
	Version			Date			Developer			Comment
	-				2020-01-31		Eddie Thomas		Created
	1.1				2020-02-05		Chris Ledger 		BUG 15372 - Fix cases
*/


SET NOCOUNT ON

		DECLARE @ErrorNumber INT
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ErrorLocation NVARCHAR(500)
		DECLARE @ErrorLine INT
		DECLARE @ErrorMessage NVARCHAR(2048)


		DECLARE @dtStart		DATE,
				@dtEnd			DATE

BEGIN TRY
		
		-- CALCULATE REPORT DATE BOUNDARY
		SET		@dtEnd = CASE 
								WHEN @ReportDate ='' THEN CONVERT(DATE, GETDATE()) 
								ELSE CONVERT(Date,@ReportDate)
						 END

		SET		@dtStart = DATEADD(DD, -@ReportDuration + 1, @dtEnd)
	

		CREATE TABLE #Uncoded_Dealer_Report
		(
			Country											NVARCHAR (500),
			Brand											VARCHAR (20),
			Survey											VARCHAR (50),
			Dealer_Code										VARCHAR (20),
			[Dealer_Code_SetUp_For_Other_Surveys_InMarket]	NVARCHAR(MAX),
			[DealerName_From_SVCRM]							VARCHAR (MAX),
			[OtherBrandInMarket]							VARCHAR (50),
			Date_First_Loaded								DATE,
			Count_Received_ToDate							BIGINT,
			Filenames										NVARCHAR(MAX),
			[Comment1]										VARCHAR (1000),
			[Comment2]										VARCHAR (1000),
			[Comment3]										VARCHAR (1000)
		)

		----------------------------------------------- POPULATE Country, Brand, Survey & Dealer_Code FIELDS -----------------------------------------------

		INSERT INTO #Uncoded_Dealer_Report ( Country, Brand, Survey, Dealer_Code, [DealerName_From_SVCRM])

		SELECT DISTINCT sq.Market, sq.Brand, sq.Questionnaire, DealerCode,
						COALESCE(ACCT_NAME_CREATING_DEA, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, ACCT_DEAL_FULNAME_OF_CREAT_DEA)  AS SVCRM_Dealer
						--ACCT_NAME_CREATING_DEA AS SVCRM_Dealer
		FROM		[$(AuditDB)].Audit.EventPartyRoles						aepr
		INNER JOIN	[$(AuditDB)].dbo.AuditItems								ai	ON	aepr.AuditItemID	= ai.AuditItemID
		INNER JOIN	[$(AuditDB)].dbo.Files									f	ON	ai.AuditID			= f.AuditID
		INNER JOIN	[$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging	sq	ON	ai.AuditItemID		= sq.AuditItemID
		LEFT JOIN	[$(SampleDB)].Event.EventPartyRoles							epr ON	epr.EventID			= aepr.EventID 
																				AND epr.RoleTypeID		=aepr.RoleTypeID
		----------------------
		--LEFT JOIN Sample_ETL.CRM.DMS_Repair_Service						DMS ON SQ.AuditItemID = DMS.AuditItemID
		LEFT JOIN [$(ETLDB)].CRM.Vista_Contract_Sales						VST ON SQ.AuditItemID = VST.AuditItemID
		----------------------

		WHERE		(aepr.PartyID = 0) AND 
					(ActionDate BETWEEN @dtStart AND @dtEnd) AND 
					(epr.EventID is NULL) AND 
					(f.FileTypeID = 1) -- Sample files  

		-------------------------------------------------------- POPULATE Date_First_Loaded FIELD --------------------------------------------------------

		;WITH UCD_FirstTimeReceived_CTE (FirstLoadDate, DealerCode, Market, Brand, Questionnaire)
		AS
		(	
			SELECT		MIN(ActionDate) FirstLoadDate, DealerCode, sq.Market, sq.Brand, sq.Questionnaire
			FROM		[$(AuditDB)].Audit.EventPartyRoles						aepr
			INNER JOIN	[$(AuditDB)].dbo.AuditItems								ai  ON	aepr.AuditItemID = ai.AuditItemID
			INNER JOIN	[$(AuditDB)].dbo.Files									f	ON	ai.AuditID		 = f.AuditID
			INNER JOIN	[$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging	sq	ON	ai.AuditItemID	 = sq.AuditItemID
			LEFT JOIN	[$(SampleDB)].Event.EventPartyRoles							epr ON	epr.EventID		 = aepr.EventID  
																					AND	epr.RoleTypeID	 = aepr.RoleTypeID
			--RESTRICT RESULTS BY JOINING ONLY ON DEALER CODES RECEIVED DURING CURRENT REPORTING PERIOD
			INNER JOIN	#Uncoded_Dealer_Report									ucd ON	aepr.DealerCode = ucd.Dealer_Code
		
			WHERE	(aepr.PartyID = 0)	AND 
					(CONVERT(DATE,ActionDate) BETWEEN '2000-01-01' AND @dtEnd) AND
					(epr.EventID is NULL) AND 
					(f.FileTypeID = 1) AND 
					(ucd.Country = sq.Market) AND
					(ucd.Brand = sq.Brand) AND 
					(ucd.Survey = sq.Questionnaire) 
			GROUP BY DealerCode, sq.Market, sq.Brand, sq.Questionnaire
		)

		UPDATE		UCD
		SET			Date_First_Loaded = CTE.FirstLoadDate
		FROM		#Uncoded_Dealer_Report UCD
		INNER JOIN	UCD_FirstTimeReceived_CTE CTE ON	UCD.Country			= CTE.Market AND
														UCD.Brand			= CTE.Brand AND
														UCD.Survey			= CTE.Questionnaire AND
														UCD.Dealer_Code		= CTE.DealerCode


		---------------------------------------------------------- POPULATE Filenames FIELD ----------------------------------------------------------

			;WITH UCD_Filenames_CTE (Market, Brand, Questionnaire, DealerCode, FileName)
			AS 
			(
				SELECT DISTINCT sq.Market, sq.Brand, sq.Questionnaire, DealerCode, FileName

				FROM		[$(AuditDB)].Audit.EventPartyRoles						aepr
				INNER JOIN	[$(AuditDB)].dbo.AuditItems								ai	ON	aepr.AuditItemID	= ai.AuditItemID
				INNER JOIN	[$(AuditDB)].dbo.Files									f	ON	ai.AuditID			= f.AuditID
				INNER JOIN	[$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging	sq	ON	ai.AuditItemID		= sq.AuditItemID
				LEFT JOIN	[$(SampleDB)].Event.EventPartyRoles							epr ON	epr.EventID			= aepr.EventID 
																						AND epr.RoleTypeID		=aepr.RoleTypeID
				----RESTRICT RESULTS BY JOINING ONLY ON DEALER CODES RECEIVED DURING CURRENT REPORTING PERIOD
				INNER JOIN	#Uncoded_Dealer_Report									ucd ON	aepr.DealerCode		= ucd.Dealer_Code

				WHERE	(aepr.PartyID = 0) AND 
						(CONVERT(DATE,ActionDate) <= @dtEnd) AND
						(epr.EventID is NULL) AND
						(f.FileTypeID = 1) AND
						(ucd.Country = sq.Market) AND
						(ucd.Brand = sq.Brand) AND 
						(ucd.Survey = sq.Questionnaire) 

			)

			UPDATE	UCD
			SET		Filenames = FLN.Files
			FROM	#Uncoded_Dealer_Report UCD
			INNER JOIN 
			(	SELECT	p1.Market, p1.Brand, p1.Questionnaire, p1.DealerCode,
						STUFF((	
							SELECT	', ' + FileName 
							FROM	UCD_Filenames_CTE p2
							WHERE	p2.Market			= p1.Market AND
									p2.Brand			= p1.Brand AND
									p2.Questionnaire	= p1.Questionnaire AND
									p2.DealerCode		= p1.DealerCode
					
							ORDER BY FileName
							FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
							,1,1,'') AS Files
				FROM	UCD_Filenames_CTE p1
				GROUP BY Market, Brand, Questionnaire, DealerCode

			) FLN ON	UCD.Country			= FLN.Market AND
						UCD.Brand			= FLN.Brand AND
						UCD.Survey			= FLN.Questionnaire AND
						UCD.Dealer_Code		= FLN.DealerCode


		------------------------------------------------------- POPULATE Count_Received_ToDate FIELD -------------------------------------------------------

		;WITH UCD_FirstTimeReceived_CTE (EventCount, DealerCode, Market, Brand, Questionnaire)
		AS
		(	
			SELECT		Count(aepr.AuditItemID) AS EventCount, DealerCode, sq.Market, sq.Brand, sq.Questionnaire
			FROM		[$(AuditDB)].Audit.EventPartyRoles						aepr
			INNER JOIN	[$(AuditDB)].dbo.AuditItems								ai  ON	aepr.AuditItemID = ai.AuditItemID
			INNER JOIN	[$(AuditDB)].dbo.Files									f	ON	ai.AuditID		 = f.AuditID
			INNER JOIN	[$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging	sq	ON	ai.AuditItemID	 = sq.AuditItemID
			LEFT JOIN	[$(SampleDB)].Event.EventPartyRoles							epr ON	epr.EventID		 = aepr.EventID  
																					AND	epr.RoleTypeID	 = aepr.RoleTypeID
			--RESTRICT RESULTS BY JOINING ONLY ON DEALER CODES RECEIVED DURING CURRENT REPORTING PERIOD
			INNER JOIN	#Uncoded_Dealer_Report									ucd ON	aepr.DealerCode = ucd.Dealer_Code


			WHERE	(aepr.PartyID = 0)	AND 
					(CONVERT(DATE,ActionDate) <= @dtEnd) AND
					(epr.EventID is NULL) AND 
					(f.FileTypeID = 1) AND 
					(ucd.Country = sq.Market) AND
					(ucd.Brand = sq.Brand) AND 
					(ucd.Survey = sq.Questionnaire) 
			GROUP BY DealerCode, sq.Market, sq.Brand, sq.Questionnaire
		)

		UPDATE		UCD
		SET			Count_Received_ToDate = CTE.EventCount
		FROM		#Uncoded_Dealer_Report UCD
		INNER JOIN	UCD_FirstTimeReceived_CTE CTE ON	UCD.Country			= CTE.Market AND
														UCD.Brand			= CTE.Brand AND
														UCD.Survey			= CTE.Questionnaire AND
														UCD.Dealer_Code		= CTE.DealerCode

		----------------------------------------------- POPULATE [Dealer_Code_SetUp_For_Other_Surveys_InMarket] FIELD -----------------------------------------------
	
		;with UCD_OtherSurveys_CTE (Country, Brand, Survey, Dealer_Code, OtherSurveysInMarket)
		AS
		(
			SELECT		DISTINCT udr.Country, udr.Brand, udr.Survey, udr.Dealer_Code, dw.OutletFunction
			FROM		#Uncoded_Dealer_Report udr
			INNER JOIN	[$(SampleDB)].dbo.DW_JLRCSPDealers dw on	udr.Brand	= dw.Manufacturer and
															udr.Country	= dw.Market and 
															udr.Dealer_Code = dw.OutletCode 
			WHERE		UDR.Survey <> DW.OutletFunction
		)

		UPDATE		UCD
		SET			[Dealer_Code_SetUp_For_Other_Surveys_InMarket] = OSM.OtherSurveysInMarket
		FROM		#Uncoded_Dealer_Report UCD
		INNER JOIN 
		( 
			SELECT	p1.Country, p1.Brand, p1.Survey, p1.Dealer_Code,
					STUFF((	
						SELECT	', ' + OtherSurveysInMarket 
						FROM	UCD_OtherSurveys_CTE p2
						WHERE	p2.Country			= p1.Country AND
								p2.Brand			= p1.Brand AND
								p2.Survey			= p1.Survey AND
								p2.Dealer_Code		= p1.Dealer_Code
					
						ORDER BY OtherSurveysInMarket
						FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
						,1,1,'') AS OtherSurveysInMarket
			FROM	UCD_OtherSurveys_CTE p1
			GROUP BY Country, Brand, Survey, Dealer_Code 
		) OSM ON	UCD.Country		= OSM.Country AND
					UCD.Brand		= OSM.Brand AND
					UCD.Survey		= OSM.Survey AND 
					UCD.Dealer_Code = OSM.Dealer_Code

		
		UPDATE	#Uncoded_Dealer_Report
		SET		[Comment1] = 'Dealer set up for ' + Dealer_Code_SetUp_For_Other_Surveys_InMarket
		WHERE	ISNULL(Dealer_Code_SetUp_For_Other_Surveys_InMarket,'') != ''
	
		----------------------------------------------- POPULATE [OtherBrandInMarket] FIELD -----------------------------------------------


		;with UCD_OtherBrand_CTE (Country, Brand, Survey, Dealer_Code, OtherBrand)
		AS
		(
			SELECT		DISTINCT udr.Country, udr.Brand, udr.Survey, udr.Dealer_Code, DW.Manufacturer AS OtherBrand
			FROM		#Uncoded_Dealer_Report udr
			INNER JOIN	[$(SampleDB)].dbo.DW_JLRCSPDealers dw on	udr.Country	= dw.Market and 
															udr.Dealer_Code = dw.OutletCode 
			WHERE		udr.Brand	<> dw.Manufacturer		
			--UDR.Survey <> DW.OutletFunction
					
		)


		UPDATE		UCD
		SET			[OtherBrandInMarket]		= OBM.OtherBrand
		FROM		#Uncoded_Dealer_Report UCD
		INNER JOIN	UCD_OtherBrand_CTE OBM ON	UCD.Country		= OBM.Country AND
												UCD.Brand		= OBM.Brand AND
												UCD.Survey		= OBM.Survey AND
												UCD.Dealer_Code = OBM.Dealer_Code

	
		UPDATE	#Uncoded_Dealer_Report
		SET		[Comment2] = 'Dealer set up for ' + OtherBrandInMarket
		WHERE	ISNULL(OtherBrandInMarket,'') != ''
		
		UPDATE	#Uncoded_Dealer_Report
		SET		[Comment3] =	CASE
									WHEN ISNULL([Comment1],'') !='' AND ISNULL([Comment2],'') !='' THEN [Comment1] + CHAR(13) + [Comment2]
									WHEN ISNULL([Comment1],'') !='' THEN [Comment1]
									ELSE [Comment2]
								END				
		
		--------------------------------------------------------------------------------------------------------------
		--SOMETIMES THERE ARE DIFFERENT DEALER NAMES FOR THE SAME DEALERCODE (SVCRM DATA), ROLL THEM UP INTO
		--BAR DELIMITED FIELD
		INSERT	[dbo].[UncodedDealerReport] (Country, Brand, Survey, Dealer_Code, Dealer_Code_SetUp_For_Other_Surveys_InMarket, OtherBrandInMarket, Comment, Date_First_Loaded, Count_Received_ToDate, Filenames, DealerName_From_SVCRM)
		SELECT	p1.Country, p1.Brand, p1.Survey, p1.Dealer_Code, p1.Dealer_Code_SetUp_For_Other_Surveys_InMarket, 

				p1.OtherBrandInMarket, p1.Comment3,  p1.Date_First_Loaded, p1.Count_Received_ToDate, p1.Filenames, 
				STUFF((	
					SELECT	' | ' + DealerName_From_SVCRM
					FROM	#Uncoded_Dealer_Report p2
					WHERE	p2.Country			= p1.Country AND
							p2.Brand			= p1.Brand AND
							p2.Survey			= p1.Survey AND
							p2.Dealer_Code		= p1.Dealer_Code
					
					ORDER BY DealerName_From_SVCRM
					FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
					,1,1,'') AS DealerName_From_SVCRM

		FROM	#Uncoded_Dealer_Report p1
		GROUP BY	Country, Brand, Survey, Dealer_Code, p1.Dealer_Code_SetUp_For_Other_Surveys_InMarket, 
					p1.OtherBrandInMarket, p1.Comment3, p1.Date_First_Loaded, p1.Count_Received_ToDate, p1.Filenames 


		--REMOVE LEADING | 
		UPDATE	[UncodedDealerReport] 
		SET		DealerName_From_SVCRM = ISNULL(SUBSTRING(DealerName_From_SVCRM, 3, len(DealerName_From_SVCRM)),'') 

		----THE FINAL RESULTSET 
		--SELECT	ISNULL(Country,'') AS Country, 
		--		ISNULL(Brand,'') AS Brand, 
		--		ISNULL(Survey,'') AS Survey, 
		--		ISNULL(Dealer_Code,'') AS Dealer_Code, 
		--		ISNULL(Dealer_Code_SetUp_For_Other_Surveys_InMarket,'') AS Dealer_Code_SetUp_For_Other_Surveys_InMarket, 
		--		ISNULL(SUBSTRING(DealerName_From_SVCRM, 3, len(DealerName_From_SVCRM)),'') AS DealerName_From_SVCRM, 
		--		ISNULL(OtherBrandInMarket,'') AS OtherBrandInMarket,
		--		ISNULL(Date_First_Loaded,'') AS Date_First_Loaded, 
		--		ISNULL(Count_Received_ToDate,'') AS Count_Received_ToDate, 
		--		ISNULL(Filenames,'') AS Filenames

		--FROM	#FinalOutput
		--WHERE	Dealer_Code IS NOT NULL
		--ORDER BY 1, 2, 3, 4

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
