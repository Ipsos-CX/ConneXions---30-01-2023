CREATE NONCLUSTERED INDEX [IX_SampleQualityAndSelectionLogging_VehicleIDEventID] 
	ON [dbo].[SampleQualityAndSelectionLogging]
	(
		[MatchedODSVehicleID] ASC,
		[MatchedODSEventID] ASC
	)
	INCLUDE ([AuditItemID],
		[EventDateOutOfDate],
		[CaseID],
		[EventDateTooYoung])
GO
