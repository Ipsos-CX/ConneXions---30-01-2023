ALTER TABLE [ContactMechanism].[NonSolicitations]
    ADD CONSTRAINT [PK_ContactMechanismNonSolicitations] PRIMARY KEY CLUSTERED ([NonSolicitationID] ASC, [ContactMechanismID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

