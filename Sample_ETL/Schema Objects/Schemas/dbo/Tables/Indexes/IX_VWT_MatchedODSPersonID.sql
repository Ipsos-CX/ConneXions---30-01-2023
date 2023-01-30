CREATE NONCLUSTERED INDEX [IX_VWT_MatchedODSPersonID]
	ON [dbo].[VWT] ([MatchedODSPersonID])
	INCLUDE ([AuditItemID],[PartyMatchingMethodologyID],[PersonParentAuditItemID],[Initials],[FirstName],[LastName],[MatchedODSAddressID],[CountryID],[ODSEventTypeID])
