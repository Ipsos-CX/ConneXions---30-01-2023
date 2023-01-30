CREATE TABLE [Meta].[PartyBestEmailAddressesLatestOnly] (
    [PartyID]            [dbo].[PartyID]            NOT NULL,
    [EventCategoryID]	 [dbo].[EventCategoryID]	NOT NULL,
    [LatestAuditItemID]  [dbo].[AuditItemID]        NOT NULL,
    [ContactMechanismID] [dbo].[ContactMechanismID] NOT NULL,
    [EmailAddressSource] [dbo].[EmailAddressSource] NULL
);
