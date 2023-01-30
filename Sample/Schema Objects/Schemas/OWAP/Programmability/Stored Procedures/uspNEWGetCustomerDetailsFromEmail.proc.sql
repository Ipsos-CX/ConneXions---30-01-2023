CREATE PROCEDURE [OWAP].[uspNEWGetCustomerDetailsFromEmail]
@EmailAddress [dbo].[EmailAddress], @RowCount INT OUTPUT, @ErrorCode INT OUTPUT
AS
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
		T.Title,
		PP.FirstName,
		PP.MiddleName,
		PP.LastName,
		PP.SecondLastName,
		ISNULL(O.OrganisationName, '') AS CompanyName,
		LTRIM(RTRIM(ISNULL(EA.EmailAddress, ''))) + ' | ' + ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PBPA.ContactMechanismID, 0)) AS OtherDetails,
		--CASE
			--WHEN PA.Country IS NOT NULL THEN CN.Country
			--WHEN PA2.Country IS NOT NULL THEN CN2.Country
			--ELSE ''
		--END AS Market
		ISNULL(CN.Country,'') AS Market
	
	FROM ContactMechanism.EmailAddresses EA
	INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = EA.ContactMechanismID
	LEFT JOIN Party.People PP
		INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID
	ON PP.PartyID = PCM.PartyID
	LEFT JOIN Party.Organisations O ON O.PartyID = PCM.PartyID
	LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PCM.PartyID
	LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
	LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID
	--LEFT JOIN ContactMechanism.PartyContactMechanisms PCM2 ON PCM2.PartyID = PP.PartyID AND PCM2.ContactMechanismTypeID = 1
	--LEFT JOIN 
	--(			SELECT	MAX(ContactMechanismID) AS ContactMechanismID, PartyID 
				--FROM ContactMechanism.PartyContactMechanisms WHERE [ContactMechanismTypeID] = 1
				--GROUP BY PartyID
	--) MaxPA ON MaxPA.PartyID = PCM2.PartyID AND MaxPA.ContactMechanismID = PCM2.ContactMechanismID
	--LEFT JOIN ContactMechanism.PostalAddresses PA2 ON PA2.ContactMechanismID = MaxPA.ContactMechanismID
	--LEFT JOIN ContactMechanism.Countries CN2 ON CN2.CountryID = PA2.CountryID
	
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

	EXEC [$(Sample_Errors)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH