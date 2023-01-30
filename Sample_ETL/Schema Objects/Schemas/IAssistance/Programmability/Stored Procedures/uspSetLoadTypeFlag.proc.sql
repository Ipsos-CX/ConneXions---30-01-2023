
CREATE PROCEDURE [IAssistance].[uspSetLoadTypeFlag]

AS 
/*
	Purpose:	Checks whether we have sufficient information supplied to provide to do 
				a normal VWT load and sets the PerformNormalVWTLoadFlag accordingly.

	Version			Date			Developer			Comment
	1.0				2018-10-26		Chris Ledger		Created from Roadside.uspSetLoadTypeFlag
	1.1				2020-01-10		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		DECLARE @AddressMatching INT, @EmailMatching INT, @TelephoneMatching INT
		SELECT @AddressMatching = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies pmm WHERE PartyMatchingMethodology = 'Name and Postal Address'
		SELECT @EmailMatching = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies pmm WHERE PartyMatchingMethodology = 'Name and Email Address'
		SELECT @TelephoneMatching = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies pmm WHERE PartyMatchingMethodology = 'Name and Telephone Number'
		

		UPDATE ie
		SET ie.PerformNormalVWTLoadFlag = CASE WHEN (    (ISNULL(ie.SurnameField1, '') <> '' OR ISNULL(ie.CompanyName , '') <> '' )
												  AND (  ISNULL(ie.Address1, '') <> '' 
												         AND m.PartyMatchingMethodologyID = @AddressMatching
													  )
													 OR
													  ( ISNULL(COALESCE(ie.EmailAddress1, ie.EmailAddress2), '') <> '' 
												        AND m.PartyMatchingMethodologyID = @EmailMatching
												      )
													 OR															
													  ( ISNULL(ie.MobileTelephoneNumber, '') <> ''					
												        AND m.PartyMatchingMethodologyID = @TelephoneMatching		
												      )															
												  ) 
										THEN 'Y'
										ELSE 'N' END
		FROM IAssistance.IAssistanceEvents ie
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha2 = ie.CountryCode
		INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = c.CountryID
		WHERE ie.PerformNormalVWTLoadFlag IS NULL

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