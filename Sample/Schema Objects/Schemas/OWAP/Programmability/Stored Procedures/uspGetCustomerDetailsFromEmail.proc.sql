CREATE PROCEDURE OWAP.uspGetCustomerDetailsFromEmail
(
	 @EmailAddress dbo.EmailAddress
	,@RowCount INT OUTPUT
	,@ErrorCode INT OUTPUT	
)

AS

/*
	Purpose:	Search for a customer given their email details
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	SET @RowCount = 0
	SET @ErrorCode = 0

	-- VALIDATE THE PARAMETERS
	SET @EmailAddress = LTRIM(RTRIM(ISNULL(@EmailAddress, N'')))
		
	SELECT DISTINCT
		PCM.PartyID,
		Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
		ISNULL(O.OrganisationName, '') AS CompanyName,
		LTRIM(RTRIM(ISNULL(EA.EmailAddress, ''))) + ' | ' + ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PBPA.ContactMechanismID, 0)) AS OtherDetails
	FROM ContactMechanism.EmailAddresses EA
	INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = EA.ContactMechanismID
	LEFT JOIN Party.People PP
		INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID
	ON PP.PartyID = PCM.PartyID
	LEFT JOIN Party.Organisations O ON O.PartyID = PCM.PartyID
	LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PCM.PartyID
	WHERE LTRIM(RTRIM(EA.EmailAddress)) = @EmailAddress
	
	SET @RowCount = @@ROWCOUNT
		
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