CREATE TABLE [Party].[BlacklistStringNonSolicitations] (
    [BlacklistStringID]     dbo.BlacklistStringID      NOT NULL,
    [NonSolicitationTextID] dbo.NonSolicitationTextID NOT NULL,
    [FromDate]              DATETIME2 NOT NULL
);

