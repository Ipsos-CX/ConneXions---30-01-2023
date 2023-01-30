CREATE  PROCEDURE [dbo].[uspVWT_DedupePostalAddress]

AS

/*
	Purpose:	Identify which addreses are the same in the VWT by assigning an AuditItemID
				(Individual row) to act as the Parent.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspDEDUPE_VWTAddresses
	1.1				14/11/2013		Chris Ross			9678 - Add in additional matching on postcode
	1.2				06/12/2013		Chris Ross			9678/9788 - Fixed issue where NULL postcodes in Warranty recs failing proc
	1.3				05/10/2021		Chris Ledger		Task 644 - Add in additional matching on CountryID to avoid addresses from different countries being assigned same Parent

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @AddressChecksumDistinct TABLE
	(
		AddressChecksum BIGINT, 
		Postcode NVARCHAR(60),														-- V1.2
		CountryID dbo.CountryID,													-- V1.3
		ParentAddressAuditItemID dbo.AuditItemID,
		UNIQUE(AddressChecksum,	Postcode, CountryID, ParentAddressAuditItemID)		-- V1.3
	)

	DECLARE @AddressChecksum TABLE
	(
		AuditItemID dbo.AuditItemID,
		AddressParentAuditItemID dbo.AuditItemID, 
		CountryID dbo.CountryID,
		MatchedODSAddressID dbo.ContactMechanismID,
		AddressChecksum BIGINT,
		Postcode  NVARCHAR(60),														-- V1.2
		UNIQUE(AddressChecksum,	Postcode, CountryID, AuditItemID)					-- V1.3
	)

	INSERT INTO @AddressChecksumDistinct
	(
		AddressChecksum,
		Postcode,
		CountryID,																	-- V1.3
		ParentAddressAuditItemID
	)
	SELECT 
		AddressChecksum, 
		Postcode, 
		CountryID,																	-- V1.3
		MIN(AuditItemID) AS ParentAddressAuditItemID
	FROM dbo.vwVWT_PostalAddresses 
	GROUP BY AddressChecksum, Postcode, CountryID									-- V1.3


	INSERT INTO @AddressChecksum
	(
		AuditItemID,
		AddressParentAuditItemID, 
		CountryID,
		MatchedODSAddressID,
		AddressChecksum,
		Postcode
	)
	SELECT 
		AuditItemID,
		AddressParentAuditItemID, 
		CountryID,
		MatchedODSAddressID,
		AddressChecksum,
		Postcode
	FROM dbo.vwVWT_PostalAddresses 

	UPDATE A 
	SET A.AddressParentAuditItemID = DistinctAddress.ParentAddressAuditItemID 
	FROM @AddressChecksum A
	INNER JOIN 
		(
			SELECT 
				AddressChecksum, 
				Postcode,
				CountryID,															-- V1.3
				ParentAddressAuditItemID
			FROM @AddressChecksumDistinct
		) AS DistinctAddress 
	ON A.AddressChecksum = DistinctAddress.AddressChecksum
	AND A.Postcode = DistinctAddress.Postcode
	AND A.CountryID = DistinctAddress.CountryID										-- V1.3

	UPDATE VWT
	SET VWT.AddressParentAuditItemID = A.AddressParentAuditItemID
	FROM @AddressChecksum A
	INNER JOIN VWT ON A.AuditItemID = VWT.AuditItemID
	
	-- SET THE AddressParentAuditItemID IN THE VWT TO BE SAME AS THE AuditItemID WHERE WE'VE NOT ALREADY SET IT
	UPDATE dbo.VWT
	SET AddressParentAuditItemID = AuditItemID
	WHERE AddressParentAuditItemID IS NULL
	
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