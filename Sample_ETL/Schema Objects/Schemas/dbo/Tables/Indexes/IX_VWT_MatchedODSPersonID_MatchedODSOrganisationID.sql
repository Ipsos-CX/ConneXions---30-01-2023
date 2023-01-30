CREATE NONCLUSTERED INDEX [IX_VWT_MatchedODSPersonID_MatchedODSOrganisationID]
	ON [dbo].[VWT] ([MatchedODSPersonID],[MatchedODSOrganisationID],[MatchedODSPartyID],[MatchedODSAddressID])