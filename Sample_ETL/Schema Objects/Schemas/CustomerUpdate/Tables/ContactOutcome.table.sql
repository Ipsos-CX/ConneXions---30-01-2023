CREATE TABLE [CustomerUpdate].[ContactOutcome] (
	[ID]							INT IDENTITY(1,1) NOT NULL ,
    [PartyID]                        dbo.PartyID            NOT NULL,
    [CaseID]                         dbo.CaseID         NOT NULL,
    [ContactMechanismID]             dbo.ContactMechanismID            NULL,
    [EmailAddress]					 dbo.EmailAddress NULL,
	[TelephoneNumber]				 dbo.ContactNumber NULL,    
    [OutcomeCode]                    dbo.OutcomeCode            NOT NULL,
    [AuditID]                        dbo.AuditID         NULL,
    [AuditItemID]                    dbo.AuditItemID         NULL,
    [ParentAuditItemID]              dbo.AuditItemID         NULL,
    [CasePartyEmailCombinationValid] BIT            NOT NULL,
    [CasePartyPhoneCombinationValid] BIT			NULL,
    [CasePartyCombinationValid]		 BIT			NULL,
    [DateLoaded]                     DATETIME2       NOT NULL,
    [DateProcessed]                  DATETIME2       NULL,
	[MedalliaDuplicate]				 BIT			 NULL
);

