CREATE VIEW Audit.vwPostalAddresses

AS

/*
	Purpose:	List of distinct ContactMechanismIDs and their associated checksums from AUDIT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.vwAUDIT_Addresses
	1.1				14/11/2013		Chris Ross			Bug 9678 - Add in Postcode checking

*/

SELECT DISTINCT 
	ContactMechanismID,
	CountryID,
	AddressChecksum,					
	Postcode		
FROM [$(AuditDB)].Audit.PostalAddresses













