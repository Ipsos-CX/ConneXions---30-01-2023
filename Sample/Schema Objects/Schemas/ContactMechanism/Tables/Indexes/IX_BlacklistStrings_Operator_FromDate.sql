CREATE NONCLUSTERED INDEX [IX_BlacklistStrings_Operator_FromDate]
	ON [ContactMechanism].[BlacklistStrings] ([Operator],[FromDate])
	INCLUDE ([BlacklistStringID],[BlacklistString],[Throughdate])