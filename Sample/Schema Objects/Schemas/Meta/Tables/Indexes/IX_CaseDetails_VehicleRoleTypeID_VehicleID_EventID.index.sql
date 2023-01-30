CREATE NONCLUSTERED INDEX [IX_CaseDetails_VehicleRoleTypeID_VehicleID_EventID] 
	ON [Meta].[CaseDetails] ([VehicleRoleTypeID], [VehicleID], [EventID]) 
	INCLUDE ([QuestionnaireRequirementID])

