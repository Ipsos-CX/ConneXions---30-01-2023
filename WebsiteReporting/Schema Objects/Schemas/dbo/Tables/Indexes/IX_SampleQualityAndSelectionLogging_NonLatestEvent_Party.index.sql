CREATE NONCLUSTERED INDEX [IX_SampleQualityAndSelectionLogging_NonLatestEvent_Party] 
	ON [dbo].[SampleQualityAndSelectionLogging]
	(
		[MatchedODSVehicleID] ASC,
		[MatchedODSPartyID] ASC,
		[SalesDealerID] ASC,
		[NonLatestEvent] ASC,
		[LostLeadDate] ASC
	)
	INCLUDE ([AuditItemID]) 
