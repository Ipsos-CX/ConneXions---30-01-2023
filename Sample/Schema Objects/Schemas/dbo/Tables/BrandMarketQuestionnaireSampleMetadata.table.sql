CREATE TABLE [dbo].[BrandMarketQuestionnaireSampleMetadata] (
    [BMQID]                       INT                   NOT NULL,
    [SampleFileID]                INT                   NOT NULL,
    [SetNameCapitalisation]       BIT                   NOT NULL,
    [QuestionnaireRequirementID]  [dbo].[RequirementID] NOT NULL,
    [DealerCodeOriginatorPartyID] [dbo].[PartyID]       NULL,
    [SelectionName]               [dbo].[Requirement]   NOT NULL,
    [CreateSelection]             BIT                   NOT NULL,
    [Enabled]                     BIT                   NOT NULL,
    [UpdateSelectionLogging]      BIT                   NOT NULL,
    [SampleTriggeredSelection]    BIT					NOT NULL
);


