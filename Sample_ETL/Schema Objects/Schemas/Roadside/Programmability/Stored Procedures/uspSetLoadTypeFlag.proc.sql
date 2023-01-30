
CREATE PROCEDURE [Roadside].[uspSetLoadTypeFlag]

AS 
/*
	Purpose:	Checks whether we have sufficient information supplied to provide to do 
				a normal VWT load and sets the PerformNormalVWTLoadFlag accordingly.

	Version			Date			Developer			Comment
	1.0				14/10/2013		Chris Ross			Original version.
	1.1				07/03/2014		Chris Ross			BUG 10075 - Add in check for South Africa and CustUniqueID
	1.2				28/04/2015		Eddie Thomas		BUG 11215 - Added email matching for MENA Roadside set-up
	1.3				21/06/2017		Chris Ledger		BUG 13957 - Add telephone matching for Russia Roadside set-up
	1.4				28/03/2018		Chris Ledger		BUG 14610 - Remove CustomerUniqueId Matching for South Africa
	1.5				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		DECLARE @AddressMatching int, @EmailMatching int, @TelephoneMatching int
		SELECT @AddressMatching = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies pmm WHERE PartyMatchingMethodology = 'Name and Postal Address'
		SELECT @EmailMatching = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies pmm WHERE PartyMatchingMethodology = 'Name and Email Address'
		SELECT @TelephoneMatching = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies pmm WHERE PartyMatchingMethodology = 'Name and Telephone Number'		--V1.3
		

		UPDATE re
		SET PerformNormalVWTLoadFlag = CASE WHEN (    (ISNULL(SurnameField1, '') <> '' OR ISNULL(CompanyName , '') <> '' )
												  AND (  ISNULL(Address1, '') <> '' 
												         AND m.PartyMatchingMethodologyID = @AddressMatching
													  )
													 OR
													  ( ISNULL(COALESCE(EmailAddress1, EmailAddress2), '') <> '' 
												        AND m.PartyMatchingMethodologyID = @EmailMatching
												      )
													 OR															--V1.3
													  ( ISNULL(MobileTelephoneNumber, '') <> ''					
												        AND m.PartyMatchingMethodologyID = @TelephoneMatching		
												      )															
												  ) 
											 --OR  (CountryCode = 'ZA' AND ISNULL(CustomerUniqueId, '') <> '' )  --v1.1	-- V1.4
										THEN 'Y'
										ELSE 'N' END
		FROM Roadside.RoadsideEvents re
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha2 = re.CountryCode
		INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = c.CountryID
		WHERE PerformNormalVWTLoadFlag IS NULL

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