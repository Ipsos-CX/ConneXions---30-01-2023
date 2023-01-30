CREATE VIEW ContactMechanism.vwDA_ContactMechanisms

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	ContactMechanismID, 
	ContactMechanismTypeID, 
	Valid
FROM ContactMechanism.ContactMechanisms


