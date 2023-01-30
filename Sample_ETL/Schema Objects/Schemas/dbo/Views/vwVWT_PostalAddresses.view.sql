CREATE VIEW [dbo].[vwVWT_PostalAddresses]
AS

/*
	Purpose:	List of distinct ContactMechanismIDs and their associated checksums from AUDIT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		(Unknown)		Created from proc in [Prophet-ETL] database
	1.1				14/11/2013		Chris Ross			Bug 9678 - Add in Postcode

*/


SELECT
	AuditItemID,
	AddressParentAuditItemID,
	CountryID,
	MatchedODSAddressID,
	AddressChecksum,					
	Postcode					
FROM dbo.VWT
WHERE ISNULL(AddressChecksum, 0) <> 0














