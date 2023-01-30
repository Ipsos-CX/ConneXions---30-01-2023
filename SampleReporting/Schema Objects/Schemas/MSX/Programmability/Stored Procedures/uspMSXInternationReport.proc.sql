CREATE PROCEDURE [MSX].[uspMSXInternationalReport]
	@Month INT,
	@Year INT
AS
	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	/*
		Purpose:	QUERY FOR MSX INTERNATIONAL REPORT
			
		Version		Date				Developer			Comment
		1.0			2017-07-07			Chris Ledger		BUG 13833 - Query for MSX International Report
		1.1			2017-07-27			Eddie Thomas		BUG 14127 - Embedded double quotes causing problems when file 
																		imported by destination application
		1.2			2017-10-24			Chris Ledger		BUG 14241 - Add Extra Countries
		1.3			2018-03-14			Chris Ledger		BUG 14321 - Consolidate list of countries
		1.4			2018-09-18			Chris Ledger		BUG 14998 - Remove UK
	*/
	
	BEGIN TRY
		
		--SELECT 
		----A.Market,
		----A.Questionnaire, 
		--C.ISOAlpha3 AS COUNTRY,
		--A.Brand AS BRAND, 
		----CONVERT(VARCHAR,A.DealerCode) AS DealerCode, 
		--CONVERT(VARCHAR,A.DealerCodeGDD) AS CI_CODE,
		----CONVERT(VARCHAR,D.OutletCode) AS OutletCode, 
		--SUBSTRING('0'+CONVERT(VARCHAR,CASE WHEN A.ReportMonth = 1 THEN 12 ELSE A.ReportMonth - 1 END),LEN(CASE WHEN A.ReportMonth = 1 THEN 12 ELSE A.ReportMonth - 1 END),2) AS 'MONTH', 
		--CASE WHEN A.ReportMonth = 12 THEN A.ReportYear - 1 ELSE A.ReportYear END AS 'YEAR', 
		--A.DealerName AS DEALER_NAME,
		--A.EventsLoaded AS TTL_EVT_REC,
		--A.UsableEvents AS USE_EVT,
		--A.InvitesSent AS CUST_CON,
		--A.PostalInvites AS POST_CON,
		--A.EmailInvites AS EMAIL_CON,
		--A.SuppliedEmail AS EVT_W_EMAIL,
		--A.SMSInvites AS SMS_CON,
		--A.PhoneInvites AS PHONE_CON,
		--A.HardBounce AS HARD_EMAIL_BB,
		--A.Responded AS RESPONSES,
		--I.FeedType AS FEED_TYPE
		SELECT 
		CONVERT(VARCHAR,C.ISOAlpha3) + ',' +
		A.Brand + ',' +
		CONVERT(VARCHAR,COALESCE(NULLIF(A.DealerCodeGDD,''),A.DealerCode)) + ',' +
		SUBSTRING('0'+CONVERT(VARCHAR,CASE WHEN A.ReportMonth = 1 THEN 12 ELSE A.ReportMonth - 1 END),LEN(CASE WHEN A.ReportMonth = 1 THEN 12 ELSE A.ReportMonth - 1 END),2) + ',' +
		CONVERT(VARCHAR,CASE WHEN A.ReportMonth = 12 THEN A.ReportYear - 1 ELSE A.ReportYear END) + ',' + 
		'"' +					
				CASE																				--V1.1	
					WHEN CHARINDEX('"', A.DealerName) > 0 THEN REPLACE(A.DealerName,'"', '""' )		--V1.1
					ELSE A.DealerName																--V1.1								
			 
				END + '",' +																		--V1.1
		CONVERT(VARCHAR,ISNULL(A.EventsLoaded,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.UsableEvents,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.InvitesSent,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.PostalInvites,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.EmailInvites,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.SuppliedEmail,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.SMSInvites,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.PhoneInvites,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.HardBounce,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(A.Responded,'')) + ',' +
		CONVERT(VARCHAR,ISNULL(I.FeedType,'')) AS DataRow
		FROM SampleReport.GlobalReportDealerRegionDistinctEventAggregate A
		LEFT JOIN [$(SampleDB)].dbo.Markets M ON M.Market = A.Market
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON M.CountryID = C.CountryID
		LEFT JOIN SampleReport.BMQSpecificInformation I ON A.Brand = I.Brand AND A.Market = I.Market AND A.Questionnaire = I.Questionnaire
		--LEFT JOIN [Sample].dbo.DW_JLRCSPDealers D ON A.DealerCode = D.OutletCode AND COALESCE(M.DealerTableEquivMarket,M.Market) = D.Market AND A.Brand = D.Manufacturer AND A.Questionnaire = REPLACE(D.OutletFunction,'Aftersales','Service')
		WHERE A.SummaryType = 'MTH'
		AND A.Market IN  
		('Albania',
		'Austria',
		'Belgium',
		'Bosnia and Herzegovina',
		'Bulgaria',
		'Croatia',
		'Cyprus',
		'Czech Republic', 
		'Denmark',
		'Estonia',
		'Finland',
		'France', 
		'Germany', 
		'Gibraltar',
		'Greece',
		'Hungary',
		'Iceland',
		'Ireland',
		'Israel',
		'Italy', 
		'Latvia',
		'Lithuania',
		'Luxembourg',
		'Macedonia',
		'Malta',
		'Netherlands', 
		'North Cyprus',
		'Norway',
		'Poland',
		'Portugal', 
		'Republic of Moldova',
		'Romania',
		'Serbia',
		'Slovakia',
		'Slovenia',
		'Spain', 
		'Sweden',
		'Switzerland',
		'Turkey',
		'Ukraine')
		--'United Kingdom')				-- V1.4
		AND A.Questionnaire = 'Service'
		AND LEN(ISNULL(A.DealerName,'')) > 0
		AND A.ReportYear = @Year
		AND A.ReportMonth = @Month

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