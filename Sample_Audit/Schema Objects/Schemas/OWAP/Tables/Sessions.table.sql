CREATE TABLE [OWAP].[Sessions] (
    [AuditID]         dbo.AuditID         NOT NULL,
    [SessionID]       VARCHAR(100) NOT NULL,
    [UserPartyRoleID] dbo.PartyRoleID            NOT NULL,
    [SessionTimeStamp] DATETIME2 NULL
);

