ALTER TABLE [ContactMechanism].[PartyContactMechanismPurposes]
    ADD CONSTRAINT [PK_PartyContactMechanismPurposes] PRIMARY KEY CLUSTERED ([ContactMechanismID] ASC, [PartyID] ASC, [ContactMechanismPurposeTypeID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

