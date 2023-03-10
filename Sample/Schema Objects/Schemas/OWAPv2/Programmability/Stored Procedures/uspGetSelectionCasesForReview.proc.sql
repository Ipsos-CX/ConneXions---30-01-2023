CREATE PROCEDURE [OWAPv2].[uspGetSelectionCasesForReview]
(
	@SelectionID dbo.RequirementID,
	@RowCount INT = 0 OUTPUT,
	@ErrorCode INT = 0 OUTPUT
)

AS

/*
	Purpose:	Returns a list of cases in a given selection for a given page for display on the review page of the OWAP
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created
	1.1				20-May-2012		Pardip Mudhar		Modified for New OWAP
	1.2				17/09/2012		Pardip Mudhar		BUG 7581 - Check for null values to be replaced by N''
	1.3				14/09/2016		Chris Ross			Move to schema OWAPv2
	1.4				10/10/2018		Chris Ross			BUG 14399 - Filter out people that have been GDPR erased.	
	1.5				21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	SELECT
		 ROW_NUMBER() OVER(ORDER BY CaseID ) AS ItemID
		,CaseID
		,PartyID
		,ISNULL( OrganisationName, N'' ) AS OrganisationName
		,Party.udfGetFullName(Title, FirstName, Initials, MiddleName, LastName, SecondLastName) AS FullName
		,ContactMechanism.udfGetInlinePostalAddress(PostalAddressContactMechanismID) AS PostalAddress
		,ISNULL( DealerName, N'' ) + ' (' + ISNULL( DealerCode, N'' ) + ')' AS Dealer
		,CASE CaseRejection 
			WHEN 0 THEN N'No' 
			ELSE N'Yes' 
		 END AS CaseRejection
	FROM Meta.CaseDetails cd
	WHERE cd.SelectionRequirementID = @SelectionID
	AND NOT EXISTS (SELECT er.PartyID FROM Sample_Audit.GDPR.ErasureRequests er				-- v1.4
					WHERE er.PartyID = cd.PartyID)
					
						
	SELECT @RowCount = @@RowCount
	
	SET @ErrorCode = @@Error

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
