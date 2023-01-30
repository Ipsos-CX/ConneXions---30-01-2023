CREATE TABLE [Audit].[CaseContactMechanismOutcomes] (
    [AuditItemID]                    dbo.AuditItemID         NOT NULL,
    [CaseID]                         dbo.CaseID         NULL,
    [PartyID]                        dbo.PartyID         NULL,
    [OutcomeCode]                    dbo.OutcomeCode            NULL,
    [OutcomeCodeTypeID]              dbo.OutcomeCodeTypeID            NULL,
    [ContactMechanismID]             dbo.ContactMechanismID            NULL,
    [EmailAddress]              dbo.EmailAddress NULL,
    [ActionDate]                     DATETIME2       NULL,
    [CasePartyEmailCombinationValid] BIT            NULL,
    [MobileNumber]					 [dbo].[TelephoneNumber] NULL,
    [CasePartyMobileCombinationValid] BIT            NULL,
   	[TelephoneNumber]				 dbo.ContactNumber NULL,    
	[CasePartyPhoneCombinationValid] BIT			   NULL,
    [CasePartyCombinationValid]		 BIT			NULL
);

