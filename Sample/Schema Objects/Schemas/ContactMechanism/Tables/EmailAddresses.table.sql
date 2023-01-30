CREATE TABLE [ContactMechanism].[EmailAddresses] (
    [ContactMechanismID] dbo.ContactMechanismID            NOT NULL,
    [EmailAddress]  dbo.EmailAddress NOT NULL,
    [EmailAddressChecksum] AS CHECKSUM(EmailAddress) PERSISTED
);

