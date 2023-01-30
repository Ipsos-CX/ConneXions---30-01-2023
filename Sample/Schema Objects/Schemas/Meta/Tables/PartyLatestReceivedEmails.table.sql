CREATE TABLE [Meta].[PartyLatestReceivedEmails] (
    [PartyID]            [dbo].[PartyID]            NOT NULL,
    [EventCategoryID]	 [dbo].[EventCategoryID]	NOT NULL,
    PartyType			 CHAR(1)					NOT NULL,
    [LatestAuditItemID]  [dbo].[AuditItemID]        NOT NULL,
    [ContactMechanismID] [dbo].[ContactMechanismID] NULL,
    [EmailAddressSource] [dbo].[EmailAddressSource] NULL,
    [EmailPriorityOrder]  INT NOT NULL
);

