CREATE TABLE [Requirement].[SelectionRequirements] (
    [RequirementID]         dbo.RequirementID      NOT NULL,
    [SelectionDate]         DATETIME2 NOT NULL,
    [SelectionStatusTypeID] dbo.SelectionStatusTypeID NOT NULL,
    [SelectionTypeID]       dbo.SelectionTypeID NULL,
    [DateLastRun]           DATETIME2 NULL,
    [RecordsSelected]       INT      NULL,
    [RecordsRejected]       INT      NULL,
    [LastViewedDate]        DATETIME2 NULL,
    [LastViewedPartyID]     dbo.PartyID      NULL,
    [LastViewedRoleTypeID]  dbo.RoleTypeID NULL,
    [DateOutputAuthorised]  DATETIME2 NULL,
    [AuthorisingPartyID]    dbo.PartyID      NULL,
    [AuthorisingRoleTypeID] dbo.RoleTypeID NULL,
    [ScheduledRunDate]      DATETIME2 NULL,
    [UseQuotas]				BIT NULL
);

