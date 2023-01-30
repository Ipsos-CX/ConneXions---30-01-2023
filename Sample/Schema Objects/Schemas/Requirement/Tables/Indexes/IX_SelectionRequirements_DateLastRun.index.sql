CREATE INDEX [IX_SelectionRequirements_DateLastRun] 
	ON [Requirement].[SelectionRequirements] ([DateLastRun]) 
	INCLUDE ([RequirementID], [SelectionDate], [SelectionStatusTypeID], [RecordsSelected], [RecordsRejected], [LastViewedDate], [LastViewedPartyID], [LastViewedRoleTypeID], [DateOutputAuthorised], [AuthorisingPartyID], [AuthorisingRoleTypeID])
