CREATE TABLE [Requirement].[Requirements] (
    [RequirementID]           dbo.RequirementID IDENTITY (1, 1) NOT NULL,
    [RequirementTypeID]       dbo.RequirementTypeID NOT NULL,
    --[FacilityID]              INT            NULL,
    [Requirement]             dbo.Requirement NOT NULL,
    [RequirementCreationDate] DATETIME2       NULL,
    --[RquiredByDate]           DATETIME       NULL,
    --[EstimatedBudget]         INT            NULL,
    --[Quantity]                SMALLINT       NULL,
    --[Reason]                  NVARCHAR (255) NULL
);

