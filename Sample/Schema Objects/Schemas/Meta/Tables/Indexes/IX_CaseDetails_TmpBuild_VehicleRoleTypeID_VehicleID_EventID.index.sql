CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_VehicleRoleTypeID_VehicleID_EventID] 
	ON [Meta].[CaseDetails_TmpBuild] ([VehicleRoleTypeID], [VehicleID], [EventID]) 
	INCLUDE ([QuestionnaireRequirementID])