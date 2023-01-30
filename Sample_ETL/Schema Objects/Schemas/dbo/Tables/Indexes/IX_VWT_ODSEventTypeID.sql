CREATE NONCLUSTERED INDEX [IX_VWT_ODSEventTypeID]
	ON [dbo].[VWT] ([ODSEventTypeID])
	INCLUDE ([AuditItemID],[MatchedODSPartyID],[MatchedODSPersonID],[PartySuppression],[MatchedODSOrganisationID],[CountryID],[PostalSuppression],[EmailSuppression],[PhoneSuppression])
