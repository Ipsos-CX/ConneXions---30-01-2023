CREATE INDEX [IX_BlacklistContactMechanisms_BlacklistStringID] 
	ON [ContactMechanism].[BlacklistContactMechanisms] ([BlacklistStringID]) 
	INCLUDE ([ContactMechanismID])