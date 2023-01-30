ALTER TABLE [SampleReport].[GlobalReportDealerRegionDistinctEventAggregate]
	ADD CONSTRAINT [PK_GlobalReportDealerRegionDistinctEventAggregate]
	PRIMARY KEY (ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire, SuperNationalRegion, BusinessRegion, SubNationalTerritory, SubNationalRegion, DealerCode, DealerName)