CREATE NONCLUSTERED INDEX [IX_SampleQualityAndSelectionLogging_NonLatestEvent_Person] 
	ON [dbo].[SampleQualityAndSelectionLogging]
	(
		[MatchedODSVehicleID] ASC,
		[MatchedODSPersonID] ASC,
		[SalesDealerID] ASC,
		[NonLatestEvent] ASC,
		[LostLeadDate] ASC
	)
	INCLUDE ([AuditItemID]) 
