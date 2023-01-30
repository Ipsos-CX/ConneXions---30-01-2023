CREATE NONCLUSTERED INDEX [IX_VIN,ModelID,ModelDescription,ModelVariantID,Variant,EV_FLAG] ON [dbo].[ChinaVINsReport]
(
	[ReportDate] ASC
)
INCLUDE ( 	[VIN],
	[ModelID],
	[ModelDescription],
	[ModelVariantID],
	[Variant],
	[EV_FLAG]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
