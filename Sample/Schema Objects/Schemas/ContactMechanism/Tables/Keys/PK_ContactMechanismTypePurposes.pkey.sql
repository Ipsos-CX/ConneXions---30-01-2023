ALTER TABLE [ContactMechanism].[ContactMechanismTypePurposes]
    ADD CONSTRAINT [PK_ContactMechanismTypePurposes] PRIMARY KEY CLUSTERED ([ContactMechanismTypeID] ASC, [ContactMechanismPurposeTypeID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

