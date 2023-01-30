CREATE TABLE [dbo].[NonSolicitationTexts] (
    [NonSolicitationTextID]          dbo.NonSolicitationTextID      IDENTITY (1, 1) NOT NULL,
    [NonSolicitationText]            NVARCHAR(50) NOT NULL,
    [NonSolicitationTextAbbreviated] NVARCHAR(50) NOT NULL
);

