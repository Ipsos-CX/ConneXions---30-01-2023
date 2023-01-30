-- this is taken from Sample_Audit.Match.uspPostalAddresses and is used to populate a temporary table


SELECT 
	ContactMechanismID,
	CountryID,
	AddressChecksum
FROM Audit.vwPostalAddresses