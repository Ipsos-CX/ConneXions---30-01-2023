CREATE TABLE [ContactMechanism].[OutcomeCodes] (
    [OutcomeCode]         dbo.OutcomeCode           NOT NULL,
    [OutcomeCodeTypeID]   dbo.OutcomeCodeTypeID           NOT NULL,
    [Outcome]         VARCHAR(100) NULL,
    [NonSolicitationType] VARCHAR(50)  NULL,
    [CausesReOutput]      BIT           NOT NULL,
    [HardBounce]		  BIT NULL,
	[SoftBounce]		  BIT NULL,
	[Unsubscribe]		  BIT NULL
);

