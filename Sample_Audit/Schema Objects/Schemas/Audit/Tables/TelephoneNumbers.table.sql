CREATE TABLE [Audit].[TelephoneNumbers] (
    [AuditItemID]           [dbo].[AuditItemID]        NOT NULL,
    [ContactMechanismID]    [dbo].[ContactMechanismID] NOT NULL,
    [ContactNumber]         [dbo].[TelephoneNumber]    NOT NULL,
    [ContactNumberChecksum] AS                         (checksum([ContactNumber])) PERSISTED
);



