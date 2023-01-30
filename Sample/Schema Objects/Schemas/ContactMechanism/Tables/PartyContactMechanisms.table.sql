CREATE TABLE [ContactMechanism].[PartyContactMechanisms] (
    [ContactMechanismID]       dbo.ContactMechanismID           NOT NULL,
    [PartyID]                  dbo.PartyID           NOT NULL,
    [RoleTypeID]               dbo.RoleTypeID      NULL,
    [FromDate]                 DATETIME2      NOT NULL
);

