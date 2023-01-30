CREATE NONCLUSTERED INDEX [IX_SampleQualityAndSelectionLogging_NonLatestEvent_Organisation] 
	ON [dbo].[SampleQualityAndSelectionLogging]
	(
		[MatchedODSVehicleID] ASC,
		[MatchedODSOrganisationID] ASC,
		[SalesDealerID] ASC,
		[NonLatestEvent] ASC,
		[LostLeadDate] ASC
	)
	INCLUDE ([AuditItemID]) 
