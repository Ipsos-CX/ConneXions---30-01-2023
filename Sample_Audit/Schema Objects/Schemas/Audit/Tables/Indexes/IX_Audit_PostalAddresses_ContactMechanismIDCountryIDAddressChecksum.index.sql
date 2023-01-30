/*CREATE NONCLUSTERED INDEX [IX_Audit_PostalAddresses_ContactMechanismIDCountryIDAddressChecksum]
    ON [Audit].[PostalAddresses]([ContactMechanismID] ASC, [CountryID] ASC, [AddressChecksum] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);*/

