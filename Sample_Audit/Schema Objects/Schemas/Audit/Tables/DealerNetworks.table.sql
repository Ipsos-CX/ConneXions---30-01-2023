CREATE TABLE [Audit].[DealerNetworks] (
    [AuditItemID]     BIGINT         NOT NULL,
    [PartyIDFrom]     INT            NOT NULL,
    [PartyIDTo]       INT            NOT NULL,
    [RoleTypeIDFrom]  SMALLINT       NOT NULL,
    [RoleTypeIDTo]    SMALLINT       NOT NULL,
    [FromDate]        DATETIME       NOT NULL,
    [DealerCode]      NVARCHAR (20)  NOT NULL,
    [DealerShortName] NVARCHAR (150) NULL
);

