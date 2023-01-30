CREATE PROCEDURE [CustomerUpdate].[uspCRCAgentLookUp_UnpivotRows]

AS

/*
	Purpose:	Unpivot reords conatining comma seperated markets into individual records
	
	Version			Date				Developer			Comment
	1.0				24/03/2021			Eddie Thomas		Created
	1.1				26/04/2022			Eddie Thomas		Populate new error description field

*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	
	DECLARE @TempAgentLookup table
	(
		AuditID						BIGINT,
		CDSID						NVARCHAR(100), 
		[FirstName]					NVARCHAR(100), 
		[Surname]					NVARCHAR(100),	
		[DisplayOnQuestionnaire]	NVARCHAR(100), 
		[DisplayOnWebsite]			NVARCHAR(100), 
		[FullName]					NVARCHAR(100),
		[Market]					VARCHAR(200)
	)



	--REMOVE DOUBLE QUOTES FROM THE MARKETS FIELD
	UPDATE	[Stage].[CRCAgents_GlobalList]
	SET		Market = REPLACE(Market,CHAR(34),'')

	
	--MARKET CONTAINS COMMA SEPERATED VALUES, FLATTEN THEM TO FORM INDIVIDUAL RECORDS
	;With Flattened_CRCAgents_CTE ( AuditID, CDSID, [FirstName], [Surname],	[DisplayOnQuestionnaire], [DisplayOnWebsite], [FullName], Market)

	AS

	(
			SELECT	AuditID, CDSID, [FirstName], [Surname],	[DisplayOnQuestionnaire], [DisplayOnWebsite], [FullName],
					CASE
							WHEN LTRIM(RTRIM(Value)) = 'Russia' THEN 'Russian Federation'
							WHEN LTRIM(RTRIM(Value)) = 'UAE' THEN 'United Arab Emirates'
							ELSE LTRIM(RTRIM(Value))  
					END AS Market
			FROM	[Stage].[CRCAgents_GlobalList] t
			CROSS APPLY STRING_SPLIT(t.Market, ',') 
	)


	INSERT	@TempAgentLookup
	SELECT	AuditID, CTE.CDSID, CTE.[FirstName], CTE.Surname, CTE.[DisplayOnQuestionnaire], 
			CTE.[DisplayOnWebsite], CTE.[FullName], CTE.Market
	FROM	Flattened_CRCAgents_CTE CTE
	ORDER BY Market, [FullName]

	BEGIN TRAN
		

		TRUNCATE TABLE [Stage].[CRCAgents_GlobalList]

		INSERT [Stage].[CRCAgents_GlobalList] (	
												AuditID, 
												CDSID, 
												[FirstName], 
												[Surname],	
												[DisplayOnQuestionnaire], 
												[DisplayOnWebsite], 
												[FullName],
												[Market]
												)

		SELECT	AuditID, 
				[CDSID], 
				[FirstName], 
				[Surname],	
				[DisplayOnQuestionnaire], 
				[DisplayOnWebsite], 
				[FullName],
				[Market]
		FROM @TempAgentLookup
		ORDER BY [Market], [FullName]
	
	
	COMMIT TRAN


	--ADD IN MARKETCODE
	UPDATE		GL
	SET			MarketCode =	CASE 
										WHEN MK2.MarketID IS NULL THEN CN.ISOAlpha3
										ELSE CN2.ISOAlpha3
								END
	FROM		[Stage].[CRCAgents_GlobalList] GL
	LEFT JOIN	[$(SampleDB)].dbo.Markets MK	ON GL.Market = MK.Market
	LEFT JOIN	[$(SampleDB)].dbo.Markets MK2	ON GL.Market = MK2.DealerTableEquivMarket 
	LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries CN ON MK.CountryID = CN.CountryID
	LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries CN2 ON MK2.CountryID = CN2.CountryID

	--V1.1
	UPDATE	[Stage].[CRCAgents_GlobalList]
	SET		IP_DataErrorDescription = 'Field [CDSID] cannot be blank;'
	WHERE	ISNULL(CDSID,'') = ''

	UPDATE	[Stage].[CRCAgents_GlobalList]
	SET		IP_DataErrorDescription = ISNULL(IP_DataErrorDescription,'') + 'Field [FullName] cannot be blank;'
	WHERE	ISNULL(FullName,'') = ''

	UPDATE	[Stage].[CRCAgents_GlobalList]
	SET		IP_DataErrorDescription = ISNULL(IP_DataErrorDescription,'') + 'Field [MarketCode] cannot be blank, check if [Market] is blank or invalid.'
	WHERE	ISNULL(MarketCode,'') = ''


	--VERIFY THAT MARKETCODE IS POPULATED FOR ALL RECORDS
	IF EXISTS ( SELECT ID FROM [Stage].[CRCAgents_GlobalList] WHERE IP_DataErrorDescription IS NOT NULL)
				RAISERROR(	N'There are records in Stage.CRCAgents_GlobalList that are missing mandatory data. ', 16, 1)
					 
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