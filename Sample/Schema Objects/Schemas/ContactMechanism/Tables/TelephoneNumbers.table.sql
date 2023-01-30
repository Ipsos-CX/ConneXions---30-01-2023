CREATE TABLE [ContactMechanism].[TelephoneNumbers] (
    [ContactMechanismID] dbo.ContactMechanismID           NOT NULL,
    [ContactNumber]      dbo.ContactNumber NOT NULL,
    [ContactNumberChecksum] AS CHECKSUM(ContactNumber) PERSISTED
);

