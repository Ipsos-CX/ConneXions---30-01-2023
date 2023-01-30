CREATE VIEW Match.vwEmailAddresses

AS

SELECT DISTINCT 
	ContactMechanismID, 
	EmailAddress, 
	EmailAddressChecksum
FROM [$(SampleDB)].ContactMechanism.EmailAddresses



















