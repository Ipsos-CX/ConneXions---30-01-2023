CREATE TABLE [SelectionOutput].[SelectionsToOutput] (
    [Brand]                        dbo.OrganisationName NOT NULL,
    [Market]                       dbo.Country NOT NULL,
    [Questionnaire]                dbo.Requirement NOT NULL,
    [SelectionRequirementID]       dbo.RequirementID        NOT NULL,
    [IncludeEmailOutputInAllFile]  BIT           NOT NULL,
    [IncludePostalOutputInAllFile] BIT           NOT NULL,
    [IncludeCATIOutputInAllFile]   BIT           NOT NULL,
    [IncludeSMSOutputInAllFile]    BIT           NOT NULL,
    [ReOutput]                     BIT           NOT NULL,
    [Processed]                    BIT           NOT NULL,
    [ContactMethodologyTypeID]     dbo.ContactMethodologyTypeID           NULL, 
    [DateProcessed] DATETIME2 NULL
);

