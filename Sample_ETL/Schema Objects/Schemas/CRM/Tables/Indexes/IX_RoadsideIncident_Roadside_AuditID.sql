CREATE INDEX [IX_RoadsideIncident_Roadside_AuditID]
	ON [CRM].[RoadsideIncident_Roadside] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])
