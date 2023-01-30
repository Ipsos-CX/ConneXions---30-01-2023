CREATE TABLE [Requirement].[QuestionnaireValidSaleTypes] (
    [RequirementID] dbo.RequirementID      NOT NULL,
    [SalesType]   VARCHAR(50) NOT NULL,
    [FromDate]      DATETIME2 NOT NULL,
    [ThroughDate]   DATETIME2 NULL
);