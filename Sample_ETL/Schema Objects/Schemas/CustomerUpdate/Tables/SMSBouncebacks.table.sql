CREATE TABLE [CustomerUpdate].[SMSBouncebacks] (
	[ID]							 INT IDENTITY(1,1)      NOT NULL ,
    [PartyID]                        dbo.PartyID            NOT NULL,
    [CaseID]                         dbo.CaseID             NOT NULL,
    [ContactMechanismID]             dbo.ContactMechanismID NULL,
    [MobileNumber]					 [dbo].[ContactNumber]  NULL,
    [OutcomeCode]                    dbo.OutcomeCode        NULL,
    [AuditID]                        dbo.AuditID         NULL,
    [AuditItemID]                    dbo.AuditItemID     NULL,
    [ParentAuditItemID]              dbo.AuditItemID     NULL,
    [CasePartyMobileCombinationValid] BIT             NOT NULL,
    [DateLoaded]                     DATETIME2       NOT NULL,
    [DateProcessed]                  DATETIME2       NULL
);

