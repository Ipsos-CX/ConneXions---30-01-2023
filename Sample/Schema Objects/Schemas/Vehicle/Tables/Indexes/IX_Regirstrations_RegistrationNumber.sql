CREATE NONCLUSTERED INDEX [IX_Regirstrations_RegistrationNumber]
ON [Vehicle].[Registrations] ([RegistrationNumber])
	INCLUDE ([RegistrationID])
GO