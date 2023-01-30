ALTER TABLE [ContactMechanism].[BlacklistContactMechanisms]
    ADD CONSTRAINT [PK_BlacklistContactMechanisms] PRIMARY KEY CLUSTERED ([ContactMechanismID] ASC, [BlacklistStringID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

