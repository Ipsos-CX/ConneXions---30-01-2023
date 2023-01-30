CREATE PROCEDURE CustomerUpdateFeeds.uspGetNonSolicitationEmailDetails

AS

/*

***************************************************************************
**
**  Description: Generates the Email Details.   
**
**
**	Date		Author			Ver		Desctiption
**	----		------			----	-----------
**	2019-02-08	Chris Ledger	1.1		Bug 15221 - Separate out Denmark, Sweden and Norway weekly customer updates
**  2019-09-27	Chris Ledger	1.2		Bug 15562 - Add DealerName
**  2021-04-02	Eddie Thomas	1.3		Azure DevOps Task 287 : Include Market's destination FTP folder in results
**  2021-07-09	Eddie Thomas	1.4		Bug 18175 - Include Roadside & CRC & CRC General Enquiries
**	2021-09-22	Chris Ledger	1.5		Fix warning in solution from mismatch of ftpid to FTPID
**									
***************************************************************************

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	--BUILD A DEALER NETWORK THAT INCLUDES ALL STUDIES		--v1.4
	SELECT		DISTINCT 
				DC.PartyIDFrom AS DealerPartyID, 
				Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market,
				DC.DealerCode
	INTO		#DealerNetwork
	FROM		[$(SampleDB)].ContactMechanism.DealerCountries DC
	INNER JOIN	[$(SampleDB)].dbo.Markets MK ON DC.CountryID = MK.CountryID

	UNION

	SELECT	--BR.Brand, 
			PartyIDFrom AS DealerPartyID,
			Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market, 
			CRC.CRCCentreCode + '_CRC'
			--'CRC' AS Questionnaire, 
	FROM	[$(SampleDB)].Party.CRCNetworks CRC
	INNER JOIN [$(SampleDB)].dbo.[Brands] BR ON CRC.PartyIDTo = BR.ManufacturerPartyID
	INNER JOIN [$(SampleDB)].dbo.Markets MK ON CRC.CountryID = MK.CountryID

	UNION

	SELECT	--BR.Brand, 
			PartyIDFrom AS DealerPartyID, 
			Coalesce(MK.DealerTableEquivMarket,mk.Market) AS Market,
			ROA.RoadsideNetworkCode + '_Roadside'
			--'Roadside' AS Questionnaire, 
		
	FROM	[$(SampleDB)].Party.RoadsideNetworks ROA
	INNER JOIN [$(SampleDB)].dbo.[Brands] BR ON ROA.PartyIDTo = BR.ManufacturerPartyID
	INNER JOIN [$(SampleDB)].dbo.Markets MK ON ROA.CountryID = MK.CountryID
	



	;WITH FTP_CTE (Market, MarketAndUploadFolder)	--V1.3
	AS  
	(
		SELECT		DISTINCT Market,
					UF.[RemoteFolder] As MarketUploadFolder
		FROM		[$(ETLDB)].[FTP].[MarketAndUploadFolder] MUF 
		INNER JOIN	[$(SampleDB)].dbo.Markets MK ON MUF.MarketID = MK.MarketID
		INNER JOIN	[$(ETLDB)].[FTP].[UploadFolder] UF ON MUF.[UploadFolderID] = UF.[UploadFolderID]
		WHERE		MUF.FTPID = (SELECT FTPID FROM [$(ETLDB)].dbo.FTPScriptMetadata WHERE FTPProcessName = 'Sample Reporting - Nonsolicitations')	-- V1.5
	)


	SELECT DISTINCT 
		CTE.Market,
		RU.DealerCode,
		ISNULL(CTE.MarketAndUploadFolder,'') AS MarketUploadFolder
	FROM CustomerUpdateFeeds.ReportingTable_Nonsolicitations RU
	LEFT JOIN 
	(	
		SELECT		Distinct Mk.Market, --OutletCode
					DealerCode	
		--FROM		[Sample].dbo.DW_JLRCSPDealers	DW
		FROM		#DealerNetwork DW	
		INNER JOIN	[$(SampleDB)].dbo.Markets				MK ON DW.Market = COALESCE(MK.DealerTableEquivMarket, MK.Market)
	--) D ON RU.DealerCode = D.OutletCode AND RU.Market = D.Market		--V1.3
	) D ON RU.DealerCode = D.DealerCode AND RU.Market = D.Market		--V1.4
	--USING A LEFT JOIN. IF MARKET FOLDER META DATA IS MISSING, THE ZIP WILL BE DUMPED INTO THE ROOT OF NON-SOLICITATIONS FTP AREA
	LEFT JOIN FTP_CTE CTE ON RU.Market = CTE.Market
	WHERE	RU.DealerCode = 'ALL'	AND --V1.3
			CTE.Market IS NOT NULL
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
