ALTER TABLE [Event].[CaseContactMechanismOutcomes]
    ADD CONSTRAINT [PK_CaseContactMechanismOutcomes] PRIMARY KEY CLUSTERED ([CaseID] ASC, [OutcomeCode] ASC, [OutcomeCodeTypeID] ASC, [ContactMechanismID] ASC, [ActionDate] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

