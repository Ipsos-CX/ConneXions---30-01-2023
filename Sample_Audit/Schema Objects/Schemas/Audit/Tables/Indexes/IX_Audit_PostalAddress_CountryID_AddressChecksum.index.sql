CREATE NONCLUSTERED INDEX [IX_Audit_PostalAddress_CountryID_AddressChecksum] 
	ON [Audit].[PostalAddresses]	([CountryID] ASC, [AddressChecksum] ASC)
	INCLUDE ([ContactMechanismID],	[PostCode])