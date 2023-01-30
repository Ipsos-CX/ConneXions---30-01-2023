CREATE PROCEDURE [DealerManagement].[uspUpdateReportingRetailerName]

AS

SET NOCOUNT ON

/*

Release			Version		Created			Author			Description	
-------		-------			------			-------			
LIVE			1.0			2021-10-08		Ben King	    TASK 643 - Update field ReportingRetailerName in Tbl Sample.[dbo].[DW_JLRCSPDealers]
LIVE            1.1         2021-13-12      Ben King        Task 724 - 18415 - Retailer hierarchy - ReportingRetailerName issue

*/
	
	-- DECLARE LOCAL VARIABLES 
	DECLARE @ErrorCode INT
	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)


	BEGIN TRY


		;WITH CTE_Outlet AS
		(
			SELECT ROW_NUMBER() OVER (PARTITION BY D.Dealer10DigitCode  ORDER BY ISNULL(D.ThroughDate,'2099-01-01') DESC, D.OutletFunctionID ASC) AS Rank,
				D.Dealer10DigitCode,
				D.ThroughDate,
				D.OutletFunctionID,
				D.OutletFunction,
				D.Outlet
			FROM dbo.DW_JLRCSPDealers D
				INNER JOIN dbo.Franchises F ON D.OutletPartyID = F.OutletPartyID
											AND D.OutletFunctionID = F.OutletFunctionID
		), CTE_ReportingRetailerName AS
		(
			SELECT O.Dealer10DigitCode,
				O.Outlet AS ReportingRetailerName
			FROM CTE_Outlet O
			WHERE O.Rank = 1
		)
		--SELECT O.*, RRN.ReportingRetailerName
		UPDATE D
		SET D.ReportingRetailerName = RRN.ReportingRetailerName
		FROM CTE_Outlet O
			INNER JOIN CTE_ReportingRetailerName RRN ON O.Dealer10DigitCode = RRN.Dealer10DigitCode
			INNER JOIN dbo.DW_JLRCSPDealers D ON RRN.Dealer10DigitCode = D.Dealer10DigitCode
	    --WHERE RRN.ReportingRetailerName <> D.Outlet
		WHERE RRN.ReportingRetailerName <> ISNULL(D.ReportingRetailerName,'') --v1.1

	
	END TRY

	BEGIN CATCH

		SET @ErrorCode = @@Error

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
GO
