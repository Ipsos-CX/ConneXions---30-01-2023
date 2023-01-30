CREATE VIEW Lookup.vwPartyPostalAddresses
AS

	SELECT DISTINCT
		PCM.PartyID,
		PA.ContactMechanismID
	FROM [$(SampleDB)].ContactMechanism.PostalAddresses PA
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = PA.ContactMechanismID


