CREATE TABLE [Event].[CaseContactMechanismOutcomes] (
    [CaseID]              dbo.CaseID   NOT NULL,
    [OutcomeCode]         dbo.OutcomeCode      NOT NULL,
    [OutcomeCodeTypeID]   dbo.OutcomeCodeTypeID      NOT NULL,
    [ContactMechanismID]  dbo.ContactMechanismID      NOT NULL,
    [ActionDate]          DATETIME2 NOT NULL,
    [ReOutputProcessed]   BIT      NOT NULL,
    [ReOutputProcessDate] DATETIME2 NULL,
    [ReOutputSuccess]     BIT      NOT NULL
);

