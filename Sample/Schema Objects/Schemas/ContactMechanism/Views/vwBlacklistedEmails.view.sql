
CREATE VIEW [ContactMechanism].[vwBlacklistedEmail]

AS

SELECT 
	BCM.ContactMechanismID,
	BCM.ContactMechanismTypeID,
	EA.EmailAddress,
	BCM.FromDate,
	CMBT.BlacklistTypeID,
	CMBT.BlacklistType,
	CMBT.PreventsSelection,
	AFRLFilter
FROM ContactMechanism.ContactMechanisms CM
INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON CM.ContactMechanismID = BCM.ContactMechanismID
INNER JOIN ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
INNER JOIN ContactMechanism.EmailAddresses EA ON CM.ContactMechanismID = EA.ContactMechanismID

